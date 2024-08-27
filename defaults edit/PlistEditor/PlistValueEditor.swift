//
//  PlistValueEditor.swift
//  defaults edit
//
//  Created by Ian Gregory on 16-07-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

/// Controls an editor view for a property list type and its corresponding value.
class TypeAndValueEditor: NSViewController {
    
    @IBOutlet var valueOC: NSObjectController!
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.destinationController {
        case let tabVC as ValueEditorTabVC:
            tabVC.representedObject = representedObject
            tabVC.bind(NSBindingName(rawValue: "representedObject"), to: self, withKeyPath: "representedObject", options: nil)
            tabVC.bubbleKeyPath = "\(#keyPath(TypeAndValueEditor.valueOC.selection)).\(#keyPath(PlistValue.value))"
            tabVC.propagateRepresentedObject = true
        default:
            return
        }
    }
    
}

/// Controls a tab view responsible for editing a property list value.
/// Each tab contains editing UI for a different property list type.
class ValueEditorTabVC: NSTabViewController {
    
    private var shouldResetValueOnTypeChange: Bool = false
    
    override func viewDidAppear() {
        selectedTabViewItemIndex = ((self.representedObject as! NSObjectController).content as! PlistItem).type.rawValue
        shouldResetValueOnTypeChange = true
        bind(NSBindingName(rawValue: "selectedTabViewItemIndex"), to: representedObject!, withKeyPath: "selection.type", options: nil)
    }
    
    private var previousValue: Any?
    
    override var selectedTabViewItemIndex: Int {
        willSet {
            guard
                shouldResetValueOnTypeChange,
                let item = (self.representedObject as? NSObjectController)?.content as? PlistItem
            else {
                return
            }
            
            previousValue = item.value
            if newValue != selectedTabViewItemIndex {
                item.value = PlistType(rawValue: newValue)!.defaultValue
            }
        }
        didSet {
            guard
                shouldResetValueOnTypeChange,
                let item = (self.representedObject as? NSObjectController)?.content as? PlistItem
            else {
                return
            }
            
            switch (PlistType(rawValue: selectedTabViewItemIndex)!, PlistType(rawValue: oldValue)!) {
            case (.string, .integer), (.string, .real):
                item.value = ((previousValue as? NSNumber)?.stringValue ?? "") as AnyObject
            case (.string, _):
                item.value = "" as AnyObject
            case (.boolean, _):
                item.value = false as AnyObject
            case (.real, .integer):
                item.value = ((previousValue as? NSNumber)?.doubleValue ?? 0.0) as AnyObject
            case (.integer, .real):
                item.value = ((previousValue as? NSNumber)?.intValue ?? 0) as AnyObject
            case (.real, .string):
                item.value = ((previousValue as? NSString)?.doubleValue ?? 0.0) as AnyObject
            case (.integer, .string):
                item.value = ((previousValue as? NSString)?.intValue ?? 0) as AnyObject
            default:
                break
            }
        }
    }
    
}
