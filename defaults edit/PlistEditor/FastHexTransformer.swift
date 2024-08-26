//
//  FastHexTransformer.swift
//  defaults edit
//
//  Created by Ian Gregory on 6 Jun ’20.
//  Copyright © 2020 Ian Gregory. All rights reserved.
//

import Foundation
import Data_FastHex

// TODO: Convert to an NSFormatter?

@objc(FastHexTransformer)
class FastHexTransformer: ValueTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        (value as? NSData)?.lowercaseHexStringRepresentation ?? ""
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        NSData(hexString: value as! String)
    }
    
}
