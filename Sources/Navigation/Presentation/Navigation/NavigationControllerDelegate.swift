//
//  NavigationControllerDelegate.swift
//  SenseiUI
//
//  Created by Oskar Groth on 2019-08-30.
//  Copyright © 2019 Oskar Groth. All rights reserved.
//

import AppKit

protocol NavigationControllerDelegate: AnyObject {
	func navigationController(_ navigationController: NavigationController, willShowViewController viewController: NSViewController, animated: Bool)
	func navigationController(_ navigationController: NavigationController, didShowViewController viewController: NSViewController, animated: Bool)
}

extension NavigationControllerDelegate {
    
    func navigationController(_ navigationController: NavigationController, willShowViewController viewController: NSViewController, animated: Bool) {
        
    }
    
    func navigationController(_ navigationController: NavigationController, didShowViewController viewController: NSViewController, animated: Bool) {
        
    }
    
}
