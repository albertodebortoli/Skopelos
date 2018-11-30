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
    func didReceiveStateChange(_ appStateReactor: AppStateReactor) -> Void
}

public final class AppStateReactor: NSObject {

    public var delegate: AppStateReactorDelegate?

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }

    public override init() {
        super.init()
        initialize()
    }

   fileprivate func initialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        forwardStatusChange()
    }
    
    @objc func applicationDidEnterBackground(_ notification: Notification) {
        forwardStatusChange()
    }
    
    @objc func applicationWillTerminate(_ notification: Notification) {
        forwardStatusChange()
    }
    
    fileprivate func forwardStatusChange() {
        delegate?.didReceiveStateChange(self)
    }
}

#endif
