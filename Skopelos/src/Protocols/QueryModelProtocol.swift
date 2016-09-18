//
//  QueryModelProtocol.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import CoreData

protocol QueryModelProtocol {
    
    typealias StatementBlock = (NSManagedObjectContext) -> Void
    
    func read(_ statements: @escaping (NSManagedObjectContext) -> Void) -> Self
}
