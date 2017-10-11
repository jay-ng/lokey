//
//  Fmt.swift
//  LoKey
//
//  Created by Will Steiner on 3/2/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation

class Fmt {
    
    
    static let null = NSNull()
    
    // ---- Packing Helpers : Struct -> JSON
    static func packCoordinate(_ coordinate : Coordinate) -> [String:AnyObject]{
        return [
            "lat" : coordinate.lat as AnyObject,
            "lng" : coordinate.lng as AnyObject
        ]
    }
    
    static func packFloor(_ floor : Floor) -> [String:AnyObject]{
        return [
            "name" : floor.name as AnyObject,
            "description" : floor.descripton as AnyObject,
            "height" : floor.height as AnyObject
        ]
    }
    
    static func packFloorplan(_ floorplan : [Floor]) -> [String:AnyObject]{
        var structureFloors : [String:AnyObject] = [String:AnyObject]()
        // pack floors
        for i in 0..<floorplan.count {
            structureFloors[String(i)] = self.packFloor(floorplan[i]) as AnyObject
        }
        return structureFloors
    }
    
    static func packFoundation(_ foundation : [Coordinate]) -> [String:AnyObject]{
        var structureFoundation : [String:AnyObject] = [String:AnyObject]()
        for i in 0..<foundation.count {
            structureFoundation[String(i)] = self.packCoordinate(foundation[i]) as AnyObject
        }
        return structureFoundation
    }
    
    static func packStructure(_ structure : Structure) -> [String:AnyObject]{
        return [
            "floors" : packFloorplan(structure.floors) as AnyObject,
            "foundation" : packFoundation(structure.foundation) as AnyObject
        ]
    }
    
    static func packLocation(_ location : Location) -> [String:AnyObject]{
        
        return [
            "id" : location.id as AnyObject,
            "is_pub" : location.is_pub as AnyObject,
            "name" : location.name as AnyObject,
            "description" : location.description as AnyObject,
            "building" : self.packStructure(location.building) as AnyObject,
            "connections" : location.connections as AnyObject,
            "center" : self.packCoordinate(location.center) as AnyObject,
            "address" : location.address as AnyObject
        ]
    }
    
    static func packConnectionType(_ connection_type:CONNECTION_TYPE) -> String {
        switch(connection_type){
        case .audio:
            return "audio"
        case .wifi:
            return "wifi"
        case .unknown:
            return "unknown"
        }
    }
    
    static func packConnection(_ connection: Connection) -> [String:AnyObject]{
        return [
            "id" : connection.id as AnyObject,
            "is_pub" : connection.is_pub as AnyObject,
            "name" : connection.name as AnyObject,
            "unique" : connection.unique as AnyObject,
            "type" : self.packConnectionType(connection.type) as AnyObject,
            "details": connection.details as AnyObject
        ]
    }
    
    static func packDevice(_ device: Device) -> [String:AnyObject] {
        
        var packedDevice = [
            "id" : device.id as AnyObject,
            "currentAltitude" : device.currentAltitude as AnyObject
        ]
        if let c : Int = device.connection{
            packedDevice["connection"] = c as AnyObject
        }
        if let pos : Coordinate = device.currentPosition{
            packedDevice["position"] = self.packCoordinate(pos) as AnyObject?
        }
        
        if let loc : Int = device.currentLocation{
            packedDevice["currentLocation"] = loc as AnyObject?
        }
        return packedDevice
    }
    
    static func packUser(_ user: User) -> [String:AnyObject]{
        
        var car = "";
        
        if let c : String = user.car {
            car = c
        }
        
        let packedUser : [String:AnyObject] = [
            "username" : user.username as AnyObject,
            "email" : user.email as AnyObject,
            "car" : car as AnyObject
        ]
        
        return packedUser;
    }
    
    // ---- END Packing Helpers
    
    
    static func packChanges(_ changes : [Change]) -> [AnyObject]{
        
        var packedChanges : [AnyObject] = [AnyObject]()
        
        for change : Change in changes {
            packedChanges.append([
                "timestamp"  : change.timestamp as AnyObject,
                "type"       : change.type.string as AnyObject,
                "id"         : change.entityId as AnyObject,
                "entityType" : change.entityType.string as AnyObject,
                "data"       : change.data as AnyObject
                ] as AnyObject)
            
        }
        
        //let isValid = JSONSerialization.isValidJSONObject(["changes" : packedChanges])
        
        
        
        return packedChanges
    }
    
