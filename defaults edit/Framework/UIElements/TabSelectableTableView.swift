//
//  TabSelectableTableView.swift
//  defaults edit
//
//  Created by Ian Gregory on 12-08-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

private func ensureSelectionExists(in tableView: NSTableView) {
    if tableView.selectedRow == -1 {
        tableView.selectRowIndexes(IndexSet(0...0), byExtendingSelection: false)
    }
}

/// An NSTableView that selects its first row if tabbed into with no selection.
class TabSelectableTableView: NSTableView {
    
    override func becomeFirstResponder() -> Bool {
        ensureSelectionExists(in: self)
        return super.becomeFirstResponder()
    }
    
}

/// An NSOutlineView that selects its first row if tabbed into with no selection.
class TabSelectableOutlineView: NSOutlineView {
    
    override func becomeFirstResponder() -> Bool {
        ensureSelectionExists(in: self)
        return super.becomeFirstResponder()
    }
    
}
