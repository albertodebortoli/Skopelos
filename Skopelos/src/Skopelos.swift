//
//  Skopelos.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

class Skopelos: DALService {
    
    convenience init(sqliteStack dataModelFileName: String) {
        let cds = CoreDataStack(storeType: .SQLite, dataModelFileName:dataModelFileName)
        self.init(coreDataStack: cds)
    }
    
    convenience init(inMemoryStack dataModelFileName: String) {
        let cds = CoreDataStack(storeType: .InMemory, dataModelFileName:dataModelFileName)
        self.init(coreDataStack: cds)
    }
    
}