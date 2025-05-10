//
//  StatisticService.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 06.05.2025.
//

import Foundation

final class StatisticService: StatisticServiceProtocol {
    
    private let storage: UserDefaults = .standard
    
    private var correct: Int {
        get {
            return storage.integer(forKey: "correctAnswers")
        }
        set {
            storage.set(newValue, forKey: "correctAnswers")
        }
    }
    
    private enum Keys: String {
        case correct, bestGame, gamesCount, bestGameDate, bestGameTotal
    }
    
    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameResult {
        get {
            let correct = storage.integer(forKey: Keys.bestGame.rawValue)
            let total = storage.integer(forKey: Keys.bestGameTotal.rawValue)
            let date = storage.object(forKey: Keys.bestGameDate.rawValue) as? Date ?? Date()
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: Keys.bestGame.rawValue)
            storage.set(newValue.total, forKey: Keys.bestGameTotal.rawValue)
            storage.set(newValue.date, forKey: Keys.bestGameDate.rawValue)
        }
    }
    
    var totalAccuracy: Double {
        if gamesCount == 0 { return 0 }
        return (Double(correct)/(Double(gamesCount) * 10) * 100)
    }
    
    func store(correct count: Int, total amount: Int) {
        let newGame = GameResult(correct: count, total: amount, date: Date())
        if newGame.isBetterThan(bestGame) {
            bestGame = newGame
        }
        correct += count
        gamesCount += 1
    }
}

