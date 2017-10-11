//
//  Instance.swift
//  ioKey
//
//  Created by Will Steiner on 2/2/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreMotion // Movement analysis
import AVFoundation // Audio connections
import SystemConfiguration.CaptiveNetwork // Wifi connections

class Instance : NSObject, CLLocationManagerDelegate {
    
    
    private var assesmentCount : Int = 0
    private var assesmentLoopRunning : Bool = false // Lock.. only one timer
    
    
    private var thisDevice : Device
    private var state : State
    private let localStorage = UserDefaults.standard
    private var runlog : [String]
    private var assesmentTimer : Timer?
    private var digestRate : Int
    
    var locationManager : CLLocationManager
    private var monitoredRegions : [CLCircularRegion]
    
    
    private var platform : Platform
    private var altimeterManager : CMAltimeter
    private var activityManager = CMMotionActivityManager()
    private var userActivity : USER_ACTIVITY
    private var currentAltitude : Double
    
    var changes : [Change]
    var events : [Event]
    
    var isRunningInBackground : Bool = false
    
    var isvalid : Bool
    
    private var fencingTimer = Timer()
    private var gettingFloor = false
    private var inFenc = false
    private var carCurrentFloor: Int
    private var locationCarPositionLog = [Coordinate]()
    private var positionLogSampleTimer = Timer()
    private var positionSampleCollectionRunning: Bool = false;
    private var quadInformationPresented: Bool = false;
    private var headerString: String = "N/A"
    
    
    var trackingDelegate : DeviceTrackingDelegate?
    
    
    private var ignoreConnections : [String] = ["Speaker", "Wired Headphones"] // iPhone defaults
    
    init(_ platform: Platform){
        
        self.platform = platform
        self.runlog = [String]()
        self.digestRate = 1
        self.state = State()
        self.locationManager = CLLocationManager()
        self.monitoredRegions = [CLCircularRegion]()
        self.thisDevice = Device(id: UIDevice.current.identifierForVendor!.uuidString, connection: nil, currentPosition: nil, currentLocation: nil, currentAltitude: 0)
        self.currentAltitude = 0.0
        self.carCurrentFloor = 0
        self.altimeterManager = CMAltimeter()
        self.userActivity = USER_ACTIVITY.unknown
        
        self.changes = [Change]()
        self.events = [Event]()
        self.isvalid = false // Will be set after platform loads succeed
        
    }
    
    public func run(){
        
        self.state.linkInstance(instance: self)
        
        //self.clearLocalData() // Development... use seed info every launch
        
        self.removeMonitoring() // Development, Remove all monitoredRegions
        
        //----- Prepare state ------
        // Fetch instance state
        /*
         if(stateExists()){
         log("local state exists")
         self.loadState()
         } else {
         log("no local state")
         // TODO: try pull from cloud
         // If no cloud state, new user. (use seed state)
         log("new user. seed state, then save")
         self.generateSeedData()
         saveState()
         }*/
        //dumpLog()
        
        //----- Location related init ------
        self.locationManager.delegate = self
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = true // ? override
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedAlways) {
            self.locationManager.requestAlwaysAuthorization()
        }
        // TODO: Check that user has given loction. Mandatory
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 2.0 // Only get location update after 2m difference
        //self.locationManager.activityType = .automotiveNavigation // ?
        // Setup initial regions and begin monitoring
        
        for location in self.state.locations {
            self.trackLocation(location)
        }
        
        self.positionEval();
        
