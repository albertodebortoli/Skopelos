//
//  Skopelos.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

open class Skopelos: DALService {
    
    public convenience init(sqliteStack modelURL: URL,
                            allowsConcurrentWritings: Bool = false,
                            shouldAddStoreAsynchronously: Bool = false,
                            completion: (() -> Void)? = nil) {
        let cds = CoreDataStack(storeType: .sqlite,
                                modelURL: modelURL,
                                securityApplicationGroupIdentifier: nil,
                                shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                handler: completion)
        self.init(coreDataStack: cds, allowsConcurrentWritings: allowsConcurrentWritings)
    }
    
    public convenience init(sqliteStack modelURL: URL,
                            securityApplicationGroupIdentifier: String?,
                            allowsConcurrentWritings: Bool = false,
                            shouldAddStoreAsynchronously: Bool = false,
                            completion: (() -> Void)? = nil) {
        let cds = CoreDataStack(storeType: .sqlite,
                                modelURL: modelURL,
                                securityApplicationGroupIdentifier: securityApplicationGroupIdentifier,
                                shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                handler: completion)
        self.init(coreDataStack: cds, allowsConcurrentWritings: allowsConcurrentWritings)
    }
    
    public convenience init(inMemoryStack modelURL: URL,
                            allowsConcurrentWritings: Bool = false,
                            shouldAddStoreAsynchronously: Bool = false,
                            completion: (() -> Void)? = nil) {
        let cds = CoreDataStack(storeType: .inMemory,
                                modelURL: modelURL,
                                securityApplicationGroupIdentifier: nil,
                                shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                handler: completion)
        self.init(coreDataStack: cds, allowsConcurrentWritings: allowsConcurrentWritings)
    }
    
    public func nuke() {
        coreDataStack.nukeStore()
    }
}
