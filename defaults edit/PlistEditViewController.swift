//
//  PlistEditViewController.swift
//  defaults edit
//
//  Created by Ian Gregory on 15-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

/// An object that a property list editor asks to effect changes.
protocol PlistEditDelegate {
    
    func add(_ item: PlistItem)
    func removeItems(for keys: Set<String>)
    func itemType(for key: String) -> PlistType?
    func loadExternalChanges()
    
}

/// A reusable, general-purpose property list editor.
class PlistEditViewController: NSViewController {
    
    /// The delegate object that persists changes to the property list.
    var delegate: PlistEditDelegate?
    
    /// The outline view used to display the property list and facilitate
    /// GUI-based editing.
    @IBOutlet var outlineView: NSOutlineView!
    /// Shown when the delegate reports that it is in the process
    /// of loading data.
    @IBOutlet var progressIndicator: NSProgressIndicator!
    
    /// The property list to display.
    /// When set, the view is updated accordingly.
    override var representedObject: Any? {
        didSet {
            if let representedObject = representedObject {
                plist = representedObject
            }
        }
    }
    
    /// Starts the animation of the built-in progress indicator.
    func startProgressIndicator() {
        progressIndicator.startAnimation(self)
    }
    
    /// Stops the animation of the built-in progress indicator.
    func stopProgressIndicator() {
        progressIndicator.stopAnimation(self)
    }
    
    /// The property list to display.
    /// When set, the view is updated accordingly.
    private var plist: Any = [:] {
        didSet {
            outlineView?.reloadData()
        }
    }
    
}

extension PlistEditViewController {
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showEdit":
            let selectedRowIndex = outlineView.selectedRow
            
            let segue = segue as! PopoverSegue
            segue.anchorView = outlineView.rowView(atRow: selectedRowIndex, makeIfNecessary: false)
            segue.preferredEdge = .minX
            
            let controller = (segue.destinationController as! AddSheetViewController)
            controller.itemOC.automaticallyPreparesContent = false
            controller.itemOC.prepareContent()
            
            let selection = controller.itemOC.selection as AnyObject
            let (key, value) = outlineView.item(atRow: selectedRowIndex) as! (key: PlistKey, value: Any)
            let type =
                delegate?.itemType(for: key.key)
                    ?? PlistType(typeOf: value)
                    ?? .string
            
            selection.setValue(key.key, forKey: #keyPath(PlistItem.key))
            selection.setValue(NSNumber(value: type.rawValue), forKey: #keyPath(PlistItem.type))
            selection.setValue(value as AnyObject, forKey: #keyPath(PlistItem.value))
        default:
            super.prepare(for: segue, sender: sender)
        }
    }
    
}

typealias PlistKey = (key: String, isDecoy: Bool)

private func <(l: (key: String, value: Any), r: (key: String, value: Any)) -> Bool {
    return l.key < r.key
}

extension PlistEditViewController: NSOutlineViewDataSource {
    
    private func dictionary(for item: Any?) -> [(key: String, value: Any)]? {
        if item == nil {
            return (plist as? [String : Any])?.sorted { $0 < $1 }
        } else if let (_, value) = item as? (key: PlistKey, value: [String : Any]) {
            return value.sorted { $0 < $1 }
        } else {
            return nil
        }
    }
    private func array(for item: Any?) -> [Any]? {
        if item == nil {
            return plist as? [Any]
        } else if let (_, value) = item as? (key: PlistKey, value: [Any]) {
            return value
        } else {
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let dictionary = self.dictionary(for: item) {
            let dictionaryIndex = dictionary.index(dictionary.startIndex, offsetBy: index)
            let (key, value) = dictionary[dictionaryIndex]
            return (key: (key: key, isDecoy: false), value: value)
        }
        let array = self.array(for: item)!
        let value = array[index]
        return (key: (key: String(index), isDecoy: true), value: value)
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is (key: PlistKey, value: [String : Any]) || item is (key: PlistKey, value: [Any])
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return dictionary(for: item)?.count ?? array(for: item)?.count ?? 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        let item = item as! (key: PlistKey, value: Any)
        switch tableColumn!.identifier.rawValue {
            case "Key": return item.key
            case "Value": return item.value
            default: fatalError("Unknown table column identifier")
        }
    }
    
}

@objc(PlistKeyDisplay)
class PlistKeyDisplay: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        return (value as? PlistKey)?.key
    }
}

