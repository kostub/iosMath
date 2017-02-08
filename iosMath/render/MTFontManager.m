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
#import "MTFont+Internal.h"

const int kDefaultFontSize = 20;

@interface MTFontManager ()

@property (nonatomic, nonnull) NSMutableDictionary<NSString*, MTFont*>* nameToFontMap;

@end

@implementation MTFontManager

+ (instancetype) fontManager
{
    static MTFontManager* manager = nil;
    if (manager == nil) {
        manager = [MTFontManager new];
    }
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nameToFontMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (MTFont *)fontWithName:(NSString *)name size:(CGFloat)size
{
    MTFont* f = self.nameToFontMap[name];
    if (!f) {
        f = [[MTFont alloc] initFontWithName:name size:size];
        self.nameToFontMap[name] = f;
    }
    if (f.fontSize == size) {
        return f;
    } else {
        return [f copyFontWithSize:size];
    }
}

- (MTFont *)latinModernFontWithSize:(CGFloat)size
{
    return [self fontWithName:@"latinmodern-math" size:size];
}

- (MTFont *)xitsFontWithSize:(CGFloat)size
{
    return [self fontWithName:@"xits-math" size:size];
}

- (MTFont *)termesFontWithSize:(CGFloat)size
{
    return [self fontWithName:@"texgyretermes-math" size:size];
}

- (MTFont *)defaultFont
{
    return [self latinModernFontWithSize:kDefaultFontSize];
}

@end
