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
    
        let expectation = self.expectation(description: "\(#function)")
    
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
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_DispatchAyncOnMainQueue() {
        
        let expectation = self.expectation(description: "\(#function)")
        
        DispatchQueue.main.async(execute: {
            
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
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_DispatchAyncOnBackgroundQueue() {
        
        let expectation = self.expectation(description: "\(#function)")
        
        let q = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background);
        q.async(execute: {
            
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
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_performance() {
        measure { 
            let sem = DispatchSemaphore(value: 0)
            var count = 3
            
            while (count > 0)
            {
                sem.wait(timeout: DispatchTime.now())
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
                
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
                    sem.signal();
                })
            }
        }
    }
    
    func test_CorrectOrderOfOperationsMainQueue() {
        
        let expectation = self.expectation(description: "\(#function)")
        var counter = 0
        
        DispatchQueue.main.async(execute: {
            
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
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectOrderOfOperationsBkgQueue() {
        
        let expectation = self.expectation(description: "\(#function)")
        var counter = 0
        
        let q = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background);
        q.async(execute: {
            
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
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsMainQueue_SyncWrite() {
        
        let expectation = self.expectation(description: "\(#function)")
        
        DispatchQueue.main.async(execute: {
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                XCTAssertTrue(Thread.isMainThread)
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            });
            
        })
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsBkgQueue_SyncWrite() {
        
        let expectation = self.expectation(description: "\(#function)")
        
        let q = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background);
        q.async(execute: {
            
            self.skopelos.writeSync({ (context: NSManagedObjectContext) in
                XCTAssertFalse(Thread.isMainThread)
            }).read({ (context: NSManagedObjectContext) in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            })
            
        })
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsMainQueue_AsyncWrite() {
        
        let expectation = self.expectation(description: "\(#function)")
        
        DispatchQueue.main.async(execute: {
            
            self.skopelos.writeAsync({ (context: NSManagedObjectContext) in
                XCTAssertFalse(Thread.isMainThread)
                }, completion: { (error: NSError?) in
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
            })
            
        })
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
    
    func test_CorrectThreadingOfOperationsBkgQueue_AsyncWrite() {
        
        let expectation = self.expectation(description: "\(#function)")
        
        let q = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background);
        q.async(execute: {
            
            self.skopelos.writeAsync({ (context: NSManagedObjectContext) in
                XCTAssertFalse(Thread.isMainThread)
                }, completion: { (error: NSError?) in
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
            })
            
        })
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
        
    }
}
