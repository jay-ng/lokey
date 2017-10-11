//
//  SettingsViewController.swift
//  LoKey
//
//  Created by Will Steiner on 1/7/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    private var updateT : Timer!
    private var state : State!
        @IBOutlet var floorLevelIndicator: UILabel!
    @IBOutlet var debugUI: UITextView!
    @IBOutlet var clearLogButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = getState();
        
        self.clearLogButton.addTarget(nil, action: #selector(self.clearLog), for: .touchUpInside)
        self.updateT = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.updateUI), userInfo: nil, repeats: true)
        updateLog()
    }
    
    func updateLog(){
        debugUI.text = self.state.log
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var currentLabel: UILabel!
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        /*
        if(DeviceManager.connectionManager.isConnectedToCar()){
            toggleConnectionButton.setTitle("Disconnect from car", for: UIControlState.normal)
        } else {
            toggleConnectionButton.setTitle("Connect to car", for: UIControlState.normal)
        }*/
    }
    
    func updateUI(){
        updateLog()
        if let loc : Location = self.state.getCurrentLocation(){
            self.currentLabel.text = "Current Location -> \(loc.name)";
        } else {
            self.currentLabel.text = "Current Location -> Unrecognized";
        }
        //debugUI.text = "Current Location: \(DeviceManager.locationManager.getCurrentLocation()?.getName()) \n Connected to car: \(DeviceManager.connectionManager.isConnectedToCar()) \n Possible Floor: \(DeviceManager.movementManager.getFloorLevel())\n \(DeviceManager.outMessage)";
    }
    
    @IBAction func enterLocationAction(_ sender: UIButton) {
        //DeviceManager.movementManager.trackUserActivity();
        
    }
    
    @IBAction func leaveLocationAction(_ sender: UIButton) {
        //DeviceManager.movementManager.leaveLocation();
        
    }
    
    func toggleConnection(){
        
    }
    
    func clearLog(){
        getState().clearLog()
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
