//
//  NSView+backgroundColor.h
//  MacOSMath
//
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#include <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>

@interface NSView (backgroundColor)

@property (strong) NSColor *backgroundColor;

@end
#endif
