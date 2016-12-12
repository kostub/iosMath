//
//  UIColor+HexString.m
//  iosMath
//
//  Created by Jakub Dolecki on 12/5/16.
//
//

#import "UIColor+HexString.h"

@implementation UIColor (HexString)

+ (UIColor *)colorFromHexString:(NSString *)hexString
{
    if ([hexString isEqualToString:@""]) {
        return nil;
    }
    
    unsigned rgbValue = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString characterAtIndex:0] == '#') {
        [scanner setScanLocation:1]; // bypass '#' character
    }
    
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
