//
//  NSManagedObject+Skopelos.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import CoreData

public protocol NSManagedObjectExtendable { }

extension NSManagedObject : NSManagedObjectExtendable { }

public extension NSManagedObjectExtendable where Self:NSManagedObject {
    
    func SK_inContext(_ otherContext: NSManagedObjectContext) -> Self? {
        
        if self.objectID.isTemporaryID {
            do {
                try self.managedObjectContext?.obtainPermanentIDs(for: [self])
                let inContext = try otherContext.existingObject(with: self.objectID)
                return inContext as? Self
            } catch let error as NSError {
                Self.handleError(error)
            }
        }

        return nil
    }
    
    @discardableResult
    static func SK_create(_ context: NSManagedObjectContext) -> Self {
        return NSEntityDescription.insertNewObject(forEntityName: self.nameOfClass, into: context) as! Self
    }
    
    static func SK_numberOfEntities(_ context: NSManagedObjectContext) -> Int {
        
        let request = basicFetchRequestInContext(context)
        
        let result: Int
        
        do {
            result = try context.count(for: request)
        } catch let error as NSError {
            handleError(error)
            result = 0
        }
        
        return result
    }
    
    static func SK_numberOfEntities(_ predicate: NSPredicate, context: NSManagedObjectContext) -> Int {
        
        let request = basicFetchRequestInContext(context)
        request.predicate = predicate
        
        let result: Int
        
        do {
            result = try context.count(for: request)
        } catch let error as NSError {
            handleError(error)
            result = 0
        }

        return result
    }
    
    func SK_remove(_ context: NSManagedObjectContext) {
        context.delete(self)
    }
    
    static func SK_removeAll(_ context: NSManagedObjectContext) {
        let request = basicFetchRequestInContext(context)
        request.returnsObjectsAsFaults = true
        request.includesPropertyValues = false

        do {
            let objs = try context.fetch(request)
            objs.forEach {
                context.delete($0)
            }
        }
        catch let error as NSError {
            handleError(error)
        }
    }
    
    static func SK_all(_ context: NSManagedObjectContext) -> [Self] {
        let request = basicFetchRequestInContext(context)

        do {
            let results = try context.fetch(request)
            return results
        } catch let error as NSError {
            handleError(error)
        }

        return []
    }
    
    static func SK_all(_ predicate: NSPredicate, context:NSManagedObjectContext) -> [Self] {
        let request = basicFetchRequestInContext(context)
        request.predicate = predicate

        do {
            let results = try context.fetch(request)
            return results
        } catch let error as NSError {
            handleError(error)
        }

        return []
    }
    
    static func SK_all(_ context: NSManagedObjectContext, predicate: NSPredicate, sortTerm: String, ascending: Bool) -> [Self] {
        let request = basicFetchRequestInContext(context)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors(sortTerm, ascending:ascending)
        
        do {
            let results = try context.fetch(request)
            return results
        } catch let error as NSError {
            handleError(error)
        }

        return []
    }
    
    static func SK_all(_ attribute: String, isEqualTo value: String, sortTerms: String, ascending: Bool, context: NSManagedObjectContext) -> [Self] {
        let request = basicFetchRequestInContext(context)
        request.predicate = NSPredicate(format: "%K = %@", attribute, value)
        request.sortDescriptors = sortDescriptors(sortTerms, ascending:ascending)
        
        do {
            let results = try context.fetch(request)
            return results
        } catch let error as NSError {
            handleError(error)
        }

        return []
    }
    
    static func SK_first(_ context: NSManagedObjectContext) -> Self? {
        let request = basicFetchRequestInContext(context)
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch let error as NSError {
            handleError(error)
        }

        return nil
    }
    
    static func SK_first(_ attribute: String, isEqualTo value: String, context: NSManagedObjectContext) -> Self? {
        let request = basicFetchRequestInContext(context)
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        request.predicate = NSPredicate(format: "%K = %@", attribute, value)

        do {
            let results = try context.fetch(request)
            return results.first
        } catch let error as NSError {
            handleError(error)
        }

        return nil
    }
    
    static func SK_first(_ predicate: NSPredicate, sortTerms: String, ascending: Bool, context: NSManagedObjectContext) -> Self? {
        let request = basicFetchRequestInContext(context)
        request.predicate = predicate
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        request.sortDescriptors = sortDescriptors(sortTerms, ascending: ascending)

        do {
            let results = try context.fetch(request)
            return results.first
        } catch let error as NSError {
            handleError(error)
        }

        return nil
    }

    // MARK: Private
    
    fileprivate static func basicFetchRequestInContext(_ context: NSManagedObjectContext) -> NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>()
        let entityDescription = NSEntityDescription.entity(forEntityName: self.nameOfClass, in: context)
        request.entity = entityDescription
        return request
    }
    
    fileprivate static func sortDescriptors(_ sortTerms: String, ascending:Bool) -> [NSSortDescriptor] {
        
        return sortTerms.components(separatedBy: ",").map { value in
        
            var sortKey = value
            var customAscending = ascending

            let sortComponents = value.components(separatedBy: ":")
            if (sortComponents.count > 1) {
                customAscending = sortComponents.last!.boolValue
                sortKey = sortComponents.first!
            }

           return NSSortDescriptor(key: sortKey, ascending:customAscending)
        }
    }
    
    fileprivate static func handleError(_ error: Error) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: DALServiceConstants.handleErrorNotification), object: self, userInfo: ["error": error])
    }
}
