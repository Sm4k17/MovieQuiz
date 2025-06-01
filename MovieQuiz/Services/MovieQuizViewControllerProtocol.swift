//
//  MovieQuizViewControllerProtocol.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 01.06.2025.
//

import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func show(quiz step: QuizStepViewModel)
    func highlightImageBorder(isCorrectAnswer: Bool)
    func resetImageBorder()
    func updateButtonsState(isEnabled: Bool)
    func showLoadingIndicator()
    func hideLoadingIndicator()
}
