import UIKit

final class MovieQuizViewController: UIViewController /*QuestionFactoryDelegate*/ {
    
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
//    private var currentQuestionIndex = 0
//    private var correctAnswers = 0
//    private let questionsAmount: Int = 10
//    private var questionFactory: QuestionFactoryProtocol?
//    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter!
    private var statisticService: StatisticServiceProtocol = StatisticService()
    private var isLoading = false
    private var presenter: MovieQuizPresenter!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        
        alertPresenter = AlertPresenter(viewController: self)
        
        imageView.layer.cornerRadius = 20
//        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticService()
        
        showLoadingIndicator()
//        questionFactory?.loadData()
    }
    
//    // MARK: - QuestionFactoryDelegate
    
//    func didReceiveNextQuestion(question: QuizQuestion?) {
//       presenter.didReceiveNextQuestion(question: question)
//    }
    
    // MARK: - Private functions
    
    func showResults(quiz result: QuizResultsViewModel) {
        let statistics = statisticService.getFullStatistics()
        
        let alertModel = AlertModel(
            title: result.title,
            message: result.text + "\n" + statistics,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                self.presenter.restartGame()
//                self.questionFactory?.requestNextQuestion()
            }
        )
        alertPresenter.presentAlert(with: alertModel)
    }
    
/*    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(data: model.imageName) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
 */
    func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
        counterLabel.text = step.questionNumber
        imageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        setAnswerButtonsEnabled(true)
    }
    
    func showAnswerResult(isCorrect: Bool) {
        presenter.didAnswer(isCorrectAnswer: isCorrect)
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        imageView.layer.cornerRadius = 20
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
//            self.presenter.questionFactory = self.questionFactory
            self.presenter.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            imageView.layer.borderWidth = 0
            imageView.layer.borderColor = nil
            
            statisticService.store(correct: presenter.correctAnswers, total: presenter.questionsAmount)
            
            let text = presenter.correctAnswers == presenter.questionsAmount ?
            "Поздравляем, вы ответили на 10 из 10!" :
            "Ваш результат \(presenter.correctAnswers)/\(presenter.questionsAmount), попробуйте ещё раз!"
            let viewModel = QuizResultsViewModel(title: "Этот раунд окончен!", text: text, buttonText: "Сыграть еще раз")
            showResults(quiz: viewModel)
        } else {
            presenter.switchToNextQuestion()
//            questionFactory?.requestNextQuestion()
        }
    }
    
    func showLoadingIndicator() {
        isLoading = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        setAnswerButtonsEnabled(false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            if self.activityIndicator.isAnimating {
                self.hideLoadingIndicator()
                self.showNetworkError(message: "Сервер долго не отвечает. Попробуйте позже.")
            }
        }
    }
    
    func hideLoadingIndicator() {
        isLoading = false
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    func showNetworkError(message: String) {
        guard !isLoading else { return }
        
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self, !self.isLoading else { return }
            
            self.showLoadingIndicator()
            self.presenter.restartGame()
            self.presenter.currentQuestion = nil
            self.setAnswerButtonsEnabled(false)
//            self.questionFactory?.loadData()
        }
        
        alertPresenter.presentAlert(with: model)
    }
    
//    internal func didLoadDataFromServer() {
//        hideLoadingIndicator()
//        setAnswerButtonsEnabled(true)
//        questionFactory?.requestNextQuestion()
//    }
    
/*    internal func didFailToLoadData (with error: Error) {
        let userFriendlyMessage: String
        
        if let networkError = error as? NetworkClient.NetworkError {
            switch networkError {
            case .codeError:
                userFriendlyMessage = "Сервер временно недоступен. Попробуйте позже."
            }
        } else {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                   userFriendlyMessage = "Нет подключения к интернету. Проверьте соединение."
                case NSURLErrorTimedOut:
                    userFriendlyMessage = "Превышено время ожидания. Попробуйте еще раз."
                default:
                    userFriendlyMessage = "Ошибка загрузки данных: \(error.localizedDescription)"
                }
            } else {
                userFriendlyMessage = "Произошла ошибка: \(error.localizedDescription)"
            }
        }
        
        showNetworkError(message: userFriendlyMessage)
    } */
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard sender.isEnabled else { return }
        processAnswer(true)
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard sender.isEnabled else { return }
        processAnswer(false)
        presenter.noButtonClicked()
    }
    
    private func processAnswer(_ givenAnswer: Bool) {
        setAnswerButtonsEnabled(givenAnswer)
    }
    
    private func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
}


