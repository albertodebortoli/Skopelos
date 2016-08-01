//
//  DALService.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 30/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import CoreData

struct DALServiceConstants {
    static let handleDALServiceErrorNotification = "handleDALServiceErrorNotification"
}

class DALService: NSObject, DALProtocol {
    
    let coreDataStack: CoreDataStackProtocol
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DALServiceConstants.handleDALServiceErrorNotification, object: nil)
    }
    
    init(coreDataStack cds: CoreDataStackProtocol) {
        coreDataStack = cds
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(receiveErrorNotification),
                                                         name: DALServiceConstants.handleDALServiceErrorNotification,
                                                         object: nil)
    }
    
    @objc func receiveErrorNotification(notification: NSNotification) {
        let userInfo: [NSObject : AnyObject] = notification.userInfo!
        if let error = userInfo["error"] {
            handleError(error as! NSError)
        }
    }
    
    func handleError(error: NSError) {
        // override in subclasses
    }
    
    func read(statements: NSManagedObjectContext -> Void) -> Self {
        let context = coreDataStack.mainContext
        context.performBlockAndWait {
            statements(context)
        }
        return self;
    }
    
    private func slaveContext() -> NSManagedObjectContext {
        let slaveContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        slaveContext.parentContext = coreDataStack.mainContext
        return slaveContext
    }
    
    
    func write(changes: NSManagedObjectContext -> Void) -> Self {
        return write(changes, completion:nil)
    }
    
    func write(changes: NSManagedObjectContext -> Void, completion: (NSError? -> Void)?) -> Self {
        
        let context = slaveContext()
        context.performBlockAndWait {
            changes(context)
            do {
                try context.save()
                self.coreDataStack.save(completion)
            } catch _ {
                //                fatalError("Failed to save main context: \(error.localizedDescription), \(error.userInfo)")
            }
            
        }
        
        return self
    }
    
}

