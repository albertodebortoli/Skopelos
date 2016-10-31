//
//  Skopelos.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

open class Skopelos: DALService {
    
    public convenience init(sqliteStack modelURL: URL) {
        let cds = CoreDataStack(storeType: .sqlite, modelURL: modelURL, securityApplicationGroupIdentifier: nil)
        self.init(coreDataStack: cds)
    }
    
    public convenience init(sqliteStack modelURL: URL, securityApplicationGroupIdentifier: String?) {
        let cds = CoreDataStack(storeType: .sqlite, modelURL: modelURL, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
        self.init(coreDataStack: cds)
    }
    
    public convenience init(inMemoryStack modelURL: URL) {
        let cds = CoreDataStack(storeType: .inMemory, modelURL: modelURL, securityApplicationGroupIdentifier: nil)
        self.init(coreDataStack: cds)
    }
    
    public func nuke() {
        coreDataStack.nukeStore()
    }
}
