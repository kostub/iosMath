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

#import "MTMathListDisplay.h"
#import "MTFontMathTable.h"
#import "MTFontManager.h"
#import "MTUnicode.h"
#import "MTFont+Internal.h"

#pragma mark Inter Element Spacing

typedef enum {
    kMTSpaceInvalid = -1,
    kMTSpaceNone = 0,
    kMTSpaceThin,
    kMTSpaceNSThin,    // Thin but not in script mode
    kMTSpaceNSMedium,
    kMTSpaceNSThick,
} MTInterElementSpaceType;


NSArray* getInterElementSpaces() {
    static NSArray* interElementSpaceArray = nil;
    if (!interElementSpaceArray) {
        interElementSpaceArray =
        //   ordinary             operator             binary               relation            open                 close               punct               // fraction
        @[ @[@(kMTSpaceNone),     @(kMTSpaceThin),     @(kMTSpaceNSMedium), @(kMTSpaceNSThick), @(kMTSpaceNone),     @(kMTSpaceNone),    @(kMTSpaceNone),    @(kMTSpaceNSThin)],    // ordinary
           @[@(kMTSpaceThin),     @(kMTSpaceThin),     @(kMTSpaceInvalid),  @(kMTSpaceNSThick), @(kMTSpaceNone),     @(kMTSpaceNone),    @(kMTSpaceNone),    @(kMTSpaceNSThin)],    // operator
           @[@(kMTSpaceNSMedium), @(kMTSpaceNSMedium), @(kMTSpaceInvalid),  @(kMTSpaceInvalid), @(kMTSpaceNSMedium), @(kMTSpaceInvalid), @(kMTSpaceInvalid), @(kMTSpaceNSMedium)],  // binary
           @[@(kMTSpaceNSThick),  @(kMTSpaceNSThick),  @(kMTSpaceInvalid),  @(kMTSpaceNone),    @(kMTSpaceNSThick),  @(kMTSpaceNone),    @(kMTSpaceNone),    @(kMTSpaceNSThick)],   // relation
           @[@(kMTSpaceNone),     @(kMTSpaceNone),     @(kMTSpaceInvalid),  @(kMTSpaceNone),    @(kMTSpaceNone),     @(kMTSpaceNone),    @(kMTSpaceNone),    @(kMTSpaceNone)],      // open
           @[@(kMTSpaceNone),     @(kMTSpaceThin),     @(kMTSpaceNSMedium), @(kMTSpaceNSThick), @(kMTSpaceNone),     @(kMTSpaceNone),    @(kMTSpaceNone),    @(kMTSpaceNSThin)],    // close
           @[@(kMTSpaceNSThin),   @(kMTSpaceNSThin),   @(kMTSpaceInvalid),  @(kMTSpaceNSThin),  @(kMTSpaceNSThin),   @(kMTSpaceNSThin),  @(kMTSpaceNSThin),  @(kMTSpaceNSThin)],    // punct
           @[@(kMTSpaceNSThin),   @(kMTSpaceThin),     @(kMTSpaceNSMedium), @(kMTSpaceNSThick), @(kMTSpaceNSThin),   @(kMTSpaceNone),    @(kMTSpaceNSThin),  @(kMTSpaceNSThin)],    // fraction
           @[@(kMTSpaceNSMedium), @(kMTSpaceNSThin),   @(kMTSpaceNSMedium), @(kMTSpaceNSThick), @(kMTSpaceNone),     @(kMTSpaceNone),    @(kMTSpaceNone),    @(kMTSpaceNSThin)]];   // radical
    }
    return interElementSpaceArray;
}


// Get's the index for the given type. If row is true, the index is for the row (i.e. left element) otherwise it is for the column (right element)
NSUInteger getInterElementSpaceArrayIndexForType(MTMathAtomType type, BOOL row) {
    switch (type) {
        case kMTMathAtomOrdinary:
        case kMTMathAtomPlaceholder:   // A placeholder is treated as ordinary
            return 0;
        case kMTMathAtomLargeOperator:
            return 1;
        case kMTMathAtomBinaryOperator:
            return 2;
        case kMTMathAtomRelation:
            return 3;
        case kMTMathAtomOpen:
            return 4;
        case kMTMathAtomClose:
            return 5;
        case kMTMathAtomPunctuation:
            return 6;
        case kMTMathAtomFraction:
            return 7;
        case kMTMathAtomRadical: {
            if (row) {
                // Radicals have inter element spaces only when on the left side.
                // Note: This is a departure from latex but we don't want \sqrt{4}4 to look weird so we put a space in between.
                // They have the same spacing as ordinary except with ordinary.
                return 8;
            } else {
                NSCAssert(false, @"Interelement space undefined for radical on the right. Treat radical as ordinary.");
                return -1;
            }
        }
            
        default:
            NSCAssert(false, @"Interelement space undefined for type %d", type);
            return -1;
    }
}

