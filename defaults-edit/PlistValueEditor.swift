//
//  PlistValueEditor.swift
//  defaults-edit
//
//  Created by Ian Gregory on 16-07-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

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

class ValueEditorTabVC: NSTabViewController {
    
    override func viewDidAppear() {
        selectedTabViewItemIndex = ((self.representedObject as! NSObjectController).content as! PlistItem).type.rawValue
        bind(NSBindingName(rawValue: "selectedTabViewItemIndex"), to: representedObject!, withKeyPath: "selection.type", options: nil)
    }
    
}
