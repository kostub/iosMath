//
//  NSView+backgroundColor.m
//  MacOSMath
//
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "NSView+backgroundColor.h"

#if !TARGET_OS_IPHONE
@implementation NSView (backgroundColor)

- (NSColor *)backgroundColor
{
    return [NSColor colorWithCGColor:self.layer.backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    [self setWantsLayer:YES];
}

@end
#endif
