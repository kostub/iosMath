//
//  MTLabel.m
//  MacOSMath
//
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTLabel.h"

#if !TARGET_OS_IPHONE
@implementation MTLabel

@synthesize bezeled, drawsBackground, editable, selectable, stringValue;

- (instancetype)init
{
    self = [super init];

    if (self != nil) {
        super.bezeled = NO;
        super.drawsBackground = NO;
        super.editable = NO;
        super.selectable = NO;
    }
    
    return self;
}

#pragma mark - Customized getter and setter methods for property text.
- (NSString *)text
{
    return super.stringValue;
}

- (void)setText:(NSString *)text
{
    super.stringValue = text;
}

@end
#endif
