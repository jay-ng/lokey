//
//  LocationEditorViewController.swift
//  LoKey
//
//  Created by Will Steiner on 1/23/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//
import UIKit
import MapKit

class LocationEditorViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    var selectedLocation : Location!
    
    private var state : State!
    private var connectionSelectorTap : UIGestureRecognizer!
    
    @IBOutlet var locationKey: UILabel!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var descriptionField: UITextView!
    @IBOutlet var connectionSelectButton: UIButton!
    @IBOutlet var connectionTable: UITableView!
    @IBOutlet var saveLocationButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
        self.connectionTable.delegate = self
        self.connectionTable.dataSource = self
        self.connectionSelectorTap = UITapGestureRecognizer(target: self, action: #selector(self.promptConnectionSelect))
        self.connectionSelectorTap.delegate = self
        self.connectionSelectButton.addGestureRecognizer(self.connectionSelectorTap)
        self.hideKeyboardWhenTappedAround()
        self.refresh()
    }
    
    @IBAction func saveLocation(_ sender: AnyObject) {
        selectedLocation.name = self.nameField.text!
        /*
        if(DeviceManager.locationManager.isKnownLocation(locationId: self.selectedLocation.getId())){
            Utils.log("Location updated: \(self.selectedLocation.getName())", level: LogLevel.debug)
            DeviceManager.locationManager.knownLocations[self.selectedLocation.getId()] = self.selectedLocation
        } else {
            Utils.log("New location added: \(self.selectedLocation.getName())", level: LogLevel.debug)
            DeviceManager.locationManager.addKnownLocation(newLocation: self.selectedLocation)
        }
        DeviceManager.dataManager.push()
        navigationController?.popViewController(animated: true)
        */
    }
    
    
    //Calls this function when the tap is recognized.
    override func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.selectedLocation != nil {
            
        } else {
            //self.selectedLocation = Location(locationId: Int(arc4random()), associatedConnections: [Int]())
        }
        refresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (selectedLocation != nil) {
            return selectedLocation.connections.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell? = self.connectionTable.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell?
        let conn = self.state.connections[selectedLocation.connections[indexPath.row]]
        cell?.textLabel?.text = conn.name
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    private func refresh(){
        if (selectedLocation != nil) {
            self.title = selectedLocation.name
            self.locationKey.text = String(selectedLocation.id)
            self.nameField.text = selectedLocation.name
            self.descriptionField.text = selectedLocation.description
            self.connectionTable.reloadData()
        }
    }
    
    func promptConnectionSelect(){
        performSegue(withIdentifier: "connectionFromEditorSegue", sender: nil)
    }
    
    deinit {
        //Utils.log("LocationEditor deinitializing...", level: LogLevel.debug)
    }
    
}