        // TODO: Need to verify activity permission.
        if(CMMotionActivityManager.isActivityAvailable()){
            self.activityManager = CMMotionActivityManager()
        }
        self.startAssesmentLoop()
        
    } // -------------- END run() -------------
    
    func startAssesmentLoop(){
        
        if(self.assesmentLoopRunning){
            return;
        }
        
        if(!self.isvalid){
            print("Instance not valid... supress loop");
        } else {
            self.assesmentLoop()
            self.assesmentLoopRunning = true
            self.assesmentTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.assesmentLoop), userInfo: nil, repeats: true)
            return
        }
        // If assesment loop could not be started.. try again in a bit
        self.assesmentTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.startAssesmentLoop), userInfo: nil, repeats: false)
        
    }
    
    var isSignificant = false // Flag for interrupting periodic sync
    @objc private func assesmentLoop(){
        self.assesmentCount += 1
        //isSignificant = false
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = DateFormatter.Style.short
        dateformatter.timeStyle = DateFormatter.Style.medium
        let now = dateformatter.string(from: NSDate() as Date)
        
        
        log("- assesment loop: \(now)       -- \(self.assesmentCount) -- \(String(time(nil)))", LOG_LEVEL.log)
        
        // ------ sync with connections -------
        self.state.activeConnections.removeAll(keepingCapacity: true) // Clear active, will repopulate
        // Audio Connections
        for connection in AVAudioSession.sharedInstance().currentRoute.outputs{
            if(ignoreConnections.contains(connection.uid)){
                continue
            }
            if let activeIndex : Int = self.state.connectionIdentifiers.index(of: connection.uid){
                // Recognized connection was discovered
                self.state.activeConnections.append(self.state.connectionMap[activeIndex])
                // TODO: Revist this.. should trigger a state update id connection drops or recognized connects
                log("active audio connection -> \(self.state.getConnection(self.state.connectionMap[activeIndex])?.name)", LOG_LEVEL.log)
            } else {
                log("new audio connection: \(connection.portName)", LOG_LEVEL.log)
                let newConnection = Connection(
                    id: self.state.generateId(),
                    is_pub: false,
                    name: connection.portName,
                    unique: connection.uid,
                    type: CONNECTION_TYPE.audio,
                    details: [String:AnyObject]()
                )
                self.state.addConnection(newConnection)
                self.state.activeConnections.append(newConnection.id)
            }
        }
        // Wifi Connections
        if let unwrappedCFArrayInterfaces : NSArray = CNCopySupportedInterfaces(){
            if let wifiConnections = unwrappedCFArrayInterfaces as? [String]{
                for interface in wifiConnections {
                    if let unwrappedInterface : NSDictionary = CNCopyCurrentNetworkInfo(interface as CFString){
                        if let connection = unwrappedInterface as? [String : AnyObject] {
                            if let activeIndex : Int = self.state.connectionIdentifiers.index(of: connection["SSID"] as! String){
                                self.state.activeConnections.append(self.state.connectionMap[activeIndex])
                                log("active wifi connection -> \(self.state.getConnection(self.state.connectionMap[activeIndex])?.name)", LOG_LEVEL.log)
                            } else {
                                // New wifi connection
                                let newConnection = Connection(
                                    id: self.state.generateId(),
                                    is_pub: false,
                                    name: connection["SSID"] as! String,
                                    unique: connection["SSID"] as! String,
                                    type: CONNECTION_TYPE.wifi,
                                    details: [
                                        "ssid"     : connection["SSID"] as AnyObject,
                                        "bssid"    : connection["BSSID"] as AnyObject
                                    ]
                                )
                                self.state.addConnection(newConnection)
                                self.state.activeConnections.append(newConnection.id)
                                log("new wifi connection: \(newConnection.name)", LOG_LEVEL.log)
                            }
                        }
                    }
                }
            }
        }
        // ------ END sync with connections -------
        
        //if isSignificant {
        self.determineLocation()
        //}
        
        // If user has car, and an active linked connection. Attempt to update that device location with current position.
        if let userDeviceId : String = self.state.user.car {
            if let userDevice : Device = self.state.getDevice(userDeviceId){
                var carUpdate = false
                var car = userDevice
                
                
                if let deviceConnectionId : Int = userDevice.connection{
                    if self.state.activeConnections.contains(deviceConnectionId){
                        
                        if(!self.state.carConnected){
                            // Car has connected
                            log("!> car recently connected", LOG_LEVEL.log)
                            // Begin significant monitoring
                            self.events.append(Event(
                                timestamp: Fmt.getTimestamp(),
                                type: EVENT_TYPE.significant,
                                entityType: ENTITY_TYPE.device,
                                entityId: userDevice.id,
                                data: "recently connected" as AnyObject
                            ))
                            //if car is in location
                            //set cars current altitude to the current altitude
                            self.currentAltitude = car.currentAltitude
                            carUpdate = true
                        } else {
                            // Car still connected
                            log("> car is connected", LOG_LEVEL.log)
                            self.events.append(Event(
                                timestamp: Fmt.getTimestamp(),
                                type: EVENT_TYPE.significant,
                                entityType: ENTITY_TYPE.device,
                                entityId: userDevice.id,
                                data: "connected" as AnyObject
                            ))
                            
                        }
                        self.state.carConnected = true
                        
                        
                        if let currentPosition : CLLocationCoordinate2D = self.locationManager.location?.coordinate{
                            
                            car.currentPosition = Coordinate(lat: currentPosition.latitude, lng: currentPosition.longitude)
                            log("-- car location updated", LOG_LEVEL.log)
                            
                            
                            if self.state.currentLocation != car.currentLocation {
                                car.currentLocation = -1
                            }
                            
                            
                            self.state.updateDevice(car.id, car)
                            
                            
                        } else {
                            log("unable to update device's location", LOG_LEVEL.error)
                        }
                    } else {
                        // Car is not connected
                        if(self.state.carConnected){
                            // Car connection was dropped
                            log("!> car recently disconnected", LOG_LEVEL.log)
                            isSignificant = true
                            
                            // Log device disconnect
                            self.events.append(
                                Event(
                                    timestamp: Fmt.getTimestamp(),
                                    type: EVENT_TYPE.significant,
                                    entityType: ENTITY_TYPE.device,
                                    entityId: userDevice.id,
                                    data: "recently lost connection" as AnyObject
                                )
                            )
                            self.state.carConnected = false
                            carUpdate = true
                            self.carCurrentFloor = self.getActiveFloorLevel()
                            self.log("-- car is on floor: \(self.carCurrentFloor)", LOG_LEVEL.log)
                            
                            self.positionLogSampleTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(addCarPositionToLog(timer:)), userInfo: car.currentPosition, repeats: true)
                            
                            if let currentPosition : CLLocationCoordinate2D = self.locationManager.location?.coordinate {
                                car.currentPosition = Coordinate(lat: currentPosition.latitude, lng: currentPosition.longitude)
                                if let currentLoc : Location = self.state.getCurrentLocation() {
                                    log("-- car location set to \(currentLoc.name)", LOG_LEVEL.log)
                                    car.currentLocation = currentLoc.id
                                    self.changes.append(
                                        Change(
                                            timestamp: Fmt.getTimestamp(),
                                            type: CHANGE_TYPE.update,
                                            entityType: ENTITY_TYPE.device,
                                            entityId: userDevice.id,
                                            data: [ "location" : currentLoc.id ] as AnyObject
                                        )
                                    )
                                    carUpdate = true
                                } else {
                                    // NOT at a known location... assume ground level
                                    self.currentAltitude = 0
                                }
                                car.currentAltitude = self.currentAltitude
                                self.log("-- car altitude set to \(self.currentAltitude)", LOG_LEVEL.log)
                                self.changes.append(
                                    Change(
                                        timestamp: Fmt.getTimestamp(),
                                        type: CHANGE_TYPE.update,
                                        entityType: ENTITY_TYPE.device,
                                        entityId: userDevice.id,
                                        data: [ "altitude" : self.currentAltitude ] as AnyObject
                                    )
                                )
                                carUpdate = true
                                
                                
                            } else {
                                log("unable to update device's location", LOG_LEVEL.error)
                            }
                        } else {
                            log("> car is disconnected", LOG_LEVEL.log)
                            log("userActivity: \(userActivity) || quadrant information presented: \(self.quadInformationPresented)", LOG_LEVEL.log)
                            
                            
                            if userActivity == USER_ACTIVITY.walking
                            {
                                
                                if self.quadInformationPresented == false {
                                    log("-----obtaining car quadrant information------", LOG_LEVEL.log)
                                    
                                    if self.samplingExitCoords.count > 0 {
                                        self.locationCarPositionLog.append(self.samplingExitCoords[self.samplingExitCoords.count-1])
                                        self.locationCarPositionLog.append(self.samplingExitCoords[self.samplingExitCoords.count - 2])
                                        //obtain the last two coordinates recorded before parking event
                                    }else{
                                        self.log("Sampling Exit Coords not collected, array is empty", LOG_LEVEL.error)
                                    }
                                    let averagedParkedCoordinate: Coordinate = self.state.getCoordinateCenter(coordinates: self.samplingExitCoords)
                                    self.getQuadInfoForLocation(averageCoordinate: averagedParkedCoordinate, carLocation: self.state.getLocation(id: car.currentLocation!)!)
                                    
                                    
                                }
                                
                            }
                            
                            
                        }
                        self.state.carConnected = false
                    }
                }
                if(carUpdate){
                    self.state.updateDevice(car.id, car)
                }
            }
        }
        
        // Attempt location recognition
        
        // Ping Position (coordinates)
        
        // Attempt location recognition
        
        // Compare to previous state
        
        // connection cases
        
        // If all same
        
        // If new known present -> check if belongs to known device
        
        // If connection dropped -> did it belong to an active device
        
        // If new unknown present -> add // ?
        
        // device cases
        
        // If same device connected
        
        // If known device connected
        
        // If device disconnected
        
        // location cases
        
        // If location same
        
        // If location change
        
        // If location added
        
        // If location removed
        //dumpLog()
        self.saveState()
        
        // If sync necessary, init request. on success, clear local logs
        
        
        
        if self.assesmentCount % 5 == 0 || isSignificant {
            var running : String = "running"
            if(self.isRunningInBackground){
                running = "running in background"
            }
            
            self.events.append(
                Event(
                    timestamp: Fmt.getTimestamp(),
                    type: EVENT_TYPE.status,
                    entityType: ENTITY_TYPE.user,
                    entityId: self.state.user.email,
                    data: running as AnyObject
                )
            )
            if self.assesmentCount % 20 == 0 || isSignificant {
                self.syncWithPlatform() // Periodic Platform sync
            }
        }
        self.isSignificant = false // Moved here
    }
    
    func syncWithPlatform(){
        self.log("- Platform Synced -", LOG_LEVEL.log)
        self.platform.sync(self.changes, self.events, {(success : Bool)-> Void in
            if(success){
                self.changes.removeAll()
                self.events.removeAll()
            }
        });
    }
    
    func trackLocation(_ location: Location){
        //let regionRadius = state.getRadius(center: location.center, foundations: location.building.foundation) // TODO: dynamic based on foundation span
        let regionRadius = 200.0
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: location.center.lat,
                                                                     longitude: location.center.lng), radius: regionRadius, identifier: String(location.id))
        //let monitoredRegions = locationManager.monitoredRegions
        //if (!monitoredRegions.contains(region)) {
        if (CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)) {
            self.locationManager.startMonitoring(for: region)
            self.monitoredRegions.append(region)
            log("monitoring for location: \(location.name)", LOG_LEVEL.log)
        }
        //}
    }
    
    var inBuilding = false
    private func determineLocation(){
        if let loc : Location = self.state.getCurrentLocation(){
            self.log("Current Location -> \(loc.name)")
            if !trackingLocation {
                locationManager.requestLocation()
            }
            if let CLCoord = self.locationManager.location?.coordinate {
                let coord = Coordinate(lat: CLCoord.latitude, lng: CLCoord.longitude)
                if !manualFencing(loc, coord) {
                    self.leaveLocation()
                }
            }
        } else {
            self.log("Current Location -> Unrecognized")
            for region in self.monitoredRegions{
                if let nearestLoc : Location = self.state.getLocation(id: Int(region.identifier)!) {
                    //let center = CLLocationCoordinate2D(latitude: nearestLoc.center.lat, longitude: nearestLoc.center.lng)
                    //let radius = state.getRadius(center: nearestLoc.center, foundations: nearestLoc.building.foundation)
                    //let currentRegion = CLCircularRegion(center: center, radius: radius, identifier: "regionCheck")
                    if let CLCoord = self.locationManager.location?.coordinate {
                        let coord = Coordinate(lat: CLCoord.latitude, lng: CLCoord.longitude)
                        if manualFencing(nearestLoc, coord) {
                            samplingExitCoords.removeAll()
                            self.inBuilding = true
                            self.state.currentLocation = Int(region.identifier)!
                            self.log("User has entered location: \(nearestLoc.name)", LOG_LEVEL.log)
                            
                            
                            self.trackUserActivity()
                        }
                    }
                }
                
            }
        }
    }
    
    func manualFencing(_ loc: Location, _ coordinate: Coordinate) -> Bool {
        let sortedFoundation = self.state.sortCoordinateClockwise(coordinates: loc.building.foundation)
        if coordinate.contained(by: sortedFoundation) {
            return true
        }
        return false
    }
    
    func getCurrentCoordinate() -> Coordinate? {
        if let current2D : CLLocationCoordinate2D = self.locationManager.location?.coordinate{
            return Coordinate(lat: current2D.latitude, lng: current2D.longitude)
        }
        return nil
    }
    
    func stopAssesmentLoop(){
        //Invalidate assmentLoopTimer
        self.log(">> stopping assesment loop", LOG_LEVEL.log)
        self.assesmentTimer?.invalidate()
        self.assesmentLoopRunning = false
    }
    
    var trackingLocation = false
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Trigger assesment
        self.assesmentLoop()
        //self.isSignificant = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.startUpdatingLocation()
        self.trackingLocation = true
        
        self.events.append(Event(
            timestamp: Fmt.getTimestamp(),
            type: EVENT_TYPE.significant,
            entityType: ENTITY_TYPE.user,
            entityId: String(self.state.user.email),
            data: "triggered an entered location" as AnyObject
        ))
        
        log("!!! ---- USER ENTERED AREA \(region.identifier)------!!!", LOG_LEVEL.log)
        if let enteredLocation : Location = self.state.getLocation(id: Int(region.identifier)!){
            self.log("User has entered area close to: \(enteredLocation.name)", LOG_LEVEL.log)
            
            // User enter an area, not necessary a location, tracking will be check and called with determineLocation()
            
            self.events.append(
                Event(
                    timestamp: Fmt.getTimestamp(),
                    type: EVENT_TYPE.significant,
                    entityType: ENTITY_TYPE.user,
                    entityId: String(self.state.user.email),
                    data: "entered location \(enteredLocation.name)" as AnyObject
                )
            )
        }
        self.syncWithPlatform()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.assesmentLoop()
        self.locationManager.pausesLocationUpdatesAutomatically = true
        self.locationManager.stopUpdatingLocation()
        self.trackingLocation = false
        
        log("!!! ---- USER EXITED AREA \(region.identifier)------!!!", LOG_LEVEL.log)
        if let exitLocation : Location = self.state.getLocation(id: Int(region.identifier)!){
            self.log("User has exited area close to: \(exitLocation.name)", LOG_LEVEL.log)
        }
        
        self.events.append(Event(
            timestamp: Fmt.getTimestamp(),
            type: EVENT_TYPE.significant,
            entityType: ENTITY_TYPE.user,
            entityId: String(self.state.user.email),
            data: "triggered an exit location" as AnyObject
        ))
        
        // Define this as user exit an area ?
        /*
         if let exitedRegion : Location = self.state.getLocation(id: Int(region.identifier)!){
         self.state.currentLocation = -1;
         self.log("User has left location: \(exitedRegion.name)", LOG_LEVEL.log)
         self.stopPositionLogSampleCollection()
         self.stopFloorTest()
         self.events.append(
         Event(
         timestamp: Fmt.getTimestamp(),
         type: EVENT_TYPE.significant,
         entityType: ENTITY_TYPE.user,
         entityId: String(self.state.user.email),
         data: "left location \(exitedRegion.name)" as AnyObject
         )
         )
         }
         Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(leaveLocation), userInfo: nil, repeats: false)
         */
        self.syncWithPlatform()
    }
    
    var samplingExitCoords = [Coordinate]()
    // Check if user is leaving location or false positive before reset altimeter and set location
    func leaveLocation() {
        if let loc = state.getCurrentLocation() {
            let center = CLLocationCoordinate2D(latitude: loc.center.lat, longitude: loc.center.lng)
            let radius = state.getRadius(center: loc.center, foundations: loc.building.foundation)
            let region = CLCircularRegion(center: center, radius: radius, identifier: "regionCheck")
            var confident = 0
            if samplingExitCoords.count > 9 {
                for coord in samplingExitCoords {
                    if region.contains(CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng)) {
                        confident += 1
                    }
                }
                if confident < 2 {
                    self.state.currentLocation = -1
                    self.isSignificant = false
                    self.stopAltimeter()
                    self.log("User has left location: \(loc.name)", LOG_LEVEL.log)
                    self.inBuilding = false
                    
                    // Corey Floor Stuffs
                    self.stopPositionLogSampleCollection()
                    self.quadInformationPresented = false
                    self.deleteAllCarPositionsInLog()//clear the positions log because car is no longer in region...
                    
                    self.events.append(
                        Event(
                            timestamp: Fmt.getTimestamp(),
                            type: EVENT_TYPE.significant,
                            entityType: ENTITY_TYPE.user,
                            entityId: String(self.state.user.email),
                            data: "left location \(loc.name)" as AnyObject
                        )
                    )
                    self.syncWithPlatform()
                }
            }
        } else {   // Ensure that User is no longer in ANY location before reseting information.
            self.stopAltimeter();//stop altimeter updates because user is no longer in region
            self.quadInformationPresented = false
            self.stopPositionLogSampleCollection()
            self.deleteAllCarPositionsInLog()//clear the positions log because car is no longer in region...
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.log("Location Manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // TODO handle change in permission
        log("location authorization updated... \(status)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let failRegion = region {
            if let location = self.state.getLocation(id: Int(failRegion.identifier)!) {
                self.log("Location Monitoring failed for \(failRegion.identifier), name: \(location.name)")
                self.log("Error: \(error.localizedDescription)")
            }
        }
    }
    
    var samplingRate = 10
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            self.log("-- Horizontal Accuracy: \(newLocation.horizontalAccuracy)", LOG_LEVEL.log)
            if newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy < 20 {
                let coordinate = Coordinate(lat: (locations.last?.coordinate.latitude)!, lng: (locations.last?.coordinate.longitude)!)
                if samplingExitCoords.count < self.samplingRate {
                    samplingExitCoords.append(coordinate)
                } else {
                    samplingExitCoords.remove(at: 0)
                    samplingExitCoords.append(coordinate)
                }
            }
        }
        // UI Refactor - START
        if let currentPos : CLLocationCoordinate2D = self.locationManager.location?.coordinate {
            let coord = Coordinate(lat: currentPos.latitude, lng: currentPos.longitude)
            print("update user position")
            self.trackingDelegate?.userPositionUpdated(updatedPosition: coord)
            if self.state.carConnected{
                print("update car position")
                self.trackingDelegate?.carPositionUpdated(updatedPosition: coord)
            }
        }
        // UI Refactor - END
        
    }
    
    func positionEval(){
        self.log("position eval");
        if let loc : CLLocation = self.locationManager.location {
            let pos = Coordinate(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
            for region in self.monitoredRegions{
                if let trackedLocation : Location = self.state.getLocation(id: Int(region.identifier)!){
                    // Assess distance to every tracked location's center
                    let d = self.state.getDistance(c1: trackedLocation.center, c2: pos)
                    if(d < self.state.getRadius(center: trackedLocation.center, foundations: trackedLocation.building.foundation)){
                        self.log("current location identified by position eval -> \(trackedLocation.name)");
                        self.events.append(
                            Event(
                                timestamp: Fmt.getTimestamp(),
                                type: EVENT_TYPE.significant,
                                entityType: ENTITY_TYPE.user,
                                entityId: String(self.state.user.email),
                                data: "at location \(trackedLocation.name)" as AnyObject
                            )
                        )
                        //self.state.currentLocation = trackedLocation.id
                        self.locationManager.startUpdatingLocation()
                        self.trackUserActivity()
                    }
                }
            }
        }
    }
    
    
    //---------- Motion Tracking / Activity Recognition -------------//
    
    func trackUserActivity(){
        altimeterManager.startRelativeAltitudeUpdates(to: OperationQueue.main) { (altimeterData: CMAltitudeData?, error: Error?) in
            self.log("reading current altitude data");
            
            self.currentAltitude = (altimeterData?.relativeAltitude.doubleValue)!;
        }
        self.log("-- Motion Tracking Started", LOG_LEVEL.log);
        self.activityManager.startActivityUpdates(to: OperationQueue.main) { (activity: CMMotionActivity?) in
            if (activity?.automotive)!{
                self.log("set driving");
                self.userActivity = USER_ACTIVITY.driving
            } else if (activity?.walking)!{
                self.log("set walking");
                self.userActivity = USER_ACTIVITY.walking
                
            } else if (activity?.stationary)!{
                self.log("set to stationary");
                self.userActivity = USER_ACTIVITY.stationary
            }
        }
    }
    func stopAltimeter(){
        self.log("altimeter activity stopped", LOG_LEVEL.debug)
        self.altimeterManager.stopRelativeAltitudeUpdates();
    }
    
    func obtainHeadingInformation(centerCoord: Coordinate, destCoord: Coordinate) -> Double{
        //var heading: String = "N/A"
        var center_lat: Double = centerCoord.lat
        let center_lon: Double = centerCoord.lng
        var dest_lat: Double = destCoord.lat
        let dest_lon: Double = destCoord.lng
        let pi_: Double = Double.pi
        
        center_lat = center_lat * pi_/180.0
        dest_lat = dest_lat * pi_/180.0
        let dLon = (dest_lon - center_lon) * pi_ / 180.0
        let y = sin(dLon) * cos(dest_lat)
        let x = cos(center_lat)*sin(dest_lat) - sin(center_lat)*cos(dest_lat)*cos(dLon)
        var bearing = atan2(y, x) * 180.0 / pi_
        if bearing < 0 {
            bearing = bearing + 360.0
        }
        return bearing
    }
    
    
    func getQuadInfoForLocation(averageCoordinate: Coordinate, carLocation: Location){
        var distance: Double = 0.0
        var lowestDistance: Double = 1000000.0
        var closestFoundationPoint: Coordinate?
        var bearing: Double = 0.0
        self.quadInformationPresented = true
        var carCurrentLocation: Location = carLocation
        
        
        if carCurrentLocation.building.foundation.count > 0 {
            
            for i in 0...carCurrentLocation.building.foundation.count - 1 {
                distance = self.state.getDistance(c1: averageCoordinate, c2: carCurrentLocation.building.foundation[i])
                log("Distance from foundation point\(i) is \(distance)", LOG_LEVEL.log)
                if distance <= lowestDistance {
                    lowestDistance = distance
                    closestFoundationPoint = carCurrentLocation.building.foundation[i]
                }
            }
            
            
            bearing = self.obtainHeadingInformation(centerCoord: carCurrentLocation.center, destCoord: closestFoundationPoint!)
            log("bearing based on lowest distance\(lowestDistance): \(bearing)", LOG_LEVEL.log)
            self.headerString = self.getHeaderString(bearing_: bearing)
            log("Car is parked in the \(self.headerString) Quadrant of the parking deck", LOG_LEVEL.log)
            
        }else{
            log("Foundation points array empty", LOG_LEVEL.error)
        }
    }
    
    func getHeaderString(bearing_: Double) -> String{
        var header: String = "N/A"
        
        if bearing_ >= 0 && bearing_ <= 89{
            header = "ne"
        }else if bearing_ >= 90 && bearing_ <= 179{
            header = "se"
        }else if bearing_ >= 180 && bearing_ <= 269{
            header = "sw"
        }else if bearing_ >= 270 && bearing_ <= 360{
            header = "nw"
        }else{
            header = "c"
        }
        
        return header
    }
    
    func getCardinalPosition() -> String {
        return self.headerString
    }
    
    func addCarPositionToLog(timer: Timer){
        self.positionSampleCollectionRunning = true
        let coordinates_ = timer.userInfo as! Coordinate
        if self.locationCarPositionLog.count == 2 {
            log("car position log is full", LOG_LEVEL.log)
            self.stopPositionLogSampleCollection()
            log("collection of car position coordinates for log has stopped with \(self.locationCarPositionLog.count) samples in log.", LOG_LEVEL.log)
        }else{
            log("coordinate added to car position log", LOG_LEVEL.log)
            self.locationCarPositionLog.append(coordinates_)
        }
    }
    
    func stopPositionLogSampleCollection(){
        if self.positionSampleCollectionRunning == true {
            self.positionLogSampleTimer.invalidate()
        }
    }
    func deleteAllCarPositionsInLog(){
        if self.locationCarPositionLog.count == 0 {
            log("car position location log already empty", LOG_LEVEL.log)
        }else{
            log("deleting all coordnates in car position log", LOG_LEVEL.log)
            self.locationCarPositionLog.removeAll()
        }
    }
    func getRelativeFloor(location: Location, altitude: Double) -> Int{
        var height: Double = 0.0
        var difference: Double = height - altitude
        var floor: Int = 0
        for i in 1..<location.building.floors.count{
            let currentFloorHeight = location.building.floors[i - 1].height
            let diff = (height + currentFloorHeight) - altitude
            if(abs(diff) < abs(difference)){
                floor = i
                height += currentFloorHeight
                difference = diff
            }else {
                break
            }
        }
        return floor
    }
    func getActiveFloorLevel() -> Int{
        if let currentLocation : Location = self.state.getCurrentLocation(){
            return getRelativeFloor(location: currentLocation, altitude: self.currentAltitude)
        } else {
            // Default return ground floor
            return 0
        }
    }
    
    
    //---------- END Motion Tracking / Activity Recognition -------------//
    
    
    
    
    
    //---------- Local Storage Integration -------------//
    
    public func getState() -> State{
        return self.state
    }
    
    
    
    // ---- END Unpacking Helpers
    
    // ---- State Persistance
    
    func saveState(){
        //let time_startStateSave = CFAbsoluteTimeGetCurrent() //-- stat
        //log("\n-- saving state --")
        var packedLocations : [String:AnyObject] = [String:AnyObject]()
        var packedConnections : [String:AnyObject] = [String:AnyObject]()
        
        //let time_startUserSave = CFAbsoluteTimeGetCurrent() //-- stat
        let packedUser : [String:AnyObject] = Fmt.packUser(self.state.user)
        
        //log("- locations packed \(CFAbsoluteTimeGetCurrent() - time_startUserSave) s") //-- stat
        
        // Pack Locations
        //let time_startLocSave = CFAbsoluteTimeGetCurrent() //-- stat
        for loc in self.state.locations {
            packedLocations[String(loc.id)] = Fmt.packLocation(loc) as AnyObject
            //log("location packed: \(loc.id)")
        }
        //log("- locations packed \(CFAbsoluteTimeGetCurrent() - time_startLocSave) s") //-- stat
        
        // Pack Connections
        //let time_startConnSave = CFAbsoluteTimeGetCurrent() //-- stat
        for conn in self.state.connections {
            packedConnections[String(conn.id)] = Fmt.packConnection(conn) as AnyObject
            //log("connection packed: \(conn.id)")
        }
        //log("- connections packed \(CFAbsoluteTimeGetCurrent() - time_startConnSave) s") //-- stat
        
        // Prepare State
        let packedState: [String: AnyObject] = [
            "user" : packedUser as AnyObject,
            "locations": packedLocations as AnyObject,
            "connections": packedConnections as AnyObject,
            "log" : self.state.log as AnyObject
        ]
        
        // If valid save to local state
        if(JSONSerialization.isValidJSONObject(packedState)){
            self.localStorage.set(packedState, forKey: "loKey")
            //log("-- state saved \(CFAbsoluteTimeGetCurrent() - time_startStateSave) s\n") //-- stat
        } else {
            //log("state is not valid JSON", LOG_LEVEL.error)
        }
    }
    
    func newState(_ newState : [String:AnyObject]){
        loadState(newState)
    }
    
    func loadState(_ packedState : [String:AnyObject]){
        log("\n-- loading state --")
        let unpackedState : State = State()
        // if let packedState : [String:AnyObject]  = self.localStorage.dictionary(forKey: "loKey") as? [String : AnyObject]{
        let time_startStateLoad = CFAbsoluteTimeGetCurrent() //-- stat
        // Unpack Locations
        let time_startUserLoad = CFAbsoluteTimeGetCurrent() //-- stat
        if let packedUser : [String:AnyObject] = packedState["user"] as? [String:AnyObject]{
            unpackedState.setUser(Fmt.unpackUser(packedUser))
        }
        log("- user unpacked \(CFAbsoluteTimeGetCurrent() - time_startUserLoad) s") //-- stat
        
        // Unpack Locations
        let time_startLocLoad = CFAbsoluteTimeGetCurrent() //-- stat
        if let packedLocations : [String:AnyObject] = packedState["locations"] as? [String:AnyObject]{
            for (id,packedLocation) in packedLocations{
                unpackedState.addLocation(Fmt.unpackLocation(packedLocation))
                log("location unpacked: \(id)")
            }
        }
        log("- locations unpacked \(CFAbsoluteTimeGetCurrent() - time_startLocLoad) s") //-- stat
        
        // Unpack Connections
        let time_startConnLoad = CFAbsoluteTimeGetCurrent() //-- stat
        if let packedConnections : [String:AnyObject] = packedState["connections"] as? [String:AnyObject]{
            for (id,packedConnection) in packedConnections{
                unpackedState.addConnection(Fmt.unpackConnection(packedConnection))
                log("connections unpacked: \(id)")
            }
        }
        log("- connections unpacked \(CFAbsoluteTimeGetCurrent() - time_startConnLoad) s") //-- stat
        
        unpackedState.log = packedState["log"] as! String
        
        let time_startDeviceLoad = CFAbsoluteTimeGetCurrent()
        if let packedDevices : [String:AnyObject] = packedState["devices"] as? [String:AnyObject]{
            for(id, packedDevice) in packedDevices{
                unpackedState.addDevice(Fmt.unpackDevice(packedDevice as! [String : AnyObject]))
                log("- device unpacked: \(id)")
            }
        }
        log("-- deviced loaded \(CFAbsoluteTimeGetCurrent() - time_startDeviceLoad) s\n") //-- stat
        
        
        log("-- state loaded \(CFAbsoluteTimeGetCurrent() - time_startStateLoad) s\n") //-- stat
        //} else {
        //  log("fetched state is not valid JSON", LOG_LEVEL.error)
        //}
        
        self.state = unpackedState
        self.state.linkInstance(instance: self)
    }
    
    private func clearLocalData(){
        self.localStorage.removeObject(forKey: "loKey");
    }
    
    // ---- END State Persistance
    
    // -- Local Storage flags
    private func stateExists() -> Bool{
        return self.localStorage.dictionary(forKey: "loKey") != nil
    }
    
    //---------- END Local Storage Integration ------------//
    
    
    //---------- Remote Platform Integration ------------//
    
    private func syncState(){
        // TODO: Evaluate changes and pull/push respectivly
    }
    
    private func pullState(){
        // TODO: GET request to platform... load state
    }
    
    func pushState(){
        if(self.stateExists()){
            if let stateJSON : [String:AnyObject]  = self.localStorage.dictionary(forKey: "ioKey") as? [String:AnyObject]{
                self.platform.pushState(stateJSON)
            }
        }
    }
    //---------- END Remote Platform Integration ------------//
    
    // Logging Utils
    func log(_ body : String){
        log(body, LOG_LEVEL.debug)
    }
    
    func log(_ body : String, _ level : LOG_LEVEL){
        let record = "\(body)"
        if level == LOG_LEVEL.log {
            self.state.log += "\(record)\n"
        }
        runlog.append(record)
        if(runlog.count >= digestRate){
            dumpLog()
        }
    }
    
    private func dumpLog(){
        for log in runlog{
            print(log)
        }
        runlog = [String]()
    }
    
    // Dev methods
    
    private func removeMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    private func generateSeedData(){
        print(" \n\n\n THIS IS STILL BEING CALLED !!!!!!! \n\n\n ");
    }
}

extension Coordinate {
    
    func contained(by vertices: [Coordinate]) -> Bool {
        let path = CGMutablePath()
        
        for vertex in vertices {
            if path.isEmpty {
                path.move(to: CGPoint(x: vertex.lng, y: vertex.lat))
            } else {
                path.addLine(to: CGPoint(x: vertex.lng, y: vertex.lat))
            }
        }
        
        let point = CGPoint(x: self.lng, y: self.lat)
        return path.contains(point)
    }
    
}
