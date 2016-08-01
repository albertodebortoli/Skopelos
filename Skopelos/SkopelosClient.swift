//
//  SkopelosClient.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

final class SkopelosClient: Skopelos {
    
    static let sharedInstance = Skopelos(sqliteStack: "DataModel")
    
    override func handleError(error: NSError) {
        // clients should do the right thing here
        print(error.description)
    }
}
