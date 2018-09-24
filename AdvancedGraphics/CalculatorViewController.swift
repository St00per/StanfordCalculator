//
//  ViewController.swift
//  Calculator
//
//  Created by kirill shteffen on 21/02/2018.
//  Copyright © 2018 kirill shteffen. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    
    
    @IBOutlet weak var display: UILabel!
    
    @IBOutlet weak var GraphBtn: UIButton!{
        didSet {
            GraphBtn.isEnabled = false
            GraphBtn.backgroundColor = UIColor.white
        }
    }
    
        override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedProgram = program as? [Any]{
            brain.program = savedProgram as PropertyList
            displayResult = brain.evaluate(using: variables)
            if let programLoading = splitViewController?.viewControllers.last?.contentViewController as? AdvancedGraphController{
                programLoading.graphPointsCalculator  = { [weak weakSelf = self] x in
                    let variablesDictionary: [String: Double] = ["M": Double(x)]
                    return CGFloat((weakSelf?.brain.evaluate(using: variablesDictionary).result)!) }
                programLoading.navigationItem.title = self.brain.evaluate().description
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !brain.evaluate(using: variables).isPending{
            program = brain.program
        }
    }
    
    var userIsInTheMiddleOfTyping = false
    let formatter:NumberFormatter={
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        return formatter
    }()
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if digit.contains("."),textCurrentlyInDisplay.contains("."){return}
            else {display.text = textCurrentlyInDisplay + digit}
        }else{
            if digit.contains("."){display.text = "0."}
            else{display.text = digit}
            userIsInTheMiddleOfTyping = true
        }
    }
    
    var displayResult: (result: Double?, isPending: Bool,
        description: String,error:String?) = (nil, false," ",nil){
        didSet {
            
            GraphBtn.isEnabled = !displayResult.isPending
            GraphBtn.backgroundColor = displayResult.isPending ? UIColor.white : UIColor.groupTableViewBackground
            
            switch displayResult {
            case (nil, _, " ",nil) : displayValue = 0
            case (let result, _,_,nil): displayValue = result ?? 0
            case (_,_,_,let error): display.text = error!
            }
            
            descriptionDisplay.text = displayResult.description != " " ?
                displayResult.description + (displayResult.isPending ? " …" : " =") : " "
            //variableValue.text = formatter.string(from: NSNumber(value:variables["M"] ?? 0))
        }
    }
    
    var displayValue: Double{
        get {
            return Double(display.text!)!
        }
        set{
            display.text = formatter.string(from: NSNumber(value:newValue))
        }
    }
    private var brain: CalculatorBrain = CalculatorBrain()
    private var variables = [String: Double]()
    
    private let defaults = UserDefaults.standard
    private struct Keys {
        static let Program = "CalculatorViewController.Program"
    }
    
    typealias PropertyList = AnyObject
    private var program: PropertyList? {
        get{return defaults.object(forKey: Keys.Program) as PropertyList?}
        set{defaults.set(newValue, forKey: Keys.Program)}
    }
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping{
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        if  let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayResult = brain.evaluate(using: variables)
    }
    
    
    //@IBOutlet weak var variableValue: UILabel!
    @IBAction func onMemory(_ sender: UIButton) {
        
        if let key = sender.currentTitle
        {   if key == "→M" {
            variables = ["M": displayValue]
            displayResult = brain.evaluate(using: variables)
            userIsInTheMiddleOfTyping=false
        } else {
            brain.setOperand(variable: "M")
            displayResult = brain.evaluate()
            userIsInTheMiddleOfTyping=false
            }
        }
    }
    
    @IBOutlet weak var descriptionDisplay: UILabel!
    @IBAction func Clear(_ sender: UIButton) {
        userIsInTheMiddleOfTyping=false
        brain.clearProgram()
        display.text = "0"
        descriptionDisplay.text! = " "
        //variableValue.text! = "0"
        variables = [:]
        GraphBtn.isEnabled = false
        GraphBtn.backgroundColor = UIColor.white
    }
    @IBAction func Backspace(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            guard !display.text!.isEmpty else { return }
            display.text = String (display.text!.dropLast())
            if display.text!.isEmpty{
                userIsInTheMiddleOfTyping = false
                displayResult = brain.evaluate(using: variables)
            }
        } else {
            brain.undo()
            displayResult = brain.evaluate(using: variables)
            
        }}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController = segue.destination
        if let navigationController = destinationViewController as? UINavigationController {
            destinationViewController = navigationController.visibleViewController ?? destinationViewController
        }
        if let advancedGraphController = destinationViewController as? AdvancedGraphController {
            if let identifier = segue.identifier {
                if identifier == "graph" {
                    advancedGraphController.graphPointsCalculator  = { [weak weakSelf = self] x in
                        let variablesDictionary: [String: Double] = ["M": Double(x)]
                        return CGFloat((weakSelf?.brain.evaluate(using: variablesDictionary).result)!) }
                    advancedGraphController.navigationItem.title = self.brain.evaluate().description
                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "graph" {
            return !brain.evaluate(using: variables).isPending
        }
        return false
    }
}
    extension UIViewController{
        var contentViewController: UIViewController{
            if let navcon = self as? UINavigationController{
                return navcon.visibleViewController ?? self} else{
                return self
            }
        }
}

