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

typealias PlistKey = (key: String, isDecoy: Bool)

class PlistOutlineItem<Value> {
    
    var key: PlistKey
    var value: Value
    
    lazy var root: PlistOutlineItem = self
    var indexPath: [Int]
    
    internal init(key: PlistKey, value: Value, root: PlistOutlineItem?, indexPath: [Int]) {
        self.key = key
        self.value = value
        self.indexPath = indexPath
        if let root = root {
            self.root = root
        }
    }
}

func replace(inKey key: String, value: Any, at indexPath: ArraySlice<Int>, withKey newKey: String, value newValue: Any) -> (key: String, value: Any) {
    switch value {
    case let dictionary as [String : Any]:
        return replace(inKey: key, dictionary: dictionary, at: indexPath, withKey: newKey, value: newValue)
    case let array as [Any]:
        return replace(inKey: key, array: array, at: indexPath, withKey: newKey, value: newValue)
    default:
        return (key: newKey, value: newValue)
    }
}
func replace(inKey key: String, dictionary: [String : Any], at indexPath: ArraySlice<Int>, withKey newKey: String, value newValue: Any) -> (key: String, value: Any) {
    if indexPath.isEmpty {
        return (key: key, value: dictionary)
    } else  {
        let index = dictionary.index(dictionary.startIndex, offsetBy: indexPath[0])
        
        if indexPath.count == 1 {
            let oldKey = dictionary[index].key
            
            var dictionary = dictionary
            if newKey == oldKey {
                dictionary[oldKey] = newValue
            } else {
                dictionary.remove(at: index)
                dictionary[newKey] = newValue
            }
            return (key: key, value: dictionary)
        } else {
            return replace(inKey: key, value: dictionary[index].value, at: indexPath.dropFirst(), withKey: newKey, value: newValue)
        }
    }
}
func replace(inKey key: String, array: [Any], at indexPath: ArraySlice<Int>, withKey newKey: String, value newValue: Any) -> (key: String, value: Any) {
    if indexPath.isEmpty {
        return (key: key, value: array)
    } else {
        let index = indexPath[0]
        
        if indexPath.count == 1 {
            // Intentionally ignore newKey
            var array = array
            array[indexPath[0]] = newValue
            return (key: key, value: array)
        } else {
            return replace(inKey: key, value: array[index], at: indexPath.dropFirst(), withKey: newKey, value: newValue)
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
            let item = outlineView.item(atRow: selectedRowIndex) as! PlistOutlineItem<Any>
            let type =
                delegate?.itemType(for: item.key.key)
                    ?? PlistType(typeOf: item.value)
                    ?? .string
            
            selection.setValue(item.key.key, forKey: #keyPath(PlistItem.key))
            selection.setValue(NSNumber(value: type.rawValue), forKey: #keyPath(PlistItem.type))
            selection.setValue(item.value as AnyObject, forKey: #keyPath(PlistItem.value))
            
            controller.itemController.content!.generatePersistentRepresentation = { editedItem in
                return replace(
                    inKey: item.root.key.key,
                    value: item.root.value,
                    at: item.indexPath[...],
                    withKey: editedItem.key,
                    value: editedItem.value as Any
                )
            }
        default:
            super.prepare(for: segue, sender: sender)
        }
    }
    
}

private func <(l: (key: String, value: Any), r: (key: String, value: Any)) -> Bool {
    return l.key < r.key
}

extension PlistEditViewController: NSOutlineViewDataSource {
    
    private func root(forParent parentItem: Any?, child: String) -> PlistOutlineItem<Any>? {
        if parentItem == nil {
            return nil
        } else {
            return (parentItem as! PlistOutlineItem<Any>)
        }
    }
    private func indexPath(fromParent parentItem: Any?, toChild childIndex: Int) -> [Int] {
        if parentItem == nil {
            return []
        } else {
            return (parentItem as! PlistOutlineItem<Any>).indexPath + [childIndex]
        }
    }
    
    private func dictionary(for item: Any?) -> [(key: String, value: Any)]? {
        switch (item as? PlistOutlineItem<Any>)?.value {
        case nil:
            return (plist as? [String : Any])?.sorted { $0 < $1 }
        case let value as [String : Any]:
            return value.sorted { $0 < $1 }
        default:
            return nil
        }
    }
    private func array(for item: Any?) -> [Any]? {
        switch (item as? PlistOutlineItem<Any>)?.value {
        case nil:
            return plist as? [Any]
        case let value as [Any]:
            return value
        default:
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let dictionary = self.dictionary(for: item) {
            let dictionaryIndex = dictionary.index(dictionary.startIndex, offsetBy: index)
            let (key, value) = dictionary[dictionaryIndex]
            return PlistOutlineItem(
                key: (key: key, isDecoy: false),
                value: value,
                root: root(forParent: item, child: key),
                indexPath: indexPath(fromParent: item, toChild: dictionaryIndex)
            )
        } else {
            let array = self.array(for: item)!
            let value = array[index]
            return PlistOutlineItem(
                key: (key: String(index), isDecoy: true),
                value: value,
                root: root(forParent: item, child: String(index)),
                indexPath: indexPath(fromParent: item, toChild: index)
            )
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch (item as? PlistOutlineItem<Any>)?.value {
        case is [String : Any]:
                return true
        case is [Any]:
                return true
        default:
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return dictionary(for: item)?.count ?? array(for: item)?.count ?? 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        let item = item as! PlistOutlineItem<Any>
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
            case let array as NSArray:
                return "[\(array.count) elements]"
            case let dictionary as NSDictionary:
                return "[\(dictionary.count) key-value pairs]"
            case let number as NSNumber:
                if NSStringFromClass(type(of: number)).range(of: "bool", options: .caseInsensitive) != nil {
                    return number.boolValue ? "True" : "False"
                }
                return number
            default:
                return value
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
            let item = outlineView.item(atRow: outlineView.selectedRow) as? PlistOutlineItem<Any>
        else {
            return false
        }
        return !(item.value is [Any] || item.value is [String : Any])
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
            return (outlineView.item(atRow: index) as! PlistOutlineItem<Any>).key.key
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
