//
//  QueryModelProtocol.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import CoreData

protocol QueryModelProtocol {
    
    func read(statements: NSManagedObjectContext -> Void) -> Self
    
}
