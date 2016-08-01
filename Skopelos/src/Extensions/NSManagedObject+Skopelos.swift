//
//  NSManagedObject+Skopelos.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {

    public func SK_inContext(otherContext: NSManagedObjectContext) -> NSManagedObject? {

        guard self.objectID.temporaryID else { return nil }

        do {
            try self.managedObjectContext?.obtainPermanentIDsForObjects([self])
            let inContext = try otherContext.existingObjectWithID(self.objectID)
            return inContext
        } catch let error as NSError {
            NSManagedObject.handleDALServiceError(error)
        }

        return nil
    }

    public static func SK_create(context: NSManagedObjectContext) -> NSManagedObject {
        return  NSEntityDescription.insertNewObjectForEntityForName(self.nameOfClass, inManagedObjectContext: context)
    }

    public static func SK_numberOfEntities(context: NSManagedObjectContext) -> Int {

        let request = SK_basicFetchRequestInContext(context)
        
        var error: NSError?
        let result = context.countForFetchRequest(request, error: &error)
        if error != nil {
            handleDALServiceError(error!)
        }

        return result
    }

    public static func SK_numberOfEntities(predicate: NSPredicate, context: NSManagedObjectContext) -> Int {

        let request = SK_basicFetchRequestInContext(context)
        request.predicate = predicate
        
        var error: NSError?
        let result = context.countForFetchRequest(request, error: &error)
        if error != nil {
            handleDALServiceError(error!)
        }

        return result
    }

    public func SK_remove(context: NSManagedObjectContext) -> Void {
        context.deleteObject(self)
    }

    public static func SK_removeAll(context: NSManagedObjectContext) -> Void {
        let request = SK_basicFetchRequestInContext(context)
        request.returnsObjectsAsFaults = true
        request.includesPropertyValues = false

        do {
            let objs = try context.executeFetchRequest(request)
            objs.forEach {
                context.deleteObject($0 as! NSManagedObject)
            }
        }
        catch let error as NSError {
            handleDALServiceError(error)
        }
    }

    public static func SK_all(context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = SK_basicFetchRequestInContext(context)

        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results
        } catch let error as NSError {
            handleDALServiceError(error)
        }

        return []
    }

    public static func SK_all(predicate: NSPredicate, context:NSManagedObjectContext) -> [NSManagedObject] {
        let request = SK_basicFetchRequestInContext(context)
        request.predicate = predicate

        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results
        } catch let error as NSError {
            handleDALServiceError(error)
        }

        return []
    }

    public static func SK_all(context: NSManagedObjectContext, predicate: NSPredicate, sortTerm: String, ascending: Bool) -> [NSManagedObject] {
        let request = SK_basicFetchRequestInContext(context)
        request.predicate = predicate
        request.sortDescriptors = SK_sortDescriptors(sortTerm, ascending:ascending)
        
        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results
        } catch let error as NSError {
            handleDALServiceError(error)
        }

        return []
    }

    public static func SK_all(attribute: String, isEqualTo value: String, sortTerms: String, ascending: Bool, context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = SK_basicFetchRequestInContext(context)
        request.predicate = NSPredicate(format: "%K = %@", attribute, value)
        request.sortDescriptors = SK_sortDescriptors(sortTerms, ascending:ascending)
        
        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results
        } catch let error as NSError {
            handleDALServiceError(error)
        }

        return []
    }

    public static func SK_first(context: NSManagedObjectContext) -> NSManagedObject? {
        let request = SK_basicFetchRequestInContext(context)
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        
        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results.first
        } catch let error as NSError {
            handleDALServiceError(error)
        }

        return nil
    }

    public static func SK_first(attribute: String, isEqualTo value: String, context: NSManagedObjectContext) -> NSManagedObject? {
        let request = SK_basicFetchRequestInContext(context)
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        request.predicate = NSPredicate(format: "%K = %@", attribute, value)

        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results.first
        } catch let error as NSError {
            handleDALServiceError(error)
        }

        return nil
    }

    public static func SK_first(predicate: NSPredicate, sortTerms: String, ascending: Bool, context: NSManagedObjectContext) -> NSManagedObject? {
        let request = SK_basicFetchRequestInContext(context)
        request.predicate = predicate
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        request.sortDescriptors = SK_sortDescriptors(sortTerms, ascending: ascending)

        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results.first
        } catch let error as NSError {
            handleDALServiceError(error)
        }

        return nil
    }

    // MARK: Private

    private static func SK_basicFetchRequestInContext(context: NSManagedObjectContext) -> NSFetchRequest {
        let request = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName(self.nameOfClass, inManagedObjectContext: context)
        request.entity = entityDescription
        return request
    }

    private static func SK_sortDescriptors(sortTerms: String, ascending:Bool) -> [NSSortDescriptor] {

        return sortTerms.componentsSeparatedByString(",").map { value in

            var sortKey = value
            var customAscending = ascending

            let sortComponents = value.componentsSeparatedByString(":")
            if (sortComponents.count > 1) {
                customAscending = sortComponents.last!.boolValue
                sortKey = sortComponents.first!
            }

           return NSSortDescriptor(key: sortKey, ascending:customAscending)
        }
    }

    private static func handleDALServiceError(error: NSError) -> Void {
        NSNotificationCenter.defaultCenter().postNotificationName(DALServiceConstants.handleDALServiceErrorNotification, object: self, userInfo: ["error": error])
    }
}
