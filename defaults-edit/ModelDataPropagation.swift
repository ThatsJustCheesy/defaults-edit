//
//  ModelDataPropagation.swift
//  defaults-edit
//
//  Created by Ian Gregory on 16-07-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

extension NSViewController {
    
    private static var bubbleKeyPathAssociationKey: Int = 0
    private static var represntedObjectControllerAssociationKey: Int = 0
    
    /// When set, representedObject is bubbled up to the parent view controller
    /// via the specified key path. e.g., to update the parent's "parameters"
    /// value when self.representedObject changes, set bubbleKeyPath to
    /// "parameters".
    @IBInspectable var bubbleKeyPath: String? {
        get {
            return objc_getAssociatedObject(self, &NSViewController.bubbleKeyPathAssociationKey) as! String?
        }
        set {
            return objc_setAssociatedObject(self, &NSViewController.bubbleKeyPathAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    // TODO: for deletion
    var representedObjectController: NSObjectController {
        get {
            guard let controller = objc_getAssociatedObject(self, &NSViewController.represntedObjectControllerAssociationKey) as? NSObjectController else {
                let controller = NSObjectController()
                controller.bind(.content, to: self, withKeyPath: "representedObject", options: nil)
                objc_setAssociatedObject(controller, &NSViewController.represntedObjectControllerAssociationKey, controller, .OBJC_ASSOCIATION_RETAIN)
                return controller
            }
            return controller
        }
    }
    
    // Swizzled in ObjC
    @objc dynamic func TJC_setRepresentedObject(_ newValue: Any?) {
        TJC_setRepresentedObject(newValue) // Swizzled in ObjC
        if let bubbleKeyPath = bubbleKeyPath {
            parent?.setValue(representedObject, forKeyPath: bubbleKeyPath)
        }
    }
    
}

extension NSTabViewController {
    
    private static var propagateRepresentedObjectAssociationKey: Int = 0
    
    @IBInspectable var propagateRepresentedObject: Bool {
        get {
            return objc_getAssociatedObject(self, &NSTabViewController.propagateRepresentedObjectAssociationKey) as? Bool ?? false
        }
        set {
            return objc_setAssociatedObject(self, &NSTabViewController.propagateRepresentedObjectAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    // Swizzled in ObjC
    @objc dynamic func TJC_tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        TJC_tabView(tabView, willSelect: tabViewItem) // Swizzled in ObjC
        if propagateRepresentedObject {
            for viewController in tabViewItems.compactMap({ $0.viewController }) {
                let oldBubbleKeyPath = viewController.bubbleKeyPath
                defer { viewController.bubbleKeyPath = oldBubbleKeyPath }
                viewController.bubbleKeyPath = nil
                viewController.representedObject = nil
            }
            tabViewItem?.viewController?.representedObject = representedObject
        }
    }
    
}

class Controller<Content>: NSObject {
    var objectController: NSObjectController
    
    init(wrapping objectController: NSObjectController) {
        self.objectController = objectController
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return objectController
    }
    
    var content: Content? {
        return objectController.content as? Content
    }
}
