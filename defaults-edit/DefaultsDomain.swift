//
//  DefaultsDomain.swift
//  defaults-edit
//
//  Created by Ian Gregory on 26-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class DefaultsDomain: NSObject {
    
    private enum Impl {
        case bundle(Bundle)
        case domainName(String)
    }
    
    private var impl: Impl
    
    init(bundle: Bundle) {
        impl = .bundle(bundle)
    }
    init(domainName: String) {
        impl = .domainName(domainName)
    }
    
    override var hash: Int {
        return (bundleIdentifier ?? name ?? "").hash
    }
    
    @objc dynamic var bundleIdentifier: String? {
        switch impl {
        case .bundle(let bundle):
            return bundle.bundleIdentifier
        case .domainName(let domainName):
            return domainName
        }
    }
    
    @objc dynamic var name: String? {
        switch impl {
        case .bundle(let bundle):
            return bundle.name
        case .domainName(let domainName):
            return domainName
        }
    }
    
    @objc dynamic var iconImage: NSImage {
        switch impl {
        case .bundle(let bundle):
            return bundle.iconImage
        case .domainName:
            return NSImage(size: .zero)
        }
    }
    
    @objc dynamic var bundlePath: String? {
        switch impl {
        case .bundle(let bundle):
            return bundle.bundlePath
        case .domainName:
            return nil
        }
    }
    
    @objc dynamic var infoDictionary: [String : Any] {
        switch impl {
        case .bundle(let bundle):
            return bundle.infoDictionary ?? [:]
        case .domainName:
            return [:]
        }
    }

}

extension Bundle {
    
    @objc dynamic var name: String? {
        return (object(forInfoDictionaryKey: "CFBundleName") as? String).flatMap { $0 == "" ? nil : $0 } ?? self.bundleURL.deletingPathExtension().lastPathComponent
    }
    
    @objc dynamic var iconImage: NSImage {
        if
            let imageName = object(forInfoDictionaryKey: "CFBundleIconFile") as? String,
            let image = image(forResource: imageName)
        {
            return image
        }
        return NSWorkspace.shared.icon(forFile: self.bundlePath)
    }
    
}
