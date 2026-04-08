import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter!
    private var statisticService: StatisticServiceProtocol = StatisticService()
    private var isLoading = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertPresenter = AlertPresenter(viewController: self)
        
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticService()
        
        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Private functions
    
    private func showResults(quiz result: QuizResultsViewModel) {
        let statistics = statisticService.getFullStatistics()
        
        let alertModel = AlertModel(
            title: result.title,
            message: result.text + "\n" + statistics,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                self.questionFactory?.requestNextQuestion()
            }
        )
        alertPresenter.presentAlert(with: alertModel)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(data: model.imageName) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
        counterLabel.text = step.questionNumber
        imageView.image = step.image
        textLabel.text = step.question
        setAnswerButtonsEnabled(true)
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        imageView.layer.cornerRadius = 20
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == (questionsAmount - 1) {
            imageView.layer.borderWidth = 0
            imageView.layer.borderColor = nil
            
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            let text = correctAnswers == questionsAmount ?
            "Поздравляем, вы ответили на 10 из 10!" :
            "Ваш результат \(correctAnswers)/\(questionsAmount), попробуйте ещё раз!"
            let viewModel = QuizResultsViewModel(title: "Этот раунд окончен!", text: text, buttonText: "Сыграть еще раз")
            showResults(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func showLoadingIndicator() {
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
    
    private func hideLoadingIndicator() {
        isLoading = false
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkError(message: String) {
        guard !isLoading else { return }
        
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self, !self.isLoading else { return }
            
            self.showLoadingIndicator()
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            self.currentQuestion = nil
            self.setAnswerButtonsEnabled(false)
            self.questionFactory?.loadData()
        }
        
        alertPresenter.presentAlert(with: model)
    }
    
    internal func didLoadDataFromServer() {
        hideLoadingIndicator()
        setAnswerButtonsEnabled(true)
        questionFactory?.requestNextQuestion()
    }
    
    internal func didFailToLoadData (with error: Error) {
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
    }
    
    // MARK: - Actions
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard sender.isEnabled else { return }
        processAnswer(false)
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard sender.isEnabled else { return }
        processAnswer(true)
    }
    
    private func processAnswer(_ givenAnswer: Bool) {
        setAnswerButtonsEnabled(false)
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
}


