//
//  MTUnicode.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/16/14.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTUnicode.h"

@implementation NSString (Unicode)


- (NSUInteger)unicodeLength
{
    // Each unicode char is represented as 4 bytes in utf-32.
    return [self lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
}

@end
