//
//  CommandModelProtocol.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import CoreData

protocol CommandModelProtocol {
    
    func write(changes: NSManagedObjectContext -> Void) -> Self
    func write(changes: NSManagedObjectContext -> Void, completion: (NSError? -> Void)?) -> Self
}
