//
//  LevelView.swift
//  MidiGestures
//
//  Created by D on 2017-07-05.
//  Copyright © 2017 Diego Lavalle. All rights reserved.
//

import UIKit

@IBDesignable
class LevelView: UIView {
    @IBInspectable var fillColor: UIColor = UIColor.black
    
    @IBInspectable var levely = CGFloat(100) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var subLayer:CAShapeLayer?
    override func draw(_ rect: CGRect) {
        // Drawing code
        let origin = CGPoint(x: bounds.origin.x, y: levely)
        let size = CGSize(width: bounds.size.width, height: bounds.size.height - levely)
        let path = UIBezierPath(rect: CGRect(origin: origin, size: size))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        //change the fill color
        shapeLayer.fillColor = fillColor.cgColor
        if subLayer == nil {
            layer.addSublayer(shapeLayer)
        } else {
            layer.replaceSublayer(subLayer!, with: shapeLayer)
        }
        subLayer = shapeLayer
    }
}

