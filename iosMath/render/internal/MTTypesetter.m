//
//  MTTypesetter.m
//  iosMath
//
//  Created by Kostub Deshmukh on 6/21/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTTypesetter.h"
#import "MTFont+Internal.h"
#import "MTMathListDisplayInternal.h"
#import "MTUnicode.h"

#pragma mark Inter Element Spacing

typedef NS_ENUM(int, MTInterElementSpaceType) {
    kMTSpaceInvalid = -1,
    kMTSpaceNone = 0,
    kMTSpaceThin,
    kMTSpaceNSThin,    // Thin but not in script mode
    kMTSpaceNSMedium,
    kMTSpaceNSThick,
};


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
        case kMTMathAtomColor:
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
        case kMTMathAtomFraction:  // Fraction and inner are treated the same.
        case kMTMathAtomInner:
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
            NSCAssert(false, @"Interelement space undefined for type %lu", (unsigned long)type);
            return -1;
    }
}

#pragma mark - Font styles

static const unichar kMTUnicodeGreekLowerStart = 0x03B1;
static const unichar kMTUnicodeGreekLowerEnd = 0x03C9;
static const unichar kMTUnicodeGreekCapitalStart = 0x0391;
static const unichar kMTUnicodeGreekCapitalEnd = 0x03A9;

#define IS_LOWER_EN(ch) ((ch) >= 'a' && (ch) <= 'z')
#define IS_UPPER_EN(ch) ((ch) >= 'A' && (ch) <= 'Z')
#define IS_NUMBER(ch) ((ch) >= '0' && (ch) <= '9')
#define IS_LOWER_GREEK(ch) ((ch) >= kMTUnicodeGreekLowerStart && (ch) <= kMTUnicodeGreekLowerEnd)
#define IS_CAPITAL_GREEK(ch) ((ch) >= kMTUnicodeGreekCapitalStart && (ch) <= kMTUnicodeGreekCapitalEnd)


NSUInteger greekSymbolOrder(unichar ch) {
    // These greek symbols that always appear in unicode in this particular order after the alphabet
    // The symbols are epsilon, vartheta, varkappa, phi, varrho, varpi.
    static NSArray* greekSymbols;
    if (!greekSymbols) {
        greekSymbols = @[@0x03F5, @0x03D1, @0x03F0, @0x03D5, @0x03F1, @0x03D6];
    }
    return [greekSymbols indexOfObject:@(ch)];
}

#define IS_GREEK_SYMBOL(ch) (greekSymbolOrder(ch) != NSNotFound)

static const unichar kMTUnicodePlanksConstant = 0x210e;
static const UTF32Char kMTUnicodeMathCapitalItalicStart = 0x1D434;
static const UTF32Char kMTUnicodeMathLowerItalicStart = 0x1D44E;
static const UTF32Char kMTUnicodeGreekCapitalItalicStart = 0x1D6E2;
static const UTF32Char kMTUnicodeGreekLowerItalicStart = 0x1D6FC;
static const UTF32Char kMTUnicodeGreekSymbolItalicStart = 0x1D716;

// mathit
UTF32Char getItalicized(unichar ch) {
    UTF32Char unicode = ch;
    // Special cases for italics
    switch(ch) {
        case 'h':
            return kMTUnicodePlanksConstant;   // italic h (plank's constant)
    }
    
    if (IS_UPPER_EN(ch)) {
        unicode = kMTUnicodeMathCapitalItalicStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        unicode = kMTUnicodeMathLowerItalicStart + (ch - 'a');
    } else if (IS_CAPITAL_GREEK(ch)) {
        // Capital Greek characters
        unicode = kMTUnicodeGreekCapitalItalicStart + (ch - kMTUnicodeGreekCapitalStart);
    } else if (IS_LOWER_GREEK(ch)) {
        // Greek characters
        unicode = kMTUnicodeGreekLowerItalicStart + (ch - kMTUnicodeGreekLowerStart);
    } else if (IS_GREEK_SYMBOL(ch)) {
        return kMTUnicodeGreekSymbolItalicStart + (int)greekSymbolOrder(ch);
    }
    // Note there are no italicized numbers in unicode so we don't support italicizing numbers.
    return unicode;
}

static const UTF32Char kMTUnicodeMathCapitalBoldStart = 0x1D400;
static const UTF32Char kMTUnicodeMathLowerBoldStart = 0x1D41A;
static const UTF32Char kMTUnicodeGreekCapitalBoldStart = 0x1D6A8;
static const UTF32Char kMTUnicodeGreekLowerBoldStart = 0x1D6C2;
static const UTF32Char kMTUnicodeGreekSymbolBoldStart = 0x1D6DC;
static const UTF32Char kMTUnicodeNumberBoldStart = 0x1D7CE;

// mathbf
UTF32Char getBold(unichar ch) {
    UTF32Char unicode = ch;
    if (IS_UPPER_EN(ch)) {
        unicode = kMTUnicodeMathCapitalBoldStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        unicode = kMTUnicodeMathLowerBoldStart + (ch - 'a');
    } else if (IS_CAPITAL_GREEK(ch)) {
        // Capital Greek characters
        unicode = kMTUnicodeGreekCapitalBoldStart + (ch - kMTUnicodeGreekCapitalStart);
    } else if (IS_LOWER_GREEK(ch)) {
        // Greek characters
        unicode = kMTUnicodeGreekLowerBoldStart + (ch - kMTUnicodeGreekLowerStart);
    } else if (IS_GREEK_SYMBOL(ch)) {
        return kMTUnicodeGreekSymbolBoldStart + (int)greekSymbolOrder(ch);
    } else if (IS_NUMBER(ch)) {
        unicode = kMTUnicodeNumberBoldStart + (ch - '0');
    }
    return unicode;
}

static const UTF32Char kMTUnicodeMathCapitalBoldItalicStart = 0x1D468;
static const UTF32Char kMTUnicodeMathLowerBoldItalicStart = 0x1D482;
static const UTF32Char kMTUnicodeGreekCapitalBoldItalicStart = 0x1D71C;
static const UTF32Char kMTUnicodeGreekLowerBoldItalicStart = 0x1D736;
static const UTF32Char kMTUnicodeGreekSymbolBoldItalicStart = 0x1D750;

// mathbfit
UTF32Char getBoldItalic(unichar ch) {
    UTF32Char unicode = ch;
    if (IS_UPPER_EN(ch)) {
        unicode = kMTUnicodeMathCapitalBoldItalicStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        unicode = kMTUnicodeMathLowerBoldItalicStart + (ch - 'a');
    } else if (IS_CAPITAL_GREEK(ch)) {
        // Capital Greek characters
        unicode = kMTUnicodeGreekCapitalBoldItalicStart + (ch - kMTUnicodeGreekCapitalStart);
    } else if (IS_LOWER_GREEK(ch)) {
        // Greek characters
        unicode = kMTUnicodeGreekLowerBoldItalicStart + (ch - kMTUnicodeGreekLowerStart);
    } else if (IS_GREEK_SYMBOL(ch)) {
        return kMTUnicodeGreekSymbolBoldItalicStart + (int)greekSymbolOrder(ch);
    } else if (IS_NUMBER(ch)) {
        // No bold italic for numbers so we just bold them.
        unicode = getBold(ch);
    }
    return unicode;
}

