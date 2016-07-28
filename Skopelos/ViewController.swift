//
//  ViewController.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sem = dispatch_semaphore_create(0)
        
        while (true) {
            dispatch_semaphore_wait(sem, DISPATCH_TIME_NOW)
            NSRunLoop.currentRunLoop().runUntilDate(NSDate.init(timeIntervalSinceNow: 0.2))
            
            SkopelosClient.sharedInstance.write({ (context: NSManagedObjectContext) in
                let user = User.SK_create(context) as! User
                user.firstname = "John"
                user.lastname = "Doe"
            }).write({ (context: NSManagedObjectContext) in
                User.SK_removeAll(context)
            }).write({ (context: NSManagedObjectContext) in
                User.SK_all(context)
                }, completion: { (error: NSError?) in
                    dispatch_semaphore_signal(sem)
            })
        }
    }
    
}

