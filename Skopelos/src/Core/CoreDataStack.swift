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
    case sqlite
    case inMemory
}

public final class CoreDataStack: NSObject {
    
    public var mainContext: NSManagedObjectContext
    public var rootContext: NSManagedObjectContext
    #if os(iOS)
    fileprivate let appStateReactor: AppStateReactor
    var backgroundTask: UIBackgroundTaskIdentifier?
    #endif
    var modelURL: URL
    var securityApplicationGroupIdentifier: String?
    var storeType: StoreType
    
    public convenience init(storeType: StoreType, modelURL: URL, securityApplicationGroupIdentifier: String?) {
        self.init(storeType: storeType, modelURL: modelURL, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier, handler: nil)
    }
    
    public init(storeType: StoreType, modelURL: URL, securityApplicationGroupIdentifier: String?, handler:((Void) -> Void)?) {
        self.modelURL = modelURL
        self.securityApplicationGroupIdentifier = securityApplicationGroupIdentifier
        self.storeType = storeType
        #if os(iOS)
        appStateReactor = AppStateReactor()
        #endif
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        rootContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        super.init()
        #if os(iOS)
        appStateReactor.delegate = self
        #endif
        self.initialize(storeType, modelURL: modelURL, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier, callback: handler)
    }
    
    func initialize(_ storeType: StoreType, modelURL: URL, securityApplicationGroupIdentifier: String?, callback:((Void) -> Void)?) {
        let mom = NSManagedObjectModel(contentsOf: modelURL)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        rootContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        rootContext.persistentStoreCoordinator = coordinator
        mainContext.parent = rootContext
    
        let privateContextSetupBlock = {
            let psc = self.rootContext.persistentStoreCoordinator!
            
            switch storeType {
            case .sqlite:
                let dataModelFileName = modelURL.deletingPathExtension().lastPathComponent
                if !dataModelFileName.isEmpty {
                    CoreDataStack.addSQLiteStore(coordinator: psc, dataModelFileName: dataModelFileName, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
                }
            case .inMemory:
                CoreDataStack.addInMemoryStore(coordinator: psc)
            }
            
            DispatchQueue.main.async {
                callback?()
            }
        }
        
        if callback != nil {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
                privateContextSetupBlock()
            })
        } else {
            privateContextSetupBlock()
        }
    }

    private static func addSQLiteStore(coordinator: NSPersistentStoreCoordinator, dataModelFileName: String, securityApplicationGroupIdentifier: String?) {

        let storeURL: URL? = persistentStoreURL(dataModelFileName: dataModelFileName, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
        
        let options = autoMigratingOptions()
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch let error as NSError {
            fatalError("Error adding Persistent Store: \(error.localizedDescription)\n\(error.userInfo)")
        }
    }
    
    private static func addInMemoryStore(coordinator: NSPersistentStoreCoordinator) {
        do {
            try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch let error as NSError {
            fatalError("Error adding Persistent Store: \(error.localizedDescription)\n\(error.userInfo)")
        }
    }
    
    private static func autoMigratingOptions() -> [String : Any] {
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true,
                       NSSQLitePragmasOption: ["journal_mode": "WAL"]] as [String : Any]
        return options
    }
    
    fileprivate static func persistentStoreURL(dataModelFileName: String, securityApplicationGroupIdentifier: String?) -> URL? {
        
        let fileManager = FileManager.default
        var storeURL: URL?
        
        if let securityApplicationGroupIdentifier = securityApplicationGroupIdentifier {
            let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
            storeURL = directory?.appendingPathComponent(String("\(dataModelFileName).sqlite"))
        }
        else {
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last
            storeURL = documentsURL?.appendingPathComponent(String("\(dataModelFileName).sqlite"))
        }
        
        return storeURL
    }
    
    fileprivate static func storeExtensions() -> [String] {
        return ["sqlite", "sqlite-shm", "sqlite-wal"]
    }
}

#if os(iOS)
extension CoreDataStack: AppStateReactorDelegate {

    fileprivate func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            [unowned self] in
            self.endBackgroundTask()
        }
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
#endif

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
            DispatchQueue.main.async {
                handler?(nil)
            }
            return
        }
        
        mainContext.perform {
            do {
                try self.mainContext.save()
            } catch let error as NSError {
                // fatalError("Failed to save main context: \(error.localizedDescription), \(error.userInfo)")
                DispatchQueue.main.async {
                    if let handler = handler {
                        handler(error)
                    }
                }
            }
            
            self.rootContext.perform {
                
                do {
                    try self.rootContext.save()
                } catch let error as NSError {
                    // fatalError("Error saving private context: \(error.localizedDescription), \(error.userInfo)")
                    DispatchQueue.main.async {
                        if let handler = handler {
                            handler(error)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    if let handler = handler {
                        handler(nil)
                    }
                }
            }
        }
    }
    
    public func nukeStore() {
        let dataModelFileName = modelURL.deletingPathExtension().lastPathComponent
        guard !dataModelFileName.isEmpty else { return }
        
        let storeURL: URL? = CoreDataStack.persistentStoreURL(dataModelFileName: dataModelFileName, securityApplicationGroupIdentifier: self.securityApplicationGroupIdentifier)
        let pathToStore = storeURL?.deletingPathExtension;
        
        let fileManager = FileManager.default
        
        for storeExtension in CoreDataStack.storeExtensions() {
            if let filePath = pathToStore?().appendingPathExtension(storeExtension).path {
                if (fileManager.fileExists(atPath: filePath)) {
                    do {
                        try fileManager.removeItem(atPath: filePath)
                    } catch let error as NSError {
                        fatalError("Error removing file at path '\(filePath)': \(error.localizedDescription)\n\(error.userInfo)")
                    }
                }
            }
        }
        
        initialize(storeType, modelURL: modelURL, securityApplicationGroupIdentifier: securityApplicationGroupIdentifier, callback: nil)
    }
}