// LaTeX default
UTF32Char getDefaultStyle(unichar ch) {
    if (IS_LOWER_EN(ch) || IS_UPPER_EN(ch) || IS_LOWER_GREEK(ch) || IS_GREEK_SYMBOL(ch)) {
        return getItalicized(ch);
    } else if (IS_NUMBER(ch) || IS_CAPITAL_GREEK(ch)) {
        // In the default style numbers and capital greek is roman
        return ch;
    } else if (ch == '.') {
        // . is treated as a number in our code, but it doesn't change fonts.
        return ch;
    } else {
        @throw [NSException exceptionWithName:@"IllegalCharacter"
                                       reason:[NSString stringWithFormat:@"Unknown character %d for default style.", ch]
                                     userInfo:nil];
    }
    return ch;
}

static const UTF32Char kMTUnicodeMathCapitalScriptStart = 0x1D49C;
// TODO(kostub): Unused in Latin Modern Math - if another font is used determine if
// this should be applicable.
// static const UTF32Char kMTUnicodeMathLowerScriptStart = 0x1D4B6;

// mathcal/mathscr (caligraphic or script)
UTF32Char getCaligraphic(unichar ch) {
    // Caligraphic has lots of exceptions:
    switch(ch) {
        case 'B':
            return 0x212C;   // Script B (bernoulli)
        case 'E':
            return 0x2130;   // Script E (emf)
        case 'F':
            return 0x2131;   // Script F (fourier)
        case 'H':
            return 0x210B;   // Script H (hamiltonian)
        case 'I':
            return 0x2110;   // Script I
        case 'L':
            return 0x2112;   // Script L (laplace)
        case 'M':
            return 0x2133;   // Script M (M-matrix)
        case 'R':
            return 0x211B;   // Script R (Riemann integral)
        case 'e':
            return 0x212F;   // Script e (Natural exponent)
        case 'g':
            return 0x210A;   // Script g (real number)
        case 'o':
            return 0x2134;   // Script o (order)
        default:
            break;
    }
    UTF32Char unicode;
    if (IS_UPPER_EN(ch)) {
        unicode = kMTUnicodeMathCapitalScriptStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        // Latin Modern Math does not have lower case caligraphic characters, so we use
        // the default style instead of showing a ?
        unicode = getDefaultStyle(ch);
    } else {
        // Caligraphic characters don't exist for greek or numbers, we give them the
        // default treatment.
        unicode = getDefaultStyle(ch);
    }
    return unicode;
}

static const UTF32Char kMTUnicodeMathCapitalTTStart = 0x1D670;
static const UTF32Char kMTUnicodeMathLowerTTStart = 0x1D68A;
static const UTF32Char kMTUnicodeNumberTTStart = 0x1D7F6;

// mathtt (monospace)
UTF32Char getTypewriter(unichar ch) {
    if (IS_UPPER_EN(ch)) {
        return kMTUnicodeMathCapitalTTStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        return kMTUnicodeMathLowerTTStart + (ch - 'a');
    } else if (IS_NUMBER(ch)) {
        return kMTUnicodeNumberTTStart + (ch - '0');
    }
    // Monospace characters don't exist for greek, we give them the
    // default treatment.
    return getDefaultStyle(ch);
}

static const UTF32Char kMTUnicodeMathCapitalSansSerifStart = 0x1D5A0;
static const UTF32Char kMTUnicodeMathLowerSansSerifStart = 0x1D5BA;
static const UTF32Char kMTUnicodeNumberSansSerifStart = 0x1D7E2;

// mathsf
UTF32Char getSansSerif(unichar ch) {
    if (IS_UPPER_EN(ch)) {
        return kMTUnicodeMathCapitalSansSerifStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        return kMTUnicodeMathLowerSansSerifStart + (ch - 'a');
    } else if (IS_NUMBER(ch)) {
        return kMTUnicodeNumberSansSerifStart + (ch - '0');
    }
    // Sans-serif characters don't exist for greek, we give them the
    // default treatment.
    return getDefaultStyle(ch);
}

static const UTF32Char kMTUnicodeMathCapitalFrakturStart = 0x1D504;
static const UTF32Char kMTUnicodeMathLowerFrakturStart = 0x1D51E;

// mathfrak
UTF32Char getFraktur(unichar ch) {
    // Fraktur has exceptions:
    switch(ch) {
        case 'C':
            return 0x212D;   // C Fraktur
        case 'H':
            return 0x210C;   // Hilbert space
        case 'I':
            return 0x2111;   // Imaginary
        case 'R':
            return 0x211C;   // Real
        case 'Z':
            return 0x2128;   // Z Fraktur
        default:
            break;
    }
    if (IS_UPPER_EN(ch)) {
        return kMTUnicodeMathCapitalFrakturStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        return kMTUnicodeMathLowerFrakturStart + (ch - 'a');
    }
    // Fraktur characters don't exist for greek & numbers, we give them the
    // default treatment.
    return getDefaultStyle(ch);
}

static const UTF32Char kMTUnicodeMathCapitalBlackboardStart = 0x1D538;
static const UTF32Char kMTUnicodeMathLowerBlackboardStart = 0x1D552;
static const UTF32Char kMTUnicodeNumberBlackboardStart = 0x1D7D8;

// mathbb (double struck)
UTF32Char getBlackboard(unichar ch) {
    // Blackboard has lots of exceptions:
    switch(ch) {
        case 'C':
            return 0x2102;   // Complex numbers
        case 'H':
            return 0x210D;   // Quarternions
        case 'N':
            return 0x2115;   // Natural numbers
        case 'P':
            return 0x2119;   // Primes
        case 'Q':
            return 0x211A;   // Rationals
        case 'R':
            return 0x211D;   // Reals
        case 'Z':
            return 0x2124;   // Integers
        default:
            break;
    }
    if (IS_UPPER_EN(ch)) {
        return kMTUnicodeMathCapitalBlackboardStart + (ch - 'A');
    } else if (IS_LOWER_EN(ch)) {
        return kMTUnicodeMathLowerBlackboardStart + (ch - 'a');
    } else if (IS_NUMBER(ch)) {
        return kMTUnicodeNumberBlackboardStart + (ch - '0');
    }
    // Blackboard characters don't exist for greek, we give them the
    // default treatment.
    return getDefaultStyle(ch);
}

static UTF32Char styleCharacter(unichar ch, MTFontStyle fontStyle)
{
    switch (fontStyle) {
        case kMTFontStyleDefault:
            return getDefaultStyle(ch);
            
        case kMTFontStyleRoman:
            return ch;
            
        case kMTFontStyleBold:
            return getBold(ch);
            
        case kMTFontStyleItalic:
            return getItalicized(ch);
            
        case kMTFontStyleBoldItalic:
            return getBoldItalic(ch);
            
        case kMTFontStyleCaligraphic:
            return getCaligraphic(ch);
            
        case kMTFontStyleTypewriter:
            return getTypewriter(ch);
            
        case kMTFontStyleSansSerif:
            return getSansSerif(ch);
            
        case kMTFontStyleFraktur:
            return getFraktur(ch);
            
        case kMTFontStyleBlackboard:
            return getBlackboard(ch);
            
        default:
            @throw [NSException exceptionWithName:@"Invalid style"
                                           reason:[NSString stringWithFormat:@"Unknown style %lu for font.", (unsigned long)fontStyle]
                                         userInfo:nil];
    }
    return ch;
}