UTF32Char getItalicized(unichar ch) {
    UTF32Char unicode;
    if (ch == 'h') {
        // special code for h - planks constant
        unicode = kMTUnicodePlanksConstant;
    } else if (ch >= 'a' && ch <= 'z') {
        unicode = kMTUnicodeMathItalicStart + (ch - 'a');
    } else if (ch >= 'A' && ch <= 'Z') {
        unicode = kMTUnicodeMathCapitalItalicStart + (ch - 'A');
    } else if (ch >= kMTUnicodeGreekStart && ch <= kMTUnicodeGreekEnd) {
        // Greek characters
        unicode = kMTUnicodeGreekMathItalicStart + (ch - kMTUnicodeGreekStart);
    } else if (ch >= kMTUnicodeCapitalGreekStart && ch <= kMTUnicodeCapitalGreekEnd) {
        // Capital Greek characters
        unicode = kMTUnicodeGreekMathCapitalItalicStart + (ch - kMTUnicodeCapitalGreekStart);    
    } else {
        @throw [NSException exceptionWithName:@"IllegalCharacter"
                                       reason:[NSString stringWithFormat:@"Unknown character %d used as variable.", ch]
                                     userInfo:nil];
    }
    return unicode;
}

static NSString* mathItalicize(NSString* str) {
    NSMutableString* retval = [NSMutableString stringWithCapacity:str.length];
    unichar charBuffer[str.length];
    [str getCharacters:charBuffer range:NSMakeRange(0, str.length)];
    for (int i = 0; i < str.length; ++i) {
        unichar ch = charBuffer[i];
        UTF32Char unicode = getItalicized(ch);
        unicode = NSSwapHostIntToLittle(unicode);
        NSString* charStr = [[NSString alloc] initWithBytes:&unicode length:sizeof(unicode) encoding:NSUTF32LittleEndianStringEncoding];
        [retval appendString:charStr];
    }
    return retval;
}

static BOOL isIos6Supported() {
    static BOOL initialized = false;
    static BOOL supported = false;
    if (!initialized) {
        NSString *reqSysVer = @"6.0";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
            supported = true;
        }
        initialized = true;
    }
    return supported;
}

static void getBboxDetails(CGRect bbox, CGFloat* ascent, CGFloat* descent, CGFloat* width)
{
    if (ascent) {
        *ascent = MAX(0, CGRectGetMaxY(bbox) - 0);
    }

    if (descent) {
        // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
        *descent = MAX(0, 0 - CGRectGetMinY(bbox));
    }

    if (width) {
        *width = CGRectGetMaxX(bbox);
    }
}

#pragma mark MTDisplay

@interface MTDisplay ()

@property (nonatomic) CGFloat ascent; 
@property (nonatomic) CGFloat descent;
@property (nonatomic) CGFloat width;
@property (nonatomic) NSRange range;

@end

@implementation MTDisplay

- (void)draw:(CGContextRef)context
{
}

- (CGRect) displayBounds
{
    return CGRectMake(self.position.x, self.position.y - self.descent, self.width, self.ascent + self.descent);
}

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

@end

#pragma mark - MTCTLine

@implementation MTCTLineDisplay


- (id)initWithString:(NSAttributedString*) attrString position:(CGPoint)position range:(NSRange) range font:(MTFont*) font atoms:(NSArray*) atoms
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
    CGContextSetTextPosition(context, self.position.x, self.position.y);
    CTLineDraw(_line, context);
}

@end

#pragma mark - MTLine

@interface MTFractionDisplay ()

@property (nonatomic) CGFloat numeratorUp;
@property (nonatomic) CGFloat denominatorDown;
@property (nonatomic) CGFloat linePosition;
@property (nonatomic) CGFloat lineThickness;

@end

@implementation MTMathListDisplay {
    NSUInteger _index;
}


- (id) initWithDisplays:(NSArray*) displays range:(NSRange) range
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

- (id)initWithNumerator:(MTMathListDisplay*) numerator denominator:(MTMathListDisplay*) denominator position:(CGPoint) position range:(NSRange) range
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

- (void)draw:(CGContextRef)context
{
    [_numerator draw:context];
    [_denominator draw:context];
    
    // draw the horizontal line
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(self.position.x, self.position.y + self.linePosition)];
    [path addLineToPoint:CGPointMake(self.position.x + self.width, self.position.y + self.linePosition)];
    path.lineWidth = self.lineThickness;
    [path stroke];
}

@end

#pragma mark - MTRadicalDisplay

@interface MTRadicalDisplay ()

@property (nonatomic) CGFloat topKern;
@property (nonatomic) CGFloat lineThickness;
@property (nonatomic) CGFloat shiftUp;

@end

@implementation MTRadicalDisplay {
    CGGlyph _glyph;
    MTFont* _font;
    CGFloat _glyphWidth;
    CGFloat _radicalShift;
}

