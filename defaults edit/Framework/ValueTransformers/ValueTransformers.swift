//
//  ValueTransformers.swift
//  defaults edit
//
//  Created by Ian Gregory on 10-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

/// `NSNegateBoolean`, but accepts non-boolean values.
@objc(NegateBoolean)
class NegateBoolean: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let boolean = value as? NSNumber else { return true }
        return !boolean.boolValue
    }
}

@objc(NotNilOrEmptyString)
class NotNilOrEmptyString: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else { return false }
        guard let string = value as? String else { return true }
        return string != ""
    }
}

@objc(ComponentsJoinedByNewline)
class ComponentsJoinedByNewline: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? NSArray else { return false }
        return array.componentsJoined(by: "\n")
    }
}

@objc(ConditionalValue)
class ConditionalValue: ValueTransformer {
    @IBInspectable var name: String = ""
    @IBInspectable var conditionTransformer: String = "NSIsNotNil" {
        didSet {
            conditionTransformerName = NSValueTransformerName(rawValue: conditionTransformer)
        }
    }
    @IBInspectable var trueValue: String?
    @IBInspectable var falseValue: String?
    
    private var conditionTransformerName: NSValueTransformerName = .isNotNilTransformerName
    
    override init() {
        super.init()
        ValueTransformer.setValueTransformer(self, forName: NSValueTransformerName(rawValue: name))
    }

    override func transformedValue(_ value: Any?) -> Any? {
        if (ValueTransformer(forName: conditionTransformerName)?.transformedValue(value) as? NSNumber)?.boolValue ?? false {
            return trueValue
        }
        return falseValue
    }
}

class CommandTransformer: ValueTransformer {
    let argumentName: NSValueTransformerName
    
    @objc init(argumentName: NSValueTransformerName) {
        self.argumentName = argumentName
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        let argument = ValueTransformer(forName: argumentName)!.transformedValue(value)
        return performCommand(onTransformedValue: argument)
    }
    
    func performCommand(onTransformedValue value: Any?) -> Any? {
        return value
    }
}

// Negates result of invoking passed transformer
class NOTCommandTransformer: CommandTransformer {
    override func performCommand(onTransformedValue value: Any?) -> Any? {
        guard let value = value else { return nil }
        guard let number = value as? NSNumber else { return value }
        return !number.boolValue
    }
}

// Returns the enabled font color if passed true, disabled color otherise
class ENABLEDFONTCOLORCommandTransformer: CommandTransformer {
    override func performCommand(onTransformedValue value: Any?) -> Any? {
        guard let value = value else { return nil }
        guard let number = value as? NSNumber else { return value }
        return number.boolValue ? NSColor.controlTextColor : NSColor.disabledControlTextColor
    }
}