static NSString* changeFont(NSString* str, MTFontStyle fontStyle) {
    NSMutableString* retval = [NSMutableString stringWithCapacity:str.length];
    unichar charBuffer[str.length];
    [str getCharacters:charBuffer range:NSMakeRange(0, str.length)];
    for (int i = 0; i < str.length; ++i) {
        unichar ch = charBuffer[i];
        UTF32Char unicode = styleCharacter(ch, fontStyle);
        unicode = NSSwapHostIntToLittle(unicode);
        NSString* charStr = [[NSString alloc] initWithBytes:&unicode length:sizeof(unicode) encoding:NSUTF32LittleEndianStringEncoding];
        [retval appendString:charStr];
    }
    return retval;
}

static void getBboxDetails(CGRect bbox, CGFloat* ascent, CGFloat* descent)
{
    if (ascent) {
        *ascent = MAX(0, CGRectGetMaxY(bbox) - 0);
    }
    
    if (descent) {
        // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
        *descent = MAX(0, 0 - CGRectGetMinY(bbox));
    }
}

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
    BOOL _spaced;
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
    return [self createLineForMathList:mathList font:font style:style cramped:cramped spaced:false];
}

// Internal
+ (MTMathListDisplay *)createLineForMathList:(MTMathList *)mathList font:(MTFont*)font style:(MTLineStyle)style cramped:(BOOL) cramped spaced:(BOOL) spaced
{
    NSParameterAssert(font);
    NSArray* preprocessedAtoms = [self preprocessMathList:mathList];
    MTTypesetter *typesetter = [[MTTypesetter alloc] initWithFont:font style:style cramped:cramped spaced:spaced];
    [typesetter createDisplayAtoms:preprocessedAtoms];
    MTMathAtom* lastAtom = mathList.atoms.lastObject;
    MTMathListDisplay* line = [[MTMathListDisplay alloc] initWithDisplays:typesetter->_displayAtoms range:NSMakeRange(0, NSMaxRange(lastAtom.indexRange))];
    return line;
}

+ (MTColor*) placeholderColor
{
    return [MTColor blueColor];
}

- (instancetype)initWithFont:(MTFont*) font style:(MTLineStyle) style cramped:(BOOL) cramped spaced:(BOOL) spaced
{
    self = [super init];
    if (self) {
        _font = font;
        _displayAtoms = [NSMutableArray array];
        _currentPosition = CGPointZero;
        _cramped = cramped;
        _spaced = spaced;
        _currentLine = [NSMutableAttributedString new];
        _currentAtoms = [NSMutableArray array];
        self.style = style;
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
        if (atom.type == kMTMathAtomVariable || atom.type == kMTMathAtomNumber) {
            // These are not a TeX type nodes. TeX does this during parsing the input.
            // switch to using the font specified in the atom
            NSString* newFont = changeFont(atom.nucleus, atom.fontStyle);
            // We convert it to ordinary
            atom.type = kMTMathAtomOrdinary;
            atom.nucleus = newFont;
        } else if (atom.type == kMTMathAtomUnaryOperator) {
            // TeX treats these as Ordinary. So will we.
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
            
        case kMTLineStyleScriptScript:
            return original * font.mathTable.scriptScriptScaleDown;
    }
}

- (void) setStyle:(MTLineStyle) style {
    _style = style;
    _styleFont = [_font copyFontWithSize:[[self class] getStyleSize:_style font:_font]];
}

- (void) addInterElementSpace:(MTMathAtom*) prevNode currentType:(MTMathAtomType) type
{
    CGFloat interElementSpace = 0;
    if (prevNode) {
        interElementSpace = [self getInterElementSpace:prevNode.type right:type];
    } else if (_spaced) {
        // For the first atom of a spaced list, treat it as if it is preceded by an open.
        interElementSpace = [self getInterElementSpace:kMTMathAtomOpen right:type];
    }
    _currentPosition.x += interElementSpace;
}

- (void) createDisplayAtoms:(NSArray*) preprocessed
{
    // items should contain all the nodes that need to be layed out.
    // convert to a list of MTDisplayAtoms
    MTMathAtom *prevNode = nil;
    MTMathAtomType lastType = 0;
    for (MTMathAtom* atom in preprocessed) {
        switch (atom.type) {
            case kMTMathAtomNumber:
            case kMTMathAtomVariable:
            case kMTMathAtomUnaryOperator:
                // These should never appear as they should have been removed by preprocessing
                NSAssert(NO, @"These types should never show here as they are removed by preprocessing.");
                break;
                
            case kMTMathAtomBoundary:
                NSAssert(NO, @"A boundary atom should never be inside a mathlist.");
                break;
                
            case kMTMathAtomSpace: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                MTMathSpace* space = (MTMathSpace*) atom;
                // add the desired space
                _currentPosition.x += space.space * _styleFont.mathTable.muUnit;
                // Since this is extra space, the desired interelement space between the prevAtom
                // and the next node is still preserved. To avoid resetting the prevAtom and lastType
                // we skip to the next node.
                continue;
            }
                
            case kMTMathAtomStyle: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                MTMathStyle* style = (MTMathStyle*) atom;
                self.style = style.style;
                // We need to preserve the prevNode for any interelement space changes.
                // so we skip to the next node.
                continue;
            }
                
            case kMTMathAtomColor: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                MTMathColor* colorAtom = (MTMathColor*) atom;
                MTDisplay* display = [MTTypesetter createLineForMathList:colorAtom.innerList font:_font style:_style];
                display.localTextColor = [MTColor colorFromHexString:colorAtom.colorString];
                display.position = _currentPosition;
                _currentPosition.x += display.width;
                [_displayAtoms addObject:display];
                break;
            }
                
            case kMTMathAtomRadical: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                MTRadical* rad = (MTRadical*) atom;
                // Radicals are considered as Ord in rule 16.
                [self addInterElementSpace:prevNode currentType:kMTMathAtomOrdinary];
                MTRadicalDisplay* displayRad = [self makeRadical:rad.radicand range:rad.indexRange];
                if (rad.degree) {
                    // add the degree to the radical
                    MTMathListDisplay* degree = [MTTypesetter createLineForMathList:rad.degree font:_font style:kMTLineStyleScriptScript];
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
                [self addInterElementSpace:prevNode currentType:atom.type];
                MTDisplay* display = [self makeFraction:frac];
                [_displayAtoms addObject:display];
                _currentPosition.x += display.width;
                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    [self makeScripts:atom display:display index:frac.indexRange.location delta:0];
                }
                break;
            }
                
            case kMTMathAtomLargeOperator: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                [self addInterElementSpace:prevNode currentType:atom.type];
                MTLargeOperator* op = (MTLargeOperator*) atom;
                MTDisplay* display = [self makeLargeOp:op];
                [_displayAtoms addObject:display];
                break;
            }
                
            case kMTMathAtomInner: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                [self addInterElementSpace:prevNode currentType:atom.type];
                MTInner* inner = (MTInner*) atom;
                MTDisplay* display = nil;
                if (inner.leftBoundary || inner.rightBoundary) {
                    display = [self makeLeftRight:inner];
                } else {
                    display = [MTTypesetter createLineForMathList:inner.innerList font:_font style:_style cramped:_cramped];
                }
                display.position = _currentPosition;
                _currentPosition.x += display.width;
                [_displayAtoms addObject:display];
                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    [self makeScripts:atom display:display index:atom.indexRange.location delta:0];
                }
                break;
            }
                
            case kMTMathAtomUnderline: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                // Underline is considered as Ord in rule 16.
                [self addInterElementSpace:prevNode currentType:kMTMathAtomOrdinary];
                atom.type = kMTMathAtomOrdinary;
                
                MTUnderLine* under = (MTUnderLine*) atom;
                MTDisplay* display = [self makeUnderline:under];
                [_displayAtoms addObject:display];
                _currentPosition.x += display.width;
                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    [self makeScripts:atom display:display index:atom.indexRange.location delta:0];
                }
                break;
            }
                
            case kMTMathAtomOverline: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                // Overline is considered as Ord in rule 16.
                [self addInterElementSpace:prevNode currentType:kMTMathAtomOrdinary];
                atom.type = kMTMathAtomOrdinary;
                
                MTOverLine* over = (MTOverLine*) atom;
                MTDisplay* display = [self makeOverline:over];
                [_displayAtoms addObject:display];
                _currentPosition.x += display.width;
                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    [self makeScripts:atom display:display index:atom.indexRange.location delta:0];
                }
                break;
            }
                
            case kMTMathAtomAccent: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                // Accent is considered as Ord in rule 16.
                [self addInterElementSpace:prevNode currentType:kMTMathAtomOrdinary];
                atom.type = kMTMathAtomOrdinary;
                
                MTAccent* accent = (MTAccent*) atom;
                MTDisplay* display = [self makeAccent:accent];
                [_displayAtoms addObject:display];
                _currentPosition.x += display.width;
                
                // add super scripts || subscripts
                if (atom.subScript || atom.superScript) {
                    [self makeScripts:atom display:display index:atom.indexRange.location delta:0];
                }
                break;
            }
                
            case kMTMathAtomTable: {
                // stash the existing layout
                if (_currentLine.length > 0) {
                    [self addDisplayLine];
                }
                // We will consider tables as inner
                [self addInterElementSpace:prevNode currentType:kMTMathAtomInner];
                atom.type = kMTMathAtomInner;
                
                MTMathTable* table = (MTMathTable*) atom;
                MTDisplay* display = [self makeTable:table];
                [_displayAtoms addObject:display];
                _currentPosition.x += display.width;
                // A table doesn't have subscripts or superscripts
                break;
            }
                
            case kMTMathAtomOrdinary:
            case kMTMathAtomBinaryOperator:
            case kMTMathAtomRelation:
            case kMTMathAtomOpen:
            case kMTMathAtomClose:
            case kMTMathAtomPlaceholder:
            case kMTMathAtomPunctuation: {
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
                    MTColor* color = [MTTypesetter placeholderColor];
                    current = [[NSAttributedString alloc] initWithString:atom.nucleus
                                                              attributes:@{ (NSString*) kCTForegroundColorAttributeName : (id) color.CGColor }];
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
        }
        lastType = atom.type;
        prevNode = atom;
    }
    if (_currentLine.length > 0) {
        [self addDisplayLine];
    }
    if (_spaced && lastType) {
        // If _spaced then add an interelement space between the last type and close
        MTDisplay* display = [_displayAtoms lastObject];
        CGFloat interElementSpace = [self getInterElementSpace:lastType right:kMTMathAtomClose];
        display.width += interElementSpace;
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
    NSArray* spaceArray = getInterElementSpaces()[leftIndex];
    NSNumber* spaceTypeObj = spaceArray[rightIndex];
    MTInterElementSpaceType spaceType = spaceTypeObj.intValue;
    NSAssert(spaceType != kMTSpaceInvalid, @"Invalid space between %lu and %lu", (unsigned long)left, (unsigned long)right);
    
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
            return kMTLineStyleScriptScript;
        case kMTLineStyleScriptScript:
            return kMTLineStyleScriptScript;
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

#pragma mark - Fractions

- (CGFloat) numeratorShiftUp:(BOOL) hasRule {
    if (hasRule) {
        if (_style == kMTLineStyleDisplay) {
            return _styleFont.mathTable.fractionNumeratorDisplayStyleShiftUp;
        } else {
            return _styleFont.mathTable.fractionNumeratorShiftUp;
        }
    } else {
        if (_style == kMTLineStyleDisplay) {
            return _styleFont.mathTable.stackTopDisplayStyleShiftUp;
        } else {
            return _styleFont.mathTable.stackTopShiftUp;
        }
    }
}

- (CGFloat) numeratorGapMin {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.fractionNumeratorDisplayStyleGapMin;
    } else {
        return _styleFont.mathTable.fractionNumeratorGapMin;
    }
}

