//
//  LocationNavigation.swift
//  routes
//
//  Created by Will Steiner on 4/19/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class LocationNavigation: UINavigationController {

    
    var map : ViewController!
    var window : MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func forceShow(location: Location){
        performSegue(withIdentifier: "location-details-jump", sender: location)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let nearByVC : LocationListViewController = segue.destination as? LocationListViewController {
            nearByVC.map = self.map
            self.window.moveToDetail()
        }
        
        if let nearByVC : LocationInformationViewController = segue.destination as? LocationInformationViewController {
            nearByVC.selectedLocation = sender as! Location
            self.window.moveToDetail()
        }

    }
    
    

}
