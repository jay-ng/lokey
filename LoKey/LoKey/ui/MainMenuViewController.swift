//
//  MainMenuViewController.swift
//  LoKey
//
//  Created by Will Steiner on 11/14/16.
//  Copyright © 2016 Will Steiner. All rights reserved.
//

import UIKit


struct navBarStruct {
    var height : Double = 40.0
}

struct layoutStruct {
    
    var canvasHeight : Double = 0.0
    var canvasWidth : Double = 0.0
    
    var navBar = navBarStruct()
}



class MainMenuViewController: UIViewController {

    var canvas : UIView = UIView()
    var layout : layoutStruct = layoutStruct()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad");
    }
    
    override func viewDidLayoutSubviews() {
        self.layout.canvasHeight = Double(self.view.bounds.height)
        self.layout.canvasWidth = Double(self.view.bounds.width)
        canvas = UIView(frame: CGRect(x: 0, y: 0, width: self.layout.canvasWidth, height: self.layout.canvasHeight))
        print("layoutSubviews");
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
