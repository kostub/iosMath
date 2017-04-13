//
//  NSColor+HexString.h
//  iosMath
//
//  Created by Markus Sähn on 21/03/2017.
//
//

#include <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>

@interface NSColor (HexString)

+ (NSColor *)colorFromHexString:(NSString *)hexString;

@end
#endif
