
import UIKit
import XCPlayground


struct S{
    var width : Double = 320
    var height : Double = 480
    var x: Double = 0.0
    var y: Double = 0.0
}
let screen = S()
let screenView = UIView(frame: CGRect(x: screen.x, y: screen.y, width: screen.width, height: screen.height))
screenView.backgroundColor = UIColor.white;

XCPShowView(identifier: "Screen", view: screenView)

struct Style{
    var marginTop : Double = 10;
    var marginBottom : Double = 45;
    var marginLeft : Double = 10;
    var marginRight : Double = 10;
    
    var inset : Double = 40;
    var offset : Double = 20;
    var floorHeight : Double = 60;
    
    let structureColor : UIColor = UIColor.darkGray
    let floorColor : UIColor = UIColor.gray
    let activeFloorColor : UIColor = UIColor.green
}

let style = Style()

let structBase : Double = screen.height - style.marginBottom;
var scaler : Double
let activeFloorIndex : Int = 3
let floorCount : Int = 5
let structureLayer = CAShapeLayer()
let structure = UIBezierPath()
let frontWallLayer = CAShapeLayer()
let frontWall = UIBezierPath()
let sideWallLayer = CAShapeLayer()
let sideWall = UIBezierPath()
var activeFloorLayer : CAShapeLayer!

// Base Coordinates
let x1 : Double = style.marginLeft;
let x2 : Double = style.marginLeft + style.inset;
let x3 : Double = screen.width - x1;
let x4 : Double = screen.width - x2;
var y1 : Double, y2 : Double, y3 : Double, y4 : Double

structure.move(to: CGPoint(x:x1, y:structBase))
structure.addLine(to: CGPoint(x:x1, y:structBase - (Double(floorCount - 3) * (style.floorHeight + style.offset))))
structure.addLine(to: CGPoint(x:x2, y:structBase - (Double(floorCount - 2) * (style.floorHeight))))
structure.addLine(to: CGPoint(x:x3, y:structBase - (Double(floorCount - 2) * (style.floorHeight))))
structure.addLine(to: CGPoint(x:x3, y:structBase - (style.floorHeight)))
structure.addLine(to: CGPoint(x:x4, y:structBase))
structure.close()

structureLayer.path = structure.cgPath
structureLayer.strokeColor = UIColor.darkGray.cgColor
structureLayer.fillColor = style.structureColor.cgColor
screenView.layer.addSublayer(structureLayer)

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

    floorLayer.strokeColor = UIColor.white.cgColor
    if(f == activeFloorIndex){
        floorLayer.fillColor = style.activeFloorColor.cgColor
        activeFloorLayer = floorLayer
    }
    else { floorLayer.fillColor = style.floorColor.withAlphaComponent(1).cgColor }

    
    floorLayer.path = floor.cgPath
    screenView.layer.addSublayer(floorLayer)
}

frontWall.move(to: CGPoint(x:x1, y:structBase))
frontWall.addLine(to: CGPoint(x:x1, y:structBase - (Double(floorCount - 3) * (style.floorHeight))))
frontWall.addLine(to: CGPoint(x:x4, y:structBase - (Double(floorCount - 3) * (style.floorHeight))))
frontWall.addLine(to: CGPoint(x:x4, y:structBase))
frontWall.close()

frontWallLayer.path = frontWall.cgPath
frontWallLayer.strokeColor = UIColor.white.cgColor
frontWallLayer.fillColor = style.structureColor.cgColor
screenView.layer.addSublayer(frontWallLayer)


sideWall.move(to: CGPoint(x:x4, y:structBase - (Double(floorCount - 3) * (style.floorHeight))))
sideWall.addLine(to: CGPoint(x:x3, y:structBase - (Double(floorCount - 2) * (style.floorHeight))))
sideWall.addLine(to: CGPoint(x:x3, y:structBase - (style.floorHeight)))
sideWall.addLine(to: CGPoint(x:x4, y:structBase))
sideWall.close()

sideWallLayer.path = sideWall.cgPath
sideWallLayer.strokeColor = UIColor.white.cgColor
sideWallLayer.fillColor = style.structureColor.withAlphaComponent(0.8).cgColor
screenView.layer.addSublayer(sideWallLayer)

let introAnimation = CABasicAnimation(keyPath: "fillColor")
introAnimation.duration = 2;
introAnimation.fromValue = style.structureColor.withAlphaComponent(1).cgColor
introAnimation.toValue = style.structureColor.withAlphaComponent(0.0).cgColor
introAnimation.repeatCount = 0;
introAnimation.autoreverses = false;
introAnimation.fillMode = kCAFillModeForwards;
introAnimation.isRemovedOnCompletion = false;
frontWallLayer.add(introAnimation, forKey: "fillColor")

let pulseFloorAnimation = CABasicAnimation(keyPath: "fillColor")
pulseFloorAnimation.timeOffset = CACurrentMediaTime()
pulseFloorAnimation.duration = 2.0;
pulseFloorAnimation.fromValue = style.activeFloorColor.withAlphaComponent(1).cgColor
pulseFloorAnimation.toValue = style.activeFloorColor.withAlphaComponent(0.6).cgColor
pulseFloorAnimation.repeatCount = .infinity;
pulseFloorAnimation.autoreverses = false;
pulseFloorAnimation.fillMode = kCAFillModeForwards;
pulseFloorAnimation.isRemovedOnCompletion = false;
activeFloorLayer.add(pulseFloorAnimation, forKey: "fillColor")
