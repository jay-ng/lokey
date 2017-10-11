//
//  State.swift
//  LoKey
//
//  Created by Will Steiner on 3/2/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation
import UIKit


class State : NSObject {
    
    
    private var instance : Instance?
    
    var user : User
    var connections : [Connection]
    var connectionMap : [Int] // [map of id's to connections]
    var connectionIdentifiers : [String] // [map of unique to connection]
    var activeConnections : [Int] // [id's of active connections in last assesment]
    var locations : [Location]
    var locationMap : [Int]
    
    var devices : [Device]
    var deviceMap : [String]
    
    var log : String
    let documentsDirectory : NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    private var localRandom : [Int]
    
    var carConnected : Bool
    var currentLocation : Int
    
    override init(){
        self.connections = [Connection]()
        self.connectionMap = [Int]()
        self.connectionIdentifiers = [String]()
        self.activeConnections = [Int]()
        self.log = ""
        self.locations = [Location]()
        self.locationMap = [Int]()
        self.localRandom = [Int]()
        self.devices = [Device]()
        self.deviceMap = [String]()
        self.carConnected = false
        self.currentLocation = -1
        self.user = User(
            car : nil,
            username : "",
            email: ""
        )
    }
    
    func linkInstance(instance: Instance){
        self.instance = instance
    }
    
    func getCurrentLocation() -> Location?{
        if(self.currentLocation > -1){
            return self.getLocation(id: self.currentLocation)
        }
        return nil
    }
    
    func setUser(_ user: User){
        self.user = user
    }
    
    func clearLog(){
        self.log.removeAll(keepingCapacity: true)
    }
    
    // Manage Locations
    
    // Create
    func addLocation(_ location: Location){
        self.locationMap.append(location.id)
        self.locations.append(location)
        self.instance?.changes.append(
            Change(
                timestamp: String(CFAbsoluteTimeGetCurrent()),
                type: CHANGE_TYPE.add,
                entityType: ENTITY_TYPE.location,
                entityId: String(location.id),
                data: Fmt.packLocation(location) as AnyObject
            )
        )
    }
    
    // Read
    func getLocation(id: Int) -> Location?{
        if let index : Int = self.locationMap.index(of: id){
            return locations[index]
        }
        return nil
    }
    
    // Update
    func updateLocation(_ id: Int, _ location: Location){
        var newLocation = location
        newLocation.center = getCoordinateCenter(coordinates: newLocation.building.foundation)
        if let index : Int = self.locationMap.index(of: id){
            
            let changes = self.parseLocationDiff(locations[index], newLocation)
            locations[index] = newLocation
            
            self.instance?.changes.append(
                Change(
                    timestamp: String(CFAbsoluteTimeGetCurrent()),
                    type: CHANGE_TYPE.update,
                    entityType: ENTITY_TYPE.location,
                    entityId: String(location.id),
                    data: changes as AnyObject
                )
            )
            
        }
    }
    
