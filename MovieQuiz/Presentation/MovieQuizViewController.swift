import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var alertPresenter: AlertPresenter!
    private var isLoading = false
    private var presenter: MovieQuizPresenter!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        
        alertPresenter = AlertPresenter(viewController: self)
        
        imageView.layer.cornerRadius = 20
        
        showLoadingIndicator()
    }
    
    // MARK: - Functions
    
    func showResults(quiz result: QuizResultsViewModel) {
        let message = presenter.makeResultsMessage()
        
        let alertModel = AlertModel(
            title: result.title,
            message: message,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                self.presenter.restartGame()
            }
        )
        alertPresenter.presentAlert(with: alertModel)
    }
    
    func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
        counterLabel.text = step.questionNumber
        imageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        setAnswerButtonsEnabled(true)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    func showLoadingIndicator() {
        isLoading = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        setAnswerButtonsEnabled(false
        )
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
            self.setAnswerButtonsEnabled(false)
        }
        
        alertPresenter.presentAlert(with: model)
    }
    
    func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard sender.isEnabled else { return }
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard sender.isEnabled else { return }
        presenter.noButtonClicked()
    }
    
}


