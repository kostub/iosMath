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

/** A manager to load font files from disc and keep them
 in memory. */
@interface MTFontManager : NSObject

/** Get the singleton instance of MTFontManager. */
+ (nonnull instancetype) fontManager;

/** Returns the default font, which is Latin Modern Math with 20pt */
- (nonnull MTFont*) defaultFont;

/** Load a font with the given name. For the font to load, there
 must be a .otf file with the given name and a .plist file containing
 the math table data. The math table can be extracted using math_table_to_plist
 python script.
 @param name The name of the font file.
 @param size The size of the font to return.
 */
- (nonnull MTFont*) fontWithName:(nonnull NSString*) name size:(CGFloat) size;

/** Helper function to return the Xits Math font. */
- (nonnull MTFont*) xitsFontWithSize:(CGFloat) size;

/** Helper function to return the Tex Gyre Termes Math font. */
- (nonnull MTFont*) termesFontWithSize:(CGFloat) size;

/** Helper function to return the Latin Modern Math font. */
- (nonnull MTFont*) latinModernFontWithSize:(CGFloat) size;

@end
