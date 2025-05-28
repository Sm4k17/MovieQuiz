//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 30.04.2025.
//

import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    
    // MARK: - Dependencies
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    
    // MARK: - Properties
    private var movies: [MostPopularMovie] = []
    
    // MARK: - Constants
    private let questionTypes: [QuestionType] = [
        .ratingHigherThan(value: 7),
        .ratingHigherThan(value: 8),
        .ratingLowerThan(value: 6),
        .yearAfter(value: 2010),
        .yearBefore(value: 2000)
    ]
    
    // MARK: - Question Type
    private enum QuestionType {
        case ratingHigherThan(value: Float)
        case ratingLowerThan(value: Float)
        case yearAfter(value: Int)
        case yearBefore(value: Int)
    }
    
    // MARK: - Initialization
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate) {
        self.delegate = delegate
        self.moviesLoader = moviesLoader
    }
    
    // MARK: - Public Methods
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            self?.handleLoadMovies(result)
        }
    }
    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            guard let randomMovie = self.movies.randomElement() else {
                self.notifyError(message: "Нет доступных фильмов для вопроса")
                return
            }
            
            guard let question = self.generateQuestion(for: randomMovie) else {
                self.notifyError(message: "Не удалось сгенерировать вопрос")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
    
    // MARK: - Private Methods
    private func handleLoadMovies(_ result: Result<MostPopularMovies, Error>) {
        DispatchQueue.main.async { [weak self] in
            switch result {
            case .success(let response):
                self?.handleMoviesSuccess(response)
            case .failure(let error):
                self?.delegate?.didFailToLoadData(with: error)
            }
        }
    }
    
    private func handleMoviesSuccess(_ response: MostPopularMovies) {
        guard response.errorMessage.isEmpty, !response.items.isEmpty else {
            let message = response.errorMessage.isEmpty
                ? "Нет доступных фильмов."
                : response.errorMessage
            notifyError(message: message)
            return
        }
        
        movies = response.items
        delegate?.didLoadDataFromServer()
    }
    
    private func notifyError(message: String) {
        let error = NSError(
            domain: "com.moviequiz",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didFailToLoadData(with: error)
        }
    }
    
    private func generateQuestion(for movie: MostPopularMovie) -> QuizQuestion? {
        guard let randomType = questionTypes.randomElement() else { return nil }
        
        let (questionText, correctAnswer) = createQuestion(for: movie, type: randomType)
        
        do {
            let imageData = try Data(contentsOf: movie.resizedImageURL)
            return QuizQuestion(
                image: imageData,
                text: questionText,
                correctAnswer: correctAnswer
            )
        } catch {
            return nil
        }
    }
    
    private func createQuestion(for movie: MostPopularMovie, type: QuestionType) -> (text: String, correctAnswer: Bool) {
        switch type {
        case .ratingHigherThan(let value):
            let rating = Float(movie.rating) ?? 0
            return ("Рейтинг этого фильма больше чем \(value)?", rating > value)
            
        case .ratingLowerThan(let value):
            let rating = Float(movie.rating) ?? 0
            return ("Рейтинг этого фильма меньше чем \(value)?", rating < value)
            
        case .yearAfter(let year):
            let movieYear = Int(movie.year) ?? 0
            return ("Этот фильм выпущен после \(year) года?", movieYear > year)
            
        case .yearBefore(let year):
            let movieYear = Int(movie.year) ?? 0
            return ("Этот фильм выпущен до \(year) года?", movieYear < year)
        }
    }
}
