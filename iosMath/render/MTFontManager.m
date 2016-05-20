//
//  MTFontManager.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/30/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTFontManager.h"

@implementation MTFontManager {
    MTFont* _defaultFont;
}

+ (instancetype) fontManager
{
    static MTFontManager* manager = nil;
    if (manager == nil) {
        manager = [MTFontManager new];
    }
    return manager;
}

- (MTFont *)defaultFont
{
    if (!_defaultFont) {
        _defaultFont = [[MTFont alloc] initFontWithName:@"latinmodern-math"];
    }
    return _defaultFont;
}

@end
