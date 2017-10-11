//
//  ConnectionSelectorDelegate.swift
//  LoKey
//
//  Created by Will Steiner on 1/31/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation

@objc protocol ConnectionSelectedDelegate {
    func selectConnection(connectionId: Int)
}
