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
        case globalDomain
    }
    
    private var impl: Impl
    
    /// Initializes from a Bundle instance. The domain name is the bundle's
    /// `bundleIdentifier`.
    ///
    /// - Parameter bundle: The bundle to represent as a defaults domain.
    init(bundle: Bundle) {
        impl = .bundle(bundle)
    }
    
    /// Initializes from a domain name.
    ///
    /// - Parameter domainName: The domain name to use.
    init(domainName: String) {
        switch domainName {
        case UserDefaults.globalDomain:
            self.impl = .globalDomain
        default:
            if let bundle = Bundle(identifier: domainName) {
                self.impl = .bundle(bundle)
            } else {
                self.impl = .domainName(domainName)
            }
        }
    }
    
    /// Initializes a `DefaultsDomain` representing the global domain.
    ///
    /// - Parameter globalDomain: Just a label. Pass `()`.
    init(globalDomain: ()) {
        impl = .globalDomain
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? DefaultsDomain else {
            return false
        }
        return object.domainName == domainName && object.localizedName == localizedName
    }
    
    override var hash: Int {
        return (domainName ?? localizedName ?? "").hash
    }
    
    @objc dynamic var domainName: String? {
        switch impl {
        case .bundle(let bundle):
            return bundle.bundleIdentifier
        case .domainName(let domainName):
            return domainName
        case .globalDomain:
            return UserDefaults.globalDomain
        }
    }
    
    @objc dynamic var localizedName: String? {
        switch impl {
        case .bundle(let bundle):
            return bundle.name
        case .domainName(let domainName):
            return domainName
        case .globalDomain:
            return "Global Domain"
        }
    }
    
    @objc dynamic var iconImage: NSImage {
        switch impl {
        case .bundle(let bundle):
            return bundle.iconImage
        case .domainName, .globalDomain:
            return NSImage(size: .zero)
        }
    }
    
    @objc dynamic var bundlePath: String? {
        switch impl {
        case .bundle(let bundle):
            return bundle.bundlePath
        case .domainName, .globalDomain:
            return nil
        }
    }
    
    @objc dynamic var infoDictionary: [String : Any] {
        switch impl {
        case .bundle(let bundle):
            return bundle.infoDictionary ?? [:]
        case .domainName, .globalDomain:
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
