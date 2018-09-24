//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by yakov shteffen on 27/03/2018.
//  Copyright © 2018 kirill shteffen. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    let formatter:NumberFormatter={
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        return formatter
    }()
    
    private enum OperationCase {
        case operand(Double)
        case operation(String)
        case variable(String)
        
    }
    
    private var operationLine = [OperationCase]()
    
    mutating func setOperand (_ operand: Double){
        operationLine.append(OperationCase.operand(operand))
        print(operand)
    }
    
    mutating func setOperand(variable named: String) {
        operationLine.append(OperationCase.variable(named))
        print(named)
    }
    
    mutating func performOperation(_ symbol: String) {
        operationLine.append(OperationCase.operation(symbol))
        print(symbol)
    }
    
    mutating func clearProgram() {
        operationLine.removeAll()
    }
    
    mutating func undo() {
        if !operationLine.isEmpty {
            operationLine = Array(operationLine.dropLast())
        }
    }
    
    typealias  PropertyList = AnyObject
    var program: PropertyList {
        get{
          var propertyListProgram = [Any]()
            for op in operationLine{
                switch op{
                case .operand(let operand):
                    propertyListProgram.append(operand as Any)
                case .operation(let operation):
                    propertyListProgram.append (operation as Any)
                case .variable(let symbol):
                    propertyListProgram.append(symbol as Any)
                }
            }
            return propertyListProgram as PropertyList
        }
        set {
            clearProgram()
            if let arrayOfAny = newValue as?[Any]{
                for op in arrayOfAny {
                    if let operand = op as? Double{
                        operationLine.append(OperationCase.operand(operand))
                    }
                    else if let symbol = op as? String {
                        if operations[symbol] != nil {
                            operationLine.append(OperationCase.operation(symbol))
                        }else{
                            operationLine.append(OperationCase.variable(symbol))
                        }
                    }
                }
            }
        }
    }
    
    func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String,error: String?)
    {
        
        var error: String?
        var accumulator: Double?
        var firstOperandAndSymbol:String?
        var description:String?
        var pendingBinaryOperation: PendingBinaryOperation?
        var resultIsPending: Bool {
            get {
                return pendingBinaryOperation != nil
            }
        }
        
        var descriptionValue: Double{
            get {
                return Double()
            }
            set{
                if description != nil {
                    description! += formatter.string(from: NSNumber(value:newValue))!
                }
                else{
                    description=formatter.string(from: NSNumber(value:newValue))
                }
            }
        }
        var result: Double?{
            get{
                return accumulator
            }
        }
        
        func setOperand(_ operand:Double){
            if !resultIsPending {
                description=nil
            }
            accumulator = operand
            descriptionValue = accumulator!
        }
        
        func setOperand (variable named: String) {
            accumulator = variables?[named] ?? 0
            if description != nil {
                description! += named}else{description=named}
        }
        
        func performPendingBinaryOperation(){
            if pendingBinaryOperation != nil && accumulator != nil {
                error = pendingBinaryOperation!.validate(with: accumulator!)
                accumulator = pendingBinaryOperation!.perform(with: accumulator!)
                pendingBinaryOperation=nil
            }
        }
        
        func performOperation(_ symbol: String){
            if let operation = operations[symbol] {
                switch operation {
                case.random(let function):
                    if resultIsPending{
                        accumulator=function()
                        descriptionValue=accumulator!
                    }else{
                        accumulator=function()
                        description = symbol}
                case.constant(let value):
                    if resultIsPending{
                        accumulator = value
                        performPendingBinaryOperation()
                        description! += symbol
                    }else{
                        accumulator = value
                        description = symbol}
                case.unaryOperation(let function,let validator):
                    if accumulator != nil {
                        error = validator?(accumulator!)
                        if resultIsPending{
                            let operand:Double=accumulator!
                            accumulator = function(accumulator!)
                            description = firstOperandAndSymbol!+symbol+"(\(operand))"
                        }
                        else{
                            let operand:String = description!
                            accumulator = function(accumulator!)
                            description = symbol
                            description! += "(\(operand))"
                        }
                    }
                case.binaryOperation(let function,let validator):
                    performPendingBinaryOperation()
                    if accumulator != nil{
                        pendingBinaryOperation=PendingBinaryOperation(function:function, firstOperand: accumulator!,validator: validator)
                        description! += symbol
                        firstOperandAndSymbol=description
                        accumulator = nil
                    }
                case.equals:
                    performPendingBinaryOperation()
                }
            }
        }
        guard !operationLine.isEmpty else {return (nil,false," ",nil)}
        for op in operationLine {
            switch op{
            case .operand(let operand):
                setOperand(operand)
            case .operation(let operation):
                performOperation(operation)
            case .variable(let symbol):
                setOperand (variable:symbol)
            }
        }
        return (result, resultIsPending, description ?? " ",error)
    }    
    private enum Operation {
        case random(()->Double)
        case constant(Double)
        case unaryOperation((Double) ->Double,((Double) -> String?)?)
        case binaryOperation((Double,Double) ->Double,((Double, Double) -> String?)?)
        case equals
    }
    
    private var operations: Dictionary<String,Operation> =
        [
            "rnd":Operation.random(drand48),
            "π":Operation.constant(Double.pi),
            "e":Operation.constant(M_E),
            "√":Operation.unaryOperation(sqrt,{ $0 < 0 ? "√ отриц. числа" : nil }),
            "cos":Operation.unaryOperation(cos,nil),
            "sin":Operation.unaryOperation(sin,nil),
            "log":Operation.unaryOperation(log,nil),
            "±":Operation.unaryOperation({-$0},nil),
            "×":Operation.binaryOperation(*,nil),
            "÷":Operation.binaryOperation(/,{ $1 == 0.0 ? "Деление на нoль" : nil }),
            "+":Operation.binaryOperation(+,nil),
            "−":Operation.binaryOperation(-,nil),
            "=":Operation.equals
    ]
    struct PendingBinaryOperation{
        let function:(Double,Double)->Double
        let firstOperand: Double
        var validator: ((Double,Double)->String?)?
        
        func perform(with secondOperand: Double)->Double{
            return function(firstOperand,secondOperand)
        }
        func validate(with secondOperand: Double) -> String? {
            guard let validator = validator  else {return nil}
            return validator (firstOperand, secondOperand)
        }
    }
    
}
