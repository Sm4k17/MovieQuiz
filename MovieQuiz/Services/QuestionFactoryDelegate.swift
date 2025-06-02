//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 01.05.2025.
//

import Foundation

protocol QuestionFactoryDelegate: AnyObject {
    func didStartLoadingData()
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
}
