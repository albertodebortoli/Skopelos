//
//  CoreDataStackProtocol.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataStackProtocol {
    
    var mainContext: NSManagedObjectContext { get set }
    var privateContext: NSManagedObjectContext { get set }

    func save(handler: (NSError? -> Void)? ) -> Void
}