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

@implementation MTFontManager

+ (id) fontManager
{
    static MTFontManager* manager = nil;
    if (manager == nil) {
        manager = [MTFontManager new];
    }
    return manager;
}

- (id) init
{
    self = [super init];
    if (self) {
        NSLog(@"Loading font latinmodern math");
        // Uses bundle for class so that this can be access by the unit tests.
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString* fontPath = [bundle pathForResource:@"latinmodern-math" ofType:@"otf"];
        CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename([fontPath UTF8String]);
        _defaultLabelFont = CGFontCreateWithDataProvider(fontDataProvider);
        CFRelease(fontDataProvider);
        NSLog(@"Num glyphs: %zd", CGFontGetNumberOfGlyphs(_defaultLabelFont));
    }
    return self;
}

- (CTFontRef)createCTFontFromDefaultFont:(CGFloat) size
{
    // CTFontCreateWithName does not load the complete math font, it only has about half the glyphs of the full math font.
    // In particular it does not have the math italic characters which breaks our variable rendering.
    // So we first load a CGFont from the file and then convert it to a CTFont.
    CTFontRef font = CTFontCreateWithGraphicsFont(_defaultLabelFont, size, nil, nil);
    return font;
}

- (void) dealloc
{
    CGFontRelease(_defaultLabelFont);
}

@end
