//
//  CoreDataStack.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import UIKit
import CoreData

public enum StoreType {
    case sqLite
    case inMemory
}

public final class CoreDataStack: NSObject {
    
    public var mainContext: NSManagedObjectContext
    public var rootContext: NSManagedObjectContext
    fileprivate let appStateReactor: AppStateReactor
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    public convenience init(storeType: StoreType, dataModelFileName: String) {
        self.init(storeType: storeType, dataModelFileName: dataModelFileName, handler: nil)
    }
    
    public init(storeType: StoreType, dataModelFileName: String, handler:((Void) -> Void)?) {
        appStateReactor = AppStateReactor()
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        rootContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        super.init()
        appStateReactor.delegate = self
        self.initialize(storeType, dataModelFileName: dataModelFileName, callback: handler)
    }
    
    func initialize(_ storeType: StoreType, dataModelFileName: String, callback:((Void) -> Void)?) {
        let modelURL = Bundle.main.url(forResource: dataModelFileName, withExtension: "momd")
        let mom = NSManagedObjectModel(contentsOf: modelURL!)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        rootContext.persistentStoreCoordinator = coordinator
        mainContext.parent = rootContext
    
        let privateContextSetupBlock = {
            let psc = self.rootContext.persistentStoreCoordinator!
            
            switch storeType {
            case .sqLite:
                CoreDataStack.addSQLiteStore(psc, dataModelFileName:dataModelFileName)
            case .inMemory:
                CoreDataStack.addInMemoryStore(psc)
            }
            
            DispatchQueue.main.async(execute: {
                if let callback = callback {
                    callback()
                }
            })
        }
        
        if callback != nil {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {
                privateContextSetupBlock()
            })
        } else {
            privateContextSetupBlock();
        }
    }

    fileprivate static func addSQLiteStore(_ coordinator: NSPersistentStoreCoordinator, dataModelFileName: String) {

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last
        let storeURL = documentsURL?.appendingPathComponent(String("\(dataModelFileName).sqlite"))
        let options = autoMigratingOptions()
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch let error as NSError {
            fatalError("Error adding Persistent Store: \(error.localizedDescription)\n\(error.userInfo)")
        }
    }
    
    fileprivate static func addInMemoryStore(_ coordinator: NSPersistentStoreCoordinator) {
        do {
            try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch let error as NSError {
            fatalError("Error adding Persistent Store: \(error.localizedDescription)\n\(error.userInfo)")
        }
    }
    
    fileprivate static func autoMigratingOptions() -> [String : Any] {
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true,
                       NSSQLitePragmasOption: ["journal_mode": "WAL"]] as [String : Any]
        return options
    }
}

extension CoreDataStack: AppStateReactorDelegate {

    fileprivate func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask (expirationHandler: {
            [unowned self] in
            self.endBackgroundTask()
        })
    }

    fileprivate func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask!)
        backgroundTask = UIBackgroundTaskInvalid
    }

    public func didReceiveStateChange(_ appStateReactor: AppStateReactor) -> Void {
        registerBackgroundTask()
        return save({ (error: NSError?) in
            self.endBackgroundTask()
            self.backgroundTask = UIBackgroundTaskInvalid
        })
    }
}

extension CoreDataStack: CoreDataStackProtocol {

    public func save(_ handler: ((NSError?) -> Void)? ) -> Void {
        var mainHasChanges = false
        var privateHasChanges = false
        
        mainContext.performAndWait {
            mainHasChanges = self.mainContext.hasChanges
        }
        
        rootContext.performAndWait {
            privateHasChanges = self.rootContext.hasChanges
        }

        guard mainHasChanges || privateHasChanges else {
            DispatchQueue.main.async(execute: {
                handler?(nil)
            })
            return
        }
        
        mainContext.perform {
            do {
                try self.mainContext.save()
            } catch let error as NSError {
                // fatalError("Failed to save main context: \(error.localizedDescription), \(error.userInfo)")
                DispatchQueue.main.async(execute: {
                    if let handler = handler {
                        handler(error);
                    }
                });
            }
            
            self.rootContext.perform {
                
                do {
                    try self.rootContext.save()
                } catch let error as NSError {
                    // fatalError("Error saving private context: \(error.localizedDescription), \(error.userInfo)")
                    DispatchQueue.main.async(execute: {
                        if let handler = handler {
                            handler(error)
                        }
                    })
                }
                
                DispatchQueue.main.async(execute: {
                    if let handler = handler {
                        handler(nil)
                    }
                })
            }
        }
    }
}
