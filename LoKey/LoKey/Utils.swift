//
//  Utils.swift
//  LoKey
//
//  Created by Will Steiner on 2/2/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation
import UIKit


class Utils {
    static let primaryColor = rgbToUIColor(r: 27, g:20, b:100)
    static let secondaryColor = rgbToUIColor(r: 230, g:230, b:230)
    public static func rgbToUIColor(r: Int, g: Int, b:Int) -> UIColor{
        return UIColor.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0 )
    }
    
    static let loggingEnabled : Bool = true
}


extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    func dismissKeyboard() {
        view.endEditing(true)
    }
    func notifyUser(_ title: String, _ message: String){
        let notifyDialog = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        notifyDialog.addAction(UIAlertAction(title: "Close", style: .default, handler: { (action: UIAlertAction!) in
            return;
        }))
        present(notifyDialog, animated: true, completion: nil)
    }
    
    func getState() -> State{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.getInstance().getState()
    }
    
    func forcePush(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.getInstance().pushState()
    }
    
    func getPlatform() -> Platform{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.platform
    }
    
    func getInstance() -> Instance{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.instance
    }
    
    func getCurrentCoordinate() -> Coordinate{
         let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let fallbackCoordinate : Coordinate = Coordinate(lat: 37.546831, lng:-77.450360)
        if let c : Coordinate = appDelegate.getInstance().getCurrentCoordinate(){
            return c
        } else {
            return fallbackCoordinate
        }
    }
    
    func saveState() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.getInstance().saveState()
    }
    
    func trackLocation(_ location : Location){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.getInstance().trackLocation(location)
    }
    
    // UI runtime logging
    func log(_ message : String){
        self.log(message, LOG_LEVEL.debug)
    }
    
    func log(_ message : String, _ level: LOG_LEVEL ){
            print(message)
    }
}
