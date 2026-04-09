import Foundation

protocol QuestionFactoryProtocol {
    func requestNextQuestion()
    func loadData()
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
}
