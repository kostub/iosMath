//
//  MTLine.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/27/13.
//  Copyright (C) 2013 MathChat
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <CoreText/CoreText.h>
#include <sys/param.h>
#include <sys/sysctl.h>

#import "MTMathListDisplay.h"
#import "MTFontMathTable.h"
#import "MTFontManager.h"
#import "MTFont+Internal.h"
#import "MTMathListDisplayInternal.h"

static BOOL isIos6Supported() {
    static BOOL initialized = false;
    static BOOL supported = false;
    if (!initialized) {
#if TARGET_OS_IPHONE
        NSString *reqSysVer = @"6.0";
        NSString *currSysVer = [UIDevice currentDevice].systemVersion;
        
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
            supported = true;
        }
#else
        supported = true;
#endif
        
        initialized = true;
    }
    return supported;
}

#pragma mark MTDisplay

@implementation MTDisplay

- (void)draw:(CGContextRef)context
{
}

- (CGRect) displayBounds
{
    return CGRectMake(self.position.x, self.position.y - self.descent, self.width, self.ascent + self.descent);
}

// Debug method skipped for MAC.
#if TARGET_OS_IPHONE
- (id)debugQuickLookObject
{
    CGSize size = CGSizeMake(self.width, self.ascent + self.descent);
    UIGraphicsBeginImageContext(size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    // move the position to (0,0)
    CGContextTranslateCTM(context, -self.position.x, -self.position.y);
    
    // Move the line up by self.descent
    CGContextTranslateCTM(context, 0, self.descent);
    // Draw self on context
    [self draw:context];
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    return img;
}
#endif

@end

#pragma mark - MTCTLine

@implementation MTCTLineDisplay

- (instancetype)initWithString:(NSAttributedString*) attrString position:(CGPoint)position range:(NSRange) range font:(MTFont*) font atoms:(NSArray<MTMathAtom*>*) atoms
{
    self = [super init];
    if (self) {
        self.position = position;
        self.attributedString = attrString;
        self.range = range;
        _atoms = atoms;
        // We can't use typographic bounds here as the ascent and descent returned are for the font and not for the line.
        self.width = CTLineGetTypographicBounds(_line, NULL, NULL, NULL);
        if (isIos6Supported()) {
            CGRect bounds = CTLineGetBoundsWithOptions(_line, kCTLineBoundsUseGlyphPathBounds);
            self.ascent = MAX(0, CGRectGetMaxY(bounds) - 0);
            self.descent = MAX(0, 0 - CGRectGetMinY(bounds));
            // TODO: Should we use this width vs the typographic width? They are slightly different. Don't know why.
            // _width = CGRectGetMaxX(bounds);
        } else {
            // Our own implementation of the ios6 function to get glyph path bounds.
            [self computeDimensions:font];
        }
    }
    return self;
}

- (void) setAttributedString:(NSAttributedString*) attrString
{
    if (_line) {
        CFRelease(_line);
    }
    _attributedString = [attrString copy];
    _line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)(_attributedString));
}

- (void)setTextColor:(MTColor *)textColor
{
    [super setTextColor:textColor];
    NSMutableAttributedString* attrStr = self.attributedString.mutableCopy;
    [attrStr addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)self.textColor.CGColor
                    range:NSMakeRange(0, attrStr.length)];
    self.attributedString = attrStr;
}

- (void) computeDimensions:(MTFont*) font
{
    NSArray* runs = (__bridge NSArray *)(CTLineGetGlyphRuns(_line));
    for (id obj in runs) {
        CTRunRef run = (__bridge CTRunRef)(obj);
        CFIndex numGlyphs = CTRunGetGlyphCount(run);
        CGGlyph glyphs[numGlyphs];
        CTRunGetGlyphs(run, CFRangeMake(0, numGlyphs), glyphs);
        CGRect bounds = CTFontGetBoundingRectsForGlyphs(font.ctFont, kCTFontHorizontalOrientation, glyphs, NULL, numGlyphs);
        CGFloat ascent = MAX(0, CGRectGetMaxY(bounds) - 0);
        // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
        CGFloat descent = MAX(0, 0 - CGRectGetMinY(bounds));
        if (ascent > self.ascent) {
            self.ascent = ascent;
        }
        if (descent > self.descent) {
            self.descent = descent;
        }
    }
}

- (void)dealloc
{
    CFRelease(_line);
}

