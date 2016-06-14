//
//  ViewController.swift
//  Calculator
//
//  Created by Daniel Persson Proos on 2016-06-05.
//  Copyright © 2016 Daniel Persson Proos. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var display: UILabel!
    private var userIsInTheMiddleOfTyping = false
    private var doingDecimal = false
    
    @IBAction private func digitPress(sender: UIButton) {
        if !brain.isPartialResult {
            brain.clearDescriptionOnOperation = true
        }
        
        if userIsInTheMiddleOfTyping && display.text! != "0" {
            display.text = display.text! + sender.currentTitle!
        } else {
            display.text = sender.currentTitle!
        }
        userIsInTheMiddleOfTyping = true
    }
    
    private var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            if newValue % 1.0 == 0.0 {
                var newValueArray = String(newValue).componentsSeparatedByString(".")
                display.text = newValueArray[0]
            } else {
                display.text = String(newValue)
            }
        }
    }
    
    private var brain = CalculatorBrain()
    @IBAction private func doOperation(sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayValue = brain.result
        descriptionDisplay.text = brain.getDescription()
    }
    
    @IBAction func doDecimal(sender: UIButton) {
        if display.text!.rangeOfString(".") == nil {
            userIsInTheMiddleOfTyping = true //in the case that the user starts by pressing .
            display.text = display.text! + ".";
        }
        
    }
    @IBAction func clearDisplay(sender: UIButton) {
        userIsInTheMiddleOfTyping = false
        displayValue = 0
        display.text = "0"
        brain.displayCleared()
        descriptionDisplay.text = " "
    }
    @IBOutlet weak var descriptionDisplay: UILabel!
    
    var savedProgram: CalculatorBrain.PropertyList?
    @IBAction func save() {
        savedProgram = brain.program
    }
    
    @IBAction func load() {
        if savedProgram != nil {
            brain.program = savedProgram!
            brain.runProgram(savedProgram!)
            displayValue = brain.result
        }
    }
    
    @IBAction func variableOrConstantPressed(sender: UIButton) {
        brain.setOperand(sender.currentTitle!)
        displayValue = brain.result
        userIsInTheMiddleOfTyping = false
    }
    
    @IBAction func setM() {
        brain.setVariable("M", value: displayValue)
        brain.runProgram(brain.program, clearVariables: false )
        displayValue = brain.result
        descriptionDisplay.text = brain.getDescription()
    }
    
    @IBAction func undoPressed() {
        if userIsInTheMiddleOfTyping {
            if display.text!.characters.count > 1 {
                display.text = String(display.text!.characters.dropLast())
            } else {
                display.text = "0"
                userIsInTheMiddleOfTyping = false
            }
        } else {
            brain.undoAction()
        }
    }
}