- (CGFloat) denominatorShiftDown:(BOOL) hasRule {
    if (hasRule) {
        if (_style == kMTLineStyleDisplay) {
            return _styleFont.mathTable.fractionDenominatorDisplayStyleShiftDown;
        } else {
            return _styleFont.mathTable.fractionDenominatorShiftDown;
        }
    } else {
        if (_style == kMTLineStyleDisplay) {
            return _styleFont.mathTable.stackBottomDisplayStyleShiftDown;
        } else {
            return _styleFont.mathTable.stackBottomShiftDown;
        }
    }
}

- (CGFloat) denominatorGapMin {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.fractionDenominatorDisplayStyleGapMin;
    } else {
        return _styleFont.mathTable.fractionDenominatorGapMin;
    }
}

- (CGFloat) stackGapMin {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.stackDisplayStyleGapMin;
    } else {
        return _styleFont.mathTable.stackGapMin;
    }
}

- (CGFloat) fractionDelimiterHeight {
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.fractionDelimiterDisplayStyleSize;
    } else {
        return _styleFont.mathTable.fractionDelimiterSize;
    }
}

- (MTLineStyle) fractionStyle
{
    if (_style == kMTLineStyleScriptScript) {
        return kMTLineStyleScriptScript;
    }
    return _style + 1;
}

- (MTDisplay*) makeFraction:(MTFraction*) frac
{
    // lay out the parts of the fraction
    MTLineStyle fractionStyle = self.fractionStyle;
    MTMathListDisplay* numeratorDisplay = [MTTypesetter createLineForMathList:frac.numerator font:_font style:fractionStyle cramped:false];
    MTMathListDisplay* denominatorDisplay = [MTTypesetter createLineForMathList:frac.denominator font:_font style:fractionStyle cramped:true];
    
    // determine the location of the numerator
    CGFloat numeratorShiftUp = [self numeratorShiftUp:frac.hasRule];
    CGFloat denominatorShiftDown = [self denominatorShiftDown:frac.hasRule];
    CGFloat barLocation = _styleFont.mathTable.axisHeight;
    CGFloat barThickness = (frac.hasRule) ? _styleFont.mathTable.fractionRuleThickness : 0;
    
    if (frac.hasRule) {
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
        // This is the difference between the top edge of the denominator and the bottom edge of the fraction bar
        CGFloat distanceFromDenominatorToBar = (barLocation - barThickness/2) - (denominatorDisplay.ascent - denominatorShiftDown);
        // The distance should at least be denominator gap
        CGFloat minDenominatorGap = self.denominatorGapMin;
        if (distanceFromDenominatorToBar < minDenominatorGap) {
            // This makes the distance between the top of the denominator and the bottom of the fraction bar to be exactly
            // minDenominatorGap
            denominatorShiftDown += (minDenominatorGap - distanceFromDenominatorToBar);
        }
    } else {
        // This is the distance between the numerator and the denominator
        CGFloat clearance = (numeratorShiftUp - numeratorDisplay.descent) - (denominatorDisplay.ascent - denominatorShiftDown);
        // This is the minimum clearance between the numerator and denominator.
        CGFloat minGap = self.stackGapMin;
        if (clearance < minGap) {
            numeratorShiftUp += (minGap - clearance)/2;
            denominatorShiftDown += (minGap - clearance)/2;
        }
    }
    
    MTFractionDisplay *display = [[MTFractionDisplay alloc] initWithNumerator:numeratorDisplay denominator:denominatorDisplay
                                                                     position:_currentPosition range:frac.indexRange];
    
    display.numeratorUp = numeratorShiftUp;
    display.denominatorDown = denominatorShiftDown;
    display.lineThickness = barThickness;
    display.linePosition = barLocation;
    if (!frac.leftDelimiter && !frac.rightDelimiter) {
        return display;
    } else {
        return [self addDelimitersToFractionDisplay:display forFraction:frac];
    }
}