    static func packEvents(_ events : [Event]) -> [AnyObject]{
        
        var packedEvents : [AnyObject] = [AnyObject]()
        
        for event : Event in events {
            packedEvents.append([
                "timestamp"  : event.timestamp as AnyObject,
                "type"       : event.type.string as AnyObject,
                "id"         : event.entityId as AnyObject,
                "entityType" : event.entityType.string as AnyObject,
                "data"       : event.data as AnyObject
                ] as AnyObject)
            
        }
        
        //let isValid = JSONSerialization.isValidJSONObject(["changes" : packedEvents])
        
        
        
        return packedEvents
    }
    
    static func getTimestamp() -> String {
        return "\(NSDate().timeIntervalSince1970 * 1000)"
    }

    
    
    // ---- Unpacking Helpers : JSON -> Struct
    static func unpackConnectionType(_ connection_type: String) -> CONNECTION_TYPE {
        switch(connection_type){
        case "audio": return CONNECTION_TYPE.audio
        case "wifi":return CONNECTION_TYPE.wifi
        case "unknown": return CONNECTION_TYPE.unknown
        default: return CONNECTION_TYPE.unknown
        }
        
    }
    
    static func unpackDevice(_ packedDevice : [String:AnyObject]) -> Device {
        let id : String = packedDevice["id"] as! String
        var connection: Int?
        var currentPosition : Coordinate?
        var currentLocation : Int?
        var currentAltitude : Double = 0
        
        
        if let conId : Int = packedDevice["connection"] as? Int{
            connection = conId
        }
        
        
        
        if let pos : AnyObject = packedDevice["currentPosition"]{
            if(!self.null.isEqual(pos)){
                currentPosition = self.unpackCoordinate(pos)
            }
        }
        
        
        if(!self.null.isEqual(packedDevice["location"])){
            if let loc : Int = packedDevice["location"] as? Int{
                currentLocation = loc
            }
        }
        
        if let alt : Double = packedDevice["currentAltitude"] as? Double{
            currentAltitude = alt
        }
        
        return Device(
            id: id,
            connection: connection,
            currentPosition: currentPosition,
            currentLocation : currentLocation,
            currentAltitude : currentAltitude
        )
    }
    
    static func unpackUser(_ user: [String:AnyObject]) -> User{
        
        var username : String = ""
        
        if let uname : String = user["username"] as? String{
            username = uname
        }
        
        return User(
            car: user["car"] as? String,
            username : username,
            email: user["creds"]!["email"] as! String
        )
    }
    
    static func unpackConnection(_ packedConnection : AnyObject) -> Connection{
        return Connection(
            id: packedConnection["id"] as! Int,
            is_pub: packedConnection["is_pub"] as! Bool,
            name: packedConnection["name"] as! String,
            unique: packedConnection["unique"] as! String,
            type: self.unpackConnectionType(packedConnection["type"] as! String),
            details: packedConnection["details"] as! [String:AnyObject]
        )
    }
    
    static func unpackCoordinate(_ packedCoordinate : AnyObject) -> Coordinate{
        
        return Coordinate(
            lat: packedCoordinate["lat"] as! Double,
            lng: packedCoordinate["lng"] as! Double
        )
    }
    
    static func unpackFloor(_ packedFloor : AnyObject) -> Floor{
        return Floor(
            name: packedFloor["name"] as! String,
            height: packedFloor["height"] as! Double,
            descripton: packedFloor["description"] as! String
        )
    }
    
    static func unpackStructure(_ packedStructure : AnyObject) -> Structure{
        
        var structureFloors : [Floor] = [Floor]()
        var structureFoundation : [Coordinate] = [Coordinate]()
        
        for (_,coord) in packedStructure["foundation"] as! [String:AnyObject]{
            structureFoundation.append(self.unpackCoordinate(coord))
        }
        
        for (_,floor) in packedStructure["floors"] as! [String:AnyObject]{
            structureFloors.append(self.unpackFloor(floor))
        }
        
        return Structure(
            foundation: structureFoundation,
            floors: structureFloors
        )
    }
    
    static func unpackLocation(_ packedLocation : AnyObject) -> Location{
        return Location(
            id: packedLocation["id"] as! Int,
            is_pub: packedLocation["is_pub"] as! Bool,
            name: packedLocation["name"] as! String,
            address: packedLocation["address"] as! String,
            description: packedLocation["description"] as! String,
            connections: packedLocation["connections"] as! [Int],
            building: self.unpackStructure(packedLocation["building"] as AnyObject),
            center: self.unpackCoordinate(packedLocation["center"] as AnyObject)
        )
    }
    
    
    
    
    
    
}
