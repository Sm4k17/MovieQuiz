//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов 
//

import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - Outlets
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textLabel: UILabel!
    @IBOutlet weak private var counterLabel: UILabel!
    @IBOutlet weak private var noButtonOutlets: UIButton!
    @IBOutlet weak private var yesButtonOutlets: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var presenter: MovieQuizPresenter?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDependencies()
        configureUI()
        startInitialDataLoad()
    }
    
    private func configureDependencies() {
        presenter = MovieQuizPresenter(viewController: self)
    }
    
    private func configureUI() {
        imageView.layer.masksToBounds = true  // Оставляем здесь единожды
        imageView.layer.cornerRadius = 20
        resetImageBorder()  // Используем метод для сброса рамки
        imageView.backgroundColor = .clear
    }
    
    private func startInitialDataLoad() {
        showLoadingIndicator()
    }
    
    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: Any) {
        presenter?.yesButtonClicked()
        updateButtonsState(isEnabled: false)
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter?.noButtonClicked()
        updateButtonsState(isEnabled: false)
    }
    
    // MARK: - Private Methods
    func showLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator?.isHidden = false // говорим, что индикатор загрузки не скрыт
            self?.activityIndicator?.startAnimating() // включаем анимацию
        }
    }
    
    func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator?.isHidden = true
            self?.activityIndicator?.stopAnimating()
        }
    }
    
    func resetImageBorder() {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
    }

    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    func updateButtonsState(isEnabled: Bool) {
        noButtonOutlets.isEnabled = isEnabled
        yesButtonOutlets.isEnabled = isEnabled
        noButtonOutlets.alpha = isEnabled ? 1 : 0.5
        yesButtonOutlets.alpha = isEnabled ? 1 : 0.5
    }
    
    // Приватный метод вывода на экран вопроса, который принимает на вход вью модель вопроса и ничего не возвращает
    func show(quiz step: QuizStepViewModel) {
        resetImageBorder()  // Используем метод вместо дублирования кода
        
        UIView.transition(with: imageView,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            self.imageView.image = step.image
            self.textLabel.text = step.question
            self.counterLabel.text = step.questionNumber
        })
    }
}