    func parseLocationDiff(_ before: Location, _ after : Location) -> [String:AnyObject]{
        
        
        var changes : [String:AnyObject] = [String:AnyObject]()
        
        if(before.name != after.name){
            changes["name"] = after.name as AnyObject?
        }
        
        if(before.address != after.address){
            changes["address"] = after.address as AnyObject?
        }
        
        if(before.description != after.description){
            changes["description"] = after.description as AnyObject?
        }
        
        var connectionChanges = [
            "add" : [Int](),
            "remove" : [Int]()
        ]
        
        for c in before.connections {
            // connection was removed
            if !after.connections.contains(c) {
                connectionChanges["add"]?.append(c)
            }
        }
        
        for c in after.connections {
            // connection was added
            if !before.connections.contains(c){
                connectionChanges["remove"]?.append(c)
            }
        }
        
        if((connectionChanges["add"]?.count)! > 0 || (connectionChanges["remove"]?.count)! > 0){
            changes["connection"] = connectionChanges as AnyObject
        }
        
        if(before.center.lat != after.center.lat || before.center.lng != after.center.lng){
            changes["center"] = ["lat" : after.center.lat, "lng" : after.center.lng] as AnyObject
        }
        
        // Order does matter for foundation & floor.. if any diff, note change to entire struct
        var floorUpdate = false
        if(after.building.floors.count == before.building.floors.count){
            for i in 0..<after.building.floors.count{
                if(
                    (after.building.floors[i].name != before.building.floors[i].name) ||
                        (after.building.floors[i].descripton != before.building.floors[i].descripton) ||
                        (after.building.floors[i].height != before.building.floors[i].height)
                    ){
                    floorUpdate = true
                }
                
            }
        } else {
            floorUpdate = true
        }
        
        if(floorUpdate){
            changes["floorplan"] = Fmt.packFloorplan(after.building.floors) as AnyObject
        }
        
        var foundationUpdate = false
        if(after.building.foundation.count == before.building.foundation.count){
            for i in 0..<after.building.foundation.count{
                if(
                    (after.building.foundation[i].lat != before.building.foundation[i].lat) ||
                        (after.building.foundation[i].lng != before.building.foundation[i].lng)
                    ){
                    foundationUpdate = true
                }
                
            }
        } else {
            foundationUpdate = true
        }
        
        if(foundationUpdate){
            changes["foundation"] = Fmt.packFoundation(after.building.foundation) as AnyObject
        }
        
        return changes
        
    }
    
    func getCoordinateCenter(coordinates : [Coordinate]) -> Coordinate {
        var latSum : Double = 0.0, lngSum : Double = 0.0
        let coordCount : Double = Double(coordinates.count)
        for coordinate in coordinates {
            latSum += coordinate.lat
            lngSum += coordinate.lng
        }
        return Coordinate(lat:(latSum / coordCount), lng: (lngSum / coordCount))
    }
    
    func getCoordinateDelta(coordinates : [Coordinate]) -> Coordinate{
        let mapPadding = 0.0005
        var maxLat : Double = 0
        var minLat : Double = .infinity
        var maxLng : Double = 0
        var minLng : Double = .infinity
        for coordinate in coordinates {
            minLat = min(abs(coordinate.lat), minLat)
            maxLat = max(abs(coordinate.lat), maxLat)
            minLng = min(abs(coordinate.lng), minLng)
            maxLng = max(abs(coordinate.lng), maxLng)
        }
        return Coordinate(lat: ((maxLat - minLat) + mapPadding), lng: ((maxLng - minLng) + mapPadding))
    }
    
    func getDistance(c1: Coordinate, c2: Coordinate) -> Double {
        let lat2 = c2.lat
        let lat1 = c1.lat
        let long2 = c2.lng
        let long1 = c1.lng
        let r = 6371000.0
        let toRads = Double.pi / 180
        let dlat = (lat2 - lat1) * toRads
        let dlong = (long2 - long1) * toRads
        let a = pow(sin(dlat/2.0), 2) + cos(lat1*toRads) * cos(lat2*toRads) * pow(sin(dlong/2.0), 2)
        let c = 2*atan2(sqrt(a), sqrt(1-a))
        let d = r * c
        return d
    }
    
    func getRadius(center: Coordinate, foundations: [Coordinate]) -> Double {
        var max  = 30.0
        for foundation in (foundations) {
            let d = getDistance(c1: center, c2: foundation)
            if (max < d) {
                max = d
            }
        }
        return max+Double(max/100*15)
    }
    
    var center = Coordinate(lat: 0.0, lng: 0.0)
    
    func sortCoordinateClockwise(coordinates: [Coordinate]) -> [Coordinate] {
        center = getCenterPts(a: coordinates)
        let coords = coordinates.sorted(by: getIsLess)
        return coords
    }
    
