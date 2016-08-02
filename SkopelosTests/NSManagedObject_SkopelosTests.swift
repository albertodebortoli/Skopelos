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
            XCTAssertEqual(User.SK_numberOfEntities(context), 0)
        }).write({ (context: NSManagedObjectContext) in
            User.SK_create(context)
        }).read { (context: NSManagedObjectContext) in
            XCTAssertEqual(User.SK_numberOfEntities(context), 1)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_remove() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            User.SK_create(context)
            User.SK_create(context)
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 2)
        }).write( { (context: NSManagedObjectContext) in
            let user = User.SK_first(context)!
            user.SK_remove(context)
            XCTAssertEqual(User.SK_numberOfEntities(context), 1)
        }).read({ (context: NSManagedObjectContext) in
            XCTAssertEqual(User.SK_numberOfEntities(context), 1)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_removeInSameTransactionalBlock() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let user = User.SK_create(context)
            User.SK_create(context)
            XCTAssertEqual(User.SK_numberOfEntities(context), 2)
            user.SK_remove(context)
            XCTAssertEqual(User.SK_numberOfEntities(context), 1)
        }).read({ (context: NSManagedObjectContext) in
            XCTAssertEqual(User.SK_numberOfEntities(context), 1)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_removeAll() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            User.SK_create(context)
            User.SK_create(context)
            XCTAssertEqual(User.SK_numberOfEntities(context), 2)
            User.SK_removeAll(context)
            XCTAssertEqual(User.SK_numberOfEntities(context), 0)
        }).read({ (context: NSManagedObjectContext) in
            let count = User.SK_numberOfEntities(context)
            XCTAssertEqual(count, 0)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_numberOfEntities() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            User.SK_create(context)
            User.SK_create(context)
        }).read({ (context: NSManagedObjectContext) in
            XCTAssertEqual(User.SK_numberOfEntities(context), 2)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_numberOfEntitiesWithPredicate() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let u1 = User.SK_create(context)
            let u2 = User.SK_create(context)
            u1.firstname = "John"
            u2.firstname = "Jane"
        }).read({ (context: NSManagedObjectContext) in
            let predicate = NSPredicate(format:"%K == %@", "firstname", "John")
            let numberOfEntitities = User.SK_numberOfEntities(predicate, context: context)
            XCTAssertEqual(numberOfEntitities, 1)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_all() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            User.SK_create(context)
            User.SK_create(context)
        }).read({ (context: NSManagedObjectContext) in
            XCTAssertEqual(User.SK_numberOfEntities(context), 2)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_allWithPredicate() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let u1 = User.SK_create(context)
            let u2 = User.SK_create(context)
            u1.firstname = "John"
            u2.firstname = "Jane"
        }).read({ (context: NSManagedObjectContext) in
            let predicate = NSPredicate(format:"%K == %@", "firstname", "John")
            let users = User.SK_all(predicate, context: context)
            XCTAssertEqual(users.count, 1)
            let user = users.first
            XCTAssertEqual(user?.firstname ?? "", "John")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_allWithPredicateSortedBy() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let u1 = User.SK_create(context)
            let u2 = User.SK_create(context)
            let u3 = User.SK_create(context)
            u1.firstname = "John"
            u1.lastname = "Doe"
            u2.firstname = "Jane"
            u2.lastname = "Doe"
            u3.firstname = "Mark"
            u3.lastname = "Smith"
        }).read({ (context: NSManagedObjectContext) in
            let predicate = NSPredicate(format: "%K == %@", "lastname", "Doe")
            let users = User.SK_all(context, predicate: predicate, sortTerm: "firstname", ascending: true)
            XCTAssertEqual(users.count, 2)
            let user = users.first
            XCTAssertEqual(user?.firstname ?? "", "Jane")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_allWhereAttributeIsEqualToSortedBy() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let u1 = User.SK_create(context)
            let u2 = User.SK_create(context)
            let u3 = User.SK_create(context)
            u1.firstname = "John"
            u1.lastname = "Doe"
            u2.firstname = "Jane"
            u2.lastname = "Doe"
            u3.firstname = "Mark"
            u3.lastname = "Smith"
        }).read({ (context: NSManagedObjectContext) in
            XCTAssertEqual(User.SK_all("lastname", isEqualTo: "Doe", sortTerms: "firstname", ascending: false, context: context).count, 2)
            let u1 = User.SK_all("lastname", isEqualTo: "Doe", sortTerms: "firstname", ascending: false, context: context).first
            let u2 = User.SK_all("lastname", isEqualTo: "Doe", sortTerms: "firstname", ascending: true, context: context).first
            XCTAssertEqual(u1!.firstname, "John");
            XCTAssertEqual(u2!.firstname, "Jane");
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_first() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let u1 = User.SK_create(context)
            let u2 = User.SK_create(context)
            u1.firstname = "John"
            u2.firstname = "Jane"
        }).read({ (context: NSManagedObjectContext) in
            let user = User.SK_first(context)
            XCTAssertNotNil(user);
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_firstWithPredicate() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let u1 = User.SK_create(context)
            let u2 = User.SK_create(context)
            u1.firstname = "John"
            u2.lastname = "Doe"
            u2.firstname = "Jane"
            u2.lastname = "Doe"
        }).read({ (context: NSManagedObjectContext) in
            let predicate = NSPredicate(format: "%K == %@", "lastname", "Doe")
            let user = User.SK_first(predicate, sortTerms: "firstname", ascending: true, context: context)
            XCTAssertEqual(user?.firstname ?? "", "Jane")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
    func test_firstWhereAttribute() {
        let expectation = expectationWithDescription("\(#function)")
        skopelos.write( { (context: NSManagedObjectContext) in
            let u1 = User.SK_create(context)
            let u2 = User.SK_create(context)
            u1.firstname = "John"
            u2.lastname = "Doe"
            u2.firstname = "Jane"
            u2.lastname = "Doe"
        }).read({ (context: NSManagedObjectContext) in
            let user1 = User.SK_first("lastname", isEqualTo: "Doe", context: context)
            XCTAssertNotNil(user1)
            let user2 = User.SK_first("lastname", isEqualTo: "Smith", context: context)
            XCTAssertNil(user2)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(NSManagedObjectTestsConsts.UnitTestTimeout, handler:nil)
    }
    
}
