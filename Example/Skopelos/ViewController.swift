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
    
    let dataStore = SkopelosClient.sqliteStack()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataStore.writeSync({ context in
            let user = User.SK_create(context)
            user.firstname = "John"
            user.lastname = "Doe"
        }).read({ context in
            let users = User.SK_all(context)
            print(users)
        }).writeSync({ context in
            User.SK_removeAll(context)
        }).writeSync({ context in
            let users = User.SK_all(context)
            print(users)
        }, completion: { error in
            if let error = error {
                print(error)
            }
        })
    }
}
