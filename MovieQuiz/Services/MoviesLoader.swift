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
            
            DispatchQueue.global(qos: .userInitiated).async {
                let decodedResult = self.decodeMovies(from: result)
                
                DispatchQueue.main.async {
                    handler(decodedResult)
                }
            }
        }
    }
    
    func cancel() {
        networkClient.cancel()
    }
    
    // MARK: - Private Methods
    private func decodeMovies(from result: Result<Data, Error>) -> Result<MostPopularMovies, Error> {
        switch result {
        case .success(let data):
            do {
                let movies = try decoder.decode(MostPopularMovies.self, from: data)
                return .success(movies)
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