- (instancetype)initWitRadicand:(MTMathListDisplay*) radicand glpyh:(CGGlyph) glyph glyphWidth:(CGFloat) glyphWidth position:(CGPoint) position range:(NSRange) range font:(MTFont*) font
{
    self = [super init];
    if (self) {
        _radicand = radicand;
        _font = font;
        _glyph = glyph;
        _glyphWidth = glyphWidth;
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
    // Note: position of degree is relative to parent.
    self.degree.position = CGPointMake(self.position.x + kernBefore, self.position.y + raise);

    // the radical is now shifted by kernBefore + degree.width + kernAfter
    _radicalShift = kernBefore + degree.width + kernAfter;
    // Update the width by the _radicalShift
    self.width = _radicalShift + _glyphWidth + self.radicand.width;
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
    self.radicand.position = CGPointMake(self.position.x + _radicalShift + _glyphWidth, self.position.y);
}

- (void)draw:(CGContextRef)context
{
    // draw the radicand & degree at its position
    [self.radicand draw:context];
    [self.degree draw:context];

    CGContextSaveGState(context);

    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    CGContextTranslateCTM(context, self.position.x + _radicalShift, self.position.y);
    CGContextSetTextPosition(context, 0, 0);

    // Draw the glyph.
    CGPoint glyphPosition = CGPointMake(0, _shiftUp);
    CTFontDrawGlyphs(_font.ctFont, &_glyph, &glyphPosition, 1, context);

    // Draw the VBOX
    // for the kern of, we don't need to draw anything.
    CGFloat heightFromTop = _topKern;

    // draw the horizontal line with the given thickness
    UIBezierPath* path = [UIBezierPath bezierPath];
    CGPoint lineStart = CGPointMake(_glyphWidth, self.ascent - heightFromTop - self.lineThickness / 2); // subtract half the line thickness to center the line
    CGPoint lineEnd = CGPointMake(lineStart.x + self.radicand.width, lineStart.y);
    [path moveToPoint:lineStart];
    [path addLineToPoint:lineEnd];
    path.lineWidth = _lineThickness;
    path.lineCapStyle = kCGLineCapRound;
    [path stroke];

    CGContextRestoreGState(context);
}

@end

#pragma mark - MTLargeOpGlyphDisplay


// Rendering of an MTLargeOpGlyph as an MTDisplay
@interface MTLargeOpGlyphDisplay : MTDisplay

// Shift the glyph down by the given amount.
@property (nonatomic) CGFloat shiftDown;

@end


@implementation MTLargeOpGlyphDisplay {
    CGGlyph _glyph;
    MTFont* _font;
}

- (instancetype)initWithGlpyh:(CGGlyph) glyph  position:(CGPoint) position range:(NSRange) range font:(MTFont*) font
{
    self = [super init];
    if (self) {
        _font = font;
        _glyph = glyph;

        self.position = position;
        self.range = range;
    }
    return self;
}

- (void)draw:(CGContextRef)context
{
    CGContextSaveGState(context);

    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    CGContextTranslateCTM(context, self.position.x, self.position.y);
    CGContextSetTextPosition(context, 0, 0);

    // Draw the glyph.
    CGPoint glyphPosition = CGPointMake(0, -self.shiftDown);
    CTFontDrawGlyphs(_font.ctFont, &_glyph, &glyphPosition, 1, context);

    CGContextRestoreGState(context);
}

@end

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

- (void)draw:(CGContextRef)context
{
    // Draw the elements.
    [self.upperLimit draw:context];
    [self.lowerLimit draw:context];
    [_nucleus draw:context];
}

@end

#pragma mark - MTTypesetter

@implementation MTTypesetter {
    MTFont* _font;
    NSMutableArray<MTDisplay *>* _displayAtoms;
    CGPoint _currentPosition;
    NSMutableAttributedString* _currentLine;
    NSMutableArray* _currentAtoms;   // List of atoms that make the line
    NSRange _currentLineIndexRange;
    MTLineStyle _style;
    MTFont* _styleFont;
    BOOL _cramped;
}

+ (MTMathListDisplay *)createLineForMathList:(MTMathList *)mathList font:(MTFont*)font style:(MTLineStyle)style
{
    MTMathList* finalizedList = mathList.finalized;
    // default is not cramped
    return [self createLineForMathList:finalizedList font:font style:style cramped:false];
}

// Internal
+ (MTMathListDisplay *)createLineForMathList:(MTMathList *)mathList font:(MTFont*)font style:(MTLineStyle)style cramped:(BOOL) cramped
{
    NSParameterAssert(font);
    NSArray* preprocessedAtoms = [self preprocessMathList:mathList];
    MTTypesetter *typesetter = [[MTTypesetter alloc] initWithFont:font style:style cramped:cramped];
    [typesetter createDisplayAtoms:preprocessedAtoms];
    MTMathAtom* lastAtom = [mathList.atoms lastObject];
    MTMathListDisplay* line = [[MTMathListDisplay alloc] initWithDisplays:typesetter->_displayAtoms range:NSMakeRange(0, NSMaxRange(lastAtom.indexRange))];
    return line;
}

+ (UIColor*) placeholderColor
{
    return [UIColor blueColor];
}

- (instancetype)initWithFont:(MTFont*) font style:(MTLineStyle) style cramped:(BOOL) cramped
{
    self = [super init];
    if (self) {
        _font = font;
        _displayAtoms = [NSMutableArray array];
        _currentPosition = CGPointZero;
        _style = style;
        _cramped = cramped;
        _currentLine = [NSMutableAttributedString new];
        _currentAtoms = [NSMutableArray array];

        _styleFont = [_font copyFontWithSize:[[self class] getStyleSize:_style font:_font]];
        _currentLineIndexRange = NSMakeRange(NSNotFound, NSNotFound);
    }
    return self;
}

+ (NSArray*) preprocessMathList:(MTMathList*) ml
{
    // Note: Some of the preprocessing described by the TeX algorithm is done in the finalize method of MTMathList.
    // Specifically rules 5 & 6 in Appendix G are handled by finalize.
    // This function does not do a complete preprocessing as specified by TeX either. It removes any special atom types
    // that are not included in TeX and applies Rule 14 to merge ordinary characters.
    NSMutableArray* preprocessed = [NSMutableArray arrayWithCapacity:ml.atoms.count];
    MTMathAtom* prevNode = nil;
    for (MTMathAtom *atom in ml.atoms) {
        if (atom.type == kMTMathAtomVariable) {
            // This is not a TeX type node. TeX does this during parsing the input.
            // switch to using the italic math font
            // We convert it to ordinary
            atom.nucleus = mathItalicize(atom.nucleus);
            atom.type = kMTMathAtomOrdinary;
        }
        if (atom.type == kMTMathAtomNumber || atom.type == kMTMathAtomUnaryOperator) {
            // Neither of these are TeX nodes. TeX treats these as Ordinary. So will we.
            atom.type = kMTMathAtomOrdinary;
        }
        
        if (atom.type == kMTMathAtomOrdinary) {
            // This is Rule 14 to merge ordinary characters.
            // combine ordinary atoms together
            if (prevNode && prevNode.type == kMTMathAtomOrdinary && !prevNode.subScript && !prevNode.superScript) {
                [prevNode fuse:atom];
                // skip the current node, we are done here.
                continue;
            }
        }

        // TODO: add italic correction here or in second pass?
        prevNode = atom;
        [preprocessed addObject:atom];
    }
    return preprocessed;
}

// returns the size of the font in this style
+ (CGFloat) getStyleSize:(MTLineStyle) style font:(MTFont*) font
{
    CGFloat original = font.fontSize;
    switch (style) {
        case kMTLineStyleDisplay:
        case kMTLineStyleText:
            return original;
            
        case kMTLineStyleScript:
            return original * font.mathTable.scriptScaleDown;
            
        case kMTLineStypleScriptScript:
            return original * font.mathTable.scriptScriptScaleDown;
    }
}

- (void) createDisplayAtoms:(NSArray*) preprocessed
{
    // items should contain all the nodes that need to be layed out.
    // convert to a list of MTDisplayAtoms
    MTMathAtom *prevNode = nil;
    for (MTMathAtom* atom in preprocessed) {     
        switch (atom.type) {
            case kMTMathAtomNumber:
            case kMTMathAtomVariable:
            case kMTMathAtomUnaryOperator:
                // These should never appear as they should have been removed by preprocessing
                NSAssert(NO, @"These types should never show here as they are removed by preprocessing.");
                break;
                
            case kMTMathAtomRadical: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                MTRadical* rad = (MTRadical*) atom;
                if (prevNode) {
                    // Radicals are considered as Ord in rule 16.
                    CGFloat interElementSpace = [self getInterElementSpace:prevNode.type right:kMTMathAtomOrdinary];
                    _currentPosition.x += interElementSpace;
                }
                MTRadicalDisplay* displayRad = [self makeRadical:rad.radicand range:rad.indexRange];
                if (rad.degree) {
                    // add the degree to the radical
                    MTMathListDisplay* degree = [MTTypesetter createLineForMathList:rad.degree font:_styleFont style:kMTLineStypleScriptScript];
                    [displayRad setDegree:degree fontMetrics:_styleFont.mathTable];
                }
                [_displayAtoms addObject:displayRad];
                _currentPosition.x += displayRad.width;

                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    [self makeScripts:atom display:displayRad index:rad.indexRange.location delta:0];
                }
                // change type to ordinary
                //atom.type = kMTMathAtomOrdinary;
                break;
            }
                
            case kMTMathAtomFraction: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                MTFraction* frac = (MTFraction*) atom;
                if (prevNode) {
                    CGFloat interElementSpace = [self getInterElementSpace:prevNode.type right:atom.type];
                    _currentPosition.x += interElementSpace;
                }
                MTFractionDisplay* displayFrac = [self addFractionWithNumerator:frac.numerator denominator:frac.denominator range:frac.indexRange];
                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    [self makeScripts:atom display:displayFrac index:frac.indexRange.location delta:0];
                }
                break;
            }
                
            case kMTMathAtomLargeOperator: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                if (prevNode) {
                    CGFloat interElementSpace = [self getInterElementSpace:prevNode.type right:atom.type];
                    _currentPosition.x += interElementSpace;
                }
                MTLargeOperator* op = (MTLargeOperator*) atom;
                MTDisplay* display = [self makeLargeOp:op];
                [_displayAtoms addObject:display];
                break;
            }

            default:
                // the rendering for all the rest is pretty similar
                // All we need is render the character and set the interelement space.
                if (prevNode) {
                    CGFloat interElementSpace = [self getInterElementSpace:prevNode.type right:atom.type];
                    if (_currentLine.length > 0) {
                        if (interElementSpace > 0) {
                            // add a kerning of that space to the previous character
                            [_currentLine addAttribute:(NSString*) kCTKernAttributeName
                                                 value:[NSNumber numberWithFloat:interElementSpace]
                                                 range:[_currentLine.string rangeOfComposedCharacterSequenceAtIndex:_currentLine.length - 1]];
                        }
                    } else {
                        // increase the space
                        _currentPosition.x += interElementSpace;
                    }
                }
                NSAttributedString* current = nil;
                if (atom.type == kMTMathAtomPlaceholder) {
                    UIColor* color = [MTTypesetter placeholderColor];
                    current = [[NSAttributedString alloc] initWithString:atom.nucleus
                                                              attributes:@{ (NSString*) kCTForegroundColorAttributeName : (id) [color CGColor] }];
                } else {
                    current = [[NSAttributedString alloc] initWithString:atom.nucleus];
                }
                [_currentLine appendAttributedString:current];
                // add the atom to the current range
                if (_currentLineIndexRange.location == NSNotFound) {
                    _currentLineIndexRange = atom.indexRange;
                } else {
                    _currentLineIndexRange.length += atom.indexRange.length;
                }
                // add the fused atoms
                if (atom.fusedAtoms) {
                    [_currentAtoms addObjectsFromArray:atom.fusedAtoms];
                } else {
                    [_currentAtoms addObject:atom];
                }
                
                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    // stash the existing line
                    // We don't check _currentLine.length here since we want to allow empty lines with super/sub scripts.
                    MTCTLineDisplay* line = [self addDisplayLine];
                    CGFloat delta = 0;
                    if (atom.nucleus.length > 0) {
                        // Use the italic correction of the last character.
                        CGGlyph glyph = [self findGlyphForCharacterAtIndex:atom.nucleus.length - 1 inString:atom.nucleus];
                        delta = [_styleFont.mathTable getItalicCorrection:glyph];
                    }
                    if (delta > 0 && !atom.subScript) {
                        // Add a kern of delta
                        _currentPosition.x += delta;
                    }
                    [self makeScripts:atom display:line index:NSMaxRange(atom.indexRange) - 1 delta:delta];
                }
                break;
        }
        prevNode = atom;
    }
    if (_currentLine.length > 0) {
        [self addDisplayLine];
    }

}

