//
//  LevelView.swift
//  MidiGestures
//
//  Created by D on 2017-07-05.
//  Copyright © 2017 Diego Lavalle. All rights reserved.
//

import UIKit

@IBDesignable
class CircleView: UIView {
    @IBInspectable var fillColor: UIColor = UIColor.blue
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.maxX, bounds.maxY) / 2
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer.fillColor = fillColor.cgColor
        
        layer.addSublayer(shapeLayer)
    }
}

