//
//  NSObject+Introspection.swift
//  Skopelos
//
//  Created by Alberto DeBortoli on 31/07/2016.
//  Copyright © 2016 Alberto De Bortoli. All rights reserved.
//

import Foundation

public extension NSObject {
    
    class var nameOfClass: String{
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
    
    var nameOfClass: String {
        return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
    }
}

