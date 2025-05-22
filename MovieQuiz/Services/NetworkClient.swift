//
//  NetworkClient.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 20.05.2025.
//

import Foundation

protocol NetworkRouting {
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void)
    func cancel()
}

final class NetworkClient: NetworkRouting {
    
    // MARK: - Error Types
    enum NetworkError: LocalizedError {
        case codeError(Int)
        case invalidData
        case invalidResponse
        case requestFailed(Error)
        case cancelled
        case noNetworkConnection
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .codeError(let code):
                return "Server returned status code \(code)"
            case .invalidData:
                return "Received invalid data"
            case .invalidResponse:
                return "Invalid server response"
            case .requestFailed(let error):
                return "Request failed: \(error.localizedDescription)"
            case .cancelled:
                return "Request was cancelled"
            case .noNetworkConnection:
                return "No network connection available"
            case .timeout:
                return "Request timed out"
            }
        }
    }
    
    // MARK: - Configuration
    struct Configuration {
        var timeoutInterval: TimeInterval
        var maxRetries: Int
        var retryDelay: TimeInterval
        
        static let `default` = Configuration(
            timeoutInterval: 30,
            maxRetries: 2,
            retryDelay: 1.0
        )
    }
    
    // MARK: - Properties
    private let session: URLSession
    private var currentTask: URLSessionTask?
    private let config: Configuration
    private var retryCount = 0
    
    // MARK: - Initialization
    init(
        session: URLSession = URLSession(configuration: .default),
        config: Configuration = .default
    ) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeoutInterval
        configuration.timeoutIntervalForResource = config.timeoutInterval * 2
        configuration.waitsForConnectivity = true
        
        self.session = session
        self.config = config
    }
    
    // MARK: - Public Methods
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        cancelPendingRequest()
        
        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: config.timeoutInterval
        )
        
        executeRequest(request, handler: handler)
    }
    
    func cancel() {
        cancelPendingRequest()
    }
    
    // MARK: - Private Methods
    private func cancelPendingRequest() {
        currentTask?.cancel()
        currentTask = nil
        retryCount = 0
    }
    
    private func executeRequest(
        _ request: URLRequest,
        handler: @escaping (Result<Data, Error>) -> Void
    ) {
        logRequest(request)
        
        currentTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = self.handleError(error, for: request, handler: handler) {
                DispatchQueue.main.async {
                    handler(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logInvalidResponse()
                DispatchQueue.main.async {
                    handler(.failure(NetworkError.invalidResponse))
                }
                return
            }
            
            self.logResponse(httpResponse)
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    handler(.failure(NetworkError.codeError(httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data else {
                self.logInvalidData()
                DispatchQueue.main.async {
                    handler(.failure(NetworkError.invalidData))
                }
                return
            }
            
            self.logSuccess(data)
            DispatchQueue.main.async {
                handler(.success(data))
            }
        }
        
        currentTask?.resume()
    }
    
    private func handleError(
        _ error: Error?,
        for request: URLRequest,
        handler: @escaping (Result<Data, Error>) -> Void
    ) -> NetworkError? {
        guard let error = error else { return nil }
        
        logError(error)
        
        let nsError = error as NSError
        
        // Handle cancellation
        if nsError.code == NSURLErrorCancelled {
            logCancellation()
            return NetworkError.cancelled
        }
        
        // Handle retriable errors
        if shouldRetry(error: nsError) {
            retryCount += 1
            if retryCount <= config.maxRetries {
                DispatchQueue.global().asyncAfter(deadline: .now() + config.retryDelay) { [weak self] in
                    self?.executeRequest(request, handler: handler)
                }
                return NetworkError.cancelled // Temporary return to prevent completion
            }
        }
        
        // Map to our error types
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorCannotConnectToHost:
            return NetworkError.noNetworkConnection
        case NSURLErrorTimedOut:
            return NetworkError.timeout
        default:
            return NetworkError.requestFailed(error)
        }
    }
    
    private func shouldRetry(error: NSError) -> Bool {
        let retriableCodes = [
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost
        ]
        return retriableCodes.contains(error.code)
    }
    
    // MARK: - Logging
    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("""
        🌐 [Network] Starting request:
        URL: \(request.url?.absoluteString ?? "nil")
        Method: \(request.httpMethod ?? "GET")
        Timeout: \(request.timeoutInterval)s
        Headers: \(request.allHTTPHeaderFields ?? [:])
        """)
        #endif
    }
    
    private func logResponse(_ response: HTTPURLResponse) {
        #if DEBUG
        print("""
        🌐 [Network] Response:
        Status Code: \(response.statusCode)
        Headers: \(response.allHeaderFields as? [String: Any] ?? [:])
        """)
        #endif
    }
    
    private func logError(_ error: Error) {
        #if DEBUG
        let nsError = error as NSError
        print("""
        🛑 [Network] Error:
        Code: \(nsError.code)
        Domain: \(nsError.domain)
        Description: \(nsError.localizedDescription)
        """)
        #endif
    }
    
    private func logInvalidResponse() {
        #if DEBUG
        print("🛑 [Network] Invalid response")
        #endif
    }
    
    private func logInvalidData() {
        #if DEBUG
        print("🛑 [Network] Invalid data")
        #endif
    }
    
    private func logSuccess(_ data: Data) {
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("✅ [Network] Success (\(data.count) bytes):")
            print(jsonString.prefix(300))
        } else {
            print("✅ [Network] Success (\(data.count) bytes of binary data)")
        }
        #endif
    }
    
    private func logCancellation() {
        #if DEBUG
        print("⏹ [Network] Request cancelled")
        #endif
    }
}
