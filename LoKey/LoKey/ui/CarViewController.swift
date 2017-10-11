//
//  CarViewController.swift
//  LoKey
//
//  Created by Will Steiner on 1/6/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit
import MapKit

class CarViewController: UIViewController, MKMapViewDelegate {

    private var state : State!
    var loop = Timer()
    var switched = false
    
    var selectedView = "map"
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var structureView: UIView!
    @IBOutlet weak var infoView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = getState();
        self.parent?.title = "Nearby Parking"
        
        let rightButton = UIBarButtonItem()
        rightButton.title = "Car"
        rightButton.style = UIBarButtonItemStyle.plain
        rightButton.target = self
        rightButton.action = #selector(switchContainer)
        self.parent?.navigationItem.setRightBarButton(rightButton, animated: true)
        self.parent?.navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.changeView("map")
        
    }
    
    
    func changeView(_ label : String){
        if label == "map" {
            structureView.isHidden = true
            infoView.isHidden = true
            containerView.isHidden = false
            //self.view.bringSubview(toFront: containerView)
            self.parent?.navigationItem.rightBarButtonItem?.title = "Car"
        }
        if label == "location" {
            if let loc : Location = self.state.getCurrentLocation(){
                performSegue(withIdentifier: "locationDetail", sender: loc)
            }
        }
        if let _ = self.state.getCurrentLocation() {
            self.parent?.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            
            if (containerView.isHidden == false) {
                self.parent?.navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }
    }
    
    func switchContainer() {
        changeView("location")
        self.selectedView = "location"
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        // self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.state = getState()
        
        if segue.identifier == "locationDetail" {
            if let dest: LocationDetailViewController = segue.destination as? LocationDetailViewController {
                dest.selectedLocation = sender as! Location!
                dest.initView = 1
            }
        }
        
    }
    
    deinit {
        print ("Car View is deinitialized.")
 
    }
 
}
