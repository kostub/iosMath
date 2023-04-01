
#import "NSColor+iosMathHexString.h"

#if !TARGET_OS_IPHONE
@implementation NSColor (iosMathHexString)

+ (NSColor *)iosMathColorFromHexString:(NSString *)hexString {
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
    // NOTE: red:green:blue:alpha: in AppKit/NSColor.h is NS_AVAILABLE_MAC(10_9), unavailable for macOS 10.8 .
    // Older method name colorWithSRGBRed::green:blue:alpha: works.
    return [NSColor colorWithSRGBRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
#endif
