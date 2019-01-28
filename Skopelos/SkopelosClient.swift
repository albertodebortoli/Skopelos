//
//  SkopelosClient.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

protocol SkopelosClientDelegate: class {
    func handle(_ error: NSError)
}

class SkopelosClient: Skopelos {
    
    static let modelURL = Bundle(for: Skopelos.self).url(forResource: "DataModel", withExtension: "momd")!
    
    weak var delegate: SkopelosClientDelegate?
    
    class func sqliteStack() -> Skopelos {
        return Skopelos(sqliteStack: modelURL)
    }
    
    class func inMemoryStack() -> Skopelos {
        return Skopelos(inMemoryStack: modelURL)
    }
    
    override func handleError(_ error: NSError) {
        DispatchQueue.main.async {
            self.delegate?.handle(error)
        }
    }
}
