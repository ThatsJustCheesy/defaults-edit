//
//  PlistItem.swift
//  defaults-edit
//
//  Created by Ian Gregory on 16-07-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Foundation

@objc enum PlistType: Int, CaseIterable {
    case string, boolean, integer, real, date, data, dictionary, array
    
    init?(typeOf object: Any) {
        switch object {
        case is String, is NSString:
            self = .string
        case is NSNumber:
            // Could be integer, real or boolean, no way to know for sure
            return nil
        case is Date, is NSDate:
            self = .date
        case is Data, is NSData:
            self = .data
        case is [String : Any], is NSDictionary:
            self = .dictionary
        case is [Any], is NSArray:
            self = .array
        default:
            return nil
        }
    }
}

@objc protocol PlistValue: NSObjectProtocol {
    
    @objc /*dynamic*/ var type: PlistType { get set }
    @objc /*dynamic*/ var value: AnyObject? { get set }
    
}

@objc(PlistItem)
class PlistItem: NSObject, PlistValue {
    
    @objc dynamic var key: String = "Key"
    @objc dynamic var type: PlistType = .string {
        didSet {
            if
                oldValue == .integer && type == .real ||
                oldValue == .real && type == .integer
            {
                return
            } else {
                value = nil
            }
        }
    }
    @objc dynamic var value: AnyObject? = "" as AnyObject
    
    @objc var isValid: Bool {
        return (try? validate()) != nil
    }
    @objc class func keyPathsForValuesAffectingIsValid() -> Set<String> {
        return ["key"]
    }
    
    func validate() throws {
        try validate(key: key)
    }
    
    @objc(validateKey:error:)
    func validate(key ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        try validate(key: ioValue.pointee as? String)
    }
    private func validate(key: String?) throws {
        guard let key = key, key != "" else {
            throw NSError(domain: "defaults-edit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Key must not be empty.", NSLocalizedRecoverySuggestionErrorKey: "Set the “Key” field to the desired value and try again."])
        }
    }
    
}
