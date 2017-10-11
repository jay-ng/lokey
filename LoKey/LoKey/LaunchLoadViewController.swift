//
//  LaunchLoadViewController.swift
//  LoKey
//
//  Created by Will Steiner on 3/10/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class LaunchLoadViewController: UIViewController, PlatformLoadDelegate {

    private var instance : Instance!
    private var platform : Platform!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.instance = self.getInstance()
        self.platform = self.getPlatform()
        self.platform.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
       print("- START LOAD\n")
        platform.initLogin(UIDevice.current.identifierForVendor!.uuidString)
    }
    
    func newState(_ newState : [String:AnyObject]){
        print("--- NEW STATE ---")
        self.instance.loadState(newState)
    }
    
    func anonLogin(success:Bool){
        if(success){
            print("--- Anon Logged ---\n")
            platform.handshake();
        } else {
            self.notifyUser("Server Error", "Lokey is currently unavailable. Please try again later.")
        }
    }
    
    func stateLoad(success: Bool){
        print("--- LOAD FINISHED ---\n")
        if(success){            
            self.instance.events.append(
                Event(
                    timestamp: Fmt.getTimestamp(),
                    type: EVENT_TYPE.status,
                    entityType: ENTITY_TYPE.user,
                    entityId: self.getState().user.email,
                    data: "launch" as AnyObject
                )
            )

            

            self.instance.isvalid = true
            self.start()
            performSegue(withIdentifier: "stateLoaded", sender: nil)
        } else {
            self.notifyUser("Server Error", "Lokey is currently unavailable. Please try again later.")
        }
    }
    
    func start(){
        self.instance.run()
        self.instance.events.append(
            Event(
                timestamp: Fmt.getTimestamp(),
                type: EVENT_TYPE.status,
                entityType: ENTITY_TYPE.user,
                entityId: self.getState().user.email,
                data: "start running" as AnyObject
            )
        )
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
