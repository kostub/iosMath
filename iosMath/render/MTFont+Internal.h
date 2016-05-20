//
//  MTFont+Internal.h
//  iosMath
//
//  Created by Kostub Deshmukh on 5/20/16.
//
//

#import "MTFont.h"

@interface MTFont (Internal)

/** Load the font with a given name. This is the designated initializer. */
- (instancetype) initFontWithName:(NSString*) name;

/** Access to the raw CTFontRef if needed. */
@property (nonatomic, readonly) CTFontRef ctFont;

/** The font math table. */
@property (nonatomic, readonly) MTFontMathTable* mathTable;

/** Returns the name of the given glyph or null if the glyph
 is not associated with the font. */
- (NSString*) getGlyphName:(CGGlyph) glyph;

/** Returns a glyph associated with the given name. */
- (CGGlyph) getGlyphWithName:(NSString*) glyphName;

@end
