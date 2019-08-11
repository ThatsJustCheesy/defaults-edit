//
//  WindowController.swift
//  defaults-edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    @objc dynamic var representedDomain: DefaultsDomain? {
        didSet {
            guard let representedDomain = representedDomain else {
                return
            }
            RecentsMenu.add(domain: representedDomain)
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @objc dynamic var windowTitle: String {
        let title = representedDomain?.localizedName ?? "Untitled"
        let domain = representedDomain?.domainName.map { " (" + $0 + ")" } ?? ""
        return title + domain + " — defaults-edit"
    }
    @objc class func keyPathsForValuesAffectingWindowTitle() -> Set<String> {
        return [#keyPath(WindowController.representedDomain)]
    }
    
}
