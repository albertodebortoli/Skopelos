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
    
    func SK_inContext(otherContext: NSManagedObjectContext) -> NSManagedObject? {
        
        if self.objectID.temporaryID {
            do {
                try self.managedObjectContext?.obtainPermanentIDsForObjects([self])
                let inContext = try otherContext.existingObjectWithID(self.objectID)
                return inContext
            } catch let error as NSError {
                NSManagedObject.handleDALServiceError(error)
            }
        }
        
        return nil
    }
    
    class func SK_create(context: NSManagedObjectContext) -> NSManagedObject {
        return  NSEntityDescription.insertNewObjectForEntityForName(self.nameOfClass, inManagedObjectContext: context)
    }
    
    class func SK_numberOfEntities(context: NSManagedObjectContext) -> Int {
        
        let request = SK_basicFetchRequestInContext(context)
        
        var error: NSError?
        let result = context.countForFetchRequest(request, error: &error)
        if error != nil {
            handleDALServiceError(error!)
        }
        return result
    }
    
    class func SK_numberOfEntities(predicate: NSPredicate, context: NSManagedObjectContext) -> Int {
        
        let request = SK_basicFetchRequestInContext(context)
        request.predicate = predicate
        
        var error: NSError?
        let result = context.countForFetchRequest(request, error: &error)
        if error != nil {
            handleDALServiceError(error!)
        }
        return result
    }
    
    func SK_remove(context: NSManagedObjectContext) -> Void {
        context.deleteObject(self)
    }
    
    class func SK_removeAll(context: NSManagedObjectContext) -> Void {
        let request = SK_basicFetchRequestInContext(context)
        request.returnsObjectsAsFaults = true
        request.includesPropertyValues = false
        do {
            let objs = try context.executeFetchRequest(request)
            
            for (_, obj) in objs.enumerate() {
                context.deleteObject(obj as! NSManagedObject)
            }
        }
        catch let error as NSError {
            handleDALServiceError(error)
        }
    }
    
    class func SK_all(context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = SK_basicFetchRequestInContext(context)
        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            return results
        } catch let error as NSError {
            handleDALServiceError(error)
        }
        return []
    }
    
    class func SK_all(predicate: NSPredicate, context:NSManagedObjectContext) -> [NSManagedObject] {
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
    
    class func SK_all(context: NSManagedObjectContext, predicate: NSPredicate, sortTerm: String, ascending: Bool) -> [NSManagedObject] {
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
    
    class func SK_all(attribute: String, isEqualTo value: String, sortTerms: String, ascending: Bool, context: NSManagedObjectContext) -> [NSManagedObject] {
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
    
    class func SK_first(context: NSManagedObjectContext) -> NSManagedObject? {
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
    
    class func SK_first(attribute: String, isEqualTo value: String, context: NSManagedObjectContext) -> NSManagedObject? {
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
    
    class func SK_first(predicate: NSPredicate, sortTerms: String, ascending: Bool, context: NSManagedObjectContext) -> NSManagedObject? {
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
    
    private class func SK_basicFetchRequestInContext(context: NSManagedObjectContext) -> NSFetchRequest {
        let request = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName(self.nameOfClass, inManagedObjectContext: context)
        request.entity = entityDescription
        return request
    }
    
    private class func SK_sortDescriptors(sortTerms: String, ascending:Bool) -> [NSSortDescriptor] {
        var sortDescriptors = [NSSortDescriptor]()
        for (_, value) in sortTerms.componentsSeparatedByString(",").enumerate() {
            
            var sortKey = value
            var customAscending = ascending
            
            let sortComponents = value.componentsSeparatedByString(":")
            if (sortComponents.count > 1) {
                customAscending = sortComponents.last!.boolValue
                sortKey = sortComponents.first!
            }
            
            let sortDescriptor = NSSortDescriptor(key: sortKey, ascending:customAscending)
            sortDescriptors.append(sortDescriptor)
        }
        return sortDescriptors
    }
    
    private class func handleDALServiceError(error: NSError) -> Void {
        NSNotificationCenter.defaultCenter().postNotificationName(DALServiceConstants.handleDALServiceErrorNotification, object: self, userInfo: ["error": error])
    }
    
}