- (MTDisplay*) addDelimitersToFractionDisplay:(MTFractionDisplay*)display forFraction:(MTFraction*) frac
{
    NSAssert(frac.leftDelimiter || frac.rightDelimiter, @"Fraction should have a delimiters to call this function");
    
    NSMutableArray* innerElements = [[NSMutableArray alloc] init];
    CGFloat glyphHeight = self.fractionDelimiterHeight;
    CGPoint position = CGPointZero;
    if (frac.leftDelimiter.length > 0) {
        MTDisplay* leftGlyph = [self findGlyphForBoundary:frac.leftDelimiter withHeight:glyphHeight];
        leftGlyph.position = position;
        position.x += leftGlyph.width;
        [innerElements addObject:leftGlyph];
    }
    
    display.position = position;
    position.x += display.width;
    [innerElements addObject:display];
    
    if (frac.rightDelimiter.length > 0) {
        MTDisplay* rightGlyph = [self findGlyphForBoundary:frac.rightDelimiter withHeight:glyphHeight];
        rightGlyph.position = position;
        position.x += rightGlyph.width;
        [innerElements addObject:rightGlyph];
    }
    MTMathListDisplay* innerDisplay = [[MTMathListDisplay alloc] initWithDisplays:innerElements range:frac.indexRange];
    innerDisplay.position = _currentPosition;
    return innerDisplay;
}

#pragma mark Radicals

- (CGFloat) radicalVerticalGap
{
    if (_style == kMTLineStyleDisplay) {
        return _styleFont.mathTable.radicalDisplayStyleVerticalGap;
    } else {
        return _styleFont.mathTable.radicalVerticalGap;
    }
}

- (MTDisplay<DownShift>*)getRadicalGlyphWithHeight:(CGFloat)radicalHeight
{
    CGFloat glyphAscent, glyphDescent, glyphWidth;
    
    CGGlyph radicalGlyph = [self findGlyphForCharacterAtIndex:0 inString:@"\u221A"];
    CGGlyph glyph = [self findGlyph:radicalGlyph withHeight:radicalHeight glyphAscent:&glyphAscent glyphDescent:&glyphDescent glyphWidth:&glyphWidth];
    
    MTDisplay<DownShift>* glyphDisplay;
    if (glyphAscent + glyphDescent < radicalHeight) {
        // the glyphs is not as large as required. A glyph needs to be constructed using the extenders.
        glyphDisplay = [self constructGlyph:radicalGlyph withHeight:radicalHeight];
    }
    
    if (!glyphDisplay) {
        // No constructed display so use the glyph we got.
        glyphDisplay = [[MTGlyphDisplay alloc] initWithGlpyh:glyph range:NSMakeRange(NSNotFound, 0) font:_styleFont];
        glyphDisplay.ascent = glyphAscent;
        glyphDisplay.descent = glyphDescent;
        glyphDisplay.width = glyphWidth;
    }
    return glyphDisplay;
}

- (MTRadicalDisplay*) makeRadical:(MTMathList*) radicand range:(NSRange) range
{
    MTMathListDisplay* innerDisplay = [MTTypesetter createLineForMathList:radicand font:_font style:_style cramped:YES];
    CGFloat clearance = self.radicalVerticalGap;
    CGFloat radicalRuleThickness = _styleFont.mathTable.radicalRuleThickness;
    CGFloat radicalHeight = innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness;
    
    MTDisplay<DownShift>* glyph = [self getRadicalGlyphWithHeight:radicalHeight];
    
    
    // Note this is a departure from Latex. Latex assumes that glyphAscent == thickness.
    // Open type math makes no such assumption, and ascent and descent are independent of the thickness.
    // Latex computes delta as descent - (h(inner) + d(inner) + clearance)
    // but since we may not have ascent == thickness, we modify the delta calculation slightly.
    // If the font designer followes Latex conventions, it will be identical.
    CGFloat delta = (glyph.descent + glyph.ascent) - (innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness);
    if (delta > 0) {
        clearance += delta/2;  // increase the clearance to center the radicand inside the sign.
    }
    
    // we need to shift the radical glyph up, to coincide with the baseline of inner.
    // The new ascent of the radical glyph should be thickness + adjusted clearance + h(inner)
    CGFloat radicalAscent = radicalRuleThickness + clearance + innerDisplay.ascent;
    CGFloat shiftUp = radicalAscent - glyph.ascent;  // Note: if the font designer followed latex conventions, this is the same as glyphAscent == thickness.
    glyph.shiftDown = -shiftUp;
    
    MTRadicalDisplay* radical = [[MTRadicalDisplay alloc] initWitRadicand:innerDisplay glpyh:glyph position:_currentPosition range:range];
    radical.ascent = radicalAscent + _styleFont.mathTable.radicalExtraAscender;
    radical.topKern = _styleFont.mathTable.radicalExtraAscender;
    radical.lineThickness = radicalRuleThickness;
    // Note: Until we have radical construction from parts, it is possible that glyphAscent+glyphDescent is less
    // than the requested height of the glyph (i.e. radicalHeight), so in the case the innerDisplay has a larger
    // descent we use the innerDisplay's descent.
    radical.descent = MAX(glyph.ascent + glyph.descent  - radicalAscent, innerDisplay.descent);
    radical.width = glyph.width + innerDisplay.width;
    return radical;
}

#pragma mark Glyphs

- (CGGlyph) findGlyph:(CGGlyph) glyph withHeight:(CGFloat) height glyphAscent:(CGFloat*) glyphAscent glyphDescent:(CGFloat*) glyphDescent glyphWidth:(CGFloat*) glyphWidth
{
    NSArray<NSNumber*>* variants = [_styleFont.mathTable getVerticalVariantsForGlyph:glyph];
    CFIndex numVariants = variants.count;
    CGGlyph glyphs[numVariants];
    for (CFIndex i = 0; i < numVariants; i++) {
        CGGlyph glyph = [variants[i] shortValue];
        glyphs[i] = glyph;
    }
    
    CGRect bboxes[numVariants];
    CGSize advances[numVariants];
    // Get the bounds for these glyphs
    CTFontGetBoundingRectsForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, glyphs, bboxes, numVariants);
    CTFontGetAdvancesForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, glyphs, advances, numVariants);
    CGFloat ascent, descent, width;
    for (int i = 0; i < numVariants; i++) {
        CGRect bounds = bboxes[i];
        width = advances[i].width;
        getBboxDetails(bounds, &ascent, &descent);
        
        if (ascent + descent >= height) {
            *glyphAscent = ascent;
            *glyphDescent = descent;
            *glyphWidth = width;
            return glyphs[i];
        }
    }
    *glyphAscent = ascent;
    *glyphDescent = descent;
    *glyphWidth = width;
    return glyphs[numVariants - 1];
}