- (MTCTLineDisplay*) addDisplayLine
{
    // add the font
    [_currentLine addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)(_styleFont.ctFont) range:NSMakeRange(0, _currentLine.length)];
    /*NSAssert(_currentLineIndexRange.length == numCodePoints(_currentLine.string),
             @"The length of the current line: %@ does not match the length of the range (%d, %d)",
             _currentLine, _currentLineIndexRange.location, _currentLineIndexRange.length);*/
    
    MTCTLineDisplay* displayAtom = [[MTCTLineDisplay alloc] initWithString:_currentLine position:_currentPosition range:_currentLineIndexRange font:_styleFont atoms:_currentAtoms];
    [_displayAtoms addObject:displayAtom];
    // update the position
    _currentPosition.x += displayAtom.width;
    // clear the string and the range
    _currentLine = [NSMutableAttributedString new];
    _currentAtoms = [NSMutableArray array];
    _currentLineIndexRange = NSMakeRange(NSNotFound, NSNotFound);
    return displayAtom;
}

#pragma mark Spacing

// Returned in units of mu = 1/18 em.
- (int) getSpacingInMu:(MTInterElementSpaceType) type
{
    switch (type) {
        case kMTSpaceInvalid:
            return -1;
        case kMTSpaceNone:
            return 0;
        case kMTSpaceThin:
            return 3;
        case kMTSpaceNSThin:
            return (_style < kMTLineStyleScript) ? 3 : 0;
            
        case kMTSpaceNSMedium:
            return (_style < kMTLineStyleScript) ? 4 : 0;
            
        case kMTSpaceNSThick:
            return (_style < kMTLineStyleScript) ? 5 : 0;
    }
}

