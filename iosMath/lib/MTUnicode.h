//
//  MTUnicode.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/16/14.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>


FOUNDATION_EXPORT const unichar kMTUnicodeCapitalGreekStart;
FOUNDATION_EXPORT const unichar kMTUnicodeCapitalGreekEnd;
FOUNDATION_EXPORT const unichar kMTUnicodeGreekStart;
FOUNDATION_EXPORT const unichar kMTUnicodeGreekEnd;
FOUNDATION_EXPORT const unichar kMTUnicodePlanksConstant;

FOUNDATION_EXPORT const UTF32Char kMTUnicodeMathItalicStart;
FOUNDATION_EXPORT const UTF32Char kMTUnicodeGreekMathItalicStart;
FOUNDATION_EXPORT const UTF32Char kMTUnicodeMathCapitalItalicStart;
FOUNDATION_EXPORT const UTF32Char kMTUnicodeGreekMathCapitalItalicStart;


@interface NSString (Unicode)

- (NSUInteger) unicodeLength;

@end
