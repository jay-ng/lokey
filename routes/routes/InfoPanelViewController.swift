//
//  InfoPanelViewController.swift
//  LoKey
//
//  Created by Will Steiner on 4/4/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class InfoPanelViewController: UIViewController {

    
    var segement : Int = 0 // Default to info
    
    @IBOutlet var paragraph: UITextView!
    private var state : State!
    var selectedLocation : Location!
    @IBOutlet var floorLabel: UILabel!
    @IBOutlet var altitudeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
        
        
        if let loc :  Location = self.selectedLocation{
            self.paragraph.text = loc.description
            if let carId : String = self.state.user.car {
                if let userDevice : Device = self.state.getDevice(carId) {
                    var floor = self.getInstance().getRelativeFloor(location: loc, altitude: userDevice.currentAltitude)
                    if floor > 0 {
                        floor = floor + 1
                        floorLabel.text = floor.description
                    } else if floor == 0 {
                        floorLabel.text = "G"
                    }
                    self.altitudeLabel.text = "\(userDevice.currentAltitude) m from base"
                }
            } else {
                floorLabel.isHidden = true
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    func openSegment(segmentIndex: Int){
        self.segement = segmentIndex
        print("Open segment: \(segmentIndex)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
