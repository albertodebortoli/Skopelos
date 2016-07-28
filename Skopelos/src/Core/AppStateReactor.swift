//
//  AppStateReactor.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation
import UIKit

protocol AppStateReactorDelegate {
    func didReceiveStateChange(appStateReactor: AppStateReactor) -> Void
}

class AppStateReactor: NSObject {
    
    var delegate: AppStateReactorDelegate?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
    }
    
    override init() {
        super.init()
        initialize()
    }
    
    func initialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplicationWillTerminateNotification, object: nil)
    }
    
    func applicationWillResignActive() {
        forwardStatusChange()
    }
    
    func applicationDidEnterBackground() {
        forwardStatusChange()
    }
    
    func applicationWillTerminate() {
        forwardStatusChange()
    }
    
    func forwardStatusChange() {
        if let delegate = delegate {
            delegate.didReceiveStateChange(self)
        }
    }
    
}
