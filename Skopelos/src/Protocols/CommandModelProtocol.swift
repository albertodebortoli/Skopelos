//
//  CommandModelProtocol.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import CoreData

protocol CommandModelProtocol {
    
    func writeSync(_ changes: @escaping (NSManagedObjectContext) -> Void) -> Self
    func writeSync(_ changes: @escaping (NSManagedObjectContext) -> Void, completion: ((NSError?) -> Void)?) -> Self

    // async writings are not chainable, return value is void
    func writeAsync(_ changes: @escaping (NSManagedObjectContext) -> Void) -> Void
    func writeAsync(_ changes: @escaping (NSManagedObjectContext) -> Void, completion: ((NSError?) -> Void)?) -> Void
}
