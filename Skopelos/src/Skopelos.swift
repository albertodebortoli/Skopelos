//
//  Skopelos.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

public class Skopelos: DALService {
    
    public convenience init(sqliteStack modelURL: NSURL) {
        let cds = CoreDataStack(storeType: .SQLite, modelURL: modelURL, securityApplicationGroupIdentifier: nil)
        self.init(coreDataStack: cds)
    }
    
    public convenience init(sqliteStack modelURL: NSURL, securityApplicationGroupIdentifier: String?) {
        let cds = CoreDataStack(storeType: .SQLite, modelURL: modelURL, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
        self.init(coreDataStack: cds)
    }
    
    public convenience init(inMemoryStack modelURL: NSURL) {
        let cds = CoreDataStack(storeType: .InMemory, modelURL: modelURL, securityApplicationGroupIdentifier: nil)
        self.init(coreDataStack: cds)
    }
    
    public func nuke() {
        coreDataStack.nukeStore()
    }
}
