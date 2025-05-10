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
        let statistics = [
            "Ваш результат: \(count)/\(amount)",
            "Количество сыгранных квизов: \(gamesCount)",
            "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))",
            "Средняя точность: \(String(format: "%.2f", totalAccuracy))%"
        ]
        return statistics.joined(separator: "\n")
    }
}

