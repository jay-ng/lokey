//
//  ViewController.swift
//  routes
//
//  Created by Will Steiner on 4/9/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController, DeviceTrackingDelegate {

    
    private var state : State!
    private var instance : Instance!
    
    private var mapView : GMSMapView!
    private var selectedFocus : FOCUS = .USER
    let trackedMarker = GMSMarker()
    let deviceMarker = GMSMarker()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.instance.trackingDelegate = self
        self.instance.locationManager.requestLocation()
        self.setupRegionOverlay()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func loadView() {
        let camera = GMSCameraPosition.camera(withLatitude: 37.546796, longitude: -77.450304, zoom: 16.0)
        self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                self.mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        self.state = self.getState()
        self.instance = self.getInstance()
        self.deviceMarker.appearAnimation = GMSMarkerAnimation.pop
        self.deviceMarker.icon = UIImage(named: "car-indicator")
        self.deviceMarker.groundAnchor = CGPoint(x: 0.0, y: 0.0)
        self.deviceMarker.map = mapView
        self.trackedMarker.appearAnimation = GMSMarkerAnimation.pop
        self.trackedMarker.icon = UIImage(named: "user-indicator")
        self.trackedMarker.groundAnchor = CGPoint(x: 0.25, y: 0.25)
        self.trackedMarker.map = mapView
        self.trackCar()
        self.trackUser()
        self.view = mapView
    }
    
    
    func displayLocation(location : Location){
        
        var pointTo : CLLocationCoordinate2D
        
        let pos = CLLocationCoordinate2D(latitude: location.center.lat, longitude: location.center.lng)
    
        pointTo = CLLocationCoordinate2D(latitude: pos.latitude.advanced(by: 0.00045), longitude: pos.longitude.advanced(by: 0))

        self.mapView.animate(toLocation: pointTo)
        self.mapView.animate(toZoom: 18)
        
        self.selectedFocus = FOCUS.SEARCH
    }
    
    func carPositionUpdated(updatedPosition: Any){
        
        if let usrCarId = self.state.user.car {
            var pos : CLLocationCoordinate2D? = nil
            
            if self.state.carConnected {
                trackedMarker.map = nil
                if let position : Coordinate = updatedPosition as? Coordinate {
                    pos = CLLocationCoordinate2D(latitude: position.lat, longitude: position.lng)
                }
            } else {
                trackedMarker.map = self.mapView
                if let car : Device = self.state.getDevice(usrCarId) {
                    if let locId : Int = car.currentLocation{
                        if let loc : Location = self.state.getLocation(id: locId){
                            pos = CLLocationCoordinate2D(latitude: loc.center.lat, longitude: loc.center.lng)
                        }
                    }
                }
            }
            
            if(pos != nil){
                deviceMarker.position = pos!
                if self.selectedFocus == .CAR {
                    self.mapView.animate(toLocation: pos!)
                }
                
                if state.carConnected {
                    self.mapView.animate(toLocation: pos!)
                }
            }
            
        }
    }
    
    func userPositionUpdated(updatedPosition: Any){
        
        if self.state.carConnected{
            return
        } else {
            trackedMarker.map = self.mapView
        }
        
        if let pos : Coordinate = updatedPosition as? Coordinate {
            let coord = CLLocationCoordinate2D(latitude: pos.lat, longitude: pos.lng)
            trackedMarker.position = coord
            if self.selectedFocus == .USER {
                self.mapView.animate(toLocation: coord)
            }
            
            
        }
    }
    
    
    func trackUser(){
        self.selectedFocus = .USER
        self.instance.locationManager.requestLocation()
        
        if let _ = self.instance.locationManager.location{
            let pos = self.instance.locationManager.location!.coordinate
            self.mapView.animate(toLocation: pos)
            self.trackedMarker.position = pos
        }
    }
    
    func trackCar(){
        self.selectedFocus = .CAR
        // Focus is on car. If user in car, update on user location updates
        if let usrCarId = self.state.user.car {
            var pos : CLLocationCoordinate2D? = nil
            if let car : Device = self.state.getDevice(usrCarId) {
                if state.carConnected{
                  pos = self.instance.locationManager.location!.coordinate
                } else {
                    if let locId : Int = car.currentLocation{
                        if let loc : Location = self.state.getLocation(id: locId){
                            self.displayLocation(location: loc)
                        }
                    } else if let cPos : Coordinate = car.currentPosition{
                        pos = CLLocationCoordinate2D(latitude: cPos.lat, longitude: cPos.lng)

                    }
                }
            } else {
                // No car position to plot
                self.notifyUser("Missing Car", "Please link a car connection in settings.")
            }
            
            if(pos != nil){
                self.mapView.animate(toLocation: pos!)
                self.deviceMarker.position = pos!
            }
        }
    }
    
    func setupRegionOverlay(){
        for location in self.state.locations {
            if (location.building.foundation.count > 2) {
                let rect = GMSMutablePath()
                var sortedCoordinates = [Coordinate]()
                //let foundations = location.building.foundation
                if !location.is_pub {
                    //foundations.remove(at: 0)
                    sortedCoordinates = state.sortCoordinateClockwise(coordinates: location.building.foundation)
                } else {
                    sortedCoordinates = location.building.foundation
                }
                for foundation in sortedCoordinates {
                    rect.add(CLLocationCoordinate2D(latitude:  foundation.lat, longitude: foundation.lng))
                }
                
                let polygon = GMSPolygon(path: rect)
                polygon.fillColor = Utils.primaryColor.withAlphaComponent(0.80)
                polygon.strokeColor = Utils.primaryColor
                polygon.strokeWidth = 2
                polygon.map = mapView
            }
        }

    }
    
    func resetZoom(){
        self.mapView.animate(toZoom: 16)
    }
    
    func noTrack(){
        
    }

}