- (MTGlyphConstructionDisplay*) constructGlyph:(CGGlyph) glyph withHeight:(CGFloat) glyphHeight
{
    NSArray<MTGlyphPart*>* parts = [_styleFont.mathTable getVerticalGlyphAssemblyForGlyph:glyph];
    if (parts.count == 0) {
        return nil;
    }
    NSArray<NSNumber*>* glyphs, *offsets;
    CGFloat height;
    [self constructGlyphWithParts:parts height:glyphHeight glyphs:&glyphs offsets:&offsets height:&height];
    CGGlyph first = glyphs[0].shortValue;
    CGFloat width = CTFontGetAdvancesForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, &first, NULL, 1);
    MTGlyphConstructionDisplay* display = [[MTGlyphConstructionDisplay alloc] initWithGlyphs:glyphs offsets:offsets font:_styleFont];
    display.width = width;
    display.ascent = height;
    display.descent = 0;   // it's upto the rendering to adjust the display up or down.
    return display;
}

- (void) constructGlyphWithParts:(NSArray<MTGlyphPart*>*) parts height:(CGFloat) glyphHeight glyphs:(NSArray<NSNumber*>**) glyphs offsets:(NSArray<NSNumber*>**) offsets height:(CGFloat*) height
{
    NSParameterAssert(glyphs);
    NSParameterAssert(offsets);
    
    for (int numExtenders = 0; true; numExtenders++) {
        NSMutableArray<NSNumber*>* glyphsRv = [NSMutableArray array];
        NSMutableArray<NSNumber*>* offsetsRv = [NSMutableArray array];
        
        MTGlyphPart* prev = nil;
        CGFloat minDistance = _styleFont.mathTable.minConnectorOverlap;
        CGFloat minOffset = 0;
        CGFloat maxDelta = CGFLOAT_MAX;  // the maximum amount we can increase the offsets by
        
        for (MTGlyphPart* part in parts) {
            int repeats = 1;
            if (part.isExtender) {
                repeats = numExtenders;
            }
            // add the extender num extender times
            for (int i = 0; i < repeats; i++) {
                [glyphsRv addObject:[NSNumber numberWithShort:part.glyph]];
                if (prev) {
                    CGFloat maxOverlap = MIN(prev.endConnectorLength, part.startConnectorLength);
                    // the minimum amount we can add to the offset
                    CGFloat minOffsetDelta = prev.fullAdvance - maxOverlap;
                    // The maximum amount we can add to the offset.
                    CGFloat maxOffsetDelta = prev.fullAdvance - minDistance;
                    // we can increase the offsets by at most max - min.
                    maxDelta = MIN(maxDelta, maxOffsetDelta - minOffsetDelta);
                    minOffset = minOffset + minOffsetDelta;
                }
                [offsetsRv addObject:[NSNumber numberWithFloat:minOffset]];
                prev = part;
            }
        }
        
        NSAssert(glyphsRv.count == offsetsRv.count, @"Offsets should match the glyphs");
        if (!prev) {
            continue;   // maybe only extenders
        }
        CGFloat minHeight = minOffset + prev.fullAdvance;
        CGFloat maxHeight = minHeight + maxDelta * (glyphsRv.count - 1);
        if (minHeight >= glyphHeight) {
            // we are done
            *glyphs = glyphsRv;
            *offsets = offsetsRv;
            *height = minHeight;
            return;
        } else if (glyphHeight <= maxHeight) {
            // spread the delta equally between all the connectors
            CGFloat delta = glyphHeight - minHeight;
            CGFloat deltaIncrease = delta / (glyphsRv.count - 1);
            CGFloat lastOffset = 0;
            for (int i = 0; i < offsetsRv.count; i++) {
                CGFloat offset = offsetsRv[i].floatValue + i*deltaIncrease;
                offsetsRv[i] = [NSNumber numberWithFloat:offset];
                lastOffset = offset;
            }
            // we are done
            *glyphs = glyphsRv;
            *offsets = offsetsRv;
            *height = lastOffset + prev.fullAdvance;
            return;
        }
    }
}

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

#pragma mark Large Operators

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
        CGFloat width = CTFontGetAdvancesForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, &glyph, NULL, 1);
        CGFloat ascent, descent;
        getBboxDetails(bbox, &ascent, &descent);
        CGFloat shiftDown = 0.5*(ascent - descent) - _styleFont.mathTable.axisHeight;
        MTGlyphDisplay* glyphDisplay = [[MTGlyphDisplay alloc] initWithGlpyh:glyph range:op.indexRange font:_styleFont];
        glyphDisplay.ascent = ascent;
        glyphDisplay.descent = descent;
        glyphDisplay.width = width;
        if (op.subScript && !limits) {
            // Remove italic correction from the width of the glyph if
            // there is a subscript and limits is not set.
            glyphDisplay.width -= delta;
        }
        glyphDisplay.shiftDown = shiftDown;
        glyphDisplay.position = _currentPosition;
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

#pragma mark Large delimiters

// Delimiter shortfall from plain.tex
static const NSInteger kDelimiterFactor = 901;
static const NSInteger kDelimiterShortfallPoints = 5;

- (MTDisplay*) makeLeftRight:(MTInner*) inner
{
    NSAssert(inner.leftBoundary || inner.rightBoundary, @"Inner should have a boundary to call this function");
    
    MTMathListDisplay* innerListDisplay = [MTTypesetter createLineForMathList:inner.innerList font:_font style:_style cramped:_cramped spaced:YES];
    CGFloat axisHeight = _styleFont.mathTable.axisHeight;
    // delta is the max distance from the axis
    CGFloat delta = MAX(innerListDisplay.ascent - axisHeight, innerListDisplay.descent + axisHeight);
    CGFloat d1 = (delta / 500) * kDelimiterFactor;  // This represents atleast 90% of the formula
    CGFloat d2 = 2 * delta - kDelimiterShortfallPoints;  // This represents a shortfall of 5pt
    // The size of the delimiter glyph should cover at least 90% of the formula or
    // be at most 5pt short.
    CGFloat glyphHeight = MAX(d1, d2);
    
    NSMutableArray* innerElements = [[NSMutableArray alloc] init];
    CGPoint position = CGPointZero;
    if (inner.leftBoundary && inner.leftBoundary.nucleus.length > 0) {
        MTDisplay* leftGlyph = [self findGlyphForBoundary:inner.leftBoundary.nucleus withHeight:glyphHeight];
        leftGlyph.position = position;
        position.x += leftGlyph.width;
        [innerElements addObject:leftGlyph];
    }
    
    innerListDisplay.position = position;
    position.x += innerListDisplay.width;
    [innerElements addObject:innerListDisplay];
    
    if (inner.rightBoundary && inner.rightBoundary.nucleus.length > 0) {
        MTDisplay* rightGlyph = [self findGlyphForBoundary:inner.rightBoundary.nucleus withHeight:glyphHeight];
        rightGlyph.position = position;
        position.x += rightGlyph.width;
        [innerElements addObject:rightGlyph];
    }
    MTMathListDisplay* innerDisplay = [[MTMathListDisplay alloc] initWithDisplays:innerElements range:inner.indexRange];
    return innerDisplay;
}

