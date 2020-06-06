//
//  AddSheetViewController.swift
//  defaults edit
//
//  Created by Ian Gregory on 15-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class AddSheetViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet var itemOC: NSObjectController! {
        get {
            return itemController.objectController
        }
        set {
            itemController = Controller<PlistItem>(wrapping: newValue)
        }
    }
    var itemController: Controller<PlistItem>!
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.destinationController {
        case let typeAndValueEditorVC as TypeAndValueEditor:
            typeAndValueEditorVC.representedObject = itemOC
        default:
            return
        }
    }
    
    @IBAction func ok(_ sender: Any?) {
        guard itemOC.commitEditing() else {
            return
        }
        (presentingViewController as! PlistEditViewController).add(itemController.content!)
        dismiss(sender)
    }
    
    @IBOutlet var keyFieldInvalidDataMarker: InvalidDataMarker!
    
}

extension AddSheetViewController {
    
    func invalidDataMarker(for control: NSControl) -> InvalidDataMarker? {
        switch control.tag {
        case 7038329: return keyFieldInvalidDataMarker
        default: return nil
        }
    }
    
    func control(_ control: NSControl, didFailToValidatePartialString string: String, errorDescription error: String?) {
        guard
            let error = error,
            let marker = invalidDataMarker(for: control)
            else {
                return
        }
        marker.errorString = error
        marker.show()
    }
    
    @objc var validationErrorStrings: [String] {
        do {
            try itemController.content?.validate()
        } catch {
            return [error.localizedDescription]
        }
        return []
    }
    @objc class func keyPathsForValuesAffectingValidationErrorStrings() -> Set<String> {
        return ["\(#keyPath(AddSheetViewController.itemOC.selection)).\(#keyPath(PlistItem.isValid))"]
    }
    
}

@objc(NonEmptyStringFormatter)
class NonEmptyStringFormatter: Formatter {
    
    override func string(for obj: Any?) -> String? {
        return obj as? String
    }
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string as AnyObject
        return true
    }
    
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString == "" {
            error?.pointee = "Must not be empty."
            newString?.pointee = partialString as NSString
            return false
        } else {
            return true
        }
    }
    
}
