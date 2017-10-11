//
//  AppDelegate.swift
//  routes
//
//  Created by Will Steiner on 4/9/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var instance : Instance!
    var platform : Platform!

    let API_KEY = "AIzaSyCX3akZA77JAnA35uPibH7cEaghmZCBw1M"

    override init(){
        
    }
    
    func getInstance()-> Instance{
        return self.instance
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.platform = Platform(deviceKey: UIDevice.current.identifierForVendor!.uuidString)
        GMSServices.provideAPIKey(API_KEY)
        self.instance = Instance(self.platform)
        self.instance.log("-- app did finish launching", LOG_LEVEL.log)
        return true
    }

    
    func newState(_ newState : [String:AnyObject]){
        self.instance.loadState(newState)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        self.instance.saveState()
        self.instance.syncWithPlatform()
        self.instance.log("-- app will resign activity")
        self.instance.stopAssesmentLoop()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
        self.instance.log("!!! app about to be unavailable", LOG_LEVEL.log)
        //self.instance.locationManager.requestLocation()
        //self.instance.locationManager.startUpdatingLocation()
        self.instance.events.append(
            Event(
                timestamp: Fmt.getTimestamp(),
                type: EVENT_TYPE.status,
                entityType: ENTITY_TYPE.user,
                entityId: self.instance.getState().user.email,
                data: "suspending" as AnyObject
            )
        )
        self.instance.syncWithPlatform()
        //self.instance.locationManager.startUpdatingLocation() // Wake up yo
        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.startBGMonitoring), userInfo: nil, repeats: false)
    }
    
    var bgTask: UIBackgroundTaskIdentifier!
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.instance.log("-- app entered background", LOG_LEVEL.log)
        self.startBGMonitoring()
        
        self.instance.isRunningInBackground = true
        self.instance.events.append(
            Event(
                timestamp: Fmt.getTimestamp(),
                type: EVENT_TYPE.status,
                entityType: ENTITY_TYPE.user,
                entityId: self.instance.getState().user.email,
                data: "background" as AnyObject
            )
        )
        self.instance.syncWithPlatform()
        //self.platform.proclaimBackground()
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    @objc func startBGMonitoring(){
        
        self.instance.log("-- Start assesment loop", LOG_LEVEL.log);
        //self.instance.locationManager.stopUpdatingLocation()
        self.instance.startAssesmentLoop()
        self.bgTask = UIBackgroundTaskInvalid
        self.bgTask = UIApplication.shared.beginBackgroundTask(withName: "lokey", expirationHandler: {
            self.instance.log("-- BG TASK EXPIRED", LOG_LEVEL.log)
            self.instance.stopAssesmentLoop()
            self.bgTask = UIBackgroundTaskInvalid
            self.instance.log("-- init another bg task")
        })
        
        /*
         DispatchQueue.global(qos: .background).async {
         self.instance.log("assesment loop dispatched", LOG_LEVEL.log);
         self.instance.startAssesmentLoop()
         }*/
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.instance.stopAssesmentLoop()
        //self.instance.loadState()
        self.instance.log("-- app will enter foreground", LOG_LEVEL.log)
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        self.instance.log("-- app did become active", LOG_LEVEL.log)
        self.instance.isRunningInBackground = false
        self.instance.startAssesmentLoop()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.instance.log("-- app will terminate", LOG_LEVEL.log)
        instance.saveState()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

