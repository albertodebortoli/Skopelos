//
//  DALService+Helpers.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

extension DALService {
    
    class func sqliteStack(dataModelFileName: String) -> DALService {
        let cds = CoreDataStack(storeType: .SQLite, dataModelFileName:dataModelFileName)
        return DALService(coreDataStack: cds)
    }
    
    class func inMemoryStack(dataModelFileName: String) -> DALService {
        let cds = CoreDataStack(storeType: .InMemory, dataModelFileName:dataModelFileName)
        return DALService(coreDataStack: cds)
    }

}