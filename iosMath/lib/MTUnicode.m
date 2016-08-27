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

const unichar kMTUnicodeCapitalGreekStart = 0x0391;
const unichar kMTUnicodeCapitalGreekEnd = 0x03A9;
const unichar kMTUnicodeGreekStart = 0x03B1;
const unichar kMTUnicodeGreekEnd = 0x03C9;
const unichar kMTUnicodePlanksConstant = 0x210e;
const UTF32Char kMTUnicodeMathItalicStart = 0x1D44E;
const UTF32Char kMTUnicodeMathCapitalItalicStart = 0x1D434;
const UTF32Char kMTUnicodeGreekMathItalicStart = 0x1D6FC;
const UTF32Char kMTUnicodeGreekMathCapitalItalicStart = 0x1D6E2;

@implementation NSString (Unicode)


- (NSUInteger)unicodeLength
{
    // Each unicode char is represented as 4 bytes in utf-32.
    return [self lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
}

@end