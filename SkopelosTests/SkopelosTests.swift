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
    
    var skopelos: Skopelos!
    
    override func setUp() {
        super.setUp()
        skopelos = Skopelos(inMemoryStack: "DataModel")
    }
    
    override func tearDown() {
        super.tearDown()
        skopelos = nil
    }
    
    func test_Chaining() {
    
        let expectation = expectationWithDescription("\(#function)")
    
        skopelos.writeSync({ (context: NSManagedObjectContext) in
            var user = User.SK_create(context)
            user = user.SK_inContext(context)!
            User.SK_create(context)
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 2)
        }).writeSync({ (context: NSManagedObjectContext) in
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
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                User.SK_removeAll(context)
            }).read({ (context: NSManagedObjectContext) in
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 0)
            }).writeSync({ (context: NSManagedObjectContext) in
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
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                User.SK_removeAll(context)
            }).read({ (context: NSManagedObjectContext) in
                let users = User.SK_all(context)
                XCTAssertEqual(users.count, 0)
            }).writeSync({ (context: NSManagedObjectContext) in
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
                
                self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                    let user = User.SK_create(context)
                    user.firstname = "John"
                    user.lastname = "Doe"
                }).writeSync({ (context: NSManagedObjectContext) in
                    User.SK_removeAll(context)
                }).writeSync({ (context: NSManagedObjectContext) in
                    User.SK_all(context)
                    }, completion: { (error: NSError?) in
                    count-=1
                    dispatch_semaphore_signal(sem);
                })
            }
        }
    }
    
    func test_CorrectOrderOfOperationsMainQueue() {
        
        let expectation = expectationWithDescription("\(#function)")
        var counter = 0
        
        dispatch_async(dispatch_get_main_queue(), {
            
            XCTAssertEqual(counter, 0)
            counter+=1
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 1)
                counter+=1
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 2)
                counter+=1
            }).writeSync({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 3)
                counter+=1
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 4)
                counter+=1
                expectation.fulfill()
            })
            XCTAssertEqual(counter, 5)
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectOrderOfOperationsBkgQueue() {
        
        let expectation = expectationWithDescription("\(#function)")
        var counter = 0
        
        let q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(q, {
            
            XCTAssertEqual(counter, 0)
            counter+=1
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 1)
                counter+=1
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 2)
                counter+=1
            }).writeSync({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 3)
                counter+=1
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertEqual(counter, 4)
                counter+=1
                expectation.fulfill()
            })
            XCTAssertEqual(counter, 5)
            
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsMainQueue_SyncWrite() {
        
        let expectation = expectationWithDescription("\(#function)")
        
        dispatch_async(dispatch_get_main_queue(), {
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                XCTAssertTrue(NSThread.isMainThread())
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertTrue(NSThread.isMainThread())
                expectation.fulfill()
            });
            
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsBkgQueue_SyncWrite() {
        
        let expectation = expectationWithDescription("\(#function)")
        
        let q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(q, {
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                XCTAssertFalse(NSThread.isMainThread())
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertTrue(NSThread.isMainThread())
                expectation.fulfill()
            })
            
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsMainQueue_AsyncWrite() {
        
        let expectation = expectationWithDescription("\(#function)")
        
        dispatch_async(dispatch_get_main_queue(), {
            
            self.skopelos.writeAsync({ (context: NSManagedObjectContext) in
                XCTAssertFalse(NSThread.isMainThread())
                }, completion: { (error: NSError?) in
                    XCTAssertTrue(NSThread.isMainThread())
                    expectation.fulfill()
            })
            
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsBkgQueue_AsyncWrite() {
        
        let expectation = expectationWithDescription("\(#function)")
        
        let q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(q, {
            
            self.skopelos.writeAsync({ (context: NSManagedObjectContext) in
                XCTAssertFalse(NSThread.isMainThread())
                }, completion: { (error: NSError?) in
                    XCTAssertTrue(NSThread.isMainThread())
                    expectation.fulfill()
            })
            
        })
        
        waitForExpectationsWithTimeout(SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_NukingSQLiteStack() {
        
        let skopelos = Skopelos(sqliteStack: "DataModel")
        testNuke(skopelos)
    }
    
    func test_NukingSQLiteStackInSharedSpace() {
        
        let skopelos = Skopelos(sqliteStack: "DataModel", securityApplicationGroupIdentifier: "group.com.skopelos")
        testNuke(skopelos)
    }
    
    func test_NukingInMemoryStack() {
        
        let skopelos = Skopelos(inMemoryStack: "DataModel")
        testNuke(skopelos)
    }
    
    private func testNuke(skopelos: Skopelos) {
        
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
