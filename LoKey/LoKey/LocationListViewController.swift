//
//  LocationListViewController.swift
//  LoKey
//
//  Created by Will Steiner on 4/5/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class LocationListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var state : State!
    var seletedLocation : Location?
    
    @IBOutlet var locationTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
        self.locationTable.delegate = self
        self.locationTable.dataSource = self
        locationTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.state.locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell")! as! LocationTableViewCell
        cell.backgroundColor = UIColor.clear
        cell.locationNameLabel.textColor = Utils.primaryColor
        cell.locationNameLabel.text = self.state.locations[indexPath.row].name
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.seletedLocation = self.state.locations[indexPath.row]
        performSegue(withIdentifier: "locationDetail", sender: Any?.self)
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
        if let dest: LocationDetailViewController = segue.destination as? LocationDetailViewController{
            dest.selectedLocation = self.seletedLocation
            if self.seletedLocation == nil {
                dest.isNew = true
            }
        }
        
    }

}
