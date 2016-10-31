//
//  ViewController.swift
//  Skopelos
//
//  Created by Alberto De Bortoli on 28/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import UIKit
import CoreData

final class ViewController: UIViewController {
    
    /*
    override func viewDidLoad() {
        super.viewDidLoad()

        let sem = DispatchSemaphore(value: 0)

        while (true) {
            let _ = sem.wait(timeout: DispatchTime.now())
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))

            let dataStore = SkopelosClient.shared
            let _ = dataStore.writeSync({ context in
                let user = User.SK_create(context)
                user.firstname = "John"
                user.lastname = "Doe"
            }).writeSync({ context in
                User.SK_removeAll(context)
            }).writeSync({ context in
                let _ = User.SK_all(context)
                }, completion: { (error: NSError?) in
                    sem.signal()
            })
        }
    }
    */
    
}

