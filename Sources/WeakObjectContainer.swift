//
//  WeakObjectContainer.swift
//  Backdrop
//
//  Created by Oskar Groth on 2024-11-26.
//  Copyright © 2024 Cindori AB. All rights reserved.
//

import Foundation

class WeakObjectContainer<T: AnyObject>: NSObject {
    
    private weak var _object: T?

    public var object: T? {
        return _object
    }
    
    public init(with object: T?) {
        _object = object
    }
    
}
