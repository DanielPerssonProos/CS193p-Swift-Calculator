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
        description = " "
        constants["e"] = M_E
        constants["π"] = M_PI
    }
    private var accumulator = 0.0
    private var internalProgram = [AnyObject]()
    private var variableValues = [String: Double]()
    private var constants = [String: Double]()
    
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
    
    func performOperation(symbol: String) {
        if internalProgram.isEmpty || operations.keys.contains(String(internalProgram.last!)) {
            setDescription(symbol, displayText: String(accumulator))
        } else {
            setDescription(symbol, displayText: String(internalProgram.last!))
        }
        
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .UnaryOperation(let function):
                unaryOperationPerformedLast = true
                plusOrMinusPerformedLast = false
                accumulator = function(accumulator)
            case .BinaryOperation(let function):
                isPartialResult = true
                unaryOperationPerformedLast = false
                executePendingBinaryOperation()
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
            case .Equals:
                isPartialResult = false
                executePendingBinaryOperation()
            }
        }
    }
    
    private func executePendingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
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
    
    func setVariable(variable: String, value: Double) {
        variableValues[variable] = value
    }
    
    func setOperand(operand: Double) {
        if !isPartialResult {
            displayCleared(false)
        }
        accumulator = operand
        internalProgram.append(operand)
    }
    
    func setOperand(variableName: String) {
        if !isPartialResult {
            displayCleared(false)
        }
        if variableValues.keys.contains(variableName) {
            accumulator = variableValues[variableName]!
        } else if constants.keys.contains(variableName) {
            accumulator = constants[variableName]!
        } else {
            accumulator = 0.0
        }
        internalProgram.append(variableName)
    }
    
    func displayCleared(clearVariables: Bool = true) {
        if clearVariables {
            variableValues = [String: Double]()
        }
        internalProgram.removeAll()
        pending = nil
        description = " "
        isPartialResult = true
        unaryOperationPerformedLast = false
        plusOrMinusPerformedLast = false
        accumulator = 0.0
    }
    
    var isPartialResult = true
    private var plusOrMinusPerformedLast = false
    private var unaryOperationPerformedLast = false
    private var description = ""
    
    private func setDescription(operation: String, displayText: String) {
        var usedDescription = description == " " ? "" : description
        let formattedDisplayText = formatNumber(displayText)
        
        switch operation {
        case "√", "cos", "sin", "tan", "ln", "x²":
            let preString = operation == "x²" ? "(" : operation+"("
            let postString = operation == "x²" ? ")²" : ")"
            
            if isPartialResult && !unaryOperationPerformedLast {
                usedDescription += preString + formattedDisplayText + postString
            } else {
                usedDescription = preString + usedDescription + postString
            }
            
        case "×", "÷", "+", "−":
            var opString = " "+operation+" "
            let MultiplicationOrDivisionCalled = (operation == "×" || operation == "÷")
            
            if !MultiplicationOrDivisionCalled {
                plusOrMinusPerformedLast = true
            } else if plusOrMinusPerformedLast && MultiplicationOrDivisionCalled {
                usedDescription = "("+usedDescription
                opString = ") "+operation+" "
                plusOrMinusPerformedLast = false
            }
            
            if isPartialResult && !unaryOperationPerformedLast {
                usedDescription += formattedDisplayText + opString
            } else {
                usedDescription += opString
            }
            
        case "=":
            if !unaryOperationPerformedLast {
                usedDescription += formattedDisplayText
            }
            isPartialResult = false
            
        default:
            break
        }
        description = usedDescription
    }
    
    func getDescription() -> String {
        if description != " " {
            if isPartialResult {
                return description + " ... "
            } else {
                return description + " = "
            }
        } else {
            return description
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
        displayCleared(clearVariables)
        let program = programToRun as! [AnyObject]
        for op in program {
            if let operand = op as? Double {
                setOperand(operand)
            } else if let operation = op as? String {
                operations.keys.contains(operation) ? performOperation(operation) : setOperand(operation)
            }
        }
        
    }
    
    func undoAction() {
        if internalProgram.count > 1 {
            internalProgram.removeLast()
            runProgram(internalProgram)
        } else {
            displayCleared(false)
        }
    }
    
}