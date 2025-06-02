//
//  AlertPresenterProtocol.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 01.06.2025.
//

import UIKit

protocol AlertPresenterProtocol {
    var viewController: UIViewController? { get set }
    func showResults(quiz model: AlertModel)
}
