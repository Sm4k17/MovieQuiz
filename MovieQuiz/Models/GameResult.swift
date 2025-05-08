//
//  GameResult.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 06.05.2025.
//

import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThan(_ another: GameResult) -> Bool {
        return self.correct > another.correct
    }
}
