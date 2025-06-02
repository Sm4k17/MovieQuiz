//
//  MoviesLoader.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 20.05.2025.
//

import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
    func cancel()
}

final class MoviesLoader: MoviesLoading {
    // MARK: - Dependencies
    private let networkClient: NetworkRouting
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    init(networkClient: NetworkRouting = NetworkClient()) {
        self.networkClient = networkClient
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Constants
    private enum Constants {
        static let apiKey = "k_zcuw1ytf"
        static let top250MoviesPath = "https://tv-api.com/en/API/Top250Movies"
    }
    
    // MARK: - Properties
    private var mostPopularMoviesUrl: URL {
        guard let url = URL(string: "\(Constants.top250MoviesPath)/\(Constants.apiKey)") else {
            assertionFailure("Failed to construct mostPopularMoviesUrl. Please check API path and key.")
            // Возвращаем дефолтный URL, который вызовет ошибку при использовании
            return URL(string: "https://invalid.url")!
        }
        return url
    }
    
    deinit {
        cancel()
    }
    
    // MARK: - Public Methods
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        networkClient.fetch(url: mostPopularMoviesUrl) { [weak self] result in
            guard let self = self else { return }
            
            let decodedResult: Result<MostPopularMovies, Error> = {
                switch result {
                case .success(let data):
                    return self.decodeMovies(from: data)
                case .failure(let error):
                    return .failure(self.enrichError(error))
                }
            }()
            
            DispatchQueue.main.async {
                handler(decodedResult)
            }
        }
    }
    
    func cancel() {
        networkClient.cancel()
    }
    
    // MARK: - Private Methods
    private func decodeMovies(from data: Data) -> Result<MostPopularMovies, Error> {
        do {
            let movies = try decoder.decode(MostPopularMovies.self, from: data)
            if movies.errorMessage.isNotEmpty {
                return .failure(NetworkError.serverError(movies.errorMessage))
            }
            return .success(movies)
        } catch {
            return .failure(error)
        }
    }
    
    private func enrichError(_ error: Error) -> Error {
        // Добавляем контекст к ошибке
        if (error as NSError).domain == NSURLErrorDomain {
            return NetworkError.connectionError(error)
        }
        return error
    }
}

// Дополнительные типы ошибок
enum NetworkError: Error {
    case connectionError(Error)
    case serverError(String)
    case invalidResponse
    case decodingError(Error)
}

extension String {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
