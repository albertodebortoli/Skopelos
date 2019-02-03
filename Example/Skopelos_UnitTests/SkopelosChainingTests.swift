//
//  SkopelosTests.swift
//  SkopelosTests
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import XCTest
import CoreData
@testable import Skopelos
@testable import Skopelos_Example

class SkopelosChainingTests: XCTestCase {
    
    let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
    var skopelos: Skopelos!
    
    override func setUp() {
        super.setUp()
        skopelos = Skopelos(inMemoryStack: modelURL)
    }
    
    override func tearDown() {
        super.tearDown()
        skopelos = nil
    }
    
    func test_Chaining() {
        let expectation = self.expectation(description: "\(#function)")
        skopelos.writeSync { context in
            var user = User.SK_create(context)
            user = user.SK_inContext(context)!
            User.SK_create(context)
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 2)
            }.writeSync { context in
                let user = User.SK_first(context)!
                user.SK_remove(context)
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 1)
            }.read { context in
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 1)
                expectation.fulfill()
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
}
