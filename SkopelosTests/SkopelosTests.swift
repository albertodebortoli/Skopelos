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
        if let modelURL = Bundle(for: type(of: self)).url(forResource: "DataModel", withExtension: "momd") {
            skopelos = Skopelos(inMemoryStack: modelURL)
        }
    }
    
    override func tearDown() {
        super.tearDown()
        skopelos = nil
    }
    
    func test_Chaining() {
        let expectation = self.expectation(description: "\(#function)")
        let _ = skopelos.writeSync { context in
            var user = User.SK_create(context)
            user = user.SK_inContext(context)!
            let _ = User.SK_create(context)
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
    
    func test_DispatchAyncOnMainQueue() {
        let expectation = self.expectation(description: "\(#function)")
        DispatchQueue.main.async {
            let _ = self.skopelos.writeSync { context in
                User.SK_removeAll(context)
                }.read { context in
                    let users = User.SK_all(context)
                    XCTAssertEqual(users.count, 0)
                }.writeSync { context in
                    let user = User.SK_create(context)
                    user.firstname = "John"
                    user.lastname = "Doe"
                }.read { context in
                    let users = User.SK_all(context)
                    XCTAssertEqual(users.count, 1)
                    expectation.fulfill()
            }
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_DispatchAyncOnBackgroundQueue() {
        let expectation = self.expectation(description: "\(#function)")
        let q = DispatchQueue.global(qos: .userInitiated)
        q.async {
            let _ = self.skopelos.writeSync { context in
                User.SK_removeAll(context)
                }.read { context in
                    let users = User.SK_all(context)
                    XCTAssertEqual(users.count, 0)
                }.writeSync { context in
                    let user = User.SK_create(context)
                    user.firstname = "John"
                    user.lastname = "Doe"
                }.read { context in
                    let users = User.SK_all(context)
                    XCTAssertEqual(users.count, 1)
                    expectation.fulfill()
            }
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_performance() {
        measure { 
            let sem = DispatchSemaphore(value: 0)
            var count = 3
            while (count > 0) {
                let _ = sem.wait(timeout: DispatchTime.now())
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
                
                let _ = self.skopelos.writeSync { context in
                    let user = User.SK_create(context)
                    user.firstname = "John"
                    user.lastname = "Doe"
                    }.writeSync { context in
                        User.SK_removeAll(context)
                    }.writeSync({ context in
                        let _ = User.SK_all(context)
                    }, completion: { error in
                        count-=1
                        sem.signal();
                    })
            }
        }
    }
    
    func test_CorrectOrderOfOperationsMainQueue() {
        let expectation = self.expectation(description: "\(#function)")
        var counter = 0
        DispatchQueue.main.async {
            XCTAssertEqual(counter, 0)
            counter+=1
            let _ = self.skopelos.writeSync { context in
                XCTAssertEqual(counter, 1)
                counter+=1
                }.read { context in
                    XCTAssertEqual(counter, 2)
                    counter+=1
                }.writeSync { context in
                    XCTAssertEqual(counter, 3)
                    counter+=1
                }.read { context in
                    XCTAssertEqual(counter, 4)
                    counter+=1
                    expectation.fulfill()
            }
            XCTAssertEqual(counter, 5)
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_CorrectOrderOfOperationsBkgQueue() {
        let expectation = self.expectation(description: "\(#function)")
        var counter = 0
        let q = DispatchQueue.global(qos: .userInitiated)
        q.async {
            XCTAssertEqual(counter, 0)
            counter+=1
            
            let _ = self.skopelos.writeSync { context in
                XCTAssertEqual(counter, 1)
                counter+=1
                }.read { context in
                    XCTAssertEqual(counter, 2)
                    counter+=1
                }.writeSync { context in
                    XCTAssertEqual(counter, 3)
                    counter+=1
                }.read { context in
                    XCTAssertEqual(counter, 4)
                    counter+=1
                    expectation.fulfill()
            }
            XCTAssertEqual(counter, 5)
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_CorrectThreadingOfOperationsMainQueue_SyncWrite() {
        let expectation = self.expectation(description: "\(#function)")
        DispatchQueue.main.async {
            let _ = self.skopelos.writeSync { context in
                XCTAssertTrue(Thread.isMainThread)
                }.read { context in
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
            }
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_CorrectThreadingOfOperationsBkgQueue_SyncWrite() {
        let expectation = self.expectation(description: "\(#function)")
        let q = DispatchQueue.global(qos: .userInitiated)
        q.async {
            let _ = self.skopelos.writeSync { context in
                XCTAssertFalse(Thread.isMainThread)
                }.read { context in
                    XCTAssertTrue(Thread.isMainThread)
                    expectation.fulfill()
            }
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_CorrectThreadingOfOperationsMainQueue_AsyncWrite() {
        let expectation = self.expectation(description: "\(#function)")
        DispatchQueue.main.async {
            self.skopelos.writeAsync({ context in
                XCTAssertFalse(Thread.isMainThread)
            }, completion: { error in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            })
        }
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_CorrectThreadingOfOperationsBkgQueue_AsyncWrite() {
        let expectation = self.expectation(description: "\(#function)")
        let q = DispatchQueue.global(qos: .userInitiated)
        q.async {
            self.skopelos.writeAsync({ context in
                XCTAssertFalse(Thread.isMainThread)
            }, completion: { error in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: SkopelosTestsConsts.UnitTestTimeout, handler: nil)
    }
    
    func test_NukingSQLiteStack() {
        var skopelos: Skopelos!
        if let modelURL = Bundle(for: type(of: self)).url(forResource: "DataModel", withExtension: "momd") {
            skopelos = Skopelos(sqliteStack: modelURL)
        }
        testNuke(skopelos)
    }
    
    func test_NukingSQLiteStackInSharedSpace() {
        var skopelos: Skopelos!
        if let modelURL = Bundle(for: type(of: self)).url(forResource: "DataModel", withExtension: "momd") {
            skopelos = Skopelos(sqliteStack: modelURL, securityApplicationGroupIdentifier: "group.com.skopelos")
        }
        testNuke(skopelos)
    }
    
    func test_NukingInMemoryStack() {
        var skopelos: Skopelos!
        if let modelURL = Bundle(for: type(of: self)).url(forResource: "DataModel", withExtension: "momd") {
            skopelos = Skopelos(inMemoryStack: modelURL)
        }
        testNuke(skopelos)
    }
    
    private func testNuke(_ skopelos: Skopelos) {
        
        let _ = skopelos.writeSync({ (context: NSManagedObjectContext) in
            let _ = User.SK_create(context)
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 1)
        }).read { (context: NSManagedObjectContext) in
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 1);
        }
        
        skopelos.nuke()
        
        let _ = skopelos.read { (context: NSManagedObjectContext) in
            let users = User.SK_all(context)
            XCTAssertEqual(users.count, 0);
        }
    }
}