    func getIsLess(c1: Coordinate, c2: Coordinate) -> Bool {
        //let coords = [c1, c2]
        //let center = getCenterPts(a: coords)
        
        if (c1.lng >= 0 && c2.lng < 0) {
            return true
        } else if (c1.lng == 0 && c2.lng == 0) {
            return (c1.lat > c2.lat)
        }
        
        let det = (c1.lng - center.lng) * (c2.lat - center.lat) - (c2.lng - center.lng) * (c1.lat - center.lat)
        if ( det < 0 ) {
            return true
        } else if ( det > 0 ) {
            return false
        }
        
        let d1 = (c1.lng - center.lng) * (c1.lng - center.lng) + (c1.lat - center.lat) * (c1.lat - center.lat)
        let d2 = (c2.lng - center.lng) * (c2.lng - center.lng) + (c2.lat - center.lat) * (c2.lat - center.lat)
        return d1 > d2
    }
    
    func getCenterPts(a: [Coordinate]) -> Coordinate {
        var coord = Coordinate(lat: 0.0, lng: 0.0)
        for i in a {
            coord.lat += i.lat
            coord.lng += i.lng
        }
        coord.lat = coord.lat / Double(a.count)
        coord.lng = coord.lng / Double(a.count)
        return coord
    }
    
    // Delete
    func removeLocation(_ id: Int){
        if let index : Int = self.locationMap.index(of: id){
            if(!locations[index].is_pub){
                locations.remove(at: index)
                self.instance?.changes.append(
                    Change(
                        timestamp: String(CFAbsoluteTimeGetCurrent()),
                        type: CHANGE_TYPE.remove,
                        entityType: ENTITY_TYPE.location,
                        entityId: String(id),
                        data: [ "active" : false ] as AnyObject
                    )
                )
            } else {
                print("Action blocked... location is public");
            }
        }
    }
    
    // Manage Connections
    
    // Create
    func addConnection(_ connection: Connection){
        self.connectionMap.append(connection.id)
        self.connectionIdentifiers.append(connection.unique)
        self.connections.append(connection)
        self.instance?.changes.append(
            Change(
                timestamp: String(CFAbsoluteTimeGetCurrent()),
                type: CHANGE_TYPE.add,
                entityType: ENTITY_TYPE.connection,
                entityId: String(connection.id),
                data: Fmt.packConnection(connection) as AnyObject
            )
        )
    }
    
    // Read
    func getConnection(_ id: Int) -> Connection?{
        if let index : Int = self.connectionMap.index(of: id){
            return connections[index]
        }
        return nil
    }
    
    func getActiveConnections() -> [Connection]{
        var activeConnections : [Connection] = [Connection]()
        for connectionId in self.activeConnections {
            activeConnections.append(self.getConnection(connectionId)!)
        }
        return activeConnections
    }
    
    // Update
    
    
    // Delete
    func removeConnection(_ id: Int){
        if let index : Int = self.connectionMap.index(of: id){
            if(!connections[index].is_pub){
                connections.remove(at: index)
            } else {
                
            }
        }
        self.instance?.changes.append(
            Change(
                timestamp: String(CFAbsoluteTimeGetCurrent()),
                type: CHANGE_TYPE.remove,
                entityType: ENTITY_TYPE.connection,
                entityId: String(id),
                data: [ "active" : false ] as AnyObject
            )
        )
    }
    
    func generateId() -> Int {
        var rand = Int(arc4random())
        while(self.localRandom.contains(rand)){
            rand = Int(arc4random())
        }
        self.localRandom.append(rand)
        return rand
    }
    
    // Manage User
    
    func getUserImage() -> UIImage? {
        
        let fileManager = FileManager.default
        let imagePath = documentsDirectory.appendingPathComponent("profile.jpg")
        if fileManager.fileExists(atPath: imagePath){
            return UIImage(contentsOfFile: imagePath)
        }
        return  nil
        
    }
    
