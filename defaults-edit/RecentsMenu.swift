//
//  RecentsMenu.swift
//  defaults-edit
//
//  Created by Ian Gregory on 11-08-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

/// Keeps a list of recently opened domains, and acts as the delegate for the
/// File > Open Recent menu.
class RecentsMenu: NSObject, NSMenuDelegate, NSUserInterfaceValidations {
    
    /// Adds a domain to the recents menu.
    ///
    /// - Parameter domain: The domain to add.
    static func add(domain: DefaultsDomain) {
        recentDomains = recentDomains
            .filter { $0.domainName != domain.domainName }
            + [domain]
    }
    
    /// A list of recently opened domains.
    /// `add(domain:)` is the public way to append to this list.
    private static var recentDomains: [DefaultsDomain] {
        get {
            return (UserDefaults.standard.array(forKey: "RecentDomains") as? [String] ?? []).map { DefaultsDomain(domainName: $0) }
        }
        set {
            var newValue = newValue
            let maxRecentItems = NSDocumentController().maximumRecentDocumentCount
            if newValue.count > maxRecentItems {
                newValue.removeFirst()
            }
            UserDefaults.standard.set(newValue.compactMap { $0.domainName }, forKey: "RecentDomains")
        }
    }
    
    /// Delegate method to update a menu with a list of recent items.
    /// Treats the first item with tag `1` as the Clear Menu item, which is
    /// re-added to the end of the menu following a separator.
    ///
    /// - Parameter menu: The menu to update.
    func menuNeedsUpdate(_ menu: NSMenu) {
        let clearItem = menu.item(withTag: 1)
        defer {
            if let clearItem = clearItem {
                menu.addItem(.separator())
                menu.addItem(clearItem)
                clearItem.isEnabled = !RecentsMenu.recentDomains.isEmpty
            }
        }
        
        menu.removeAllItems()
        for domain in RecentsMenu.recentDomains.reversed() {
            guard let title = domain.localizedName ?? domain.domainName else {
                break
            }
            let item = menu.addItem(withTitle: title, action: #selector(ViewController.openRecentItem(_:)), keyEquivalent: "")
            item.representedObject = domain
        }
    }
    
    /// Clears the list of recent domains.
    ///
    /// - Parameter sender: Action sender.
    @IBAction func clearRecentDocuments(_ sender: Any?) {
        RecentsMenu.recentDomains = []
    }
    
    /// Validates a Clear Menu item.
    ///
    /// - Parameter item: The item to validate.
    /// - Returns: If the item's action is to `-clearRecentDocuments:`, returns
    ///            whether the recents list has any items to remove.
    ///            Otherwise returns `true`.
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(clearRecentDocuments(_:)):
            return !RecentsMenu.recentDomains.isEmpty
        default:
            return true
        }
    }
    
}
