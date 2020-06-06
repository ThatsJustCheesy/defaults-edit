//
//  WindowController.swift
//  defaults edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

/// Controls an editor window.
class WindowController: NSWindowController {
    
    /// The defaults domain represnted by this editor window.
    /// Controls, e.g., the window title.
    @objc dynamic var representedDomain: DefaultsDomain? {
        didSet {
            guard let representedDomain = representedDomain else {
                return
            }
            RecentsMenu.add(domain: representedDomain)
        }
    }
    
    /// The window's title.
    /// # Bindings
    ///   * The controlled window's `title`.
    @objc dynamic var windowTitle: String {
        let title = representedDomain?.localizedName ?? "Untitled"
        let domain = representedDomain?.domainName.map { " (" + $0 + ")" } ?? ""
        return title + domain + " — defaults edit"
    }
    
    /// The represented domain affects the window title.
    @objc class func keyPathsForValuesAffectingWindowTitle() -> Set<String> {
        return [#keyPath(WindowController.representedDomain)]
    }
    
}
