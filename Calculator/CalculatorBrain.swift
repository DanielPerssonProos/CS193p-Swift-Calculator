//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Daniel Persson Proos on 2016-06-05.
//  Copyright © 2016 Daniel Persson Proos. All rights reserved.
//

import Foundation

class CalculatorBrain {
    init () {
        description = ""
        constants["e"] = M_E
        constants["π"] = M_PI
    }
    private var accumulator = 0.0
    private var internalProgram = [AnyObject]()
    private var variableValues = [String: Double]()
    private var constants = [String: Double]()
    
    
    func setVariable(variable: String, value: Double) {
        print("Setting \(variable) to \(value)")
        variableValues[variable] = value
        print("Value for \(variable) in variableValues: \(variableValues[variable])")
        print("setVariable - M is set: \(variableValues.keys.contains(variable))")
    }
    
    func setOperand(operand: Double) {
        accumulator = operand
        internalProgram.append(operand)
    }
    
    func setOperand(variableName: String) {
        if !isPartialResult {
            displayCleared(false)
        }
        print("setOperand - M is set: \(variableValues.keys.contains(variableName))")
        if variableValues.keys.contains(variableName) {
            accumulator = variableValues[variableName]!
        } else if constants.keys.contains(variableName) {
            accumulator = constants[variableName]!
        } else {
            accumulator = 0.0
        }
        internalProgram.append(variableName)
        print("setOperand: accumulator = \(accumulator)")
    }
    
    func displayCleared(clearVariables: Bool = true) {
        if clearVariables {
            variableValues = [String: Double]()
        }
        internalProgram.removeAll()
        pending = nil
        description = ""
        isPartialResult = true
        unaryOperationPerformedLast = false
        plusOrMinusPerformedLast = false
        clearDescriptionOnOperation = false
        accumulator = 0.0
    }
    
    private var operations: Dictionary<String,Operation> = [
        "±" : Operation.UnaryOperation({ -$0 }),
        "√" : Operation.UnaryOperation(sqrt),
        "cos" : Operation.UnaryOperation(cos),
        "sin" : Operation.UnaryOperation(sin),
        "tan" : Operation.UnaryOperation(tan),
        "ln" : Operation.UnaryOperation(log),
        "x²" : Operation.UnaryOperation({ pow($0,2) }),
        "×" : Operation.BinaryOperation({ $0 * $1 }),
        "÷" : Operation.BinaryOperation({ $0 / $1 }),
        "+" : Operation.BinaryOperation({ $0 + $1 }),
        "−" : Operation.BinaryOperation({ $0 - $1 }),
        "=" : Operation.Equals
    ]
    
    private enum Operation {
        case UnaryOperation((Double) -> Double)
        case BinaryOperation((Double, Double) -> Double)
        case Equals
    }
    
    var binaryOperationCalledLast = false
    func performOperation(symbol: String) {
        /*if !internalProgram.isEmpty {
            setDescription(symbol, displayText: String(internalProgram.last!))
            
        }
        if let last = internalProgram.last {
            if symbol == String(last) {
                return
            } else if operations.keys.contains(String(last)) {
                switch operations[String(last)]! {
                case .BinaryOperation(let function):
                    pending = PendingBinaryOperationInfo(binaryFunction: function,firstOperand: pending!.firstOperand)
                default: break
                }
            }
        }*/
        binaryOperationCalledLast = false
        if !internalProgram.isEmpty && operations.keys.contains(String(internalProgram.last)) {
            switch operations[String(internalProgram.last)]! {
            case .BinaryOperation: binaryOperationCalledLast = true
            default: break
            }
        }
        
        if binaryOperationCalledLast || internalProgram.isEmpty {
            setDescription(symbol, displayText: String(accumulator))
        } else {
            setDescription(symbol, displayText: String(internalProgram.last!))
        }
        
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .UnaryOperation(let function):
                print("PerformOperation: accumulator = \(accumulator)")
                accumulator = function(accumulator)
            case .BinaryOperation(let function):
                executePendingBinaryOperation()
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
            case .Equals:
                executePendingBinaryOperation()
            }
        }
    }
    
    private func executePendingBinaryOperation() {
        if pending != nil {
            print("Performing operation on \(pending!.firstOperand) and \(accumulator)")
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            print("Accumulator set to \(accumulator)")
            pending = nil
        }
    }
    
    private var pending: PendingBinaryOperationInfo?
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
    }
    
    var result: Double {
        get {
            return accumulator
        }
    }
    
    
    var clearDescriptionOnOperation = false
    var isPartialResult = false
    private var plusOrMinusPerformedLast = false
    private var unaryOperationPerformedLast = false
    private var description = ""
    
    private func setDescription(operation: String, displayText: String) {
        if clearDescriptionOnOperation {
            displayCleared(false)
        }
        print("Stuff added to description '\(formatNumber(displayText))'")
        let formattedDisplayText = formatNumber(displayText)
        
        switch operation {
        case "√", "cos", "sin", "tan", "ln":
            if isPartialResult {
                print("Doing operation \(operation) on value \(formattedDisplayText)")
                description += operation+"("+formattedDisplayText+") "
            } else {
                description = operation + "("+description+")"
            }
            unaryOperationPerformedLast = true
            plusOrMinusPerformedLast = false
        case "×", "÷", "+", "−":
            
            var opString = " "+operation+" "
            let MultiplicationOrDivisionCalled = (operation == "×" || operation == "÷")
            
            if !MultiplicationOrDivisionCalled {
                plusOrMinusPerformedLast = true
            } else if plusOrMinusPerformedLast && MultiplicationOrDivisionCalled {
                description = "("+description
                opString = ") "+operation+" "
                plusOrMinusPerformedLast = false
            }
            
            if isPartialResult && !unaryOperationPerformedLast {
                description += formattedDisplayText + opString
            } else {
                description += opString
            }
            
            isPartialResult = true
            unaryOperationPerformedLast = false
        case "x²":
            if false {
                description = description+"("+formattedDisplayText+")²"
            } else {
                description = "("+description+")²"
            }
            isPartialResult = false
            unaryOperationPerformedLast = true
        case "=":
            if !unaryOperationPerformedLast {
                description += formattedDisplayText
            }
            isPartialResult = false
        default:
            break
        }
        
    }
    func getDescription() -> String {
        if isPartialResult {
            return description + " ... "
        } else {
            return description + " = "
        }
    }
    private func formatNumber(number: String) -> String {
        if Double(number) != nil && Double(number)! % 1.0 == 0.0 {
            return number.componentsSeparatedByString(".")[0]
        } else {
            return number
        }
    }
    
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get {
            return internalProgram
        }
        set {
            runProgram(newValue)
        }
    }
    
    func runProgram(programToRun: PropertyList, clearVariables: Bool = true) {
        if clearVariables {
            displayCleared(clearVariables)
        }
        if let arrayOfOps = programToRun as? [AnyObject] {
            arrayOfOps.count
            for op in arrayOfOps {
                if let operand = op as? Double {
                    setOperand(operand)
                } else if let operation = op as? String {
                    operations.keys.contains(operation) ? performOperation(operation) : setOperand(operation)
                }
            }
        }
    }
    
    
    
}