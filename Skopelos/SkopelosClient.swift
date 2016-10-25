//
//  SkopelosClient.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

final class SkopelosClient: Skopelos {
    
    static let sharedInstance: Skopelos! = {
     
        if let modelURL = NSBundle(forClass: Skopelos.self).URLForResource("DataModel", withExtension: "momd") {
            return Skopelos(inMemoryStack: modelURL)
        }
        
        return nil
        
    }()
    
    override func handleError(error: NSError) {
        // clients should do the right thing here
        print(error.description)
    }
}
