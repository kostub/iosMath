//
//  MTTypesetter+Testing.h
//  iosMath
//
//  Exposes the private -constructGlyphWithParts:height:glyphs:offsets:height:
//  method for unit-testing the loop-termination guard (FUN-4).
//  NOT part of the public API; include only from test targets.
//

#import "MTTypesetter.h"
#import "MTFontMathTable.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTTypesetter (Testing)

/// Designated initializer (normally private). Exposed so tests can construct a
/// fully initialised instance (with _styleFont set) for synthetic-parts testing.
- (instancetype)initWithFont:(MTFont *)font
                       style:(MTLineStyle)style
                     cramped:(BOOL)cramped
                      spaced:(BOOL)spaced;

/// Exposed for unit testing the no-progress / iteration-cap guard (FUN-4).
/// Builds a glyph assembly from the given parts stretched to glyphHeight.
- (void)constructGlyphWithParts:(NSArray<MTGlyphPart *> *)parts
                         height:(CGFloat)glyphHeight
                         glyphs:(NSArray<NSNumber *> *_Nonnull __autoreleasing *_Nonnull)glyphs
                        offsets:(NSArray<NSNumber *> *_Nonnull __autoreleasing *_Nonnull)offsets
                         height:(CGFloat *)height;

@end

NS_ASSUME_NONNULL_END
