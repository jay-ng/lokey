//
//  MainViewController.swift
//  routes
//
//  Created by Will Steiner on 4/10/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit
import UserNotifications

enum FOCUS {
    case SEARCH
    case CAR
    case USER
}

class MainViewController: UIViewController, UIGestureRecognizerDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var detailContainer: UIView!
    
    private var mapController : ViewController!
    private var detailNav : LocationNavigation!

    @IBOutlet var nav_button_settings: UIImageView!
    @IBOutlet var nav_button_car: UIImageView!
    @IBOutlet var nav_button_user: UIImageView!
    
    private var selectedFocus : FOCUS = .USER
    
    private var state: State!
    
    private var userTrackRecognizer : UIGestureRecognizer!
    private var deviceTrackRecognizer : UIGestureRecognizer!
    private var settingsRecognizer : UIGestureRecognizer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UNUserNotificationCenter.current().delegate = self
        self.navigationController?.isNavigationBarHidden = true
        
        self.state = self.getState();
        
        self.userTrackRecognizer = UITapGestureRecognizer(target: self.mapController, action: #selector(self.mapController.trackUser))
        self.userTrackRecognizer.delegate = self
        self.nav_button_user.isUserInteractionEnabled = true
        self.nav_button_user.addGestureRecognizer(userTrackRecognizer)
        
        self.deviceTrackRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.focusOnDevice))
        self.deviceTrackRecognizer.delegate = self
        self.nav_button_car.isUserInteractionEnabled = true
        self.nav_button_car.addGestureRecognizer(deviceTrackRecognizer)
        
        self.settingsRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.displaySettings))
        self.settingsRecognizer.delegate = self
        self.nav_button_settings.isUserInteractionEnabled = true
        self.nav_button_settings.addGestureRecognizer(settingsRecognizer)
    }
    
    func displaySettings(){
        performSegue(withIdentifier: "user-settings", sender: nil)
    }
    
    func focusOnDevice(){
        
        if state.carConnected {
            self.mapController.trackCar()
            return
        }
        

        if let car = self.state.getUserCar(){
            if let locId = car.currentLocation{
                let location = self.state.getLocation(id: locId)
                self.mapController.displayLocation(location: location!)
                self.detailNav.forceShow(location: location!)
                return
            }
        }
        
        self.mapController.trackCar()
        

    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let mapVC : ViewController = segue.destination as? ViewController {
            self.mapController = mapVC
        }
        
        if let nearByVC : LocationNavigation = segue.destination as? LocationNavigation {
            self.detailNav = nearByVC
            nearByVC.map = self.mapController
            nearByVC.window = self
        }
        
    }
    
    func moveToDetail(){
        self.scrollView.setContentOffset(CGPoint(x: 0.0, y: (self.view.frame.height * (0.30))), animated: true)
    }
    
    func moveToTop(){
        self.scrollView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: true)
    }
    
    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //If you don't want to show notification when app is open, do something here else and make a return here.
        //Even you you don't implement this delegate method, you will not see the notification on the specified controller. So, you have to implement this delegate and make sure the below line execute. i.e. completionHandler.
        
        completionHandler([.alert,.badge])
    }
    
    // For handling tap and user actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "action1":
            print("Action First Tapped")
        case "action2":
            print("Action Second Tapped")
        default:
            break
        }
        completionHandler()
    }

}
