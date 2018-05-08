//
//  NSColor+HexString.m
//  iosMath
//
//  Created by Markus Sähn on 21/03/2017.
//
//

#import "NSColor+HexString.h"

#if !TARGET_OS_IPHONE
@implementation NSColor (HexString)

+ (NSColor *)colorFromHexString:(NSString *)hexString {
    if ([hexString isEqualToString:@""]) {
        return nil;
    }
    
    if ([hexString characterAtIndex:0] != '#') {
        return nil;
    }
    
    unsigned rgbValue = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString characterAtIndex:0] == '#') {
        [scanner setScanLocation:1];
    }
    
    [scanner scanHexInt:&rgbValue];
    return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
#endif
