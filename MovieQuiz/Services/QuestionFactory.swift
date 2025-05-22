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
    
    // метод генерации случайного вопроса
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                // Обработка ошибки: передаем ошибку через делегат
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didFailToLoadData(with: NSError(domain: "com.moviequiz", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось загрузить изображение"]))
                }
                return
            }
            
            let rating = Float(movie.rating) ?? 0
            
            let text = "Рейтинг этого фильма больше чем 7?"
            let correctAnswer = rating > 7
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
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
