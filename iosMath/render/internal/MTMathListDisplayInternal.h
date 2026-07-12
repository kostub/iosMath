//
//  MTMathListDisplay+Internal.h
//  iosMath
//
//  Created by Kostub Deshmukh on 6/21/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathListDisplay.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTDisplay ()

@property (nonatomic) CGFloat ascent;
@property (nonatomic) CGFloat descent;
@property (nonatomic) CGFloat width;
@property (nonatomic) NSRange range;
@property (nonatomic) BOOL hasScript;

@end

// The Downshift protocol allows an MTDisplay to be shifted down by a given amount.
@protocol DownShift <NSObject>

@property (nonatomic) CGFloat shiftDown;

@end

@interface MTMathListDisplay ()

- (instancetype)init NS_UNAVAILABLE;

- (instancetype) initWithDisplays:(NSArray<MTDisplay*>*) displays range:(NSRange) range NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite) MTLinePosition type;
@property (nonatomic, readwrite) NSUInteger index;

@end

@interface MTCTLineDisplay ()

- (instancetype)initWithString:(NSAttributedString*) attrString position:(CGPoint)position range:(NSRange) range font:(MTFont*) font atoms:(NSArray<MTMathAtom*>*) atoms NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface MTTextDisplay ()

/**
 Designated initializer.
 - `text`: raw body (already escape-processed).
 - `textStyle`: the requested style — used for introspection only;
   `ctFont` already encodes traits.
 - `ctFont`: a CT font owned by the caller; this initializer takes its
   own retain so the caller may release.
 - `range`: the source-code character range driving this display.
 */
- (instancetype) initWithText:(NSString*) text
                    textStyle:(MTTextStyle) textStyle
                       ctFont:(CTFontRef) ctFont
                        range:(NSRange) range NS_DESIGNATED_INITIALIZER;

- (instancetype) init NS_UNAVAILABLE;

@end

@interface MTFractionDisplay ()

- (instancetype)initWithNumerator:(MTMathListDisplay*) numerator denominator:(MTMathListDisplay*) denominator position:(CGPoint) position range:(NSRange) range NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic) CGFloat numeratorUp;
@property (nonatomic) CGFloat denominatorDown;
@property (nonatomic) CGFloat linePosition;
@property (nonatomic) CGFloat lineThickness;
@property (nonatomic) MTFractionAlignment numeratorAlignment;

@end

@interface MTRadicalDisplay ()

- (instancetype)initWitRadicand:(MTMathListDisplay*) radicand glpyh:(MTDisplay*) glyph position:(CGPoint) position range:(NSRange) range NS_DESIGNATED_INITIALIZER;

- (void) setDegree:(MTMathListDisplay *)degree fontMetrics:(MTFontMathTable*) fontMetrics;

@property (nonatomic) CGFloat topKern;
@property (nonatomic) CGFloat lineThickness;

@end

// Rendering of an large glyph as an MTDisplay
@interface MTGlyphDisplay() <DownShift>

- (instancetype)initWithGlpyh:(CGGlyph) glyph range:(NSRange) range font:(MTFont*) font NS_DESIGNATED_INITIALIZER;

@end

// Rendering of a constructed glyph as an MTDisplay
@interface MTGlyphConstructionDisplay : MTDisplay<DownShift>

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithGlyphs:(NSArray<NSNumber*>*) glyphs offsets:(NSArray<NSNumber*>*) offsets font:(MTFont*) font NS_DESIGNATED_INITIALIZER;

@end

@interface MTLargeOpLimitsDisplay ()

- (instancetype) initWithNucleus:(MTDisplay*) nucleus upperLimit:(MTMathListDisplay*) upperLimit lowerLimit:(MTMathListDisplay*) lowerLimit limitShift:(CGFloat) limitShift extraPadding:(CGFloat) extraPadding NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic) CGFloat upperLimitGap;
@property (nonatomic) CGFloat lowerLimitGap;

@end

