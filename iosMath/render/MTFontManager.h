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

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface MTFontManager : NSObject

+ (id) fontManager;

// The caller is responsible for releasing this font.
- (CTFontRef) createCTFontFromDefaultFont:(CGFloat) size;

@property (nonatomic, readonly) CGFontRef defaultLabelFont;

@end
