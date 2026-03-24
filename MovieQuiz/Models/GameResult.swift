import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var accuracyPercentage: Double {
        guard total > 0 else { return 0.0 }
        return (Double(correct) / Double(total)) * 100
    }
    
    func isBetterThan(_ another: GameResult) -> Bool {
        correct > another.correct
        }
}
