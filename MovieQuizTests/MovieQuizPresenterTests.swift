//
//  MovieQuizPresenterTests.swift
//  MovieQuizTests
//
//  Created by Рустам Ханахмедов on 01.06.2025.
//

import XCTest
import Foundation

@testable import MovieQuiz

final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    
    func updateButtonsState(isEnabled: Bool) {
        
    }
    
    func show(quiz step: QuizStepViewModel) {
        
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        
    }
    
    func showLoadingIndicator() {
        
    }
    
    func hideLoadingIndicator() {
        
    }
    
    
    func showNetworkError(message: String) {
        
    }
    
    func resetImageBorder() {
        
    }
    
    
    func blockButton(isEnabled: Bool) {
        
    }
    
    func showAlert(with model: MovieQuiz.AlertModel) {
        
    }
}

final class MovieQuizPresenterTests: XCTestCase {
    func testPresenterConvertModel() throws {
        let viewControllerMock = MovieQuizViewControllerMock()
        let sut = MovieQuizPresenter(viewController: viewControllerMock)
        
        let emptyData = Data()
        let question = QuizQuestion(image: emptyData, text: "Question Text", correctAnswer: true)
        let viewModel = sut.convert(model: question)
        
        XCTAssertNotNil(viewModel.image)
        XCTAssertEqual(viewModel.question, "Question Text")
        XCTAssertEqual(viewModel.questionNumber, "1/10")
    }
}
