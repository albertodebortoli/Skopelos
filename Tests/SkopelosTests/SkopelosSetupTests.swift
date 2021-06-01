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

class SkopelosSetupTests: XCTestCase {
    
    let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
    var skopelos: Skopelos!
    
    func test_SetupSync() {
        let expectation1 = self.expectation(description: "\(#function)")
        let expectation2 = self.expectation(description: "\(#function)")
        skopelos = Skopelos(inMemoryStack: modelURL,
                            allowsConcurrentWritings: true,
                            shouldAddStoreAsynchronously: false,
                            completion: {
                                expectation1.fulfill()
        })
        expectation2.fulfill()
        wait(for: [expectation1, expectation2], timeout: SkopelosTestsConsts.UnitTestTimeout, enforceOrder: true)
    }
    
    func test_SetupAsync() {
        let expectation1 = self.expectation(description: "\(#function)")
        let expectation2 = self.expectation(description: "\(#function)")
        skopelos = Skopelos(inMemoryStack: modelURL,
                            allowsConcurrentWritings: true,
                            shouldAddStoreAsynchronously: true,
                            completion: {
                                expectation2.fulfill()
        })
        expectation1.fulfill()
        wait(for: [expectation1, expectation2], timeout: SkopelosTestsConsts.UnitTestTimeout, enforceOrder: true)
    }
}
