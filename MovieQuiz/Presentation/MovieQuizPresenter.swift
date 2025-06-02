//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 31.05.2025.
//

import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private weak var viewController: MovieQuizViewControllerProtocol?
    private var questionFactory: QuestionFactoryProtocol?
    private let statisticService: StatisticServiceProtocol
    private var alertPresenter: AlertPresenterProtocol
    
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = .zero
    var correctAnswers: Int = .zero
    var currentQuestion: QuizQuestion?
    
    init(
        viewController: MovieQuizViewControllerProtocol,
        questionFactory: QuestionFactoryProtocol? = nil,
        statisticService: StatisticServiceProtocol = StatisticService(),
        alertPresenter: AlertPresenterProtocol = AlertPresenter()
    ) {
        self.viewController = viewController
        self.statisticService = statisticService
        self.alertPresenter = alertPresenter
        self.alertPresenter.viewController = viewController as? UIViewController
        
        // Сначала создаем фабрику, потом загружаем данные
        let factory = questionFactory ?? QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        self.questionFactory = factory
        factory.loadData() // Загружаем данные через созданную фабрику
    }
    
    // MARK: - QuestionFactoryDelegate
    func didStartLoadingData() {
        viewController?.showLoadingIndicator()
    }
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        viewController?.hideLoadingIndicator()
        let message = error.localizedDescription
        showNetworkError(message: message)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    // Метод конвертации, который принимает моковый вопрос и возвращает вью модель для экрана вопроса
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    // MARK: - Actions
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    private func didAnswer(isCorrectAnswer: Bool) {
        guard isCorrectAnswer else { return }

        correctAnswers += 1
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        
        proceedWithAnswer(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    // Отображение результатов в сплывающем окне (чтобы не усложнять метод showNextQuestionOrResults, вывели алерты в отдельный)
    private func showResults(quiz result: QuizResultsViewModel) {
        
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,  // Теперь текст формируется в Presenter
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                self.restartGame()
            }
        )
        alertPresenter.showResults(quiz: alertModel)
    }
    
    private func showNetworkError(message: String) {
        viewController?.hideLoadingIndicator()
        
        let model = AlertModel(title: "Что-то пошло не так(",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            self.restartGame()
        }
        alertPresenter.showResults(quiz: model)
    }
    
    // Приватный метод, который содержит логику перехода в один из сценариев
    private func proceedToNextQuestionOrResults() {
        if self.isLastQuestion() {
            // Сохраняем результаты текущей игры
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            // Формируем текст статистики
            let text = """
                    \(statisticService.getStatisticsText(correct: correctAnswers, total: questionsAmount))
                    """
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            showResults(quiz: viewModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    // Приватный метод, который меняет цвет рамки
    private func proceedWithAnswer(isCorrect: Bool) {
        didAnswer(isCorrectAnswer: isCorrect)
        // Настройка анимации рамки
        let animation = CABasicAnimation(keyPath: "borderColor")
        animation.fromValue = UIColor.clear.cgColor
        animation.toValue = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        animation.duration = 0.3
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            // Плавное исчезновение рамки
            UIView.animate(withDuration: 0.3) {
                self.viewController?.resetImageBorder()
            }
            self.proceedToNextQuestionOrResults()
            self.viewController?.updateButtonsState(isEnabled: true)
        }
    }
}
