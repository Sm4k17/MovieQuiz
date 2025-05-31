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
    private var top250MoviesURL: URL {
        guard let url = URL(string: "\(Constants.top250MoviesPath)/\(Constants.apiKey)") else {
            fatalError("Failed to construct mostPopularMoviesUrl. Please check API path and key.")
        }
        return url
    }
    
    deinit {
        cancel()
    }
    
    // MARK: - Public Methods
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        networkClient.fetch(url: top250MoviesURL) { [weak self] result in
            guard let self = self else { return }
            
            // Улучшенная обработка потока
            let decodedResult: Result<MostPopularMovies, Error>
            
            switch result {
            case .success(let data):
                decodedResult = self.decodeMovies(from: data)
            case .failure(let error):
                decodedResult = .failure(self.enrichError(error))
            }
            
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
            return .success(movies)
        } catch {
            return .failure(error)
        }
    }
    
    private func enrichError(_ error: Error) -> Error {
        // Можно добавить дополнительную информацию к ошибке
        return error
    }
}
