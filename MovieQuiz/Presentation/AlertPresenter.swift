//
//  AlertPresenter.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 01.05.2025.
//

import UIKit

final class AlertPresenter {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func showResults(quiz result: AlertModel) {
        let alert = UIAlertController(
            title: result.title,
            message: result.message,
            preferredStyle: .alert) //actionSheet (выход снизу)
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard self != nil else { return }
            result.completion?()
        }
        
        alert.addAction(action)
        viewController?.present(alert, animated: true, completion: nil)
    }
}
