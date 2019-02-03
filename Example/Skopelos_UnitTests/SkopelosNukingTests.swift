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

class SkopelosNukingTests: XCTestCase {
    
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
    
    func test_NukingSQLiteStack() {
        let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
        let skopelos = Skopelos(sqliteStack: modelURL)
        testNuke(skopelos)
    }
    
    func test_NukingSQLiteStackInSharedSpace() {
        let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
        let skopelos = Skopelos(sqliteStack: modelURL, securityApplicationGroupIdentifier: "group.com.skopelos")
        testNuke(skopelos)
    }
    
    func test_NukingInMemoryStack() {
        let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
        let skopelos = Skopelos(inMemoryStack: modelURL)
        testNuke(skopelos)
    }
    
    private func testNuke(_ skopelos: Skopelos) {
        skopelos.writeSync({ (context: NSManagedObjectContext) in
            User.SK_create(context)
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 1)
        }).read { (context: NSManagedObjectContext) in
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 1);
        }
        
        skopelos.nuke()
        
        skopelos.read { (context: NSManagedObjectContext) in
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 0);
        }
    }
}
