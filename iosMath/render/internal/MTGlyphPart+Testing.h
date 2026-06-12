//
//  MTGlyphPart+Testing.h
//  iosMath
//
//  Redeclares MTGlyphPart's writable properties (originally in the class
//  extension inside MTFontMathTable.m) so test code can build synthetic
//  MTGlyphPart instances for unit-testing constructGlyphWithParts: (FUN-4).
//  NOT part of the public API; include only from test targets.
//

#import "MTFontMathTable.h"

@interface MTGlyphPart (Testing)

@property (nonatomic) CGGlyph glyph;
@property (nonatomic) CGFloat fullAdvance;
@property (nonatomic) CGFloat startConnectorLength;
@property (nonatomic) CGFloat endConnectorLength;
@property (nonatomic) BOOL isExtender;

@end
