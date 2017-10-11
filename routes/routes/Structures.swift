//
//  Structures.swift
//  ioKey
//
//  Created by Will Steiner on 2/2/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation

struct Connection {
    let id : Int
    let is_pub : Bool
    var name : String = ""
    var unique : String = ""
    var type : CONNECTION_TYPE
    var details : [String:AnyObject]  = [String:AnyObject]() // depends on connection type
}

struct Floor {
    var name : String
    var height : Double
    var descripton : String
}

struct Coordinate {
    var lat : Double
    var lng : Double
}

struct Structure {
    var foundation : [Coordinate]
    var floors : [Floor]
}

struct Location {
    let id : Int
    let is_pub : Bool
    var name : String
    var address : String
    var description : String
    var connections : [Int] // [connection.id]
    var building : Structure
    var center : Coordinate
}

struct User {
    var car : String? // ID of device
    var username : String
    var email : String = ""
}

struct Device {
    let id : String
    var connection: Int?
    var currentPosition : Coordinate?
    var currentLocation : Int?
    var currentAltitude : Double
}

struct Change {
    let timestamp : String
    let type : CHANGE_TYPE
    let entityType : ENTITY_TYPE
    let entityId : String
    let data : AnyObject
}

struct Event {
    let timestamp : String
    let type : EVENT_TYPE
    let entityType : ENTITY_TYPE
    let entityId : String?
    let data : AnyObject
}
