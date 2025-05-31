import UIKit


final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    //  questionsAmount — общее количество вопросов для квиза. Пусть оно будет равно десяти.
    //  questionFactory — фабрика вопросов. Контроллер будет обращаться за вопросами к ней.
    //  currentQuestion — вопрос, который видит пользователь.
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticServiceProtocol?
    
    // Состояние текущего и правильно вопроса
    private var correctAnswers: Int = .zero
    
    private let presenter = MovieQuizPresenter()
    
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
        presenter.viewController = self
        statisticService = StatisticService()
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
    }
    
    private func configureUI() {
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.backgroundColor = .clear
    }
    
    private func startInitialDataLoad() {
        questionFactory?.loadData()
        showLoadingIndicator()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.show(quiz: viewModel)
        }
    }
    
    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: Any) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
        updateButtonsState(isEnabled: false)
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.currentQuestion = currentQuestion
        presenter.noButtonClicked()
        updateButtonsState(isEnabled: false)
    }
    
    // MARK: - Private Methods
    private func showLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator?.isHidden = false // говорим, что индикатор загрузки не скрыт
            self?.activityIndicator?.startAnimating() // включаем анимацию
        }
    }
    
    // Приватный метод вывода на экран вопроса, который принимает на вход вью модель вопроса и ничего не возвращает
    private func show(quiz step: QuizStepViewModel) {
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
        if isCorrect {
            correctAnswers += 1
        }
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
            
            self.showNextQuestionOrResults()
            self.updateButtonsState(isEnabled: true)
        }
    }
    
    // Приватный метод, который содержит логику перехода в один из сценариев
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            
            statisticService?.store(correct: correctAnswers, total: presenter.questionsAmount)
            
            let text = "Вы ответили правильно на \(correctAnswers)/\(presenter.questionsAmount) вопросов"
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            showResults(quiz: viewModel)
        } else {
            presenter.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    // Отображение результатов в сплывающем окне (чтобы не усложнять метод showNextQuestionOrResults, вывели алерты в отдельный)
    private func showResults(quiz result: QuizResultsViewModel) {
        let statisticText = statisticService?.getStatisticsText(correct: correctAnswers, total: presenter.questionsAmount) ?? "Статистики нет"
        let alertModel = AlertModel(
            title: result.title,
            message: statisticText,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.presenter.resetQuestionIndex()
                self.correctAnswers = .zero
                self.questionFactory?.requestNextQuestion()
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
    
    func didLoadDataFromServer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    private func showNetworkError(message: String) {
        activityIndicator.isHidden = true
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.questionFactory?.loadData()
        }
        alertPresenter?.showResults(quiz: model)
    }
}