- (CGFloat) getInterElementSpace:(MTMathAtomType) left right:(MTMathAtomType) right
{
    NSUInteger leftIndex = getInterElementSpaceArrayIndexForType(left, true);
    NSUInteger rightIndex = getInterElementSpaceArrayIndexForType(right, false);
    NSArray* spaceArray = [getInterElementSpaces() objectAtIndex:leftIndex];
    NSNumber* spaceTypeObj = [spaceArray objectAtIndex:rightIndex];
    MTInterElementSpaceType spaceType = [spaceTypeObj intValue];
    NSAssert(spaceType != kMTSpaceInvalid, @"Invalid space between %d and %d", left, right);
    
    int spaceMultipler = [self getSpacingInMu:spaceType];
    if (spaceMultipler > 0) {
        // 1 em = size of font in pt. space multipler is in multiples mu or 1/18 em
        return spaceMultipler * _styleFont.mathTable.muUnit;
    }
    return 0;
}


#pragma mark Subscript/Superscript

- (MTLineStyle) scriptStyle
{
    switch (_style) {
        case kMTLineStyleDisplay:
        case kMTLineStyleText:
            return kMTLineStyleScript;
        case kMTLineStyleScript:
            return kMTLineStypleScriptScript;
        case kMTLineStypleScriptScript:
            return kMTLineStypleScriptScript;
    }
}

// subscript is always cramped
- (BOOL) subscriptCramped
{
    return true;
}

// superscript is cramped only if the current style is cramped
- (BOOL) superScriptCramped
{
    return _cramped;
}

- (CGFloat) superScriptShiftUp
{
    if (_cramped) {
        return _styleFont.mathTable.superscriptShiftUpCramped;
    } else {
        return _styleFont.mathTable.superscriptShiftUp;
    }
}

