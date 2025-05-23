//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 30.04.2025.
//

import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    
    private var movies: [MostPopularMovie] = []
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate) {
        self.delegate = delegate
        self.moviesLoader = moviesLoader
    }
    
    private enum QuestionType {
        case ratingHigherThan(value: Float)
        case ratingLowerThan(value: Float)
        case yearAfter(value: Int)
        case yearBefore(value: Int)
    }
    
    private func generateQuestion(for movie: MostPopularMovie) -> QuizQuestion? {
        // Выбираем случайный тип вопроса
        let questionTypes: [QuestionType] = [
            .ratingHigherThan(value: 7),
            .ratingHigherThan(value: 8),
            .ratingLowerThan(value: 6),
            .yearAfter(value: 2010),
            .yearBefore(value: 2000)
        ]
        
        guard let randomType = questionTypes.randomElement() else { return nil }
        
        let (questionText, correctAnswer) = createQuestion(for: movie, type: randomType)
        
        do {
            let imageData = try Data(contentsOf: movie.resizedImageURL)
            return QuizQuestion(image: imageData,
                                text: questionText,
                                correctAnswer: correctAnswer)
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
    
    // метод генерации случайного вопроса
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // Выбираем случайный фильм
            guard let randomMovie = self.movies.randomElement() else { return }
            
            // Генерируем вопрос
            guard let question = self.generateQuestion(for: randomMovie) else {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didFailToLoadData(with: NSError(domain: "com.moviequiz", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось сгенерировать вопрос"]))
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    if !mostPopularMovies.errorMessage.isEmpty || mostPopularMovies.items.isEmpty {
                        let errorMessage = mostPopularMovies.errorMessage.isEmpty ? "Нет доступных фильмов." : mostPopularMovies.errorMessage
                        self.delegate?.didFailToLoadData(with: NSError(domain: "com.moviequiz", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                    } else {
                        self.movies = mostPopularMovies.items
                        self.delegate?.didLoadDataFromServer()
                    }
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
}
