//
//  MTConfig.h
//  MacOSMath
//
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

// Make TARGET_OS_IPHONE macro visible.
#include <TargetConditionals.h>

// Type definitions.
#if TARGET_OS_IPHONE
// TARGET_OS_MAC is defined as 1 for both Mac OS and iOS,
// so TARGET_OS_IPHONE is reliable.
@import UIKit;
#import "UIColor+HexString.h"

typedef UIView          MTView;
typedef UIColor         MTColor;
typedef UIBezierPath    MTBezierPath;
typedef UIEdgeInsets    MTEdgeInsets;
typedef UILabel         MTLabel;
typedef CGRect          MTRect;

#define MTEdgeInsetsZero UIEdgeInsetsZero
#define MTGraphicsGetCurrentContext() UIGraphicsGetCurrentContext()
#define MTLineCapStyleRound kCGLineCapRound

#else
@import AppKit;
#import "NSBezierPath+addLineToPoint.h"
#import "NSView+backgroundColor.h"
#import "NSColor+HexString.h"
#import "MTLabel.h"

typedef NSView          MTView;
typedef NSColor         MTColor;
typedef NSBezierPath    MTBezierPath;
typedef NSEdgeInsets    MTEdgeInsets;
typedef NSRect          MTRect;

#define MTEdgeInsetsZero NSEdgeInsetsZero
#define MTGraphicsGetCurrentContext() ([[NSGraphicsContext currentContext] CGContext])
#define MTLineCapStyleRound NSLineCapStyleRound

#endif  // TARGET_OS_IPHONE
