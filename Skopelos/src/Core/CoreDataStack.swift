//
//  CoreDataStack.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum StoreType {
    case SQLite
    case InMemory
}

class CoreDataStack: NSObject, CoreDataStackProtocol, AppStateReactorDelegate {
    
    var mainContext: NSManagedObjectContext
    var privateContext: NSManagedObjectContext
    var appStateReactor: AppStateReactor
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    convenience init(storeType: StoreType, dataModelFileName: String) {
        self.init(storeType: storeType, dataModelFileName: dataModelFileName, handler: nil)
    }
    
    init(storeType: StoreType, dataModelFileName: String, handler:(Void -> Void)?) {
        appStateReactor = AppStateReactor()
        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        super.init()
        appStateReactor.delegate = self
        self.initialize(storeType, dataModelFileName: dataModelFileName, callback: handler)
    }
    
    func initialize(storeType: StoreType, dataModelFileName: String, callback:(Void -> Void)?) {
        let modelURL = NSBundle.mainBundle().URLForResource(dataModelFileName, withExtension: "momd")
        let mom = NSManagedObjectModel(contentsOfURL: modelURL!)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        privateContext.persistentStoreCoordinator = coordinator
        mainContext.parentContext = privateContext
    
        let privateContextSetupBlock = {
            let psc = self.privateContext.persistentStoreCoordinator!
            
            switch storeType {
            case .SQLite:
                CoreDataStack.addSQLiteStore(psc, dataModelFileName:dataModelFileName)
            case .InMemory:
                CoreDataStack.addInMemoryStore(psc)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                if let callback = callback {
                    callback()
                }
            })
        }
        
        if callback != nil {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                privateContextSetupBlock()
            })
        } else {
            privateContextSetupBlock();
        }
    }
    
    func save(handler: (NSError? -> Void)? ) -> Void {
        var mainHasChanges = false
        var privateHasChanges = false
        
        mainContext.performBlockAndWait {
            mainHasChanges = self.mainContext.hasChanges
        }
        
        privateContext.performBlockAndWait {
            privateHasChanges = self.privateContext.hasChanges
        }
        
        if !mainHasChanges && !privateHasChanges {
            dispatch_async(dispatch_get_main_queue(), {
                if let handler = handler {
                    handler(nil)
                }
            })
            return
        }
        
        mainContext.performBlock {
            do {
                try self.mainContext.save()
            } catch let error as NSError {
                //                fatalError("Failed to save main context: \(error.localizedDescription), \(error.userInfo)")
                dispatch_async(dispatch_get_main_queue(), {
                    if let handler = handler {
                        handler(error);
                    }
                });
            }
            
            self.privateContext.performBlock {
                
                do {
                    try self.privateContext.save()
                } catch let error as NSError {
                    //                    fatalError("Error saving private context: \(error.localizedDescription), \(error.userInfo)")
                    dispatch_async(dispatch_get_main_queue(), {
                        if let handler = handler {
                            handler(error)
                        }
                    })
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if let handler = handler {
                        handler(nil)
                    }
                })
            }
        }
        
    }
    
    class func addSQLiteStore(coordinator: NSPersistentStoreCoordinator, dataModelFileName: String) {
        let fileManager = NSFileManager.defaultManager()
        let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last
        let storeURL = documentsURL?.URLByAppendingPathComponent(String("\(dataModelFileName).sqlite"))
        let options = autoMigratingOptions()
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
        } catch _ {
            // handle error @"Error adding Persistent Store: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    class func addInMemoryStore(coordinator: NSPersistentStoreCoordinator) {
        do {
            try coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        } catch _ {
            // handle error @"Error adding Persistent Store: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    class func autoMigratingOptions() -> [NSObject: AnyObject] {
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true,
                       NSSQLitePragmasOption: ["journal_mode": "WAL"]]
        return options
    }
    
    // MARK: ADBAppStateReactorDelegate
    
    private func registerBackgroundTask() {
        backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
            [unowned self] in
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.sharedApplication().endBackgroundTask(backgroundTask!)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    func didReceiveStateChange(appStateReactor: AppStateReactor) -> Void {
        registerBackgroundTask()
        return save({ (error: NSError?) in
            self.endBackgroundTask()
            self.backgroundTask = UIBackgroundTaskInvalid
        })
    }
    
}
