//
//  PlatformLoadDelegate.swift
//  LoKey
//
//  Created by Will Steiner on 3/10/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation

@objc protocol PlatformLoadDelegate {
    
    func anonLogin(success : Bool)
    func stateLoad(success: Bool)
    func newState(_ newState : [String:AnyObject])
}
