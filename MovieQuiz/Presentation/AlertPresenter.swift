//
//  AlertPresenter.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 01.05.2025.
//

import UIKit

final class AlertPresenter {
    private weak var viewController: UIViewController?
    private var isAlertPresenting = false  // Флаг для отслеживания состояния
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func showResults(quiz result: AlertModel) {
        // Проверяем, не показывается ли уже алерт
        guard !isAlertPresenting else {
            print("Alert is already presenting, ignoring duplicate request")
            return
        }
        let alert = UIAlertController(
            title: result.title,
            message: result.message,
            preferredStyle: .alert) //actionSheet (выход снизу)
        
        let action = UIAlertAction(
            title: result.buttonText,
            style: .default) { [weak self] _ in
                self?.isAlertPresenting = false  // Сбрасываем флаг при закрытии
                result.completion?()
            }
        
        alert.addAction(action)
        
        // Всегда выполняем презентацию на главном потоке
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Дополнительная проверка на случай race condition
            if !self.isAlertPresenting {
                self.isAlertPresenting = true
                self.viewController?.present(alert, animated: true)
            }
        }
    }
}
