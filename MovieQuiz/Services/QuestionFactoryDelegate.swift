//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 01.05.2025.
//

import Foundation

protocol QuestionFactoryDelegate: AnyObject {               // 1
    func didReceiveNextQuestion(question: QuizQuestion?)    // 2
}