// make scripts for the last atom
// index is the index of the element which is getting the sub/super scripts.
- (void) makeScripts:(MTMathAtom*) atom display:(MTDisplay*) display index:(NSUInteger) index delta:(CGFloat) delta
{
    assert(atom.subScript || atom.superScript);
    
    double superScriptShiftUp = 0;
    double subscriptShiftDown = 0;
    
    display.hasScript = YES;
    if (![display isKindOfClass:[MTCTLineDisplay class]]) {
        // get the font in script style
        CGFloat scriptFontSize = [[self class] getStyleSize:self.scriptStyle font:_font];
        MTFont* scriptFont = [_font copyFontWithSize:scriptFontSize];
        MTFontMathTable *scriptFontMetrics = scriptFont.mathTable;
        
        // if it is not a simple line then
        superScriptShiftUp = display.ascent - scriptFontMetrics.superscriptBaselineDropMax;
        subscriptShiftDown = display.descent + scriptFontMetrics.subscriptBaselineDropMin;
    }
    
    if (!atom.superScript) {
        assert(atom.subScript);
        MTMathListDisplay* subscript = [MTTypesetter createLineForMathList:atom.subScript font:_font style:self.scriptStyle cramped:self.subscriptCramped];
        subscript.type = kMTLinePositionSubscript;
        subscript.index = index;
        
        subscriptShiftDown = fmax(subscriptShiftDown, _styleFont.mathTable.subscriptShiftDown);
        subscriptShiftDown = fmax(subscriptShiftDown, subscript.ascent - _styleFont.mathTable.subscriptTopMax);
        // add the subscript
        subscript.position = CGPointMake(_currentPosition.x, _currentPosition.y - subscriptShiftDown);
        [_displayAtoms addObject:subscript];
        // update the position
        _currentPosition.x += subscript.width + _styleFont.mathTable.spaceAfterScript;
        return;
    }
    
    MTMathListDisplay* superScript = [MTTypesetter createLineForMathList:atom.superScript font:_font style:self.scriptStyle cramped:self.superScriptCramped];
    superScript.type = kMTLinePositionSuperscript;
    superScript.index = index;
    superScriptShiftUp = fmax(superScriptShiftUp, self.superScriptShiftUp);
    superScriptShiftUp = fmax(superScriptShiftUp, superScript.descent + _styleFont.mathTable.superscriptBottomMin);
    
    if (!atom.subScript) {
        superScript.position = CGPointMake(_currentPosition.x, _currentPosition.y + superScriptShiftUp);
        [_displayAtoms addObject:superScript];
        // update the position
        _currentPosition.x += superScript.width + _styleFont.mathTable.spaceAfterScript;
        return;
    }
    MTMathListDisplay* subscript = [MTTypesetter createLineForMathList:atom.subScript font:_font style:self.scriptStyle cramped:self.subscriptCramped];
    subscript.type = kMTLinePositionSubscript;
    subscript.index = index;
    subscriptShiftDown = fmax(subscriptShiftDown, _styleFont.mathTable.subscriptShiftDown);
    
    // joint positioning of subscript & superscript
    CGFloat subSuperScriptGap = (superScriptShiftUp - superScript.descent) + (subscriptShiftDown - subscript.ascent);
    if (subSuperScriptGap < _styleFont.mathTable.subSuperscriptGapMin) {
        // Set the gap to atleast as much
        subscriptShiftDown += _styleFont.mathTable.subSuperscriptGapMin - subSuperScriptGap;
        CGFloat superscriptBottomDelta = _styleFont.mathTable.superscriptBottomMaxWithSubscript - (superScriptShiftUp - superScript.descent);
        if (superscriptBottomDelta > 0) {
            // superscript is lower than the max allowed by the font with a subscript.
            superScriptShiftUp += superscriptBottomDelta;
            subscriptShiftDown -= superscriptBottomDelta;
        }
    }
    // The delta is the italic correction above that shift superscript position
    superScript.position = CGPointMake(_currentPosition.x + delta, _currentPosition.y + superScriptShiftUp);
    [_displayAtoms addObject:superScript];
    subscript.position = CGPointMake(_currentPosition.x, _currentPosition.y - subscriptShiftDown);
    [_displayAtoms addObject:subscript];
    _currentPosition.x += MAX(superScript.width + delta, subscript.width) + _styleFont.mathTable.spaceAfterScript;
}

#pragma mark Fractions

- (CGFloat) numeratorShiftUp {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.fractionNumeratorDisplayStyleShiftUp;
    } else {
        return _styleFont.mathTable.fractionNumeratorShiftUp;
    }
}

- (CGFloat) numeratorGapMin {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.fractionNumeratorDisplayStyleGapMin;
    } else {
        return _styleFont.mathTable.fractionNumeratorGapMin;
    }
}

- (CGFloat) denominatorShiftDown {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.fractionDenominatorDisplayStyleShiftDown;
    } else {
        return _styleFont.mathTable.fractionDenominatorShiftDown;
    }
}

- (CGFloat) denominatorGapMin {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.fractionDenominatorDisplayStyleGapMin;
    } else {
        return _styleFont.mathTable.fractionDenominatorGapMin;
    }
}

- (MTLineStyle) fractionStyle
{
    if (_style == kMTLineStypleScriptScript) {
        return kMTLineStypleScriptScript;
    }
    return _style + 1;
}

