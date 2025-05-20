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

/// Отвечает за загрузку данных по URL
final class NetworkClient: NetworkRouting {
    
    // MARK: - Nested Types
    enum NetworkError: LocalizedError {
        case codeError(Int)
        case invalidData
        case invalidResponse
        case requestFailed(Error)
        case cancelled
        
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
            }
        }
    }
    
    // MARK: - Properties
    private let session: URLSession
    private var currentTask: URLSessionTask?
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        // Cancel previous task if exists
        cancel()
        
        let request = URLRequest(url: url, timeoutInterval: 30)
        logRequest(request)
        
        currentTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle cancellation
            if let error = error as? NSError, error.code == NSURLErrorCancelled {
                self.logCancellation()
                DispatchQueue.main.async {
                    handler(.failure(NetworkError.cancelled))
                }
                return
            }
            
            // Handle other errors
            if let error = error {
                self.logError(error)
                DispatchQueue.main.async {
                    handler(.failure(NetworkError.requestFailed(error)))
                }
                return
            }
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logInvalidResponse()
                DispatchQueue.main.async {
                    handler(.failure(NetworkError.invalidResponse))
                }
                return
            }
            
            self.logResponse(httpResponse)
            
            // Check status code
            guard (200..<300).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    handler(.failure(NetworkError.codeError(httpResponse.statusCode)))
                }
                return
            }
            
            // Validate data
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
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - Private Methods
    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("🌐 [Network] Starting request: \(request.url?.absoluteString ?? "nil")")
        #endif
    }
    
    private func logResponse(_ response: HTTPURLResponse) {
        #if DEBUG
        print("🌐 [Network] Response: \(response.statusCode)")
        #endif
    }
    
    private func logError(_ error: Error) {
        #if DEBUG
        print("🌐 [Network] Error: \(error.localizedDescription)")
        #endif
    }
    
    private func logInvalidResponse() {
        #if DEBUG
        print("🌐 [Network] Invalid response")
        #endif
    }
    
    private func logInvalidData() {
        #if DEBUG
        print("🌐 [Network] Invalid data")
        #endif
    }
    
    private func logSuccess(_ data: Data) {
        #if DEBUG
        print("🌐 [Network] Success: \(data.count) bytes")
        #endif
    }
    
    private func logCancellation() {
        #if DEBUG
        print("🌐 [Network] Request cancelled")
        #endif
    }
}