- (void)draw:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    CGContextSetTextPosition(context, self.position.x, self.position.y);
    CTLineDraw(_line, context);
    
    CGContextRestoreGState(context);
}

@end

#pragma mark - MTLine

@implementation MTMathListDisplay {
    NSUInteger _index;
}


- (instancetype) initWithDisplays:(NSArray<MTDisplay*>*) displays range:(NSRange) range
{
    self = [super init];
    if (self) {
        _subDisplays = [displays copy];
        self.position = CGPointZero;
        _type = kMTLinePositionRegular;
        _index = NSNotFound;
        self.range = range;
        [self recomputeDimensions];
    }
    return self;
}

- (void) setType:(MTLinePosition) type
{
    _type = type;
}

- (void) setIndex:(NSUInteger) index
{
    _index = index;
}

- (void)setTextColor:(MTColor *)textColor
{
    // Set the color on all subdisplays
    [super setTextColor:textColor];
    for (MTDisplay* displayAtom in self.subDisplays) {
        // set the global color, if there is no local color
        if(displayAtom.localTextColor == nil) {
            displayAtom.textColor = textColor;
        } else {
            displayAtom.textColor = displayAtom.localTextColor;
        }
        
    }
}

- (void)draw:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    CGContextTranslateCTM(context, self.position.x, self.position.y);
    CGContextSetTextPosition(context, 0, 0);
    
    // draw each atom separately
    for (MTDisplay* displayAtom in self.subDisplays) {
        [displayAtom draw:context];
    }
    
    CGContextRestoreGState(context);
}

- (void) recomputeDimensions
{
    CGFloat max_ascent = 0;
    CGFloat max_descent = 0;
    CGFloat max_width = 0;
    for (MTDisplay* atom in self.subDisplays) {
        CGFloat ascent = MAX(0, atom.position.y + atom.ascent);
        if (ascent > max_ascent) {
            max_ascent = ascent;
        }
        
        CGFloat descent = MAX(0, 0 - (atom.position.y - atom.descent));
        if (descent > max_descent) {
            max_descent = descent;
        }
        CGFloat width = atom.width + atom.position.x;
        if (width > max_width) {
            max_width = width;
        }
    }
    self.ascent = max_ascent;
    self.descent = max_descent;
    self.width = max_width;
}


@end

#pragma mark - MTFractionDisplay

@implementation MTFractionDisplay

- (instancetype)initWithNumerator:(MTMathListDisplay*) numerator denominator:(MTMathListDisplay*) denominator position:(CGPoint) position range:(NSRange) range
{
    self = [super init];
    if (self) {
        _numerator = numerator;
        _denominator = denominator;
        self.position = position;
        self.range = range;
        NSAssert(self.range.length == 1, @"Fraction range length not 1 - range (%lu, %lu)", (unsigned long)range.location, (unsigned long)range.length);
    }
    return self;
}

- (CGFloat)ascent
{
    return _numerator.ascent + self.numeratorUp;
}

- (CGFloat)descent
{
    return _denominator.descent + self.denominatorDown;
}

- (CGFloat)width
{
    return MAX(_numerator.width, _denominator.width);
}

- (void)setDenominatorDown:(CGFloat)denominatorDown
{
    _denominatorDown = denominatorDown;
    [self updateDenominatorPosition];
}

- (void) setNumeratorUp:(CGFloat)numeratorUp
{
    _numeratorUp = numeratorUp;
    [self updateNumeratorPosition];
}

- (void) updateDenominatorPosition
{
    _denominator.position = CGPointMake(self.position.x + (self.width - _denominator.width)/2, self.position.y - self.denominatorDown);
}

- (void) updateNumeratorPosition
{
    _numerator.position = CGPointMake(self.position.x + (self.width - _numerator.width)/2, self.position.y + self.numeratorUp);
}

- (void) setPosition:(CGPoint)position
{
    super.position = position;
    [self updateDenominatorPosition];
    [self updateNumeratorPosition];
}

- (void)setTextColor:(MTColor *)textColor
{
    [super setTextColor:textColor];
    _numerator.textColor = textColor;
    _denominator.textColor = textColor;
}

- (void)draw:(CGContextRef)context
{
    [_numerator draw:context];
    [_denominator draw:context];
    
    CGContextSaveGState(context);
    
    [self.textColor setStroke];
    
    // draw the horizontal line
    MTBezierPath* path = [MTBezierPath bezierPath];
    [path moveToPoint:CGPointMake(self.position.x, self.position.y + self.linePosition)];
    [path addLineToPoint:CGPointMake(self.position.x + self.width, self.position.y + self.linePosition)];
    path.lineWidth = self.lineThickness;
    [path stroke];
    
    CGContextRestoreGState(context);
}