- (MTDisplay*) findGlyphForBoundary:(NSString*) delimiter withHeight:(CGFloat) glyphHeight
{
    CGFloat glyphAscent, glyphDescent, glyphWidth;
    CGGlyph leftGlyph = [self findGlyphForCharacterAtIndex:0 inString:delimiter];
    CGGlyph glyph = [self findGlyph:leftGlyph withHeight:glyphHeight glyphAscent:&glyphAscent glyphDescent:&glyphDescent glyphWidth:&glyphWidth];
    
    MTDisplay<DownShift>* glyphDisplay;
    if (glyphAscent + glyphDescent < glyphHeight) {
        // we didn't find a pre-built glyph that is large enough
        glyphDisplay = [self constructGlyph:leftGlyph withHeight:glyphHeight];
    }
    
    if (!glyphDisplay) {
        // Create a glyph display
        glyphDisplay = [[MTGlyphDisplay alloc] initWithGlpyh:glyph range:NSMakeRange(NSNotFound, 0) font:_styleFont];
        glyphDisplay.ascent = glyphAscent;
        glyphDisplay.descent = glyphDescent;
        glyphDisplay.width = glyphWidth;
    }
    // Center the glyph on the axis
    CGFloat shiftDown = 0.5*(glyphDisplay.ascent - glyphDisplay.descent) - _styleFont.mathTable.axisHeight;
    glyphDisplay.shiftDown = shiftDown;
    return glyphDisplay;
}

#pragma mark Underline/Overline

- (MTDisplay*) makeUnderline:(MTUnderLine*) under
{
    MTMathListDisplay* innerListDisplay = [MTTypesetter createLineForMathList:under.innerList font:_font style:_style cramped:_cramped];
    MTLineDisplay* underDisplay = [[MTLineDisplay alloc] initWithInner:innerListDisplay position:_currentPosition range:under.indexRange];
    // Move the line down by the vertical gap.
    underDisplay.lineShiftUp = -(innerListDisplay.descent + _styleFont.mathTable.underbarVerticalGap);
    underDisplay.lineThickness = _styleFont.mathTable.underbarRuleThickness;
    underDisplay.ascent = innerListDisplay.ascent;
    underDisplay.descent = innerListDisplay.descent + _styleFont.mathTable.underbarVerticalGap + _styleFont.mathTable.underbarRuleThickness + _styleFont.mathTable.underbarExtraDescender;
    underDisplay.width = innerListDisplay.width;
    return underDisplay;
}

- (MTDisplay*) makeOverline:(MTOverLine*) over
{
    MTMathListDisplay* innerListDisplay = [MTTypesetter createLineForMathList:over.innerList font:_font style:_style cramped:YES];
    MTLineDisplay* overDisplay = [[MTLineDisplay alloc] initWithInner:innerListDisplay position:_currentPosition range:over.indexRange];
    overDisplay.lineShiftUp = innerListDisplay.ascent + _styleFont.mathTable.overbarVerticalGap;
    overDisplay.lineThickness = _styleFont.mathTable.underbarRuleThickness;
    overDisplay.ascent = innerListDisplay.ascent + _styleFont.mathTable.overbarVerticalGap + _styleFont.mathTable.overbarRuleThickness + _styleFont.mathTable.overbarExtraAscender;
    overDisplay.descent = innerListDisplay.descent;
    overDisplay.width = innerListDisplay.width;
    return overDisplay;
}

#pragma mark Accents

- (BOOL) isSingleCharAccentee:(MTAccent*) accent
{
    if (accent.innerList.atoms.count != 1) {
        // Not a single char list.
        return 0;
    }
    MTMathAtom* innerAtom = accent.innerList.atoms[0];
    if (innerAtom.nucleus.unicodeLength != 1) {
        // A complex atom, not a simple char.
        return NO;
    }
    if (innerAtom.subScript || innerAtom.superScript) {
        return NO;
    }
    return YES;
}

// The distance the accent must be moved from the beginning.
- (CGFloat) getSkew:(MTAccent*) accent accenteeWidth:(CGFloat) width accentGlyph:(CGGlyph) accentGlyph
{
    if (accent.nucleus.length == 0) {
        // No accent
        return 0;
    }
    CGFloat accentAdjustment = [_styleFont.mathTable getTopAccentAdjustment:accentGlyph];
    CGFloat accenteeAdjustment = 0;
    if (![self isSingleCharAccentee:accent]) {
        // use the center of the accentee
        accenteeAdjustment = width/2;
    } else {
        MTMathAtom* innerAtom = accent.innerList.atoms[0];
        CGGlyph accenteeGlyph = [self findGlyphForCharacterAtIndex:innerAtom.nucleus.length - 1 inString:innerAtom.nucleus];
        accenteeAdjustment = [_styleFont.mathTable getTopAccentAdjustment:accenteeGlyph];
    }
    // The adjustments need to aligned, so skew is just the difference.
    return (accenteeAdjustment - accentAdjustment);
}

// Find the largest horizontal variant if exists, with width less than max width.
- (CGGlyph) findVariantGlyph:(CGGlyph) glyph withMaxWidth:(CGFloat) maxWidth glyphAscent:(CGFloat*) glyphAscent glyphDescent:(CGFloat*) glyphDescent glyphWidth:(CGFloat*) glyphWidth
{
    NSArray<NSNumber*>* variants = [_styleFont.mathTable getHorizontalVariantsForGlyph:glyph];
    CFIndex numVariants = variants.count;
    NSAssert(numVariants > 0, @"A glyph is always it's own variant, so number of variants should be > 0");
    CGGlyph glyphs[numVariants];
    for (CFIndex i = 0; i < numVariants; i++) {
        CGGlyph glyph = [variants[i] shortValue];
        glyphs[i] = glyph;
    }
    
    CGGlyph curGlyph = glyphs[0];  // if no other glyph is found, we'll return the first one.
    CGRect bboxes[numVariants];
    CGSize advances[numVariants];
    // Get the bounds for these glyphs
    CTFontGetBoundingRectsForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, glyphs, bboxes, numVariants);
    CTFontGetAdvancesForGlyphs(_styleFont.ctFont, kCTFontHorizontalOrientation, glyphs, advances, numVariants);
    for (int i = 0; i < numVariants; i++) {
        CGRect bounds = bboxes[i];
        CGFloat ascent, descent;
        CGFloat width = CGRectGetMaxX(bounds);
        getBboxDetails(bounds, &ascent, &descent);
        
        if (width > maxWidth) {
            if (i == 0) {
                // glyph dimensions are not yet set
                *glyphWidth = advances[i].width;
                *glyphAscent = ascent;
                *glyphDescent = descent;
            }
            return curGlyph;
        } else {
            curGlyph = glyphs[i];
            *glyphWidth = advances[i].width;
            *glyphAscent = ascent;
            *glyphDescent = descent;
        }
    }
    // We exhausted all the variants and none was larger than the width, so we return the largest
    return curGlyph;
}

