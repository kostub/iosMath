//
//  MTLabel.h
//  MacOSMath
//
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#include <TargetConditionals.h>

#if !TARGET_OS_IPHONE
@import AppKit;

@interface MTLabel : NSTextField

@property (strong) NSString *text;

@end
#endif
