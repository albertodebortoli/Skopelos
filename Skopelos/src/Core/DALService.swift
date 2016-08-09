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

public class DALService: NSObject {
    
    let coreDataStack: CoreDataStackProtocol
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DALServiceConstants.handleDALServiceErrorNotification, object: nil)
    }
    
    public init(coreDataStack cds: CoreDataStackProtocol) {
        coreDataStack = cds
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(receiveErrorNotification),
                                                         name: DALServiceConstants.handleDALServiceErrorNotification,
                                                         object: nil)
    }
    
    @objc func receiveErrorNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo, error = userInfo["error"]  else { return }
        handleError(error as! NSError)
    }
    
    public func handleError(error: NSError) {
        // override in subclasses
    }
    
    private func slaveContext() -> NSManagedObjectContext {
        let slaveContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        slaveContext.parentContext = coreDataStack.mainContext
        
        return slaveContext
    }
}

extension DALService: DALProtocol {

    public func read(statements: NSManagedObjectContext -> Void) -> Self {
        let context = coreDataStack.mainContext
        context.performBlockAndWait {
            statements(context)
        }

        return self
    }
    
    public func writeSync(changes: NSManagedObjectContext -> Void) -> Self {
        return writeSync(changes, completion:nil)
    }
    
    public func writeSync(changes: NSManagedObjectContext -> Void, completion: (NSError? -> Void)?) -> Self {
        let context = slaveContext()
        context.performBlockAndWait {
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
    
    public func writeAsync(changes: NSManagedObjectContext -> Void) -> Void {
        return writeAsync(changes, completion:nil)
    }
    
    public func writeAsync(changes: NSManagedObjectContext -> Void, completion: (NSError? -> Void)?) -> Void {
        let context = slaveContext()
        context.performBlock {
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