    func parseUserDiff(_ before: User, _ after : User) -> [String:AnyObject]{
        var changes : [String:AnyObject] = [String:AnyObject]()
        
        if(before.username != after.username){
            changes["username"] = after.username as AnyObject?
            
        }
        
        if(before.car != after.car){
            changes["car"] = after.car as AnyObject?
        }
        
        
        return changes
    }
    
    func getUserCar() -> Device? {
        if let id : String = self.user.car {
            return self.getDevice(id);
        }
        return nil
    }
    
    func updateUser(_ updatedUser: User){
        
        let changes = self.parseUserDiff(self.user, updatedUser)
        self.user = updatedUser
        if(!changes.isEmpty){
            self.instance?.changes.append(
                Change(
                    timestamp: Fmt.getTimestamp(),
                    type: CHANGE_TYPE.update,
                    entityType: ENTITY_TYPE.user,
                    entityId: updatedUser.email,
                    data: changes as AnyObject
                )
            )
        } else {
            print("> no changes to user")
        }
    }
    
    func setUserImage(image: UIImage){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("profile.jpg")
        print(paths)
        let imageData = UIImageJPEGRepresentation(image, 0.8)
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
    }
    
    
    // Device Help[ers
    
    // Create
    func addDevice(_ device: Device){
        print("--- ADD DEVICE ---")
        self.deviceMap.append(device.id)
        self.devices.append(device)
        self.instance?.changes.append(
            Change(
                timestamp: Fmt.getTimestamp(),
                type: CHANGE_TYPE.add,
                entityType: ENTITY_TYPE.device,
                entityId: String(device.id),
                data: Fmt.packDevice(device) as AnyObject
            )
        )
    }
    
    // Read
    func getDevice(_ id: String) -> Device?{
        if let index : Int = self.deviceMap.index(of: id){
            return devices[index]
        }
        return nil
    }
    
    // Update
    func updateDevice(_ id: String, _ device: Device){
        if let index : Int = self.deviceMap.index(of: id) {
            let changes = self.parseDeviceDiff(devices[index], device)
            devices[index] = device
            // Only push change if they exist
            if changes.count > 0 {
                self.instance?.changes.append(
                    Change(
                        timestamp: Fmt.getTimestamp(),
                        type: CHANGE_TYPE.update,
                        entityType: ENTITY_TYPE.device,
                        entityId: String(device.id),
                        data: changes as AnyObject
                    )
                )
            }
        }
    }
    
    func parseDeviceDiff(_ before: Device, _ after : Device) -> [String:AnyObject]{
        var changes : [String:AnyObject] = [String:AnyObject]()
        
        if(before.connection != after.connection){
            changes["connection"] = after.connection as AnyObject?
        }
        
        if( before.currentAltitude != after.currentAltitude){
            changes["currentAltitude"] = after.currentAltitude as AnyObject?
        }
        
        if( before.currentLocation != after.currentLocation){
            changes["currentLocation"] = after.currentLocation as AnyObject?
        }
        
        if(before.currentPosition == nil && after.currentPosition != nil){
            changes["currentPosition"] = Fmt.packCoordinate(after.currentPosition!) as AnyObject?
        }
        else if (before.currentPosition != nil && after.currentPosition != nil){
            // Only adjust posiiton if moved more than a resonable location diffrence... > 11m
            
            let precision : Double = 10000
            
            let bLat = round((before.currentPosition?.lat)! * precision) / precision
            let aLat = round((after.currentPosition?.lat)! * precision) / precision
            
            let bLng = round((before.currentPosition?.lng)! * precision) / precision
            let aLng = round((after.currentPosition?.lng)! * precision) / precision
            
            if( bLat != aLat || bLng != aLng){
                changes["currentPosition"] = Fmt.packCoordinate(after.currentPosition!) as AnyObject?
            }
        }
        
        return changes
    }
}
