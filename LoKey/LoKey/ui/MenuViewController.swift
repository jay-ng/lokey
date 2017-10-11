//
//  MenuViewController.swift
//  LoKey
//
//  Created by Will Steiner on 1/6/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var userNavItem: UIView!
    @IBOutlet var locationsNavItem: UIView!
    @IBOutlet var statsNavItem: UIView!
    @IBOutlet var settingsNavItem: UIView!
    
    var userNavTapGesture : UITapGestureRecognizer!
    var locationsNavTapGesture : UITapGestureRecognizer!
    var statsNavTapGesture : UITapGestureRecognizer!
    var settingsNavTapGesture : UITapGestureRecognizer!
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNavTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleNavTransition))
        locationsNavTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleNavTransition))
        statsNavTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleNavTransition))
        settingsNavTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleNavTransition))
        
        userNavTapGesture.delegate = self
        locationsNavTapGesture.delegate = self
        statsNavTapGesture.delegate = self
        settingsNavTapGesture.delegate = self
        
        
        userNavItem.addGestureRecognizer(userNavTapGesture)
        locationsNavItem.addGestureRecognizer(locationsNavTapGesture)
        statsNavItem.addGestureRecognizer(statsNavTapGesture)
        settingsNavItem.addGestureRecognizer(settingsNavTapGesture)
    }
    
    func toggleNavTransition(sender: UITapGestureRecognizer) {
        if let tag : Int = sender.view?.tag {
            switch(tag){
                case 1:
                    //Utils.log("Navigate to user view", level: LogLevel.debug)
                    self.performSegue(withIdentifier: "segueToUser", sender:nil);
                    break;
                
                case 2:
                    //Utils.log("Navigate to locations view", level: LogLevel.debug)
                    self.performSegue(withIdentifier: "segueToLocations", sender:nil);
                    break;
                    
                case 3:
                    //Utils.log("Navigate to stats view", level: LogLevel.debug)
                    self.performSegue(withIdentifier: "segueToStats", sender:nil);
                    break;
                    
                case 4:
                    //Utils.log("Navigate to settings view", level: LogLevel.debug)
                    self.performSegue(withIdentifier: "segueToSettings", sender:nil);
                    break;

                default:
                    log("Unlinked navigation tag: " + String(tag), LOG_LEVEL.error)
                    break;
            }
        } else {
            log("Missing navigation tag", LOG_LEVEL.error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.navigationController?.isNavigationBarHidden == false{
            self.navigationController?.isNavigationBarHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
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
