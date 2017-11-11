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
    
    @discardableResult
    func writeSync(_ changes: @escaping ChangesBlock) -> Self
    @discardableResult
    func writeSync(_ changes: @escaping ChangesBlock, completion: CompletionBlock?) -> Self
    
    func writeSync(_ saveToParentContext: Bool, changes: @escaping ChangesBlock) -> Self
    func writeSync(_ saveToParentContext: Bool, changes: @escaping ChangesBlock, completion: CompletionBlock?) -> Self
    
    // async writings are not chainable, return value is void
    func writeAsync(_ changes: @escaping ChangesBlock) -> Void
    func writeAsync(_ changes: @escaping ChangesBlock, completion: CompletionBlock?) -> Void
    
    func writeAsync(_ saveToParentContext: Bool, changes: @escaping ChangesBlock) -> Void
    func writeAsync(_ saveToParentContext: Bool, changes: @escaping ChangesBlock, completion: CompletionBlock?) -> Void
}