// range is the range of the original mathlist represented by this fraction.
- (MTFractionDisplay*) addFractionWithNumerator:(MTMathList*) numerator denominator:(MTMathList*) denominator range:(NSRange) range
{
    // lay out the parts of the fraction
    MTLineStyle fractionStyle = self.fractionStyle;
    MTMathListDisplay* numeratorDisplay = [MTTypesetter createLineForMathList:numerator font:_font style:fractionStyle cramped:false];
    MTMathListDisplay* denominatorDisplay = [MTTypesetter createLineForMathList:denominator font:_font style:fractionStyle cramped:true];
    
    // determine the location of the numerator
    CGFloat numeratorShiftUp = self.numeratorShiftUp;
    CGFloat barLocation = _styleFont.mathTable.axisHeight;
    CGFloat barThickness = _styleFont.mathTable.fractionRuleThickness;
    // This is the difference between the lowest edge of the numerator and the top edge of the fraction bar
    CGFloat distanceFromNumeratorToBar = (numeratorShiftUp - numeratorDisplay.descent) - (barLocation + barThickness/2);
    // The distance should at least be displayGap
    CGFloat minNumeratorGap = self.numeratorGapMin;
    if (distanceFromNumeratorToBar < minNumeratorGap) {
        // This makes the distance between the bottom of the numerator and the top edge of the fraction bar
        // at least minNumeratorGap.
        numeratorShiftUp += (minNumeratorGap - distanceFromNumeratorToBar);
    }
    
    // Do the same for the denominator
    CGFloat denominatorShiftDown = self.denominatorShiftDown;
    // This is the difference between the top edge of the denominator and the bottom edge of the fraction bar
    CGFloat distanceFromDenominatorToBar = (barLocation - barThickness/2) - (denominatorDisplay.ascent - denominatorShiftDown);
    // The distance should at least be denominator gap
    CGFloat minDenominatorGap = self.denominatorGapMin;
    if (distanceFromDenominatorToBar < minDenominatorGap) {
        // This makes the distance between the top of the denominator and the bottom of the fraction bar to be exactly
        // minDenominatorGap
        denominatorShiftDown += (minDenominatorGap - distanceFromDenominatorToBar);
    }
    
    MTFractionDisplay *display = [[MTFractionDisplay alloc] initWithNumerator:numeratorDisplay denominator:denominatorDisplay position:_currentPosition range:range];
    display.numeratorUp = numeratorShiftUp;
    display.denominatorDown = denominatorShiftDown;
    display.lineThickness = barThickness;
    display.linePosition = barLocation;
    [_displayAtoms addObject:display];
    _currentPosition.x += display.width;
    return display;
}

#pragma mark - Radicals

- (CGFloat) radicalVerticalGap
{
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.radicalDisplayStyleVerticalGap;
    } else {
        return _styleFont.mathTable.radicalVerticalGap;
    }
}

- (MTRadicalDisplay*) makeRadical:(MTMathList*) radicand range:(NSRange) range
{
    MTMathListDisplay* innerDisplay = [MTTypesetter createLineForMathList:radicand font:_font style:_style cramped:YES];
        CGFloat clearance = self.radicalVerticalGap;
    CGFloat radicalRuleThickness = _styleFont.mathTable.radicalRuleThickness;
    CGFloat radicalHeight = innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness;
    CGFloat glyphAscent, glyphDescent, glyphWidth;
    CGGlyph glyph = [self findGlyph:@"radical" withHeight:radicalHeight glyphAscent:&glyphAscent glyphDescent:&glyphDescent glyphWidth:&glyphWidth];

    // Note this is a departure from Latex. Latex assumes that glyphAscent == thickness.
    // Open type math makes no such assumption, and ascent and descent are independent of the thickness.
    // Latex computes delta as descent - (h(inner) + d(inner) + clearance)
    // but since we may not have ascent == thickness, we modify the delta calculation slightly.
    // If the font designer followes Latex conventions, it will be identical.
    CGFloat delta = (glyphDescent + glyphAscent) - (innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness);
    if (delta > 0) {
        clearance += delta/2;  // increase the clearance to center the radicand inside the sign.
    }

    // we need to shift the radical glyph up, to coincide with the baseline of inner.
    // The new ascent of the radical glyph should be thickness + adjusted clearance + h(inner)
    CGFloat radicalAscent = radicalRuleThickness + clearance + innerDisplay.ascent;
    CGFloat shiftUp = radicalAscent - glyphAscent;  // Note: if the font designer followed latex conventions, this is the same as glyphAscent == thickness.

    MTRadicalDisplay* radical = [[MTRadicalDisplay alloc] initWitRadicand:innerDisplay glpyh:glyph glyphWidth:glyphWidth position:_currentPosition range:range font:_styleFont];
    radical.ascent = radicalAscent + _styleFont.mathTable.radicalExtraAscender;
    radical.topKern = _styleFont.mathTable.radicalExtraAscender;
    radical.shiftUp = shiftUp;
    radical.lineThickness = radicalRuleThickness;
    radical.descent = glyphAscent + glyphDescent - radicalAscent;
    radical.width = glyphWidth + innerDisplay.width;
    return radical;
}

- (CGGlyph) findGlyph:(NSString*) name withHeight:(CGFloat) height glyphAscent:(CGFloat*) glyphAscent glyphDescent:(CGFloat*) glyphDescent glyphWidth:(CGFloat*) glyphWidth
{
    CFArrayRef variants = [_styleFont.mathTable copyVerticalVariantsForGlyphWithName:name];
    CFIndex numVariants = CFArrayGetCount(variants);
    CGGlyph glyphs[numVariants];
    for (CFIndex i = 0; i < numVariants; i++) {
        CGGlyph glyph = (CGGlyph)CFArrayGetValueAtIndex(variants, i);
        glyphs[i] = glyph;
    }
    CFRelease(variants);

    CGRect bboxes[numVariants];
    // Get the bounds for these glyphs
    CTFontGetBoundingRectsForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, glyphs, bboxes, numVariants);
    CGFloat ascent, descent, width;
    for (int i = 0; i < numVariants; i++) {
        CGRect bounds = bboxes[i];
        getBboxDetails(bounds, &ascent, &descent, &width);

        if (ascent + descent >= height) {
            *glyphAscent = ascent;
            *glyphDescent = descent;
            *glyphWidth = width;
            return glyphs[i];
        }
    }
    // TODO: none of the glyphs are as large as required. A glyph needs to be constructed using the extenders.
    *glyphAscent = ascent;
    *glyphDescent = descent;
    *glyphWidth = width;
    return glyphs[numVariants - 1];
}

