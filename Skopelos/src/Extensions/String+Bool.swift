//
//  String+Bool.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 01/08/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

extension String {
    public var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}
