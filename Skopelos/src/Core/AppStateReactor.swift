//
//  AppStateReactor.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

#if os(iOS)
    
import UIKit

public protocol AppStateReactorDelegate {
    func didReceiveStateChange(appStateReactor: AppStateReactor) -> Void
}

public final class AppStateReactor: NSObject {

    public var delegate: AppStateReactorDelegate?

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
    }

    public override init() {
        super.init()
        initialize()
    }

   private func initialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplicationWillTerminateNotification, object: nil)
    }
    
    @objc func applicationWillResignActive(notification: NSNotification) {
        forwardStatusChange()
    }
    
    @objc func applicationDidEnterBackground(notification: NSNotification) {
        forwardStatusChange()
    }
    
    @objc func applicationWillTerminate(notification: NSNotification) {
        forwardStatusChange()
    }
    
    private func forwardStatusChange() {
        delegate?.didReceiveStateChange(self)
    }
}

#endif