@end

#pragma mark - MTRadicalDisplay

@implementation MTRadicalDisplay {
    MTDisplay* _radicalGlyph;
    CGFloat _radicalShift;
}

- (instancetype)initWitRadicand:(MTMathListDisplay*) radicand glpyh:(MTDisplay*) glyph position:(CGPoint) position range:(NSRange) range
{
    self = [super init];
    if (self) {
        _radicand = radicand;
        _radicalGlyph = glyph;
        _radicalShift = 0;
        
        self.position = position;
        self.range = range;
    }
    return self;
}

- (void) setDegree:(MTMathListDisplay *)degree fontMetrics:(MTFontMathTable*) fontMetrics
{
    // sets up the degree of the radical
    CGFloat kernBefore = fontMetrics.radicalKernBeforeDegree;
    CGFloat kernAfter = fontMetrics.radicalKernAfterDegree;
    CGFloat raise = fontMetrics.radicalDegreeBottomRaisePercent * (self.ascent - self.descent);
    
    // The layout is:
    // kernBefore, raise, degree, kernAfter, radical
    _degree = degree;
    
    // the radical is now shifted by kernBefore + degree.width + kernAfter
    _radicalShift = kernBefore + degree.width + kernAfter;
    if (_radicalShift < 0) {
        // we can't have the radical shift backwards, so instead we increase the kernBefore such
        // that _radicalShift will be 0.
        kernBefore -= _radicalShift;
        _radicalShift = 0;
    }
    
    // Note: position of degree is relative to parent.
    self.degree.position = CGPointMake(self.position.x + kernBefore, self.position.y + raise);
    // Update the width by the _radicalShift
    self.width = _radicalShift + _radicalGlyph.width + self.radicand.width;
    // update the position of the radicand
    [self updateRadicandPosition];
}

- (void) setPosition:(CGPoint)position
{
    super.position = position;
    [self updateRadicandPosition];
}

- (void) updateRadicandPosition
{
    // The position of the radicand includes the position of the MTRadicalDisplay
    // This is to make the positioning of the radical consistent with fractions and
    // have the cursor position finding algorithm work correctly.
    // move the radicand by the width of the radical sign
    self.radicand.position = CGPointMake(self.position.x + _radicalShift + _radicalGlyph.width, self.position.y);
}

- (void)setTextColor:(MTColor *)textColor
{
    [super setTextColor:textColor];
    self.radicand.textColor = textColor;
    self.degree.textColor = textColor;
}

- (void)draw:(CGContextRef)context
{
    // draw the radicand & degree at its position
    [self.radicand draw:context];
    [self.degree draw:context];
    
    CGContextSaveGState(context);
    [self.textColor setStroke];
    [self.textColor setFill];
    
    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    CGContextTranslateCTM(context, self.position.x + _radicalShift, self.position.y);
    CGContextSetTextPosition(context, 0, 0);
    
    // Draw the glyph.
    [_radicalGlyph draw:context];
    
    // Draw the VBOX
    // for the kern of, we don't need to draw anything.
    CGFloat heightFromTop = _topKern;
    
    // draw the horizontal line with the given thickness
    MTBezierPath* path = [MTBezierPath bezierPath];
    CGPoint lineStart = CGPointMake(_radicalGlyph.width, self.ascent - heightFromTop - self.lineThickness / 2); // subtract half the line thickness to center the line
    CGPoint lineEnd = CGPointMake(lineStart.x + self.radicand.width, lineStart.y);
    [path moveToPoint:lineStart];
    [path addLineToPoint:lineEnd];
    path.lineWidth = _lineThickness;
    path.lineCapStyle = kCGLineCapRound;
    [path stroke];
    
    CGContextRestoreGState(context);
}

@end

#pragma mark - MTGlyphDisplay

@implementation MTGlyphDisplay {
    CGGlyph _glyph;
    MTFont* _font;
}

@synthesize shiftDown;

- (instancetype)initWithGlpyh:(CGGlyph) glyph range:(NSRange) range font:(MTFont*) font
{
    self = [super init];
    if (self) {
        _font = font;
        _glyph = glyph;
        
        self.position = CGPointZero;
        self.range = range;
    }
    return self;
}

