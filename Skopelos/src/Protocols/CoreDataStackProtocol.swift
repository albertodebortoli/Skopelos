//
//  CoreDataStackProtocol.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import CoreData

public protocol CoreDataStackProtocol {
    
    var mainContext: NSManagedObjectContext { get set }
    var rootContext: NSManagedObjectContext { get set }

    func save(_ handler: ((NSError?) -> Void)? ) -> Void
    func nukeStore()
}
