//
//  MTFont.h
//  iosMath
//
//  Created by Kostub Deshmukh on 5/18/16.
//
//

@import CoreText;
@import CoreGraphics;
@import Foundation;

#import "MTFontMathTable.h"

/** MTFont wraps the inconvenient distinction between CTFont and CGFont as well
 as the data loaded from the math table.
 */
@interface MTFont : NSObject

/** Load the font with a given name. This is the designated initializer. */
- (instancetype) initFontWithName:(NSString*) name;

/** Returns a copy of this font but with a different size. */
- (MTFont*) copyFontWithSize:(CGFloat) size;

/** Returns the name of the given glyph or null if the glyph
 is not associated with the font. */
- (NSString*) getGlyphName:(CGGlyph) glyph;

/** Returns a glyph associated with the given name. */
- (CGGlyph) getGlyphWithName:(NSString*) glyphName;

/** Returns a CFArray of all the vertical variants of the glyph if any.
 This array needs to be released by the caller. */
- (CFArrayRef) copyVerticalVariantsForGlyphWithName:(NSString*) glyphName;

/** Returns a larger vertical variant of the given glyph if any.
 If there is no larger version, this returns the current glyph.
 */
- (CGGlyph) getLargerGlyph:(CGGlyph) glyph;

/** The size of this font in points. */
@property (nonatomic, readonly) CGFloat fontSize;

/** Access to the raw CTFontRef if needed. */
@property (nonatomic, readonly) CTFontRef ctFont;

/** The font math table. */
@property (nonatomic, readonly) MTFontMathTable* mathTable;

@end