- (void)draw:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    [self.textColor setFill];
    
    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    CGContextTranslateCTM(context, self.position.x, self.position.y - self.shiftDown);
    CGContextSetTextPosition(context, 0, 0);
    
    CTFontDrawGlyphs(_font.ctFont, &_glyph, &CGPointZero, 1, context);
    
    CGContextRestoreGState(context);
}

- (CGFloat)ascent
{
    return super.ascent - self.shiftDown;
}

- (CGFloat)descent
{
    return super.descent + self.shiftDown;
}

@end

#pragma mark - MTGlyphConstructionDisplay

@implementation MTGlyphConstructionDisplay {
    CGGlyph *_glyphs;
    CGPoint *_positions;
    MTFont* _font;
    NSInteger _numGlyphs;
}

@synthesize shiftDown;

- (instancetype)initWithGlyphs:(NSArray<NSNumber *> *)glyphs offsets:(NSArray<NSNumber *> *)offsets font:(MTFont *)font
{
    self = [super init];
    if (self) {
        NSAssert(glyphs.count == offsets.count, @"Glyphs and offsets need to match");
        _numGlyphs = glyphs.count;
        _glyphs = malloc(sizeof(CGGlyph) * _numGlyphs);
        _positions = malloc(sizeof(CGPoint) * _numGlyphs);
        for (int i = 0; i < _numGlyphs; i++) {
            _glyphs[i] = glyphs[i].shortValue;
            _positions[i] = CGPointMake(0, offsets[i].floatValue);
        }
        _font = font;
        self.position = CGPointZero;
    }
    return self;
}

- (void)draw:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    [self.textColor setFill];
    
    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    CGContextTranslateCTM(context, self.position.x, self.position.y - self.shiftDown);
    CGContextSetTextPosition(context, 0, 0);
    
    // Draw the glyphs.
    CTFontDrawGlyphs(_font.ctFont, _glyphs, _positions, _numGlyphs, context);
    
    CGContextRestoreGState(context);
}

- (CGFloat)ascent
{
    return super.ascent - self.shiftDown;
}

- (CGFloat)descent
{
    return super.descent + self.shiftDown;
}

- (void)dealloc
{
    free(_glyphs);
    free(_positions);
}

@end

#pragma mark - MTLargeOpLimitsDisplay

@implementation MTLargeOpLimitsDisplay {
    CGFloat _limitShift;
    CGFloat _upperLimitGap;
    CGFloat _lowerLimitGap;
    CGFloat _extraPadding;
    
    MTDisplay *_nucleus;
}

- (instancetype) initWithNucleus:(MTDisplay*) nucleus upperLimit:(MTMathListDisplay*) upperLimit lowerLimit:(MTMathListDisplay*) lowerLimit limitShift:(CGFloat) limitShift extraPadding:(CGFloat) extraPadding
{
    self = [super init];
    if (self) {
        _upperLimit = upperLimit;
        _lowerLimit = lowerLimit;
        _nucleus = nucleus;
        
        CGFloat maxWidth = MAX(nucleus.width, upperLimit.width);
        maxWidth = MAX(maxWidth, lowerLimit.width);
        
        _limitShift = limitShift;
        _upperLimitGap = 0;
        _lowerLimitGap = 0;
        _extraPadding = extraPadding;  // corresponds to \xi_13 in TeX
        self.width = maxWidth;
    }
    return self;
}

- (CGFloat)ascent
{
    if (self.upperLimit) {
        return _nucleus.ascent + _extraPadding + self.upperLimit.ascent + _upperLimitGap + self.upperLimit.descent;
    } else {
        return _nucleus.ascent;
    }
}

- (CGFloat)descent
{
    if (self.lowerLimit) {
        return _nucleus.descent + _extraPadding + _lowerLimitGap + self.lowerLimit.descent + self.lowerLimit.ascent;
    } else {
        return _nucleus.descent;
    }
}

- (void)setLowerLimitGap:(CGFloat)lowerLimitGap
{
    _lowerLimitGap = lowerLimitGap;
    [self updateLowerLimitPosition];
}

- (void) setUpperLimitGap:(CGFloat)upperLimitGap
{
    _upperLimitGap = upperLimitGap;
    [self updateUpperLimitPosition];
}

