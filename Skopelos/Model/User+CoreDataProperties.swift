//
//  User+CoreDataProperties.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import CoreData

extension User {

    @NSManaged var firstname: String?
    @NSManaged var lastname: String?
    @NSManaged var relationship: NSSet?
}
