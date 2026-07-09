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
    
    // Drop the leading '#'.
    NSString *hex = [hexString substringFromIndex:1];

    // Expand CSS 3-digit shorthand #RGB → #RRGGBB (e.g. "f00" → "ff0000").
    if (hex.length == 3) {
        unichar r = [hex characterAtIndex:0];
        unichar g = [hex characterAtIndex:1];
        unichar b = [hex characterAtIndex:2];
        hex = [NSString stringWithFormat:@"%C%C%C%C%C%C", r, r, g, g, b, b];
    }

    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    [scanner scanHexInt:&rgbValue];
    return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
#endif
