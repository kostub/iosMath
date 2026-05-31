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
@import CoreText;

#import "MTFont.h"
#import "MTMathList.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const MTFontNameLatinModern;
extern NSString *const MTFontNameXITS;
extern NSString *const MTFontNameTermes;
extern NSString *const MTFontNameNewComputerModern;
extern NSString *const MTFontNamePagella;
extern NSString *const MTFontNameSTIXTwo;
extern NSString *const MTFontNameFiraMath;
extern NSString *const MTFontNameNotoSansMath;

/** A manager to load font files from disc and keep them
 in memory. */
@interface MTFontManager : NSObject

/** The shared font manager.

 Declared as a class property (not a `+fontManager` factory method) so that
 Swift imports it as `MTFontManager.fontManager` instead of collapsing it into
 `init()`. In Objective-C it is still reached via `[MTFontManager fontManager]`
 or `MTFontManager.fontManager`. */
@property (class, readonly, strong) MTFontManager *fontManager;

/** MTFontManager is a singleton; use +fontManager. Constructing your own
 instance bypasses the shared font cache, so init/new are unavailable. */
+ (instancetype) new NS_UNAVAILABLE;
- (instancetype) init NS_UNAVAILABLE;

/** Returns the default font, which is Latin Modern Math with 20pt */
- (MTFont *) defaultFont;

/** Load a font with the given name. For the font to load, there
 must be a .otf file with the given name and a .plist file containing
 the math table data. The math table can be extracted using math_table_to_plist
 python script.
 @param name The name of the font file.
 @param size The size of the font to return.
 */
- (MTFont *) fontWithName:(NSString *)name size:(CGFloat)size;

/**
 Returns a CoreText font suitable for `\text*` rendering. The caller owns
 the returned reference (CF_RETAINED) and must `CFRelease` it.

 - `kMTTextStyleRoman` and `kMTTextStyleSansSerif` → system text font.
 - `kMTTextStyleBold` / `kMTTextStyleItalic` → system text font with
   `kCTFontTraitBold` / `kCTFontTraitItalic` applied via
   `CTFontCreateCopyWithSymbolicTraits`. If the trait is unsatisfiable the
   plain system font is returned.
 - `kMTTextStyleTypewriter` → system monospace font.
 */
+ (CTFontRef) textCTFontForStyle:(MTTextStyle) style
                            size:(CGFloat) size CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END
