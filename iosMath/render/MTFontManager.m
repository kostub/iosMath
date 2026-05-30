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

NSString *const MTFontNameLatinModern       = @"latinmodern-math";
NSString *const MTFontNameXITS              = @"xits-math";
NSString *const MTFontNameTermes            = @"texgyretermes-math";
NSString *const MTFontNameNewComputerModern = @"newcm-math";
NSString *const MTFontNamePagella           = @"texgyrepagella-math";
NSString *const MTFontNameSTIXTwo           = @"stixtwo-math";
NSString *const MTFontNameFiraMath          = @"firamath";
NSString *const MTFontNameNotoSansMath      = @"notosansmath";

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

- (MTFont *)defaultFont
{
    return [self fontWithName:MTFontNameLatinModern size:kDefaultFontSize];
}

+ (CTFontRef) textCTFontForStyle:(MTTextStyle) style
                            size:(CGFloat) size
{
    CTFontUIFontType base;
    switch (style) {
        case kMTTextStyleTypewriter:
            base = kCTFontUIFontUserFixedPitch;
            break;
        case kMTTextStyleRoman:
        case kMTTextStyleBold:
        case kMTTextStyleItalic:
        case kMTTextStyleSansSerif:
        default:
            base = kCTFontUIFontSystem;
            break;
    }

    CTFontRef baseFont = CTFontCreateUIFontForLanguage(base, size, NULL);

    CTFontSymbolicTraits requested = 0;
    if (style == kMTTextStyleBold)   requested |= kCTFontTraitBold;
    if (style == kMTTextStyleItalic) requested |= kCTFontTraitItalic;

    if (requested == 0) {
        return baseFont;
    }

    CTFontRef styled = CTFontCreateCopyWithSymbolicTraits(
        baseFont, size, NULL, requested, requested);
    if (styled != NULL) {
        CFRelease(baseFont);
        return styled;
    }
    return baseFont;
}

@end
