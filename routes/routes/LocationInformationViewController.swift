//
//  LocationInformationViewController.swift
//  routes
//
//  Created by Will Steiner on 4/19/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit
import UserNotifications

class LocationInformationViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var locationDetailNav: UISegmentedControl!
    @IBOutlet var locationNameLabel: UILabel!
    var selectedLocation : Location!
    @IBOutlet var locationDescriptionField: UITextView!
    @IBOutlet var locationAddressLabel: UILabel!
    @IBOutlet var meterDown: UIImageView!
    @IBOutlet var meterUp: UIImageView!
    @IBOutlet var meterStart: UIButton!
    
    private var downHold : UILongPressGestureRecognizer!
    private var downClick : UIGestureRecognizer!
    
    private var upHold : UILongPressGestureRecognizer!
    private var upClick : UIGestureRecognizer = UIGestureRecognizer()
    @IBOutlet var meterView: UIView!
    
    @IBOutlet var meterMin: UITextField!
    @IBOutlet var meterHour: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.meterView.isHidden = true
        self.hideKeyboardWhenTappedAround()
        
        self.downHold = UILongPressGestureRecognizer(target: self, action: #selector(self.jumpDown))
        self.downClick = UITapGestureRecognizer(target: self, action: #selector(self.decreaseMeter))
        self.downClick.delegate = self
        self.meterDown.isUserInteractionEnabled = true
        self.meterDown.addGestureRecognizer(downClick)
        self.meterDown.addGestureRecognizer(downHold)
        
        self.upHold = UILongPressGestureRecognizer(target: self, action: #selector(self.jumpUp))
        self.upClick = UITapGestureRecognizer(target: self, action: #selector(self.increaseMeter))
        self.upClick.delegate = self
        self.meterUp.isUserInteractionEnabled = true
        self.meterUp.addGestureRecognizer(upClick)
        self.meterUp.addGestureRecognizer(upHold)
    }
    
    let jumpDist = 10
    
    func jumpDown(){
        let currentMin = Int(self.meterMin.text!)!
        let currentHr = Int(self.meterHour.text!)!
        
    
        if(currentMin - jumpDist) < 0 {
            if(currentHr > 0){
                let diff = abs(currentMin - jumpDist)
                self.meterHour.text = String(currentHr - 1)
                self.meterMin.text = String(59 - diff)
            } else {
                notifyUser("Invalid Meter", "Must be greater than 1 min")
            }
        } else {
            self.meterMin.text = String(currentMin - 1)
        }

        
    }
    
    func jumpUp(){
        let currentMin = Int(self.meterMin.text!)!
        let currentHr = Int(self.meterHour.text!)!
        
        
        if(currentMin + jumpDist) > 59 {
            if(currentHr > 0){
                let diff = abs(currentMin - jumpDist)
                self.meterHour.text = String(currentHr - 1)
                self.meterMin.text = String(59 - diff)
            } else {
                notifyUser("Invalid Meter", "Must be greater than 1 min")
            }
        } else {
            self.meterMin.text = String(currentMin - 1)
        }

        
    }
    
    func decreaseMeter(){
        
        let currentMin = Int(self.meterMin.text!)!
        let currentHr = Int(self.meterHour.text!)!
        
        if(currentMin - 1) < 0 {
            if(currentHr - 1 >= 0){
                self.meterHour.text = String(currentHr - 1)
                self.meterMin.text = String(59)
            } else {
                notifyUser("Invalid Meter", "Must be greater than 1 min")
            }
        } else {
            self.meterMin.text = String(currentMin - 1)
        }

    }
    
    func increaseMeter(){
        let currentMin = Int(self.meterMin.text!)!
        let currentHr = Int(self.meterHour.text!)!
        
        if(currentMin + 1) > 59 {
            self.meterHour.text = String(currentHr + 1)
            self.meterMin.text = String(00)
        } else {
            self.meterMin.text = String(currentMin + 1)
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.backItem?.title = "Nearby"
        self.locationNameLabel.text = self.selectedLocation.name
        self.locationAddressLabel.text = self.selectedLocation.address
        self.locationDescriptionField.text = self.selectedLocation.description
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func infoNavChange(_ sender: UISegmentedControl) {
        
        
        switch(sender.selectedSegmentIndex){
            case 0:
                // Desc
                self.locationDescriptionField.isHidden = false
                self.meterView.isHidden = true
                break
            case 1:
                // Meter
                self.locationDescriptionField.isHidden = true
                self.meterView.isHidden = false
                break
            default:
                print("------- ERROR ------ Nav selected is out of bounds")
        }
        
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller
    }

    @IBAction func scheduleAlert(_ sender: Any) {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization
            
            
            // Handle if user granted permission
            
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey:
                "Lokey", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey:
                "Your parking meter has expired!", arguments: nil)
            
            // Deliver the notification in five seconds.
            content.sound = UNNotificationSound.default()
            
            
            let currentMin = Int(self.meterMin.text!)!
            let currentHr = Int(self.meterHour.text!)!
            
            let t = (currentMin * 60) + (currentHr * 3600)
            
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(t),
                                                            repeats: false)
            
            // Schedule the notification.
            let request = UNNotificationRequest(identifier: "CarMeter", content: content, trigger: trigger)
            center.add(request, withCompletionHandler: self.notificationScheduled)
            
        }
    }

    func notificationScheduled(err : Error?){
        self.notifyUser("Meter Started", "Your meter has been set successfully!")
    }
    
}
