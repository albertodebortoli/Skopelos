//
//  SkopelosClient.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

final class SkopelosClient: Skopelos {
    
    static let shared: Skopelos = {
        
        var skopelos: Skopelos!
        
        if let modelURL = Bundle(for: Skopelos.self).url(forResource: "DataModel", withExtension: "momd") {
            skopelos = Skopelos(inMemoryStack: modelURL)
        }
        
        return skopelos
        
    }()
    
    override func handleError(_ error: NSError) {
        // clients should do the right thing here
        print(error.localizedDescription)
    }
}
