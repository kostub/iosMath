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

@interface MTDisplay ()

@property (nonatomic) CGFloat ascent;
@property (nonatomic) CGFloat descent;
@property (nonatomic) CGFloat width;
@property (nonatomic) NSRange range;
@property (nonatomic) BOOL hasScript;

@end

@interface MTMathListDisplay ()

- (instancetype) initWithDisplays:(NSArray*) displays range:(NSRange) range;

@property (nonatomic, readwrite) MTLinePosition type;
@property (nonatomic, readwrite) NSUInteger index;

@end

@interface MTCTLineDisplay ()

- (instancetype)initWithString:(NSAttributedString*) attrString position:(CGPoint)position range:(NSRange) range font:(MTFont*) font atoms:(NSArray<MTMathAtom*>*) atoms NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface MTFractionDisplay ()

- (instancetype)initWithNumerator:(MTMathListDisplay*) numerator denominator:(MTMathListDisplay*) denominator position:(CGPoint) position range:(NSRange) range NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic) CGFloat numeratorUp;
@property (nonatomic) CGFloat denominatorDown;
@property (nonatomic) CGFloat linePosition;
@property (nonatomic) CGFloat lineThickness;

@end

@interface MTRadicalDisplay ()

- (instancetype)initWitRadicand:(MTMathListDisplay*) radicand glpyh:(CGGlyph) glyph glyphWidth:(CGFloat) glyphWidth position:(CGPoint) position range:(NSRange) range font:(MTFont*) font NS_DESIGNATED_INITIALIZER;

- (void) setDegree:(MTMathListDisplay *)degree fontMetrics:(MTFontMathTable*) fontMetrics;

@property (nonatomic) CGFloat topKern;
@property (nonatomic) CGFloat lineThickness;
@property (nonatomic) CGFloat shiftUp;

@end

// Rendering of an large glyph as an MTDisplay
@interface MTLargeGlyphDisplay()

- (instancetype)initWithGlpyh:(CGGlyph) glyph  position:(CGPoint) position range:(NSRange) range font:(MTFont*) font NS_DESIGNATED_INITIALIZER;

// Shift the glyph down by the given amount.
@property (nonatomic) CGFloat shiftDown;

@end

@interface MTLargeOpLimitsDisplay ()

- (instancetype) initWithNucleus:(MTDisplay*) nucleus upperLimit:(MTMathListDisplay*) upperLimit lowerLimit:(MTMathListDisplay*) lowerLimit limitShift:(CGFloat) limitShift extraPadding:(CGFloat) extraPadding NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic) CGFloat upperLimitGap;
@property (nonatomic) CGFloat lowerLimitGap;

@end