#pragma Large Operators

- (CGGlyph) findGlyphForCharacterAtIndex:(NSUInteger) index inString:(NSString*) str
{
    // Get the character at index taking into account UTF-32 characters
    NSRange range = [str rangeOfComposedCharacterSequenceAtIndex:index];
    unichar chars[range.length];
    [str getCharacters:chars range:range];

    // Get the glyph fromt the font
    CGGlyph glyph[range.length];
    bool found = CTFontGetGlyphsForCharacters(_styleFont.ctFont, chars, glyph, range
                                              .length);
    if (!found) {
        // the font did not contain a glyph for our character, so we just return 0 (notdef)
        return 0;
    }
    return glyph[0];
}

- (MTDisplay*) makeLargeOp:(MTLargeOperator*) op
{
    bool limits = (op.limits && _style == kMTLineStyleDisplay);
    CGFloat delta = 0;
    if (op.nucleus.length == 1) {
        CGGlyph glyph = [self findGlyphForCharacterAtIndex:0 inString:op.nucleus];
        if (_style == kMTLineStyleDisplay && glyph != 0) {
            // Enlarge the character in display style.
            glyph = [_styleFont.mathTable getLargerGlyph:glyph];
        }
        // This is be the italic correction of the character.
        delta = [_styleFont.mathTable getItalicCorrection:glyph];

        // vertically center
        CGRect bbox = CTFontGetBoundingRectsForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, &glyph, NULL, 1);
        CGFloat ascent, descent, width;
        getBboxDetails(bbox, &ascent, &descent, &width);
        CGFloat shiftDown = 0.5*(ascent - descent) - _styleFont.mathTable.axisHeight;
        MTLargeOpGlyphDisplay* glyphDisplay = [[MTLargeOpGlyphDisplay alloc] initWithGlpyh:glyph position:_currentPosition range:op.indexRange font:_styleFont];
        glyphDisplay.ascent = ascent;
        glyphDisplay.descent = descent;
        glyphDisplay.width = width;
        if (op.subScript && !limits) {
            // Remove italic correction from the width of the glyph if
            // there is a subscript and limits is not set.
            glyphDisplay.width -= delta;
        }
        glyphDisplay.shiftDown = shiftDown;
        return [self addLimitsToDisplay:glyphDisplay forOperator:op delta:delta];
    } else {
        // Create a regular node
        NSMutableAttributedString* line = [[NSMutableAttributedString alloc] initWithString:op.nucleus];
        // add the font
        [line addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)(_styleFont.ctFont) range:NSMakeRange(0, line.length)];
        MTCTLineDisplay* displayAtom = [[MTCTLineDisplay alloc] initWithString:line position:_currentPosition range:op.indexRange font:_styleFont atoms:@[ op ]];
        return [self addLimitsToDisplay:displayAtom forOperator:op delta:0];
    }
}

- (MTDisplay*) addLimitsToDisplay:(MTDisplay*) display forOperator:(MTLargeOperator*) op delta:(CGFloat)delta
{
    // If there is no subscript or superscript, just return the current display
    if (!op.subScript && !op.superScript) {
        _currentPosition.x += display.width;
        return display;
    }
    if (op.limits && _style == kMTLineStyleDisplay) {
        // make limits
        MTMathListDisplay *superScript = nil, *subScript = nil;
        if (op.superScript) {
            superScript = [MTTypesetter createLineForMathList:op.superScript font:_font style:self.scriptStyle cramped:self.superScriptCramped];
        }
        if (op.subScript) {
            subScript = [MTTypesetter createLineForMathList:op.subScript font:_font style:self.scriptStyle cramped:self.subscriptCramped];
        }
        NSAssert(superScript || subScript, @"Atleast one of superscript or subscript should have been present.");
        MTLargeOpLimitsDisplay* opsDisplay = [[MTLargeOpLimitsDisplay alloc] initWithNucleus:display upperLimit:superScript lowerLimit:subScript limitShift:delta/2 extraPadding:0];
        if (superScript) {
            CGFloat upperLimitGap = MAX(_styleFont.mathTable.upperLimitGapMin, _styleFont.mathTable.upperLimitBaselineRiseMin - superScript.descent);
            opsDisplay.upperLimitGap = upperLimitGap;
        }
        if (subScript) {
            CGFloat lowerLimitGap = MAX(_styleFont.mathTable.lowerLimitGapMin, _styleFont.mathTable.lowerLimitBaselineDropMin - subScript.ascent);
            opsDisplay.lowerLimitGap = lowerLimitGap;
        }
        opsDisplay.position = _currentPosition;
        opsDisplay.range = op.indexRange;
        _currentPosition.x += opsDisplay.width;
        return opsDisplay;
    } else {
        _currentPosition.x += display.width;
        [self makeScripts:op display:display index:op.indexRange.location delta:delta];
        return display;
    }
}

@end
