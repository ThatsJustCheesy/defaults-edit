//
//  NSValueTransformer+NameSynthesis.m
//  defaults-edit
//
//  Created by Ian Gregory on 10-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

#import "NSValueTransformer+NameSynthesis.h"
#import "defaults_edit-Swift.h"

#import <objc/runtime.h>

@implementation NSValueTransformer (TJC_NameSynthesis)

+ (nullable NSValueTransformer *)TJC_valueTransformerForName:(NSValueTransformerName)name {
    if ([name characterAtIndex:0] != '#') goto original;
    NSRange bracketRange = [name rangeOfString:@"["];
    if (bracketRange.location == NSNotFound) goto original;
    
    {
        NSString *command = [name substringWithRange:NSMakeRange(1, bracketRange.location - 1)];
        NSString *argumentName = [name substringWithRange:NSMakeRange(bracketRange.location + 1, name.length - bracketRange.location - 1 - 1)];
        if ([command isEqualToString:@"NOT"]) {
            return [[NOTCommandTransformer alloc] initWithArgumentName:argumentName];
        } else if ([command isEqualToString:@"ENABLEDFONTCOLOR"]){
            return [[ENABLEDFONTCOLORCommandTransformer alloc] initWithArgumentName:argumentName];
        } else {
            [NSException raise:NSInvalidArgumentException format:@"Unknown #COMMAND in value transformer name"];
            return nil;
        }
    }
    
original:
    return [self TJC_valueTransformerForName:name]; // Swizzled
}

@end

@interface AppDelegate (Swizzling)
@end

static void swizzleClassMethod(Class clas, SEL targetSel, SEL newSel) {
    NSLog(@"Swizzling +[%@ %@] -> +%@", NSStringFromClass(clas), NSStringFromSelector(targetSel), NSStringFromSelector(newSel));
    method_exchangeImplementations(class_getClassMethod(clas, targetSel), class_getClassMethod(clas, newSel));
}
static void swizzleInstanceMethod(Class clas, SEL targetSel, SEL newSel) {
    NSLog(@"Swizzling -[%@ %@] -> -%@", NSStringFromClass(clas), NSStringFromSelector(targetSel), NSStringFromSelector(newSel));
    method_exchangeImplementations(class_getInstanceMethod(clas, targetSel), class_getInstanceMethod(clas, newSel));
}

@implementation AppDelegate (Swizzling)

+ (void)initialize {
    swizzleClassMethod([NSValueTransformer class], @selector(valueTransformerForName:), @selector(TJC_valueTransformerForName:));
    swizzleInstanceMethod([NSViewController class], @selector(setRepresentedObject:), @selector(TJC_setRepresentedObject:));
    swizzleInstanceMethod([NSTabViewController class], @selector(tabView:willSelectTabViewItem:), @selector(TJC_tabView:willSelect:));
}

@end
