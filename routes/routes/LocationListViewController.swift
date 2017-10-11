 //
//  LocationListViewController.swift
//  LoKey
//
//  Created by Will Steiner on 4/5/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class LocationListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    var map : ViewController!
    private var state : State!
    private var instance : Instance!
    var seletedLocation : Location?
    
    @IBOutlet var locationTable: UITableView!
    
    private var fmtLocations : [[String:AnyObject]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
        self.locationTable.delegate = self
        self.locationTable.dataSource = self
        self.instance = self.getInstance()
        //self.instance.trackingDelegate = self
        self.updateTable()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Display the overview scene
        (self.navigationController as! LocationNavigation).window.moveToTop()
        (self.navigationController as! LocationNavigation).map.resetZoom()
    }
    
    
    func updateTable(){
        
        var fmtLocations = [[String:AnyObject]]()
        var placed = false;
        if self.instance.locationManager.location != nil{
            let currentCoordinate = getCurrentCoordinate()
            for loc in self.state.locations {
                // Compute the distance
                var dist = self.state.getDistance(c1: currentCoordinate, c2: loc.center) * 0.000621371192;
                // Add at proper position in array
                dist = round(100.0 * dist) / 100;
                placed = false
                
                
                let locObj = [
                    "label"    : loc.name as AnyObject,
                    "dist"     : dist as AnyObject,
                    "location" : loc as AnyObject
                ];
                
                for i in 0..<fmtLocations.count {
                    if(dist < fmtLocations[i]["dist"]! as! Double){
                        fmtLocations.insert(locObj, at: i)
                        placed = true
                        break
                    }
                }
                
                if(!placed){
                    fmtLocations.append([
                        "label"    : loc.name as AnyObject,
                        "dist"     : dist as AnyObject,
                        "location" : loc as AnyObject
                    ]);
                    
                    
                }
            }
        } else {
            for loc in self.state.locations {
                fmtLocations.append([
                    "label"    : loc.name as AnyObject,
                    "location" : loc as AnyObject
                ]);
                
            }
        }
        
        self.fmtLocations = fmtLocations
        locationTable.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.locationTable.reloadData()
        self.seletedLocation = nil
    }
    
    
    @IBAction func triggerNewLocation(_ sender: Any) {
        print("NEW LOCATION,, set current to nil")
        self.seletedLocation = nil;
        performSegue(withIdentifier: "locationDetail", sender: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func userPositionUpdated(updatedPosition: Any) {
        self.updateTable()
    }
    
    func carPositionUpdated(updatedPosition: Any) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fmtLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell")! as! LocationTableViewCell
        cell.backgroundColor = UIColor.clear
        cell.locationNameLabel.textColor = Utils.primaryColor
        cell.locationNameLabel.text = self.fmtLocations[indexPath.row]["label"] as! String?
        
        
        if let d : Double = self.fmtLocations[indexPath.row]["dist"] as? Double {
            cell.locationDistanceFromUser.text = "\(d) mi"
            cell.locationDistanceFromUser.isHidden = false;
        } else {
            cell.locationDistanceFromUser.isHidden = true;
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.seletedLocation = self.fmtLocations[indexPath.row]["location"] as! Location
        
        if let nav : LocationNavigation = self.navigationController as? LocationNavigation{
            nav.map.displayLocation(location: self.seletedLocation!)
            nav.window.moveToDetail()
            
        }
        performSegue(withIdentifier: "location-details", sender: Any?.self)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! LocationTableViewCell
        cell.locationNameLabel.textColor = Utils.secondaryColor
        cell.backgroundColor = Utils.primaryColor
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! LocationTableViewCell
        cell.locationNameLabel.textColor = Utils.primaryColor
        cell.backgroundColor = .clear
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        if let dest: LocationInformationViewController = segue.destination as? LocationInformationViewController{
            dest.selectedLocation = self.seletedLocation
            if self.seletedLocation == nil {
                // TODO: err
            }

        }
        
    }

}
