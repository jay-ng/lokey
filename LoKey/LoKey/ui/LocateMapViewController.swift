//
//  LocateMapViewController.swift
//  LoKey
//
//  Created by Huy Nguyen on 2/21/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit
import MapKit

class LocateMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapSegment: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!
    private var state : State!
    private var instance : Instance!
    private var mapAnnotations = [MKAnnotation]()
    private var carAnnotation = CustomPointAnnotation()
    private var carPlaced = false
    
    var mapTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = getState()
        self.instance = getInstance()
        
        // Do any additional setup after loading the view.
        
        if let carId : String = self.state.user.car {
            if let userDevice : Device = self.state.getDevice(carId) {
                carAnnotation = CustomPointAnnotation()
                carAnnotation.pinCustomImageName = "car-indicator.png"
                carAnnotation.title = "Your Car"
                var locationLabel = "Not Parked"
                if let locId : Int = userDevice.currentLocation {
                    let location = self.state.getLocation(id: locId)
                    if let name : String = location?.name{
                        locationLabel = name
                    }
                }
                
                carAnnotation.subtitle = locationLabel // Can add car current parked location here
                carAnnotation.accessibilityLabel = "Your Car"
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        mapView.isHidden = false
        mapView.showsPointsOfInterest = false
        mapView.showsBuildings = false
        mapView.showsUserLocation = true
        
        if (CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse) {
            mapTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateMap), userInfo: nil, repeats: true)
        }
        
        if let userLoc = self.getInstance().locationManager.location{
            mapView.setCenter(userLoc.coordinate, animated: false)
            mapView.delegate = self
            let adjustedRegion = mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(userLoc.coordinate, 500, 500))
            mapView.setRegion(adjustedRegion, animated: false)
        }
        
        setupRegionOverlay()
        
        if let carId : String = self.state.user.car {
            if let userDevice : Device = self.state.getDevice(carId) {
                if let coordinate : Coordinate = userDevice.currentPosition {
                    carAnnotation.coordinate = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lng)
                    mapView.addAnnotation(carAnnotation)
                }
            }
        }
    }
    
    func setupRegionOverlay() {
        for location in self.state.locations {
            
            if (location.building.foundation.count > 2) {
                var CLCoords = [CLLocationCoordinate2D]()
                var sortedCoordinates = [Coordinate]()
                if !location.is_pub {
                    sortedCoordinates = state.sortCoordinateClockwise(coordinates: location.building.foundation)
                } else {
                    sortedCoordinates = location.building.foundation
                }
                for foundation in sortedCoordinates {
                    CLCoords.append(CLLocationCoordinate2D(latitude: foundation.lat, longitude: foundation.lng))
                }
                let count = CLCoords.count
                let polygon = MKPolygon(coordinates: &CLCoords, count: count) as MKOverlay
                mapView.add(polygon)
            }
        }
    }
    
    func updateMap() {
        if state.carConnected {
            if carPlaced {
                self.mapView.showsUserLocation = false
                self.mapView.showsUserLocation = true
            }
            carPlaced = false
            mapView.removeAnnotation(carAnnotation)
        } else {
            if !carPlaced {
                if let carId : String = self.state.user.car {
                    if let userDevice : Device = self.state.getDevice(carId) {
                        if let coordinate : Coordinate = userDevice.currentPosition {
                            if let currentLocation = self.state.getCurrentLocation() {
                                if coordinate.contained(by: currentLocation.building.foundation) {
                                    carAnnotation.coordinate = CLLocationCoordinate2D(latitude: currentLocation.center.lat, longitude: currentLocation.center.lng)
                                } else {
                                    for samplingCoordinate in (self.instance.samplingExitCoords) {
                                        if samplingCoordinate.contained(by: currentLocation.building.foundation) {
                                            carAnnotation.coordinate = CLLocationCoordinate2D(latitude: currentLocation.center.lat, longitude: currentLocation.center.lng)
                                        }
                                    }
                                }
                                carAnnotation.subtitle = currentLocation.name
                            }
                            mapView.addAnnotation(carAnnotation)
                            carPlaced = true
                            self.mapView.showsUserLocation = false
                            self.mapView.showsUserLocation = true
                        }
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let polygonRenderer = MKPolygonRenderer(overlay: overlay)
            polygonRenderer.strokeColor = UIColor.blue.withAlphaComponent(0.2)
            polygonRenderer.lineWidth = 0.5
            polygonRenderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
            return polygonRenderer
        } else if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.strokeColor = UIColor.red.withAlphaComponent(0.3)
            circleRenderer.lineWidth = 1.0
            circleRenderer.fillColor = UIColor.red.withAlphaComponent(0.3)
            return circleRenderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        var defaultImage = UIImage(named: "user-indicator")
        
        if (annotation.isEqual(mapView.userLocation)) {
            if (state.carConnected) {
                defaultImage = UIImage(named: "car-indicator")
            }
            
        } else {
            defaultImage = UIImage(named: "car-indicator")
        }
        annotationView?.image = defaultImage!
        return annotationView
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        //self.navigationController?.setNavigationBarHidden(false, animated: true)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let overlays = self.mapView.overlays
        self.mapView.removeAnnotations(self.mapView.annotations)
        for overlay in (overlays) {
            self.mapView.remove(overlay)
        }
    }
    
    deinit {
        print ("Map View is deinitialized.")
    }
}



class PinAnnotation:NSObject, MKAnnotation{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
    class func createViewAnnotationForMap(mapView:MKMapView, annotation:MKAnnotation)->MKAnnotationView{
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "PinAnnotation"){
            return annotationView
        }else{
            let returnedAnnotationView:MKPinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier:"PinAnnotation")
            returnedAnnotationView.pinTintColor = UIColor.purple
            returnedAnnotationView.animatesDrop = true
            returnedAnnotationView.canShowCallout = true
            return returnedAnnotationView
            
        }
    }
}

class CustomPointAnnotation: MKPointAnnotation {
    var pinCustomImageName:String!
}
