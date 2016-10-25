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
    case SQLite
    case InMemory
}

public final class CoreDataStack: NSObject {
    
    public var mainContext: NSManagedObjectContext
    public var rootContext: NSManagedObjectContext
    private let appStateReactor: AppStateReactor
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    var dataModelFileName: String!
    var securityApplicationGroupIdentifier: String?
    var storeType: StoreType
    
    public convenience init(storeType: StoreType, dataModelFileName: String, securityApplicationGroupIdentifier: String?) {
        self.init(storeType: storeType, dataModelFileName: dataModelFileName, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier, handler: nil)
    }
    
    public init(storeType: StoreType, dataModelFileName: String, securityApplicationGroupIdentifier: String?, handler:(Void -> Void)?) {
        self.dataModelFileName = dataModelFileName
        self.securityApplicationGroupIdentifier = securityApplicationGroupIdentifier
        self.storeType = storeType
        appStateReactor = AppStateReactor()
        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        rootContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        super.init()
        appStateReactor.delegate = self
        self.initialize(storeType, dataModelFileName: dataModelFileName, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier, callback: handler)
    }
    
    func initialize(storeType: StoreType, dataModelFileName: String, securityApplicationGroupIdentifier: String?, callback:(Void -> Void)?) {
        let modelURL = NSBundle.mainBundle().URLForResource(dataModelFileName, withExtension: "momd")
        let mom = NSManagedObjectModel(contentsOfURL: modelURL!)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        rootContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        rootContext.persistentStoreCoordinator = coordinator
        mainContext.parentContext = rootContext
    
        let privateContextSetupBlock = {
            let psc = self.rootContext.persistentStoreCoordinator!
            
            switch storeType {
            case .SQLite:
                CoreDataStack.addSQLiteStore(psc, dataModelFileName:dataModelFileName, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
            case .InMemory:
                CoreDataStack.addInMemoryStore(psc)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                callback?()
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

    private static func addSQLiteStore(coordinator: NSPersistentStoreCoordinator, dataModelFileName: String, securityApplicationGroupIdentifier: String?) {

        // if securityApplicationGroupIdentifier then -> shared Location i.e. storeURL = blah blah
        // else, nope
        
        let storeURL: NSURL? = persistentStoreURL(dataModelFileName, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
        
        let options = autoMigratingOptions()
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
        } catch let error as NSError {
            fatalError("Error adding Persistent Store: \(error.localizedDescription)\n\(error.userInfo)")
        }
    }
    
    private static func addInMemoryStore(coordinator: NSPersistentStoreCoordinator) {
        do {
            try coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        } catch let error as NSError {
            fatalError("Error adding Persistent Store: \(error.localizedDescription)\n\(error.userInfo)")
        }
    }
    
    private static func autoMigratingOptions() -> [NSObject: AnyObject] {
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true,
                       NSSQLitePragmasOption: ["journal_mode": "WAL"]]
        return options
    }
    
    private static func persistentStoreURL(dataModelFileName: String, securityApplicationGroupIdentifier: String?) -> NSURL? {
        
        let fileManager = NSFileManager.defaultManager()
        var storeURL: NSURL?
        
        if let securityApplicationGroupIdentifier = securityApplicationGroupIdentifier {
            let directory = fileManager.containerURLForSecurityApplicationGroupIdentifier(securityApplicationGroupIdentifier)
            storeURL = directory?.URLByAppendingPathComponent(String("\(dataModelFileName).sqlite"))
        }
        else {
            let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last
            storeURL = documentsURL?.URLByAppendingPathComponent(String("\(dataModelFileName).sqlite"))
        }
        
        return storeURL
    }
    
    private static func storeExtensions() -> [String] {
        return ["sqlite", "sqlite-shm", "sqlite-wal"]
    }
}

extension CoreDataStack: AppStateReactorDelegate {

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

    public func didReceiveStateChange(appStateReactor: AppStateReactor) -> Void {
        registerBackgroundTask()
        return save({ (error: NSError?) in
            self.endBackgroundTask()
            self.backgroundTask = UIBackgroundTaskInvalid
        })
    }
}

extension CoreDataStack: CoreDataStackProtocol {

    public func save(handler: (NSError? -> Void)? ) -> Void {
        var mainHasChanges = false
        var privateHasChanges = false
        
        mainContext.performBlockAndWait {
            mainHasChanges = self.mainContext.hasChanges
        }
        
        rootContext.performBlockAndWait {
            privateHasChanges = self.rootContext.hasChanges
        }

        guard mainHasChanges || privateHasChanges else {
            dispatch_async(dispatch_get_main_queue(), {
                handler?(nil)
            })
            return
        }
        
        mainContext.performBlock {
            do {
                try self.mainContext.save()
            } catch let error as NSError {
                // fatalError("Failed to save main context: \(error.localizedDescription), \(error.userInfo)")
                dispatch_async(dispatch_get_main_queue(), {
                    if let handler = handler {
                        handler(error);
                    }
                });
            }
            
            self.rootContext.performBlock {
                
                do {
                    try self.rootContext.save()
                } catch let error as NSError {
                    // fatalError("Error saving private context: \(error.localizedDescription), \(error.userInfo)")
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
    
    public func nukeStore() {        
        let storeURL: NSURL? = CoreDataStack.persistentStoreURL(self.dataModelFileName, securityApplicationGroupIdentifier: self.securityApplicationGroupIdentifier)
        let pathToStore = storeURL?.URLByDeletingPathExtension;
        
        let fileManager = NSFileManager.defaultManager()
        
        for storeExtension in CoreDataStack.storeExtensions() {
            if let filePath = pathToStore?.URLByAppendingPathExtension(storeExtension)?.path {
                if (fileManager.fileExistsAtPath(filePath)) {
                    do {
                        try fileManager.removeItemAtPath(filePath)
                    } catch let error as NSError {
                        fatalError("Error removing file at path '\(filePath)': \(error.localizedDescription)\n\(error.userInfo)")
                    }
                }
            }
        }
        
        initialize(storeType, dataModelFileName: dataModelFileName, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier, callback: nil)
    }
}
