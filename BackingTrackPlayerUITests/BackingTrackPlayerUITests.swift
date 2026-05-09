//
//  BackingTrackPlayerUITests.swift
//  BackingTrackPlayerUITests
//
//  Created by Nick Malbraaten on 6/2/18.
//  Copyright © 2018 Nick Malbraaten. All rights reserved.
//
//  Note: This test class uses the legacy XCTest framework style.
//  For newer Swift and iOS projects, consider migrating to Swift Testing frameworks and modern async test APIs.
//

import XCTest

class BackingTrackPlayerUITests: XCTestCase {
        
    override func setUp() {
        // Called before the invocation of each test method in the class.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test.
        // Doing this in setup ensures it happens for each test method.
        XCUIApplication().launch()
        
        // Consider setting initial state such as interface orientation here if needed.
    }
    
    override func tearDown() {
        // Called after the invocation of each test method in the class.
        // Clean up resources here if needed.
    }
    
    func testExample() {
        // Use recording or Swift Testing's async APIs to start writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
