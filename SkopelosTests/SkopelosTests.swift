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

struct SkopelosTestsConsts {
    static let UnitTestTimeout = 10.0
}

class SkopelosTests: XCTestCase {
    
    var skopelos: Skopelos = Skopelos(inMemoryStack: "DataModel")
    
    func test_Chaining() {
    
        let expectation = expectationWithDescription("\(#function)")
    
        skopelos.write({ (context: NSManagedObjectContext) in
            var user = User.SK_create(context)
            user = user.SK_inContext(context)!
            User.SK_create(context)
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 2)
        }).write({ (context: NSManagedObjectContext) in
            let user = User.SK_first(context)!
            user.SK_remove(context)
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 1);
        }).read { (context: NSManagedObjectContext) in
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 1);
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_DispatchAyncOnMainQueue() {
        
        let expectation = expectationWithDescription("\(#function)")
        
        dispatch_async(dispatch_get_main_queue(), {
            
            self.skopelos.write({ (context: NSManagedObjectContext) in
                User.SK_removeAll(context)
            }).read({ (context: NSManagedObjectContext) in
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 0)
            }).write({ (context: NSManagedObjectContext) in
                let user = User.SK_create(context)
                user.firstname = "John"
                user.lastname = "Doe"
            }).read({ (context: NSManagedObjectContext) in
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 1)
                expectation.fulfill()
            })
            
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_DispatchAyncOnBackgroundQueue() {
        
        let expectation = expectationWithDescription("\(#function)")
        
        let q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(q, {
            
            self.skopelos.write({ (context: NSManagedObjectContext) in
                User.SK_removeAll(context)
            }).read({ (context: NSManagedObjectContext) in
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 0)
            }).write({ (context: NSManagedObjectContext) in
                let user = User.SK_create(context)
                user.firstname = "John"
                user.lastname = "Doe"
            }).read({ (context: NSManagedObjectContext) in
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 1)
                expectation.fulfill()
            })
            
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_performance() {
        measureBlock { 
            let sem = dispatch_semaphore_create(0)
            var count = 3
            
            while (count > 0)
            {
                dispatch_semaphore_wait(sem, DISPATCH_TIME_NOW)
                NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.2))
                
                self.skopelos.write({ (context: NSManagedObjectContext) in
                    let user = User.SK_create(context)
                    user.firstname = "John"
                    user.lastname = "Doe"
                }).write({ (context: NSManagedObjectContext) in
                    User.SK_removeAll(context)
                }).write({ (context: NSManagedObjectContext) in
                    User.SK_all(context)
                    }, completion: { (error: NSError?) in
                    count-=1
                    dispatch_semaphore_signal(sem);
                })
            }
        }
    }
}
