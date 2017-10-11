//
//  LocationDetailViewController.swift
//  LoKey
//
//  Created by Will Steiner on 1/22/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//


// TODO: On unwind / 

import UIKit
    import MapKit

class LocationDetailViewController: UIViewController , MKMapViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate{
    
    var selectedLocation : Location!
    var initView : Int = 0
    var isNew : Bool = false
    var buildingRender : BuildingViewController!
    
    private var state : State!
    private let FALLBACK_MAP_CENTER : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5245782, longitude: -77.6333459)
    
    @IBOutlet var editToggle: UIBarButtonItem!
    
    @IBOutlet var locationMap: MKMapView!
    @IBOutlet var locationAddress: UILabel!
    @IBOutlet var locationDescription: UITextView!
    @IBOutlet var locationName: UILabel!
    @IBOutlet var locationViewToggle: UISegmentedControl!
    
    @IBOutlet var editDialogMap: UIView!
    @IBOutlet var locationNameField: UITextField!
    @IBOutlet var locationAddressField: UITextField!
    @IBOutlet var locationDescriptionField: UITextView!
    @IBOutlet var deleteLocationButton: UIButton!
    @IBOutlet var locationDetails: UIStackView!
    
    @IBOutlet var structureDisplay: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var buildingInfoContainer: UIView!
    
    var activeField: UITextField?
    var refInset : UIEdgeInsets!
    
    var deleteLocationTap : UIGestureRecognizer!
    
    @IBOutlet var floorControls: UIStackView!
    @IBOutlet var addFloorButton: UIButton!
    @IBOutlet var removeFloorButton: UIButton!
    @IBOutlet var structureView: UIView!
    
    @IBOutlet var paneNavigation: UISegmentedControl!
    var selectedSegment = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: true)
        self.state = self.getState()
        self.hideKeyboardWhenTappedAround()
        //self.buildingInfoContainer.isHidden = true
        self.scrollView.delegate = self
        self.locationMap.delegate = self
        
        self.locationNameField.delegate = self
        self.locationAddressField.delegate = self
        self.locationDescriptionField.delegate = self

        self.locationViewToggle.layer.cornerRadius = 5;
        self.locationViewToggle.layer.backgroundColor = Utils.secondaryColor.cgColor;
        
        self.deleteLocationTap = UITapGestureRecognizer(target: self, action: #selector(self.removeLocation))
        self.deleteLocationTap.delegate = self
        self.deleteLocationButton.addGestureRecognizer(deleteLocationTap)
        
        self.registerForKeyboardNotifications()
        /* removing gradient backdrop, because a switch background looks better
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [Utils.secondaryColor.cgColor, Utils.secondaryColor.withAlphaComponent(0.0).cgColor]
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: toggleBackdrop.frame.size.width, height: toggleBackdrop.frame.size.height)
        toggleBackdrop.layer.insertSublayer(gradient, at: 0)*/
        
        self.paneNavigation.layer.cornerRadius = 5;
        self.paneNavigation.layer.backgroundColor = Utils.secondaryColor.cgColor;
        
        self.locationViewToggle.selectedSegmentIndex = self.selectedSegment
        self.locationViewToggle.sendActions(for: UIControlEvents.valueChanged)
    
    }
    
    @IBAction func navigateToPane(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            // Info
            break
        case 1:
            // Timer
            break
        case 2:
            // Stat
            /*
             if (UIApplication.shared.canOpenURL(NSURL(string:"comgooglemaps://")! as URL)) {
             UIApplication.shared.openURL(NSURL(string:
             "comgooglemaps://?saddr=&daddr=\(self.selectedLocation.center.lat),\(self.selectedLocation.center.lng)&directionsmode=driving")! as URL)
             } else {
             NSLog("Can't use comgooglemaps://");
             }
             }*/
            break
        default:
            break
        }
    }

    override func viewWillLayoutSubviews() {
        // If location is not set... imediatly toggle edit mode
        
        if self.selectedLocation == nil {
            
            self.isNew = true;
            
            let seedCoord : Coordinate = self.getCurrentCoordinate()
            let seedFloor = Floor(name: "", height: 4.0, descripton: "")
            let seedStruct : Structure = Structure(foundation: [seedCoord], floors: [seedFloor])
            
            self.selectedLocation = Location(
                id: self.state.generateId(),
                is_pub: false,
                name: "",
                address: "",
                description: "",
                connections: [Int](),
                building: seedStruct,
                center: seedCoord
            )
            
            buildingRender.location = self.selectedLocation;
        } else {
            if(self.selectedLocation.is_pub){
                self.navigationItem.setRightBarButton(nil, animated: false)
            }
        }
        
        render()
        
        print("LAYOUT SUBVIEWS")
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let polygonRenderer = MKPolygonRenderer(overlay: overlay)
            polygonRenderer.strokeColor = UIColor.blue.withAlphaComponent(0.2)
            polygonRenderer.lineWidth = 0.5
            polygonRenderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
            return polygonRenderer
        }
        return MKOverlayRenderer()
    }
    
    
    
    @objc func removeLocation(){
        print("REMOVE LOCATION");
        self.state.removeLocation(self.selectedLocation.id)
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
         self.state = self.getState()
        if(self.isNew){
            self.enterEditMode()
        }
        self.refInset = self.scrollView.contentInset
        print("VIEW DID APPEAR")
        let u = UISegmentedControl()
        u.selectedSegmentIndex = initView
        self.adjustSegment(u)
        self.renderBuilding()
    }
    
    //------ edit Mode and helpers -------
    
    @IBAction func addFloorLevel(_ sender: UIButton) {
        
        let newFloor = Floor(
            name: "New Floor",
            height: 3.1,
            descripton: ""
        )
        
        self.selectedLocation.building.floors.append(newFloor)
        renderBuilding()
    }
    
    @IBAction func removeFloorLevel(_ sender: Any) {
        self.selectedLocation.building.floors.remove(at: self.selectedLocation.building.floors.count - 1)
        renderBuilding()
    }
    
    var foundationPressRecognizer : UILongPressGestureRecognizer!
    var editMode = false
    
    @IBAction func toggleEditMode(_ sender: Any) {
        if(editMode){
            self.exitEditMode()
        } else {
            self.enterEditMode()
        }
    }
    
    private func enterEditMode(){
        self.editMode = true
        self.log("Entering location edit mode")
        self.editToggle.title = "Save"
        
        self.foundationPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.addPinAtPress))
        self.foundationPressRecognizer.minimumPressDuration = 0.5
        self.locationMap.addGestureRecognizer(foundationPressRecognizer)
        
        // Populate editFields
        
        self.locationNameField.text = self.selectedLocation.name
        self.locationAddressField.text = self.selectedLocation.address
        self.locationDescriptionField.text = self.selectedLocation.description
        
        if(self.locationViewToggle.selectedSegmentIndex == 0){
            self.editDialogMap.isHidden = false
        } else {
            /*
            self.buildingInfoContainer.isHidden = true*/
            self.floorControls.isHidden = false
        }
        self.renderAnnotations()
    }
    
    func renderAnnotations(){
        self.clearAnnotations()
        for foundationPoint in selectedLocation.building.foundation {
            annotate(foundationPoint)
        }
    }
    
    @IBAction func resetFoundationPoints(_ sender: Any) {
        log("Reset all foundation points\(self.selectedLocation.building.foundation)")
        // Prompt confirm
        self.selectedLocation.building.foundation.removeAll()
        self.renderAnnotations()
        log("foundation points after: \(self.selectedLocation.building.foundation)")
    }
    @IBAction func removeLastFoundationPoint(_ sender: Any) {
        
        log("Remove last foundation point")
        let index = self.selectedLocation.building.foundation.count
        if(index > 0){
        self.selectedLocation.building.foundation.remove(at: self.selectedLocation.building.foundation.count - 1)
        }
        self.renderAnnotations()
    }
    
    @objc private func addPinAtPress(recognizer : UIGestureRecognizer){
        // Only when finger is released
        if (recognizer.state == UIGestureRecognizerState.ended) {
            let touchPoint : CGPoint = recognizer.location(in: locationMap)
            let touchCoord = locationMap.convert(touchPoint, toCoordinateFrom: locationMap)
            let foundationPoint = Coordinate(lat: touchCoord.latitude, lng: touchCoord.longitude)
            selectedLocation.building.foundation.append(foundationPoint)
            annotate(foundationPoint)
        }
    }
    
    private func annotate(_ coordinate: Coordinate){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lng)
        locationMap.addAnnotation(annotation)
    }
    
    private func exitEditMode(){
        log("Exiting location edit mode")
        
        //Validate
        
        let parsedName = self.locationNameField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let parsedAddress = self.locationAddressField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let parsedDescription = self.locationDescriptionField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let foundationPointCount = self.selectedLocation.building.foundation.count
        
        var valid = true
        var errMessage = ""
        
        if((parsedName?.isEmpty)!){
            valid = false
            errMessage += "Name is required \n"
        }
        
        if((parsedAddress?.isEmpty)!){
            valid = false
            errMessage += "Address is required \n"
        }
        if((parsedDescription?.isEmpty)!){
            valid = false
            errMessage += "Description is required \n"
        }
        if(foundationPointCount <= 0){
            valid = false
            errMessage += "Minimum of one foundation point \n"
        }
        
        if(valid) {
            self.selectedLocation.name = parsedName!
            self.selectedLocation.address = parsedAddress!
            self.selectedLocation.description = parsedDescription!
            self.selectedLocation.center = self.state.getCoordinateCenter(coordinates: self.selectedLocation.building.foundation)
            self.view.endEditing(true)
            if(!isNew){
                // If valid save and exit edit
                self.state.updateLocation(self.selectedLocation.id, self.selectedLocation)
            } else {
                self.state.addLocation(self.selectedLocation)
                self.trackLocation(self.selectedLocation);
                self.isNew = false
            }
            self.saveState()
            self.render()
            self.clearAnnotations()
            self.editMode = false
            self.editDialogMap.isHidden = true
            self.floorControls.isHidden = true
            self.editToggle.title = "Edit"
            self.locationMap.removeGestureRecognizer(foundationPressRecognizer)
        } else {
            // Not valid location, prompt error correction
            self.notifyUser("Invalid Data", errMessage)
        }
    }
    
    private func clearAnnotations(){
        let allAnnotations = self.locationMap.annotations
        self.locationMap.removeAnnotations(allAnnotations)
    }
    
    //------ END edit Mode and helpers -------
    
    @IBAction func adjustSegment(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.locationMap.isHidden = false
            self.locationDetails.isHidden = false
            self.structureView.isHidden = true
            //self.buildingInfoContainer.isHidden = true
            if(self.editMode){
                self.floorControls.isHidden = true;
                self.editDialogMap.isHidden = false;
            }
        case 1:
            self.locationMap.isHidden = true
            self.locationDetails.isHidden = true
            self.structureView.isHidden = false
            //self.buildingInfoContainer.isHidden = false
            if(self.editMode){
                //self.buildingInfoContainer.isHidden = true
                self.floorControls.isHidden = false;
                self.editDialogMap.isHidden = true;
            }
            
        default:
            break;
        }
        
        
    }
    
    
    
    //---- Render map and location details ------
    func render(){
        self.renderMap()
        self.renderLocationDetails()
    }
    
    func renderBuilding(){
        self.buildingRender.drawBuilding(floors: self.selectedLocation.building.floors.count, activeFloor: -1, carPosition: "NW")
    }
    
    private func renderMap(){
        
        self.locationMap.clearsContextBeforeDrawing = true
        self.locationMap.mapType = MKMapType.standard
    
        //locationMap.showsUserLocation = true
        let sortedCoordinates = state.sortCoordinateClockwise(coordinates: self.selectedLocation.building.foundation)
        
        var CLCoords = [CLLocationCoordinate2D]()
        for foundation in sortedCoordinates {
            CLCoords.append(CLLocationCoordinate2D(latitude: foundation.lat, longitude: foundation.lng))
        }
        
        let polygon = MKPolygon(coordinates: CLCoords, count: CLCoords.count) as MKOverlay
        self.locationMap.add(polygon)
        // Center of foundation points
        locationMap.centerCoordinate = CLLocationCoordinate2D(latitude: selectedLocation.center.lat, longitude: selectedLocation.center.lng)
        
        // Adjust zoom to include all or most foundation points
        let spanCoordinate = self.state.getCoordinateDelta(coordinates: selectedLocation.building.foundation)
        let span = MKCoordinateSpan(latitudeDelta: spanCoordinate.lat + 0.0002, longitudeDelta: spanCoordinate.lng + 0.0002)
        locationMap.setRegion(MKCoordinateRegion(center: locationMap.centerCoordinate, span: span),animated: false)
    }
    
    private func renderLocationDetails(){
        self.title = self.selectedLocation.name
        self.locationAddress.text = self.selectedLocation.address
        self.locationName.text = self.selectedLocation.name
        self.locationDescription.text = self.selectedLocation.description
    }
    
    //---- END Render map and location details ------

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification){
        
        // Keyboard was sh
        //Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.isScrollEnabled = true
        // This is sketch. Proper implentation would have been to include a scroll view within the view for edit fields.
        // Currently scroll up to display fields
        
        if(self.locationViewToggle.selectedSegmentIndex == 0){
        self.scrollView.contentInset = UIEdgeInsetsMake((-self.editDialogMap.frame.minY + 28), 0, 0, 0)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "embededBuildingSegue") {
            let childViewController = segue.destination as! BuildingViewController
            buildingRender = childViewController
            buildingRender.location = self.selectedLocation
            buildingRender.isCurrent = false
            self.state = self.getState()
            
            
            if !isNew{
                if let carId : String = self.state.user.car {
                    let userCar : Device = self.state.getDevice(carId)!
                    if let carLocId : Int = userCar.currentLocation{
                        if(carLocId == self.selectedLocation.id){
                            // User is viewing the render coresponding to the current location of a tracked device. Attempt to determine floor level and cardinal direction.
                            let carLoc = self.state.getLocation(id: carLocId)!
                            self.buildingRender.currentActiveFloor = self.getInstance().getRelativeFloor(location: carLoc, altitude: userCar.currentAltitude)
                        }
                    }
                }
            }
        }
        if (segue.identifier == "buildingInfoSegue") {
            let dest = segue.destination as! BuildingInformationViewController
            dest.selectedLocation = self.selectedLocation
            dest.isCurrent = false
        }
    
    }
    
    func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        self.scrollView.contentInset = self.refInset
    }
    
    deinit {
        log("LocationDetail deinitialized...")
    }
}
