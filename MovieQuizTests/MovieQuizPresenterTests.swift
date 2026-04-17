import XCTest
@testable import MovieQuiz

final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    // Сохраняем переданные данные для проверки
    var lastStepModel: QuizStepViewModel?
    var lastResultsModel: QuizResultsViewModel?
    var lastHighlightedState: Bool?
    var lastNetworkErrorMessage: String?
    var lastButtonsEnabledState: Bool?
    var didCallShowLoadingIndicator = false
    var didCallHideLoadingIndicator = false
    
    func show(quiz step: MovieQuiz.QuizStepViewModel) {
        lastStepModel = step
    }
    
    func showResults(quiz result: MovieQuiz.QuizResultsViewModel) {
        lastResultsModel = result
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        lastHighlightedState = isCorrectAnswer
    }
    
    func showLoadingIndicator() {
        didCallShowLoadingIndicator = true
    }
    
    func hideLoadingIndicator() {
        didCallHideLoadingIndicator = true
    }
    
    func showNetworkError(message: String) {
        lastNetworkErrorMessage = message
    }
    
    func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        lastButtonsEnabledState = isEnabled
    }
}

final class MovieQuizPresenterTests: XCTestCase {
    
    func testPresenterConvertModel() throws {
        // Given
        let viewControllerMock = MovieQuizViewControllerMock()
        let sut = MovieQuizPresenter(viewController: viewControllerMock)
        
        // Создаем тестовые данные
        let testImage = UIImage(systemName: "star") ?? UIImage()
        let testImageData = testImage.pngData() ?? Data()
        let question = QuizQuestion(
            imageName: testImageData,
            text: "Question Text",
            correctAnswer: true
        )
        
        // When
        let viewModel = sut.convert(model: question)
        
        // Then
        XCTAssertNotNil(viewModel.image)
        XCTAssertEqual(viewModel.question, "Question Text")
        XCTAssertEqual(viewModel.questionNumber, "1/10")  // currentQuestionIndex = 0
    }
}
