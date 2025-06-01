import UIKit


final class MovieQuizViewController: UIViewController {
    
    //  questionsAmount — общее количество вопросов для квиза. Пусть оно будет равно десяти.
    //  questionFactory — фабрика вопросов. Контроллер будет обращаться за вопросами к ней.
    //  currentQuestion — вопрос, который видит пользователь.
    
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticServiceProtocol?
    
    private var presenter: MovieQuizPresenter!
    
    // MARK: - Outlets
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textLabel: UILabel!
    @IBOutlet weak private var counterLabel: UILabel!
    @IBOutlet weak private var noButtonOutlets: UIButton!
    @IBOutlet weak private var yesButtonOutlets: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDependencies()
        configureUI()
        startInitialDataLoad()
    }
    
    private func configureDependencies() {
        alertPresenter = AlertPresenter(viewController: self)
        presenter = MovieQuizPresenter(viewController: self)
        statisticService = StatisticService()
    }
    
    private func configureUI() {
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.backgroundColor = .clear
    }
    
    private func startInitialDataLoad() {
        showLoadingIndicator()
    }
    
    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: Any) {
        presenter.yesButtonClicked()
        updateButtonsState(isEnabled: false)
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.noButtonClicked()
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
    
    // Приватный метод вывода на экран вопроса, который принимает на вход вью модель вопроса и ничего не возвращает
     func show(quiz step: QuizStepViewModel) {
        // Гарантированный сброс рамки перед новым вопросом
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
        //Добавили анимацию для плавного появления изображения
        UIView.transition(with: imageView,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: {
            self.imageView.image = step.image
            self.textLabel.text = step.question
            self.counterLabel.text = step.questionNumber
        })
    }
    
    // Приватный метод, который меняет цвет рамки
    func showAnswerResult(isCorrect: Bool) {
        presenter.didAnswer(isCorrectAnswer: isCorrect)
        
        // Настройка анимации рамки
        let animation = CABasicAnimation(keyPath: "borderColor")
        animation.fromValue = UIColor.clear.cgColor
        animation.toValue = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        animation.duration = 0.3
        imageView.layer.add(animation, forKey: "borderAnimation")
        
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Плавное исчезновение рамки
            UIView.animate(withDuration: 0.3) {
                self.imageView.layer.borderWidth = 0
                self.imageView.layer.borderColor = UIColor.clear.cgColor
            }
            
            // Обновляем состояние через presenter

            self.presenter.showNextQuestionOrResults()
            
            self.updateButtonsState(isEnabled: true)
        }
    }
    
    // Приватный метод, который содержит логику перехода в один из сценариев
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            
            statisticService?.store(correct: presenter.correctAnswers, total: presenter.questionsAmount)
            
            let text = "Вы ответили правильно на \(presenter.correctAnswers)/\(presenter.questionsAmount) вопросов"
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            showResults(quiz: viewModel)
        } else {
            presenter.switchToNextQuestion()
            presenter.restartGame()
        }
    }
    
    // Отображение результатов в сплывающем окне (чтобы не усложнять метод showNextQuestionOrResults, вывели алерты в отдельный)
     func showResults(quiz result: QuizResultsViewModel) {
         let statisticText = statisticService?.getStatisticsText(correct: presenter.correctAnswers, total: presenter.questionsAmount) ?? "Статистики нет"
        let alertModel = AlertModel(
            title: result.title,
            message: statisticText,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.presenter.restartGame()
            }
        )
        alertPresenter?.showResults(quiz: alertModel)
    }
    
    private func updateButtonsState(isEnabled: Bool) {
        noButtonOutlets.isEnabled = isEnabled
        yesButtonOutlets.isEnabled = isEnabled
        noButtonOutlets.alpha = isEnabled ? 1 : 0.5
        yesButtonOutlets.alpha = isEnabled ? 1 : 0.5
    }
    
     func showNetworkError(message: String) {
         hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            self.presenter.restartGame()
        }
        alertPresenter?.showResults(quiz: model)
    }
}
