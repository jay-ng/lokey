//: Playground - noun: a place where people can play

import UIKit


struct S{
    var width : Double = 375.0
    var height : Double = 667.0
    var x: Double = 0.0
    var y: Double = 0.0
}
let screen = S()

let screenView = UIView(frame: CGRect(x: screen.x, y: screen.y, width: screen.width, height: screen.height))

let layer = CAShapeLayer()
layer.path = UIBezierPath(roundedRect: CGRect(x: 64, y: 64, width: 160, height: 160), cornerRadius: 50).cgPath
layer.fillColor = UIColor.red.cgColor
screenView.layer.addSublayer(layer)
