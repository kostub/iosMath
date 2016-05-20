//
//  MTFontManager.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/30/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//  

@import Foundation;

#import "MTFont.h"

@interface MTFontManager : NSObject

+ (instancetype) fontManager;

- (MTFont*) defaultFont;

@end
