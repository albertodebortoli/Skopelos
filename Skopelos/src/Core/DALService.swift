//
//  DALService.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import CoreData

public struct DALServiceConstants {
    static let handleDALServiceErrorNotification = "handleDALServiceErrorNotification"
}

open class DALService: NSObject {
    
    let coreDataStack: CoreDataStackProtocol
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DALServiceConstants.handleDALServiceErrorNotification), object: nil)
    }
    
    public init(coreDataStack cds: CoreDataStackProtocol) {
        coreDataStack = cds
        super.init()
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(receiveErrorNotification),
                                                         name: NSNotification.Name(rawValue: DALServiceConstants.handleDALServiceErrorNotification),
                                                         object: nil)
    }
    
    @objc func receiveErrorNotification(_ notification: Notification) {
        guard let userInfo = (notification as NSNotification).userInfo, let error = userInfo["error"]  else { return }
        handle(error: error as! NSError)
    }
    
    open func handle(error: NSError) {
        // override in subclasses
    }
    
    fileprivate func slaveContext() -> NSManagedObjectContext {
        let slaveContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        slaveContext.parent = coreDataStack.mainContext
        
        return slaveContext
    }
}

extension DALService: DALProtocol {

    @discardableResult
    public func read(_ statements: @escaping (NSManagedObjectContext) -> Void) -> Self {
        let context = coreDataStack.mainContext
        context.performAndWait {
            statements(context)
        }

        return self
    }
    
    @discardableResult
    public func writeSync(_ changes: @escaping (NSManagedObjectContext) -> Void) -> Self {
        return writeSync(changes, completion:nil)
    }
    
    @discardableResult
    public func writeSync(_ changes: @escaping (NSManagedObjectContext) -> Void, completion: ((NSError?) -> Void)?) -> Self {
        let context = slaveContext()
        context.performAndWait {
            changes(context)
            do {
                try context.save()
                self.coreDataStack.save(completion)
            } catch let error as NSError {
                fatalError("Failed to save main context: \(error.localizedDescription), \(error.userInfo)")
            }
        }
        
        return self
    }
    
    public func writeAsync(_ changes: @escaping (NSManagedObjectContext) -> Void) -> Void {
        return writeAsync(changes, completion:nil)
    }
    
    public func writeAsync(_ changes: @escaping (NSManagedObjectContext) -> Void, completion: ((NSError?) -> Void)?) -> Void {
        let context = slaveContext()
        context.perform {
            changes(context)
            do {
                try context.save()
                self.coreDataStack.save(completion)
            } catch let error as NSError {
                fatalError("Failed to save main context: \(error.localizedDescription), \(error.userInfo)")
            }
        }
    }
}