- (void)setPosition:(CGPoint)position
{
    super.position = position;
    [self updateLowerLimitPosition];
    [self updateUpperLimitPosition];
    [self updateNucleusPosition];
}

- (void) updateLowerLimitPosition
{
    if (self.lowerLimit) {
        // The position of the lower limit includes the position of the MTLargeOpLimitsDisplay
        // This is to make the positioning of the radical consistent with fractions and radicals
        // Move the starting point to below the nucleus leaving a gap of _lowerLimitGap and subtract
        // the ascent to to get the baseline. Also center and shift it to the left by _limitShift.
        self.lowerLimit.position = CGPointMake(self.position.x - _limitShift + (self.width - _lowerLimit.width)/2,
                                               self.position.y - _nucleus.descent - _lowerLimitGap - self.lowerLimit.ascent);
    }
}

- (void) updateUpperLimitPosition
{
    if (self.upperLimit) {
        // The position of the upper limit includes the position of the MTLargeOpLimitsDisplay
        // This is to make the positioning of the radical consistent with fractions and radicals
        // Move the starting point to above the nucleus leaving a gap of _upperLimitGap and add
        // the descent to to get the baseline. Also center and shift it to the right by _limitShift.
        self.upperLimit.position = CGPointMake(self.position.x + _limitShift + (self.width - self.upperLimit.width)/2,
                                               self.position.y + _nucleus.ascent + _upperLimitGap + self.upperLimit.descent);
    }
}

- (void) updateNucleusPosition
{
    // Center the nucleus
    _nucleus.position = CGPointMake(self.position.x + (self.width - _nucleus.width)/2, self.position.y);
}

- (void)setTextColor:(MTColor *)textColor
{
    [super setTextColor:textColor];
    self.upperLimit.textColor = textColor;
    self.lowerLimit.textColor = textColor;
    _nucleus.textColor = textColor;
}

- (void)draw:(CGContextRef)context
{
    // Draw the elements.
    [self.upperLimit draw:context];
    [self.lowerLimit draw:context];
    [_nucleus draw:context];
}

@end

#pragma mark - MTLineDisplay

@implementation MTLineDisplay

- (instancetype)initWithInner:(MTMathListDisplay *)inner position:(CGPoint) position range:(NSRange)range
{
    self = [super init];
    if (self) {
        _inner = inner;
        
        self.position = position;
        self.range = range;
    }
    return self;
}

- (void)setTextColor:(MTColor *)textColor
{
    [super setTextColor:textColor];
    _inner.textColor = textColor;
}

- (void)draw:(CGContextRef)context
{
    [self.inner draw:context];
    
    CGContextSaveGState(context);
    
    [self.textColor setStroke];
    
    // draw the horizontal line
    MTBezierPath* path = [MTBezierPath bezierPath];
    CGPoint lineStart = CGPointMake(self.position.x, self.position.y + self.lineShiftUp);
    CGPoint lineEnd = CGPointMake(lineStart.x + self.inner.width, lineStart.y);
    [path moveToPoint:lineStart];
    [path addLineToPoint:lineEnd];
    path.lineWidth = self.lineThickness;
    [path stroke];
    
    CGContextRestoreGState(context);
}

- (void) setPosition:(CGPoint)position
{
    super.position = position;
    [self updateInnerPosition];
}

- (void) updateInnerPosition
{
    self.inner.position = CGPointMake(self.position.x, self.position.y);
}

@end

#pragma mark - MTAccentDisplay

@implementation MTAccentDisplay

- (instancetype)initWithAccent:(MTGlyphDisplay*) glyph accentee:(MTMathListDisplay*) accentee range:(NSRange) range
{
    self = [super init];
    if (self) {
        _accent = glyph;
        _accentee = accentee;
        _accentee.position = CGPointZero;
        self.range = range;
    }
    return self;
}

- (void)setTextColor:(MTColor *)textColor
{
    [super setTextColor:textColor];
    _accentee.textColor = textColor;
    _accent.textColor = textColor;
}

- (void) setPosition:(CGPoint)position
{
    super.position = position;
    [self updateAccenteePosition];
}

- (void) updateAccenteePosition
{
    self.accentee.position = CGPointMake(self.position.x, self.position.y);
}

- (void)draw:(CGContextRef)context
{
    [self.accentee draw:context];
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, self.position.x, self.position.y);
    CGContextSetTextPosition(context, 0, 0);
    
    [self.accent draw:context];
    
    CGContextRestoreGState(context);
}
@end
