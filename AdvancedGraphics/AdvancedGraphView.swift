//
//  AdvancedGraphView.swift
//  AdvancedGraphics
//
//  Created by Kirill Shteffen on 22/05/2018.
//  Copyright © 2018 Kirill Shteffen. All rights reserved.
//

import UIKit

@IBDesignable
class AdvancedGraphView: UIView {
    var graphPointsCalculator:((_ x:CGFloat) -> CGFloat)?
    
    @IBInspectable
    var scale: CGFloat = 20{ didSet { setNeedsDisplay() } }
    
    var originSet: CGPoint?{ didSet { setNeedsDisplay() } }
    private  var centerPoint: CGPoint  {
        get {
            return originSet ?? CGPoint(x: self.bounds.midX, y:self.bounds.midY)
        }
        set {
            originSet = newValue
        }
    }
    private var gesturingContentScaleFactor: CGFloat = 0.3
    private var localContentScaleFactor: CGFloat!
    private let userdefaults = UserDefaults.standard
    private struct Keys{
        static let ScaleAndOrigin = "GraphViewScaleAndOrigin"
    }
    
    func storeData (){
        let dataToSave = [scale, centerPoint.x, centerPoint.y]
        userdefaults.set(dataToSave, forKey: Keys.ScaleAndOrigin)
    }
    func restoreData(){
        if let dataToRestore = userdefaults.array(forKey: Keys.ScaleAndOrigin) as? [CGFloat],dataToRestore.count == 3
        {
            scale = dataToRestore[0]
            centerPoint = CGPoint(x: dataToRestore[1], y: dataToRestore[2])
        }
    }
    
    @objc
    func changeScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer){
        switch pinchRecognizer.state {
        case .began:
            localContentScaleFactor = gesturingContentScaleFactor
        case .changed:
            scale *= pinchRecognizer.scale
            pinchRecognizer.scale = 1
            case.ended:
            localContentScaleFactor = contentScaleFactor
            storeData()
        default:
            break
            }
    }
    
    @objc
    func moveGraph(byReactingTo panRecognizer: UIPanGestureRecognizer){
        switch panRecognizer.state {
        case .began:
            localContentScaleFactor = gesturingContentScaleFactor
        
        case .changed:
            let translation = panRecognizer.translation(in: self)
            if translation != CGPoint.zero {
                centerPoint.x += translation.x
                centerPoint.y += translation.y
                panRecognizer.setTranslation(CGPoint.zero, in: self)
            }
            case .ended:
                localContentScaleFactor = contentScaleFactor
                storeData()
        default: break
        }
    }
    
    @objc
    func jumpGraphToPoint(byReactingTo tapRecognizer:UITapGestureRecognizer){
        if tapRecognizer.state == .ended {
            centerPoint = tapRecognizer.location(in: self)
            storeData()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let axesDrawer = AxesDrawer()
        axesDrawer.drawAxes(in: bounds, origin: centerPoint, pointsPerUnit: scale)
        graphDrawer()
    }
    
    func graphDrawer() {
        var isFirstPoint = true
        let path = UIBezierPath()
        path.lineWidth = 5
        UIColor.red.setStroke()
        for x:CGFloat in stride(from: -500, to: 500, by: 0.3) {
            let y:CGFloat = graphPointsCalculator!(x)
            guard y.isFinite else {continue}
        if isFirstPoint{
            path.move(to: CGPoint(x:centerPoint.x+x*scale, y:centerPoint.y-y*scale))
            isFirstPoint = false
        }else{
                path.addLine(to: CGPoint(x:centerPoint.x+x*scale, y:centerPoint.y-y*scale))
            }
        }
        path.stroke()
    }
    
}