- (MTDisplay*) makeAccent:(MTAccent*) accent
{
    MTMathListDisplay* accentee = [MTTypesetter createLineForMathList:accent.innerList font:_font style:_style cramped:YES];
    if (accent.nucleus.length == 0) {
        // no accent!
        return accentee;
    }
    CGGlyph accentGlyph = [self findGlyphForCharacterAtIndex:accent.nucleus.length - 1 inString:accent.nucleus];
    CGFloat accenteeWidth = accentee.width;
    CGFloat glyphAscent, glyphDescent, glyphWidth;
    accentGlyph = [self findVariantGlyph:accentGlyph withMaxWidth:accenteeWidth glyphAscent:&glyphAscent glyphDescent:&glyphDescent glyphWidth:&glyphWidth];
    CGFloat delta = MIN(accentee.ascent, _styleFont.mathTable.accentBaseHeight);
    
    CGFloat skew = [self getSkew:accent accenteeWidth:accenteeWidth accentGlyph:accentGlyph];
    CGFloat height = accentee.ascent - delta;  // This is always positive since delta <= height.
    CGPoint accentPosition = CGPointMake(skew, height);
    MTGlyphDisplay* accentGlyphDisplay = [[MTGlyphDisplay alloc] initWithGlpyh:accentGlyph range:accent.indexRange font:_styleFont];
    accentGlyphDisplay.ascent = glyphAscent;
    accentGlyphDisplay.descent = glyphDescent;
    accentGlyphDisplay.width = glyphWidth;
    accentGlyphDisplay.position = accentPosition;
    
    if ([self isSingleCharAccentee:accent] && (accent.subScript || accent.superScript)) {
        // Attach the super/subscripts to the accentee instead of the accent.
        MTMathAtom* innerAtom = accent.innerList.atoms[0];
        innerAtom.superScript = accent.superScript;
        innerAtom.subScript = accent.subScript;
        accent.superScript = nil;
        accent.subScript = nil;
        // Remake the accentee (now with sub/superscripts)
        // Note: Latex adjusts the heights in case the height of the char is different in non-cramped mode. However this shouldn't be the case since cramping
        // only affects fractions and superscripts. We skip adjusting the heights.
        accentee = [MTTypesetter createLineForMathList:accent.innerList font:_font style:_style cramped:_cramped];
    }
    
    MTAccentDisplay* display = [[MTAccentDisplay alloc] initWithAccent:accentGlyphDisplay accentee:accentee range:accent.indexRange];
    display.width = accentee.width;
    display.descent = accentee.descent;
    CGFloat ascent = accentee.ascent - delta + glyphAscent;
    display.ascent = MAX(accentee.ascent, ascent);
    display.position = _currentPosition;
    
    return display;
}

#pragma mark - Table

static const CGFloat kBaseLineSkipMultiplier = 1.2;  // default base line stretch is 12 pt for 10pt font.
static const CGFloat kLineSkipMultiplier = 0.1;  // default is 1pt for 10pt font.
static const CGFloat kLineSkipLimitMultiplier = 0;
static const CGFloat kJotMultiplier = 0.3; // A jot is 3pt for a 10pt font.

- (MTDisplay*) makeTable:(MTMathTable*) table
{
    NSUInteger numColumns = table.numColumns;
    if (numColumns == 0 || table.numRows == 0) {
        // Empty table
        return [[MTMathListDisplay alloc] initWithDisplays:[NSArray array] range:table.indexRange];
    }
    
    CGFloat columnWidths[numColumns];
    for (int i = 0; i < numColumns; i++) {
        columnWidths[i] = 0;
    }
    NSArray<NSArray<MTDisplay*>*>* displays = [self typesetCells:table columnWidths:columnWidths];
    
    // Position all the columns in each row
    NSMutableArray<MTDisplay*>* rowDisplays = [NSMutableArray arrayWithCapacity:table.cells.count];
    for (NSArray<MTDisplay*>* row in displays) {
        MTMathListDisplay* rowDisplay = [self makeRowWithColumns:row forTable:table columnWidths:columnWidths];
        [rowDisplays addObject:rowDisplay];
    }
    
    // Position all the rows
    [self positionRows:rowDisplays forTable:table];
    MTMathListDisplay* tableDisplay = [[MTMathListDisplay alloc] initWithDisplays:rowDisplays range:table.indexRange];
    tableDisplay.position = _currentPosition;
    return tableDisplay;
}

// Typeset every cell in the table. As a side-effect calculate the max column width of each column.
- (NSArray<NSArray<MTDisplay*>*>*) typesetCells:(MTMathTable*) table columnWidths:(CGFloat[]) columnWidths
{
    NSMutableArray<NSMutableArray<MTDisplay*>*> *displays = [NSMutableArray arrayWithCapacity:table.numRows];
    
    for(NSArray<MTMathList*>* row in table.cells) {
        NSMutableArray<MTDisplay*>* colDisplays = [NSMutableArray arrayWithCapacity:row.count];
        [displays addObject:colDisplays];
        for (int i = 0; i < row.count; i++) {
            MTMathListDisplay* disp = [MTTypesetter createLineForMathList:row[i] font:_font style:_style cramped:NO];
            columnWidths[i] = MAX(disp.width, columnWidths[i]);
            [colDisplays addObject:disp];
        };
    };
    return displays;
}

- (MTMathListDisplay*) makeRowWithColumns:(NSArray<MTDisplay*>*) cols forTable:(MTMathTable*) table columnWidths:(CGFloat[]) columnWidths
{
    CGFloat columnStart = 0;
    NSRange rowRange = NSMakeRange(NSNotFound, 0);
    for (int i = 0; i < cols.count; i++) {
        MTDisplay* col = cols[i];
        CGFloat colWidth = columnWidths[i];
        MTColumnAlignment alignment = [table getAlignmentForColumn:i];
        
        CGFloat cellPos = columnStart;
        switch (alignment) {
            case kMTColumnAlignmentRight:
                cellPos += colWidth - col.width;
                break;
                
            case kMTColumnAlignmentCenter:
                cellPos += (colWidth - col.width) / 2;
                break;
                
            case kMTColumnAlignmentLeft:
                // No changes if left aligned
                break;
        }
        if (rowRange.location != NSNotFound) {
            rowRange = NSUnionRange(rowRange, col.range);
        } else {
            rowRange = col.range;
        }
        
        col.position = CGPointMake(cellPos, 0);
        columnStart += colWidth + table.interColumnSpacing * _styleFont.mathTable.muUnit;
    };
    // Create a display for the row
    MTMathListDisplay* rowDisplay = [[MTMathListDisplay alloc] initWithDisplays:cols range:rowRange];
    return rowDisplay;
}

- (void) positionRows:(NSArray<MTDisplay*>*) rows forTable:(MTMathTable*) table
{
    // Position the rows
    // We will first position the rows starting from 0 and then in the second pass center the whole table vertically.
    CGFloat currPos = 0;
    CGFloat openup = table.interRowAdditionalSpacing * kJotMultiplier * _styleFont.fontSize;
    CGFloat baselineSkip = openup + kBaseLineSkipMultiplier * _styleFont.fontSize;
    CGFloat lineSkip = openup + kLineSkipMultiplier * _styleFont.fontSize;
    CGFloat lineSkipLimit = openup + kLineSkipLimitMultiplier * _styleFont.fontSize;
    CGFloat prevRowDescent = 0;
    CGFloat ascent = 0;
    BOOL first = true;
    for (MTDisplay* row in rows) {
        if (first) {
            row.position = CGPointZero;
            ascent += row.ascent;
            first = false;
        } else {
            CGFloat skip = baselineSkip;
            if (skip - (prevRowDescent + row.ascent) < lineSkipLimit) {
                // rows are too close to each other. Space them apart further
                skip = prevRowDescent + row.ascent + lineSkip;
            }
            // We are going down so we decrease the y value.
            currPos -= skip;
            row.position = CGPointMake(0, currPos);
        }
        prevRowDescent = row.descent;
    }
    
    // Vertically center the whole structure around the axis
    // The descent of the structure is the position of the last row
    // plus the descent of the last row.
    CGFloat descent =  - currPos + prevRowDescent;
    CGFloat shiftDown = 0.5*(ascent - descent) - _styleFont.mathTable.axisHeight;
    
    for (MTDisplay* row in rows) {
        row.position = CGPointMake(row.position.x, row.position.y - shiftDown);
    }
}
@end
