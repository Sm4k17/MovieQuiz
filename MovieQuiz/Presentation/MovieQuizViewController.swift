import UIKit


final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    //  questionsAmount — общее количество вопросов для квиза. Пусть оно будет равно десяти.
    //  questionFactory — фабрика вопросов. Контроллер будет обращаться за вопросами к ней.
    //  currentQuestion — вопрос, который видит пользователь.
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticServiceProtocol?

    // Состояние текущего и правильно вопроса
    private var currentQuestionIndex: Int = .zero
    private var correctAnswers: Int = .zero
    
    // MARK: - Outlets
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textLabel: UILabel!
    @IBOutlet weak private var counterLabel: UILabel!
    @IBOutlet weak private var noButtonOutlets: UIButton!
    @IBOutlet weak private var yesButtonOutlets: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        alertPresenter = AlertPresenter(viewController: self)
        statisticService = StatisticService()
        questionFactory = QuestionFactory(delegate: self)
        guard let questionFactory = questionFactory else { return }
        questionFactory.requestNextQuestion()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in // Исключение как и UIView.animate (можно ведь не ставить слабую ссылку ?)
            guard let self = self else { return }
            self.show(quiz: viewModel)
        }
    }
    
    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }

        let givenAnswer = true
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        updateButtonsState(isEnabled: false)
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {

        guard let currentQuestion = currentQuestion else {
            return
        }

        let givenAnswer = false
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        updateButtonsState(isEnabled: false)
    }
    
    // MARK: - Private Methods
    // Метод конвертации, который принимает моковый вопрос и возвращает вью модель для экрана вопроса
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    // Приватный метод вывода на экран вопроса, который принимает на вход вью модель вопроса и ничего не возвращает
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    // Приватный метод, который меняет цвет рамки
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in // Исключение как и UIView.animate (можно ведь не ставить слабую ссылку ?)
            guard let self = self else { return }

            self.showNextQuestionOrResults()
            self.imageView.layer.borderColor = UIColor.clear.cgColor
            self.updateButtonsState(isEnabled: true)
        }
    }
    
    // Приватный метод, который содержит логику перехода в один из сценариев
    private func showNextQuestionOrResults() {

        if currentQuestionIndex == questionsAmount - 1 {
            let text = correctAnswers == questionsAmount ?
            "Поздравляем, вы ответили на 10 из 10!" :
            "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"
            
            statisticService?.store(correct: correctAnswers, total: questionsAmount)
            

            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            //->
            showResults(quiz: viewModel)
        } else {
            currentQuestionIndex += 1

            self.questionFactory?.requestNextQuestion()
            

        }
    }
    
    // Отображение результатов в сплывающем окне (чтобы не усложнять метод showNextQuestionOrResults, вывели алерты в отдельный)
    private func showResults(quiz result: QuizResultsViewModel) {

        let statisticText = statisticService?.getStatisticsText(correct: correctAnswers, total: questionsAmount) ?? "Статистики нет"
        let alertModel = AlertModel(
            title: result.title,
            message: statisticText,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.currentQuestionIndex = .zero
                self.correctAnswers = .zero
                self.questionFactory?.requestNextQuestion()
            }
        )
        alertPresenter?.showResults(quiz: alertModel)

    }
    
    private func updateButtonsState(isEnabled: Bool) {
        noButtonOutlets.isEnabled = isEnabled
        yesButtonOutlets.isEnabled = isEnabled
    }
    
}
