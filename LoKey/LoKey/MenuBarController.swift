//
//  MenuBarController.swift
//  LoKey
//
//  Created by Will Steiner on 1/7/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class MenuBarController: UITabBarController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        if let id = self.getState().user.car{
            if let car = self.getState().getDevice(id){
                if car.currentPosition != nil {
                    self.selectedIndex = 0
                    return;
                }
            }
        }
        self.selectedIndex = 1
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
