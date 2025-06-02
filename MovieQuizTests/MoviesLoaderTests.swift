//
//  MoviesLoaderTests.swift
//  MovieQuizTests
//
//  Created by Рустам Ханахмедов on 28.05.2025.
//

import XCTest
@testable import MovieQuiz

// MARK: - Test Doubles

struct StubNetworkClient: NetworkRouting {
    
    enum TestError: Error {
        case test
        case invalidData
    }
    
    let emulateError: Bool
    let expectedResponse: Data
    
    init(emulateError: Bool = false, responseData: Data? = nil) {
        self.emulateError = emulateError
        self.expectedResponse = responseData ?? Self.defaultResponseData
    }
    
    static var defaultResponseData: Data {
        """
        {
           "errorMessage" : "",
           "items" : [
              {
                 "crew" : "Dan Trachtenberg (dir.), Amber Midthunder, Dakota Beavers",
                 "fullTitle" : "Prey (2022)",
                 "id" : "tt11866324",
                 "imDbRating" : "7.2",
                 "imDbRatingCount" : "93332",
                 "image" : "https://m.media-amazon.com/images/M/MV5BMDBlMDYxMDktOTUxMS00MjcxLWE2YjQtNjNhMjNmN2Y3ZDA1XkEyXkFqcGdeQXVyMTM1MTE1NDMx._V1_Ratio0.6716_AL_.jpg",
                 "rank" : "1",
                 "title" : "Prey",
                 "year" : "2022"
              }
           ]
        }
        """.data(using: .utf8)!
    }
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        if emulateError {
            handler(.failure(TestError.test))
        } else {
            handler(.success(expectedResponse))
        }
    }
    
    func cancel() {}
}

// MARK: - Main Test Class

class MoviesLoaderTests: XCTestCase {
    
    // MARK: - Success Tests
    
    func testSuccessLoading() {
        // Given
        let stub = StubNetworkClient()
        let loader = MoviesLoader(networkClient: stub)
        
        // When
        let expectation = expectation(description: "Loading expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .success(let movies):
                XCTAssertEqual(movies.items.count, 1)
                XCTAssertEqual(movies.items.first?.title, "Prey (2022)")
                XCTAssertEqual(movies.items.first?.rating, "7.2")
            case .failure:
                XCTFail("Unexpected failure")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    // MARK: - Error Tests
    
    func testFailureLoading() {
        // Given
        let stub = StubNetworkClient(emulateError: true)
        let loader = MoviesLoader(networkClient: stub)
        
        // When
        let expectation = expectation(description: "Error loading expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .success:
                XCTFail("Should fail")
            case .failure(let error):
                XCTAssertTrue(error is StubNetworkClient.TestError)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    // MARK: - Decoder Tests
    
    func testDecoderSuccess() {
        // Given
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = StubNetworkClient.defaultResponseData
        
        // When
        do {
            let result = try decoder.decode(MostPopularMovies.self, from: data)
            
            // Then
            XCTAssertEqual(result.items.count, 1)
            XCTAssertEqual(result.items.first?.title, "Prey (2022)")
            XCTAssertEqual(result.items.first?.year, "2022")
        } catch {
            XCTFail("Decoding failed: \(error)")
        }
    }
    
    func testDecoderWithInvalidData() {
        // Given
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let invalidData = "invalid data".data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try decoder.decode(MostPopularMovies.self, from: invalidData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testDecoderWithMissingFields() {
        // Given
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let incompleteData = """
        {
           "items": [
              {
                 "title": "Incomplete Movie",
                 "year": "2023"
              }
           ]
        }
        """.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try decoder.decode(MostPopularMovies.self, from: incompleteData))
    }
    
    // MARK: - Integration Tests
    
    func testEmptyResponseHandling() {
        // Given
        let emptyData = """
        {
           "errorMessage": "",
           "items": []
        }
        """.data(using: .utf8)!
        let stub = StubNetworkClient(responseData: emptyData)
        let loader = MoviesLoader(networkClient: stub)
        
        // When
        let expectation = expectation(description: "Empty response expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .success(let movies):
                XCTAssertTrue(movies.items.isEmpty)
            case .failure:
                XCTFail("Should handle empty response")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testErrorMessageHandling() {
        // Given
        let errorData = """
        {
           "errorMessage": "API limit reached",
           "items": []
        }
        """.data(using: .utf8)!
        let stub = StubNetworkClient(responseData: errorData)
        let loader = MoviesLoader(networkClient: stub)
        
        // When
        let expectation = expectation(description: "Error message expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .success(let movies):
                XCTAssertEqual(movies.errorMessage, "API limit reached")
            case .failure:
                XCTFail("Should handle error message")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
}
