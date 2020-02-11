

#include <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>

@interface NSColor (iosMathHexString)

+ (NSColor *)iosMathColorFromHexString:(NSString *)hexString;

@end
#endif
