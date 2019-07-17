//
//  FastHexTransformer.m
//  defaults-edit
//
//  Created by Ian Gregory on 23-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

#import "FastHexTransformer.h"
#import "NSData+FastHex.h"

// TODO: Convert to an NSFormatter

@implementation FastHexTransformer

- (NSString *)transformedValue:(id)value {
    if ([value isKindOfClass:[NSData class]]) {
        return [(NSData *)value hexStringRepresentationUppercase:NO];
    } else {
        return @"";
    }
}

- (NSData *)reverseTransformedValue:(NSString *)value {
    return [[NSData alloc] initWithHexString:value ignoreOtherCharacters:YES];
}

@end