@interface MTLineDisplay ()

- (instancetype)initWithInner:(MTMathListDisplay*) inner position:(CGPoint) position range:(NSRange) range NS_DESIGNATED_INITIALIZER;

// How much the line should be moved up.
@property (nonatomic) CGFloat lineShiftUp;
@property (nonatomic) CGFloat lineThickness;

@end

@interface MTAccentDisplay ()

- (instancetype)initWithAccent:(MTGlyphDisplay*) glyph accentee:(MTMathListDisplay*) accentee range:(NSRange) range NS_DESIGNATED_INITIALIZER;

@end

// A standalone straight rule (horizontal or vertical) used to draw array `|` and \hline.
// A positioned leaf like MTGlyphDisplay: it carries its own position/width/ascent/descent
// so -recomputeDimensions folds it into the enclosing table's bounds.
@interface MTRuleDisplay : MTDisplay

// `start` is a point on the stroke's centre-line, in table-local coordinates. For a
// horizontal rule `length` extends rightward (+x); for a vertical rule it extends upward
// (+y). The stroke straddles the centre-line by thickness/2, so the initializer records
// `position` as the box's lower-left origin (inset by thickness/2 on the thickness axis);
// callers pass the raw centre-line and must not pre-offset for edge alignment.
- (instancetype) initWithStart:(CGPoint) start
                        length:(CGFloat) length
                     thickness:(CGFloat) thickness
                      vertical:(BOOL) isVertical
                         range:(NSRange) range NS_DESIGNATED_INITIALIZER;

@end

@interface MTStackDisplay ()

- (instancetype)initWithBase:(MTMathListDisplay*) base
                        over:(nullable MTDisplay*) over
                       under:(nullable MTDisplay*) under
                       range:(NSRange) range NS_DESIGNATED_INITIALIZER;

@end

/// Horizontal assembled glyph display — horizontal twin of `MTGlyphConstructionDisplay`.
/// Used to render OpenType HorizontalGlyphAssembly: [lft, ex×N, (md, ex×N), rt] with per-part
/// connector overlaps honoring MinConnectorOverlap.
@interface MTHorizontalGlyphAssemblyDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/// @param glyphs  Array of CGGlyph values (as NSNumber shortValue).
/// @param positions  Array of CGPoint values (as NSValue CGPointValue); x=horizontal offset, y=0.
/// @param font  The font used to draw the glyphs.
/// @param range  Source range in the parent math list.
- (instancetype)initWithGlyphs:(NSArray<NSNumber*>*) glyphs
                     positions:(NSArray<NSValue*>*) positions
                          font:(MTFont*) font
                         range:(NSRange) range NS_DESIGNATED_INITIALIZER;

@end


@interface MTMathBoxDisplay ()

- (instancetype) initWithChild:(MTMathListDisplay*) child
                     keepWidth:(BOOL) keepWidth
                    keepHeight:(BOOL) keepHeight
                     keepDepth:(BOOL) keepDepth
                     drawChild:(BOOL) drawChild
                        hAlign:(MTBoxHAlign) hAlign
                         range:(NSRange) range NS_DESIGNATED_INITIALIZER;

@property (nonatomic) MTMathListDisplay* child;
@property (nonatomic) BOOL drawChild;
@property (nonatomic) BOOL keepWidth;
@property (nonatomic) MTBoxHAlign hAlign;

@end

@interface MTInnerDisplay ()

- (instancetype) initWithInner:(MTMathListDisplay*) inner leftDelimiter:(MTDisplay*) leftDelimiter rightDelimiter:(MTDisplay*) rightDelimiter atIndex:(NSUInteger) index NS_DESIGNATED_INITIALIZER;

@property (nonatomic) MTMathListDisplay* inner;

@property (nonatomic, nullable) MTDisplay* leftDelimiter;
@property (nonatomic, nullable) MTDisplay* rightDelimiter;

@property (nonatomic) NSUInteger index;

@end

NS_ASSUME_NONNULL_END
