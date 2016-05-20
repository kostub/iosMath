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

/** Returns a copy of this font but with a different size. */
- (MTFont*) copyFontWithSize:(CGFloat) size;

/** Returns the name of the given glyph or null if the glyph
 is not associated with the font. */
- (NSString*) getGlyphName:(CGGlyph) glyph;

@property (nonatomic, readonly) CTFontRef font;

@property (nonatomic, readonly) NSDictionary* mathTable;

@end
