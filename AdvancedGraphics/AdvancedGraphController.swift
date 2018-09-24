//
//  AdvancedGraphController.swift
//  AdvancedGraphics
//
//  Created by Kirill Shteffen on 22/05/2018.
//  Copyright © 2018 Kirill Shteffen. All rights reserved.
//

import UIKit

class AdvancedGraphController: UIViewController {
    
    @IBOutlet var AdvancedGraphView: AdvancedGraphView!{didSet{
        let handler = #selector(AdvancedGraphView.changeScale(byReactingTo:))
        let pinchRecognizer = UIPinchGestureRecognizer(target: AdvancedGraphView, action: handler)
        AdvancedGraphView.addGestureRecognizer(pinchRecognizer)
        
        let panHandler = #selector(AdvancedGraphView.moveGraph(byReactingTo:))
        let panRecognizer = UIPanGestureRecognizer(target: AdvancedGraphView, action: panHandler)
        AdvancedGraphView.addGestureRecognizer(panRecognizer)
        
        let doubleTapRecognizer = UITapGestureRecognizer(
            target: AdvancedGraphView, action: #selector(AdvancedGraphView.jumpGraphToPoint(byReactingTo:)))
        
        doubleTapRecognizer.numberOfTapsRequired = 2
        AdvancedGraphView.addGestureRecognizer(doubleTapRecognizer)
        updateUI()
        AdvancedGraphView.restoreData()
        }}
    
    
    
    var graphPointsCalculator: ((CGFloat) -> CGFloat)?{didSet{updateUI()}}
    func updateUI(){
        AdvancedGraphView?.graphPointsCalculator = graphPointsCalculator
    }
    /*override func viewDidLoad() {
     super.viewDidLoad()
     graphPointsCalculator = {cos($0)}
     }*/
}
