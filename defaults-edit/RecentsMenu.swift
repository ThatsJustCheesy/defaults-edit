//
//  RecentsMenu.swift
//  defaults-edit
//
//  Created by Ian Gregory on 11-08-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class RecentsMenu: NSObject, NSMenuDelegate, NSUserInterfaceValidations {
    
    static func add(domain: DefaultsDomain) {
        recentDomains = recentDomains
            .filter { $0.domainName != domain.domainName }
            + [domain]
    }
    
    private static var recentDomains: [DefaultsDomain] {
        get {
            return (UserDefaults.standard.array(forKey: "RecentDomains") as? [String] ?? []).map { DefaultsDomain(domainName: $0) }
        }
        set {
            var newValue = newValue
            if newValue.count > 10 {
                newValue.removeFirst()
            }
            UserDefaults.standard.set(newValue.compactMap { $0.domainName }, forKey: "RecentDomains")
        }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let clearItem = menu.item(withTag: 1)!
        defer {
            menu.addItem(.separator())
            menu.addItem(clearItem)
            clearItem.isEnabled = !RecentsMenu.recentDomains.isEmpty
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
    
    @IBAction func clearRecentDocuments(_ sender: Any?) {
        RecentsMenu.recentDomains = []
    }
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(clearRecentDocuments(_:)):
            return !RecentsMenu.recentDomains.isEmpty
        default:
            return true
        }
    }
    
}
