//
//  StatisticServiceProtocol.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 06.05.2025.
//

import Foundation

protocol StatisticServiceProtocol {
    var gamesCount: Int { get }
    var bestGame: GameResult { get }
    var totalAccuracy: Double { get }
    
    func store(correct count: Int, total amount: Int)
    func getStatisticsText(correct count: Int, total amount: Int) -> String
}

//Чем выносить код в MovieQuiz, модифицируем Protocol, чтобы он сам формировал статистику
extension StatisticServiceProtocol {
    func getStatisticsText(correct count: Int, total amount: Int) -> String {
        let score = "Ваш результат: \(count)/\(amount)"
        let gamesCount = "Количество сыгранных квизов: \(gamesCount)"
        let record = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
        let totalAccuracy = "Средняя точность: \(String(format: "%.2f", totalAccuracy))%"
        
        return [score, gamesCount, record, totalAccuracy].joined(separator: "\n")
    }
}

