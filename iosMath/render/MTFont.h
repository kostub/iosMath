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

/** The size of this font in points. */
@property (nonatomic, readonly) CGFloat fontSize;

/** Access to the raw CTFontRef if needed. */
@property (nonatomic, readonly) CTFontRef ctFont;
/** Access to the raw math table if needed. */
@property (nonatomic, readonly) NSDictionary* mathTable;

@end
