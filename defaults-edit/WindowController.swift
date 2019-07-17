//
//  WindowController.swift
//  defaults-edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    @objc dynamic var representedDomain: DefaultsDomain?
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @objc dynamic var windowTitle: String {
        let title = representedDomain?.name ?? "Untitled"
        let domain = representedDomain?.bundleIdentifier.map { " (" + $0 + ")" } ?? ""
        return title + domain + " — defaults-edit"
    }
    @objc class func keyPathsForValuesAffectingWindowTitle() -> Set<String> {
        return [#keyPath(WindowController.representedDomain)]
    }
    
}
