//
//  BuildingInformationViewController.swift
//  LoKey
//
//  Created by Huy Nguyen on 3/13/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation
import UIKit

class BuildingInformationViewController: UIViewController {
    
    private var state : State!
    private var instance : Instance!
    var updateLoop = Timer()
    var populateLoop = Timer()
    var isCurrent = false
    
    @IBOutlet var paneNavigation: UISegmentedControl!
    var selectedLocation : Location!
    
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var floorLabel: UILabel!
    
    @IBOutlet weak var containerSegue: UISegmentedControl!
    
    @IBAction func navigateToPane(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            // Info
            self.infoPane.openSegment(segmentIndex: 0)
            break
        case 1:
            // Timer
            self.infoPane.openSegment(segmentIndex: 1)
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
            self.infoPane.openSegment(segmentIndex: 2)
            break
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
        self.instance = self.getInstance()
        if let loc : Location = self.selectedLocation {
            self.locationName.text = loc.name
            self.address.text = loc.address
        }
        
        //self.paneNavigation.layer.cornerRadius = 5;
        //self.paneNavigation.layer.backgroundColor = Utils.secondaryColor.cgColor;
        
    }
    
    var infoPane : InfoPanelViewController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let info = segue.destination as? InfoPanelViewController{
            self.infoPane = info
            self.infoPane.selectedLocation = self.selectedLocation
            self.infoPane.segement = 0 // Info
        }
    }
}