@objc(PlistKeyFont)
class PlistKeyFont: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let (key, isDecoy) = value as? PlistKey else { return nil }
        if isDecoy && Int(key) != nil {
            // Array index
            return NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        } else {
            return NSFont.systemFont(ofSize: NSFont.systemFontSize)
        }
    }
}

@objc(PlistKeyTextColor)
class PlistKeyTextColor: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let (_, isDecoy) = value as? PlistKey else { return nil }
        return isDecoy ? NSColor.systemGray : NSColor.controlTextColor
    }
}

@objc(PlistValueDisplay)
class PlistValueDisplay: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        switch value {
            case let array as NSArray: return "[\(array.count) elements]"
            case let dictionary as NSDictionary: return "[\(dictionary.count) key-value pairs]"
            default: return value
        }
    }
}

@objc(PlistValueTextColor)
class PlistValueTextColor: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        switch value {
            case is NSArray, is NSDictionary: return NSColor.systemGray
            default: return NSColor.controlTextColor
        }
    }
}

extension PlistEditViewController: NSUserInterfaceValidations, NSOutlineViewDelegate {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else {
            return false
        }
        switch action {
        case #selector(delete(_:)):
            return canDelete
        case #selector(edit(_:)):
            return canEdit
        default:
            return true
        }
    }
    
    @objc dynamic var canDelete: Bool {
        return outlineView?.selectedRow != -1
    }
    
    @objc dynamic var canEdit: Bool {
        guard
            let outlineView = outlineView,
            outlineView.selectedRow != -1,
            let (_, value) = outlineView.item(atRow: outlineView.selectedRow) as? (key: PlistKey, value: Any)
        else {
            return false
        }
        return !(value is [Any] || value is [String : Any])
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        willChangeValue(forKey: "canDelete")
        didChangeValue(forKey: "canDelete")
        willChangeValue(forKey: "canEdit")
        didChangeValue(forKey: "canEdit")
    }
    
    private func resetSelection() {
        // Prevent operation ordering issue whereby:
        //   • canEdit returns true since the outline view has a valid selection;
        //   • The outline view's selection then changes on the same runloop cycle;
        //   • Thus, the "Edit" button is enabled and causes a crash when clicked.
        // This forcibly resets the selection again. Shouldn't be necessary, but is.
        outlineView.selectRowIndexes([], byExtendingSelection: false)
    }
    
    func add(_ item: PlistItem) {
        delegate?.add(item)
        resetSelection()
    }
    
    @IBAction func add(_ sender: Any?) {
        performSegue(withIdentifier: "showAdd", sender: sender)
    }
    
    @IBAction func delete(_ sender: Any?) {
        remove(itemsFor: Set<String>(outlineView.selectedRowIndexes.map { index in
            return (outlineView.item(atRow: index) as! (key: PlistKey, value: Any)).key.key
        }))
    }
    
    @IBAction func edit(_ sender: Any?) {
        performSegue(withIdentifier: "showEdit", sender: sender)
    }
    
    func remove(itemsFor keys: Set<String>) {
        delegate?.removeItems(for: keys)
        resetSelection()
    }
    
    @IBAction func loadExternalChanges(_ sender: Any?) {
        delegate?.loadExternalChanges()
        resetSelection()
    }
    
}

/// A popover segue whose parameters can be modified in code.
@objc
class PopoverSegue: NSStoryboardSegue {
    
    var popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .semitransient
        return popover
    }()
    
    var behavior: NSPopover.Behavior = .semitransient
    var anchorView: NSView?
    var preferredEdge: NSRectEdge = .minY
    
    override init(identifier: NSStoryboardSegue.Identifier, source sourceController: Any, destination destinationController: Any) {
        super.init(identifier: identifier, source: sourceController, destination: destinationController)
        
        popover.contentViewController = (destinationController as! NSViewController)
    }
    
    override func perform() {
        (sourceController as! NSViewController).present(destinationController as! NSViewController, asPopoverRelativeTo: .zero, of: anchorView ?? (sourceController as! NSViewController).view, preferredEdge: preferredEdge, behavior: behavior)
    }
    
}
