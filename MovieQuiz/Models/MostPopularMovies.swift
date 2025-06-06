//
//  MostPopularMovies.swift
//  MovieQuiz
//
//  Created by Рустам Ханахмедов on 20.05.2025.
//

import Foundation

struct MostPopularMovies: Decodable {
    let errorMessage: String
    let items: [MostPopularMovie]
}

struct MostPopularMovie: Decodable {
    let title: String
    let rating: String
    let year: String
    let imageURL: URL
    
    var resizedImageURL: URL {
        let urlString = imageURL.absoluteString
        let imageUrlString = urlString.components(separatedBy: "._")[0] + "._V0_UX600_.jpg"
        
        guard let newURL = URL(string: imageUrlString) else {
            return imageURL
        }
        return newURL
    }
    
    private enum CodingKeys : String, CodingKey {
        case title = "fullTitle"
        case rating = "imDbRating"
        case year = "year"
        case imageURL = "image"
    }
}
