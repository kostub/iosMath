//
//  NSBezierPath+addLineToPoint.m
//  MacOSMath
//
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "NSBezierPath+addLineToPoint.h"

#if !TARGET_OS_IPHONE
@implementation NSBezierPath (addLineToPoint)

- (void)addLineToPoint:(CGPoint)point
{
    [self lineToPoint:point];
}

@end
#endif
