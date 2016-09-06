//
//  CommandModelProtocol.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import CoreData

protocol CommandModelProtocol {
    
    typealias ChangesBlock = (NSManagedObjectContext) -> Void
    typealias CompletionBlock = (NSError?) -> Void
    
    func writeSync(_ changes: ChangesBlock) -> Self
    func writeSync(_ changes: ChangesBlock, completion: CompletionBlock?) -> Self

    // async writings are not chainable, return value is void
    func writeAsync(_ changes: ChangesBlock) -> Void
    func writeAsync(_ changes: ChangesBlock, completion: CompletionBlock?) -> Void
}
