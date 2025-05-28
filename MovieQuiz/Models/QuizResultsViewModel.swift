//
//  QuizResultsViewModel.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 30.04.2025.
//

import Foundation

/// Модель данных для отображения результатов квиза
///
/// Используется для передачи данных между презентационным слоем и UI.
///
/// ## Пример использования
/// ```swift
/// let result = QuizResultsViewModel(
///     title: "Раунд окончен",
///     text: "Вы ответили на 8/10",
///     buttonText: "Сыграть ещё раз"
/// )
/// ```
///
/// - Parameters:
///   - title: Заголовок алерта (например, "Раунд окончен")
///   - text: Основной текст результата (например, "Вы ответили на 5/10")
///   - buttonText: Текст кнопки (например, "Сыграть ещё раз")
///   
struct QuizResultsViewModel {
    let title: String
    let text: String
    let buttonText: String
}
