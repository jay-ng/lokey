//
//  Constants.swift
//  ioKey
//
//  Created by Will Steiner on 2/2/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation

enum LOG_LEVEL {
    case error
    case warn
    case debug
    case status
    case log
}

enum CONNECTION_TYPE {
    case audio
    case wifi
    case unknown
    //case bt
    //case ble
}

enum USER_ACTIVITY {
    case walking
    case driving
    case stationary
    case unknown
    //case bt
    //case ble
}

enum CHANGE_TYPE {
    case update
    case add
    case remove
    
    var string : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .update: return "update"
        case .add: return "add"
        case .remove: return "remove"
        }
    }
}

enum EVENT_TYPE {
    case significant
    case status
    case request
    var string : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .significant: return "significant"
        case .status: return "status"
        case .request: return "request"
        }
    }
}

enum ENTITY_TYPE {
    case user
    case device
    case location
    case connection
    case system
    
    var string : String {
        switch self {
            // Use Internationalization, as appropriate.
            case .user: return "user"
            case .device: return "device"
            case .location: return "location"
            case .connection: return "connection"
            case .system: return "system"
        }
    }
}
