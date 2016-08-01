//
//  NSManagedObject_SkopelosTests.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 01/08/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import XCTest
import CoreData
@testable import Skopelos

struct NSManagedObjectTestsConsts {
    static let UnitTestTimeout = 10.0
}

class NSManagedObject_SkopelosTests: XCTestCase {

    var skopelos: Skopelos = Skopelos(inMemoryStack: "DataModel")
    
    func test_create() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.read({ (context: NSManagedObjectContext) in
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 0)
        }).write({ (context: NSManagedObjectContext) in
            User.SK_create(context)
        }).read { (context: NSManagedObjectContext) in
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 1)
            expectation.fulfill()
        }
    
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }


}
