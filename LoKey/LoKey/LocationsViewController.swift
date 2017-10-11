//
//  LocationsViewController.swift
//  LoKey
//
//  Created by Will Steiner on 1/7/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

/*
 Lists all of the user's locations - Allow editing
 and
 List nearby public locations - View Only
 */




import UIKit

class LocationsViewController: UITableViewController {
    
    private var state : State!
    var seletedLocation : Location?

    @IBOutlet var locationTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        locationTable.reloadData()
    }
    
    
    @IBAction func triggerNewLocation(_ sender: Any) {
        print("NEW LOCATION,, set current to nil")
        self.seletedLocation = nil;
        performSegue(withIdentifier: "locationDetail", sender: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.state.locations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell")! as! LocationTableViewCell
        let bgColorView = UITableViewCell()
        bgColorView.backgroundColor = Utils.primaryColor.withAlphaComponent(0.5)
        cell.selectedBackgroundView = bgColorView
        cell.locationNameLabel.text = self.state.locations[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.seletedLocation = self.state.locations[indexPath.row]
        performSegue(withIdentifier: "locationDetail", sender: Any?.self)
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
