//
//  BuildingViewController.swift
//  parking-app
//
//  Created by Will Steiner on 11/2/16.
//
//

import UIKit

class BuildingViewController: UIViewController {
    
    var loop = Timer()
    private var state : State!
    private var instance : Instance!
    private var userDevice : Device!
    var location : Location!
    var isCurrent = false
    
    @IBOutlet var screenView: UIView!
    
    var currentActiveFloor = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
        self.instance = self.getInstance()
        if let carId : String = self.state.user.car {
            if let device : Device = self.state.getDevice(carId) {
                self.userDevice = device
            }
        }
        print("Structure loading")
    }
    
    struct S{
        var width : Double!
        var height : Double!
        var x: Double = 0.0
        var y: Double = 0.0
    }
    
    var screen = S()
    
    
    func demo(t : Timer){
        let data = t.userInfo as! NSDictionary
        self.drawBuilding(floors: data["floors"] as! Int, activeFloor: data["activeFloor"] as! Int, carPosition: data["carPosition"] as! String)
    }
    
    override func viewDidLayoutSubviews() {
        let bounds = self.screenView.bounds
        screen.height = Double(bounds.height)
        screen.width = Double(bounds.width)
    }
    
    func drawBuilding(floors: Int, activeFloor: Int, carPosition: String){
        
        // Clear previous rendering
        screenView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Set Screen default bg
        self.screenView.backgroundColor = UIColor.darkGray;
        
        struct Style{
            var marginTop : Double = 20;
            var marginBottom : Double = 20;
            var marginLeft : Double = 10;
            var marginRight : Double = 10;
            
            var inset : Double = 40;
            var offset : Double = 20;
            var floorHeight : Double = 60;
            
            let structureColor : UIColor = Utils.rgbToUIColor(r:45, g: 51, b:61)
            let floorColor : UIColor = Utils.rgbToUIColor(r:102, g: 106, b: 115)
            let activeFloorColor : UIColor = Utils.rgbToUIColor(r:228, g: 234, b:242)
            let terrianColor : UIColor = Utils.rgbToUIColor(r: 176, g: 204, b: 153)
            let skyColor : UIColor = Utils.rgbToUIColor(r: 189, g: 212, b: 222)
        }
        
        var style = Style()
        
        
        //-------------------------------------------- upper half of screenView  "floor overview"
        /*
        let carPos = carPosition
        
        let FPbase : Double = screen.height - (style.marginBottom + style.marginTop)
        let activeFloorplanLayer = CAShapeLayer()
        let activeFloorplan = UIBezierPath()
        
        activeFloorplan.move(to: CGPoint(x:style.marginLeft , y:FPbase))
        activeFloorplan.addLine(to: CGPoint(x: (style.marginLeft + style.inset), y: style.marginTop))
        activeFloorplan.addLine(to: CGPoint(x: screen.width - (style.marginLeft + style.inset), y: style.marginTop))
        activeFloorplan.addLine(to: CGPoint(x: screen.width - (style.marginLeft), y: FPbase))
        activeFloorplan.close()
        
        activeFloorplanLayer.path = activeFloorplan.cgPath
        activeFloorplanLayer.fillColor = style.floorColor.cgColor
        
        screenView.layer.addSublayer(activeFloorplanLayer)
        
        /*------- highlighted zone: NW,NE, SW, SE
         |   __________
         |   |        |
         |   | NW, NE |
         |   | SW, SE |
         |   |________|
         |
         
         TODO: make cases an enum
         ____________
         |   |           |
         |   | NW, N, NE |
         |   |  W, C, E  |
         |   | SW, S, SE |
         |   |___________|
         */
        
        let carMarkLayer = CAShapeLayer()
        let carMark = UIBezierPath()
        switch(carPos){
            
        case "ne":
            carMark.move(to: CGPoint(x: (screen.width / 2) - (0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            carMark.addLine(to: CGPoint(x: (screen.width / 2), y: style.marginTop))
            carMark.addLine(to: CGPoint(x: screen.width - (style.marginLeft + style.inset), y: style.marginTop))
            carMark.addLine(to: CGPoint(x: screen.width - (style.marginLeft + 0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            
            break;
        case "nw":
            carMark.move(to: CGPoint(x:(style.marginLeft + 0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            carMark.addLine(to: CGPoint(x: style.marginLeft + style.inset, y: style.marginTop))
            carMark.addLine(to: CGPoint(x: (screen.width / 2), y: style.marginTop))
            carMark.addLine(to: CGPoint(x: (screen.width / 2) + (0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            break;
        case "se":
            carMark.move(to: CGPoint(x:(screen.width / 2) - style.inset, y: FPbase))
            carMark.addLine(to: CGPoint(x: (screen.width / 2) - (0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            carMark.addLine(to: CGPoint(x: screen.width - (style.marginLeft + 0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            carMark.addLine(to: CGPoint(x:screen.width - style.marginRight, y: FPbase))
            
            break;
        case "sw":
            carMark.move(to: CGPoint(x:(style.marginLeft), y: FPbase))
            carMark.addLine(to: CGPoint(x:(style.marginLeft + 0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            carMark.addLine(to: CGPoint(x: (screen.width / 2) + (0.5 * style.inset), y: (screen.height / 2) - style.marginTop))
            carMark.addLine(to: CGPoint(x:(screen.width / 2) + style.inset, y: FPbase))
            break;
        default:
            //Center
            break;
        }
        carMark.close()
        
        carMarkLayer.path = carMark.cgPath
        
        screenView.layer.addSublayer(carMarkLayer)
        */
        //-------------------------------------------- lower half of screenView  "building overview"
        
        // floor settings
        
        let structBase : Double = (screen.height) - (style.marginBottom + style.marginTop);
        let activeFloorIndex : Int = activeFloor
        let floorCount : Int = floors
        var activeFloorLayer : CAShapeLayer!
        
        // foundation coordinates
        let x1 : Double = style.marginLeft;
        let x2 : Double = style.marginLeft + style.inset;
        let x3 : Double = screen.width - x1;
        let x4 : Double = screen.width - x2;
        var y1 : Double, y2 : Double, y3 : Double, y4 : Double
        style.floorHeight = min(((screen.height + style.marginBottom) / Double(floorCount)), style.floorHeight)
        
        
        //----- backdrop of building overview
        
        let terrianLayer = CAShapeLayer()
        let terrian = UIBezierPath()
        let skyLayer = CAShapeLayer()
        let sky = UIBezierPath()        
        y1 = structBase
        y2 = y1 - style.floorHeight
        y3 = y2
        y4 = y1
        
        let bottomOfCanvas = (screen.height)
        let horizon = structBase - (style.floorHeight + style.offset)
        
        terrian.move(to: CGPoint(x: 0, y: bottomOfCanvas!))
        terrian.addLine(to: CGPoint(x: 0, y:horizon))
        terrian.addLine(to: CGPoint(x: screen.width, y: horizon))
        terrian.addLine(to: CGPoint(x: screen.width, y: bottomOfCanvas!))
        terrian.close()
        
        
        terrianLayer.path = terrian.cgPath
        terrianLayer.fillColor = style.terrianColor.cgColor
        
        screenView.layer.addSublayer(terrianLayer)
        
        sky.move(to: CGPoint(x:0, y: horizon))
        sky.addLine(to: CGPoint(x:0, y:0))
        sky.addLine(to: CGPoint(x:screen.width, y:0))
        sky.addLine(to: CGPoint(x:screen.width, y:horizon))
        sky.close()
        
        skyLayer.path = sky.cgPath
        skyLayer.fillColor = style.skyColor.cgColor
        
        screenView.layer.addSublayer(skyLayer)
        
        
        
        
        //------------------------------- building
        
        //---- foundation along with North and West walls
        let structureLayer = CAShapeLayer()
        let structure = UIBezierPath()
        
        let topFloorY1 = (structBase - Double(floorCount - 1) * (style.floorHeight - style.offset))
        let topFloorY2 = (structBase - Double(floorCount) * (style.floorHeight - style.offset)) - style.offset
        
        structure.move(to: CGPoint(x:style.marginLeft, y:structBase))
        structure.addLine(to: CGPoint(x:x1, y:topFloorY1 - (style.floorHeight - style.offset)))
        structure.addLine(to: CGPoint(x:x2, y:topFloorY2 - (style.floorHeight - style.offset)))
        structure.addLine(to: CGPoint(x:x3, y:topFloorY2 - (style.floorHeight - style.offset)))
        structure.addLine(to: CGPoint(x:x3, y:structBase - (style.floorHeight)))
        structure.addLine(to: CGPoint(x:x4, y:structBase))
        structure.close()
        
        structureLayer.path = structure.cgPath
        structureLayer.strokeColor = UIColor.darkGray.cgColor
        structureLayer.fillColor = style.structureColor.cgColor
        screenView.layer.addSublayer(structureLayer)
        
        //----- floors
        var scaler : Double
        for f in 0..<floorCount {
            let floorLayer = CAShapeLayer()
            let floor = UIBezierPath()
            scaler = Double(f);
            
            y1 = structBase - (scaler * (style.floorHeight - style.offset))
            y2 = y1 - style.floorHeight
            y3 = y2
            y4 = y1
            
            floor.move(to: CGPoint(x: x1, y:y1))
            floor.addLine(to: CGPoint(x: x2, y:y2))
            floor.addLine(to: CGPoint(x: x3, y:y3))
            floor.addLine(to: CGPoint(x: x4, y:y4))
            floor.close()
            
            floorLayer.fillColor = style.floorColor.withAlphaComponent(1).cgColor
            floorLayer.strokeColor = UIColor.white.cgColor
            screenView.layer.addSublayer(floorLayer)
            
            floorLayer.path = floor.cgPath
            screenView.layer.addSublayer(floorLayer)
            
            if(f == activeFloorIndex){
                activeFloorLayer = CAShapeLayer()
                let activeFloor = UIBezierPath()
                
                activeFloor.move(to: CGPoint(x: x1, y:y1))
                activeFloor.addLine(to: CGPoint(x: x1, y:y1 - (style.floorHeight - style.offset)))
                activeFloor.addLine(to: CGPoint(x: x2, y:y2 - (style.floorHeight - style.offset)))
                activeFloor.addLine(to: CGPoint(x: x3, y:y3 - (style.floorHeight - style.offset)))
                activeFloor.addLine(to: CGPoint(x: x3, y:y3))
                activeFloor.addLine(to: CGPoint(x: x4, y:y4))
                activeFloor.addLine(to: CGPoint(x: x1, y:y1))
                
                activeFloor.close()
                
                activeFloorLayer.path = activeFloor.cgPath
                activeFloorLayer.fillColor = style.activeFloorColor.cgColor
                activeFloorLayer.strokeColor = style.activeFloorColor.cgColor
                screenView.layer.addSublayer(activeFloorLayer)
            }
            
        }
        
        //----- South side of building
        let frontWallLayer = CAShapeLayer()
        let frontWall = UIBezierPath()
        frontWall.move(to: CGPoint(x:x1, y:structBase))
        frontWall.addLine(to: CGPoint(x:x1, y:structBase - Double(max((floorCount - 1), 0)) * (style.floorHeight - style.offset) - (style.floorHeight - style.offset)))
        frontWall.addLine(to: CGPoint(x:x4, y:structBase - Double(max((floorCount - 1), 0)) * (style.floorHeight - style.offset) - (style.floorHeight - style.offset)))
        frontWall.addLine(to: CGPoint(x:x4, y:structBase))
        frontWall.close()
        frontWallLayer.path = frontWall.cgPath
        frontWallLayer.strokeColor = style.structureColor.cgColor
        frontWallLayer.fillColor = style.structureColor.withAlphaComponent(0.25).cgColor
        
        screenView.layer.addSublayer(frontWallLayer)
        
        // North side of building
        let sideWallLayer = CAShapeLayer()
        let sideWall = UIBezierPath()
        sideWall.move(to: CGPoint(x:x4, y:structBase))
        sideWall.addLine(to: CGPoint(x:x4, y:structBase - Double(max((floorCount - 1), 0)) * (style.floorHeight - style.offset) - (style.floorHeight - style.offset)))
        sideWall.addLine(to: CGPoint(x:x3, y:(structBase - Double(floorCount) * (style.floorHeight - style.offset) - style.offset) - (style.floorHeight - style.offset)))
        sideWall.addLine(to: CGPoint(x:x3, y:structBase - (style.floorHeight)))
        sideWall.close()
        sideWallLayer.path = sideWall.cgPath
        sideWallLayer.strokeColor  = style.structureColor.cgColor
        sideWallLayer.fillColor = style.structureColor.withAlphaComponent(0.8).cgColor
        
        screenView.layer.addSublayer(sideWallLayer)
        
        
        //------------------------------------------ Animations
        
        /*
        let introAnimation = CABasicAnimation(keyPath: "fillColor")
        introAnimation.duration = 2;
        introAnimation.fromValue = style.structureColor.withAlphaComponent(1).cgColor
        introAnimation.toValue = style.structureColor.withAlphaComponent(0.25).cgColor
        introAnimation.repeatCount = 0;
        introAnimation.autoreverses = false;
        introAnimation.fillMode = kCAFillModeForwards;
        introAnimation.isRemovedOnCompletion = false;
        frontWallLayer.add(introAnimation, forKey: "fillColor")*/
        
        let pulseFloorAnimation = CABasicAnimation(keyPath: "fillColor")
        pulseFloorAnimation.timeOffset = CACurrentMediaTime()
        pulseFloorAnimation.duration = 2.0;
        pulseFloorAnimation.fromValue = style.activeFloorColor.withAlphaComponent(1).cgColor
        pulseFloorAnimation.toValue = style.activeFloorColor.withAlphaComponent(0.25).cgColor
        pulseFloorAnimation.repeatCount = .infinity;
        pulseFloorAnimation.autoreverses = false;
        pulseFloorAnimation.fillMode = kCAFillModeForwards;
        pulseFloorAnimation.isRemovedOnCompletion = false;
        
        if(activeFloorIndex > -1){
          activeFloorLayer.add(pulseFloorAnimation, forKey: "fillColor")
        }
        //carMarkLayer.add(pulseFloorAnimation, forKey: "fillColor")
    }
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        if location != nil {
            if userDevice != nil && isCurrent {
                self.currentActiveFloor = instance.getRelativeFloor(location: self.location, altitude: userDevice.currentAltitude)
            }
            self.drawBuilding(floors: location.building.floors.count, activeFloor: self.currentActiveFloor, carPosition: "nw")
        }
        
        if isCurrent {
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(drawLoop), userInfo: nil, repeats: true)
        }
        
        
        //Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(self.demoLoop), userInfo: nil, repeats: true)
        //self.demoLoop();
    }
    
    func drawLoop() {
        if location == nil {
            if let loc = state.getCurrentLocation() {
                self.location = loc
            }
        } else {
            if (userDevice != nil) && isCurrent {
                self.currentActiveFloor = self.instance.getRelativeFloor(location: location, altitude: userDevice.currentAltitude)
            }
            self.drawBuilding(floors: location.building.floors.count, activeFloor: self.currentActiveFloor, carPosition: "nw")
        }
    }
    
    func demoLoop(){
        
        let f = randRange(lower: 1, upper: 10);
        let a = randRange(lower: 1, upper: UInt32(f));
        Timer.scheduledTimer(timeInterval: 0, target: self, selector: #selector(self.demo), userInfo: ["floors": f, "activeFloor": a, "carPosition": "nw"], repeats: false)
        
        let f2 = randRange(lower: 1, upper: 10);
        let a2 = randRange(lower: 1, upper: UInt32(f2));
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.demo), userInfo: ["floors": f2, "activeFloor": a2, "carPosition": "ne"], repeats: false)
        
        let f3 = randRange(lower: 1, upper: 10);
        let a3 = randRange(lower: 1, upper: UInt32(f3));
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.demo), userInfo: ["floors": f3, "activeFloor": a3, "carPosition": "se"], repeats: false)
        
        let f4 = randRange(lower: 1, upper: 10);
        let a4 = randRange(lower: 1, upper: UInt32(f4));
        Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(self.demo), userInfo: ["floors": f4, "activeFloor": a4, "carPosition": "sw"], repeats: false)
    }
    
    func randRange (lower: UInt32 , upper: UInt32) -> Int {
        return Int(lower + arc4random_uniform(upper - lower + 1))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    
}
