//
//  DeviceTrackingDelegate.swift
//  routes
//
//  Created by Will Steiner on 4/10/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation

@objc protocol DeviceTrackingDelegate {
    func carPositionUpdated(updatedPosition: Any)
    func userPositionUpdated(updatedPosition: Any)
}
