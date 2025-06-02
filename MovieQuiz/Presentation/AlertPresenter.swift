//
//  AlertPresenter.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 01.05.2025.
//

import UIKit

final class AlertPresenter: AlertPresenterProtocol {
    weak var viewController: UIViewController?
    
    func showResults(quiz model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(
            title: model.buttonText,
            style: .default) { _ in
                model.completion?()
            }
        
        alert.addAction(action)
        
#if DEBUG
        alert.view.accessibilityIdentifier = "GameResultsAlert"
#endif
        
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.present(alert, animated: true)
        }
    }
}
