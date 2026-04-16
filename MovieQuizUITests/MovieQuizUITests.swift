import XCTest

final class MovieQuizUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = XCUIApplication()
        app.launch()
        
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        app.terminate()
        app = nil
    }
    
    // MARK: - Helper Methods
    
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    // MARK: - Tests
    
    func testScreenCast() throws {
        let yesButton = app.buttons["YesButton"]
        let noButton = app.buttons["NoButton"]
        
        XCTAssertTrue(yesButton.waitForExistence(timeout: 5))
        yesButton.tap()
        
        sleep(1) // Ждем анимацию
        
        XCTAssertTrue(noButton.exists)
        noButton.tap()
    }
    
    func testYesButton() {
        // Ждем загрузки первого вопроса
        let poster = app.images["PosterImage"]
        XCTAssertTrue(poster.waitForExistence(timeout: 10))
        
        let firstPosterData = poster.screenshot().pngRepresentation
        
        // Нажимаем "Да"
        let yesButton = app.buttons["YesButton"]
        XCTAssertTrue(yesButton.exists)
        yesButton.tap()
        
        // Ждем появления следующего вопроса
        sleep(2)
        
        let secondPosterData = poster.screenshot().pngRepresentation
        
        // Постеры должны отличаться
        XCTAssertNotEqual(firstPosterData, secondPosterData)
    }
    
    func testNoButton() {
        // Ждем загрузки первого вопроса
        let poster = app.images["PosterImage"]
        XCTAssertTrue(poster.waitForExistence(timeout: 10))
        
        let firstPosterData = poster.screenshot().pngRepresentation
        
        // Нажимаем "Нет"
        let noButton = app.buttons["NoButton"]
        XCTAssertTrue(noButton.exists)
        noButton.tap()
        
        // Ждем появления следующего вопроса
        sleep(2)
        
        let secondPosterData = poster.screenshot().pngRepresentation
        
        // Проверяем индекс
        let indexLabel = app.staticTexts["IndexLabel"]
        XCTAssertTrue(indexLabel.exists)
        XCTAssertEqual(indexLabel.label, "2/10")
        
        // Постеры должны отличаться
        XCTAssertNotEqual(firstPosterData, secondPosterData)
    }
    
    func testIndexLabel() {
        // Ждем загрузки
        let indexLabel = app.staticTexts["IndexLabel"]
        XCTAssertTrue(indexLabel.waitForExistence(timeout: 10))
        
        // Проверяем первый индекс
        XCTAssertEqual(indexLabel.label, "1/10")
        
        // Нажимаем "Да"
        let yesButton = app.buttons["YesButton"]
        yesButton.tap()
        
        // Ждем обновления
        sleep(2)
        
        // Проверяем второй индекс
        XCTAssertEqual(indexLabel.label, "2/10")
    }

    func testGameFinishAlert() {
        // Ждем загрузки
        let yesButton = app.buttons["YesButton"]
        XCTAssertTrue(yesButton.waitForExistence(timeout: 10))
        
        // Проходим 10 вопросов
        for _ in 1...10 {
            yesButton.tap()
            sleep(2) // Ждем анимацию и загрузку следующего вопроса
        }
        
        // Проверяем наличие алерта
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        
        // Проверяем заголовок алерта
        XCTAssertTrue(alert.staticTexts["Этот раунд окончен!"].exists)
        
        // Проверяем кнопку
        let alertButton = alert.buttons.firstMatch
        XCTAssertTrue(alertButton.exists)
        XCTAssertEqual(alertButton.label, "Сыграть еще раз")
    }
    
    func testAlertDismiss() {
        // Ждем загрузки
        let yesButton = app.buttons["YesButton"]
        XCTAssertTrue(yesButton.waitForExistence(timeout: 10))
        
        // Проходим 10 вопросов
        for _ in 1...10 {
            yesButton.tap()
            sleep(2)
        }
        
        // Ждем появления алерта
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        
        // Нажимаем кнопку "Сыграть еще раз"
        let restartButton = alert.buttons.firstMatch
        restartButton.tap()
        
        // Ждем исчезновения алерта
        sleep(1)
        
        // Проверяем, что алерт исчез
        XCTAssertFalse(alert.exists)
        
        // Проверяем, что игра перезапустилась (индекс сбросился на 1)
        let indexLabel = app.staticTexts["IndexLabel"]
        XCTAssertTrue(indexLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(indexLabel.label, "1/10")
    }
    
}
