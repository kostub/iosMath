//
//  UIColor+HexString.h
//  iosMath
//
//  Created by Markus Sähn on 21/03/2017.
//
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

@interface UIColor (HexString)

+ (UIColor *)colorFromHexString:(NSString *)hexString;

@end
#endif
