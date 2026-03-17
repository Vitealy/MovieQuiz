//
//  QuestionFactoryProtocol.swift
//  MovieQuiz
//
//  Created by Vitaly Kashavkin on 17.03.2026.
//

import Foundation

protocol QuestionFactoryProtocol {
    func requestNextQuestion() -> QuizQuestion?
}
