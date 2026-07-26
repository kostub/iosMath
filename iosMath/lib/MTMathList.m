//
//  MathList.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathList.h"
#import "MTMathListBuilder.h"
#import "MTMathAtomFactory.h"
#import "MTMacroParameterAtom.h"

// Returns true if the current binary operator is not really binary.
static BOOL isNotBinaryOperator(MTMathAtom* prevNode)
{
    if (!prevNode) {
        return true;
    }
    
    if (prevNode.type == kMTMathAtomBinaryOperator || prevNode.type == kMTMathAtomRelation || prevNode.type == kMTMathAtomOpen || prevNode.type == kMTMathAtomPunctuation || prevNode.type == kMTMathAtomLargeOperator) {
        return true;
    }
    return false;
}

static NSString* typeToText(MTMathAtomType type) {
    switch (type) {
        case kMTMathAtomOrdinary:
            return @"Ordinary";
        case kMTMathAtomNumber:
            return @"Number";
        case kMTMathAtomVariable:
            return @"Variable";
        case kMTMathAtomBinaryOperator:
            return @"Binary Operator";
        case kMTMathAtomUnaryOperator:
            return @"Unary Operator";
        case kMTMathAtomRelation:
            return @"Relation";
        case kMTMathAtomOpen:
            return @"Open";
        case kMTMathAtomClose:
            return @"Close";
        case kMTMathAtomFraction:
            return @"Fraction";
        case kMTMathAtomRadical:
            return @"Radical";
        case kMTMathAtomPunctuation:
            return @"Punctuation";
        case kMTMathAtomPlaceholder:
            return @"Placeholder";
        case kMTMathAtomLargeOperator:
            return @"Large Operator";
        case kMTMathAtomInner:
            return @"Inner";
        case kMTMathAtomUnderline:
            return @"Underline";
        case kMTMathAtomOverline:
            return @"Overline";
        case kMTMathAtomAccent:
            return @"Accent";
        case kMTMathAtomStack:
            return @"Stack";
        case kMTMathAtomText:
            return @"Text";
        case kMTMathAtomBox:
            return @"Box";
        case kMTMathAtomOrdGroup:
            return @"Ord Group";
        case kMTMathAtomMacro:
            return @"Macro";
        case kMTMathAtomBoundary:
            return @"Boundary";
        case kMTMathAtomSpace:
            return @"Space";
        case kMTMathAtomStyle:
            return @"Style";
        case kMTMathAtomColor:
            return @"Color";
        case kMTMathAtomColorbox:
            return @"Colorbox";
        case kMTMathAtomTable:
            return @"Table";
    }
}

// NSArray's -copy is shallow: it copies the array but shares the (mutable)
// MTMathList elements. MTMathList's own -copyWithZone: is already deep.
static NSArray<MTMathList*>* MTDeepCopyMathListArray(NSArray<MTMathList*>* lists)
{
    NSMutableArray<MTMathList*>* copies = [NSMutableArray arrayWithCapacity:lists.count];
    for (MTMathList* list in lists) {
        [copies addObject:[list copy]];
    }
    return [copies copy];
}

/** YES if `object` is, or transitively holds, an MTMacroParameterAtom.

 Duck-typed on the accessor names the containers in MTMathList.h share, rather
 than switched on -type: -innerList alone is declared on nine unrelated classes
 with no common protocol, and a container added later that follows the same
 naming is covered for free. */
static BOOL MTContainsMacroParameter(id object)
{
    if ([object isKindOfClass:[MTMacroParameterAtom class]]) {
        return YES;
    }
    if ([object isKindOfClass:[MTMathList class]]) {
        for (MTMathAtom* atom in [(MTMathList*)object atoms]) {
            if (MTContainsMacroParameter(atom)) {
                return YES;
            }
        }
        return NO;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        for (id element in (NSArray*)object) {
            if (MTContainsMacroParameter(element)) {
                return YES;
            }
        }
        return NO;
    }
    // Keys and their selectors are both resolved once: this runs per visited object,
    // and NSSelectorFromString on every key on every visit is pure overhead.
    static NSArray<NSString*>* childKeys = nil;
    static SEL* childSelectors = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        childKeys = @[ @"innerList", @"numerator", @"denominator", @"radicand",
                       @"degree", @"superScript", @"subScript", @"cells",
                       @"over", @"under", @"list", @"arguments",
                       @"templateExpression" ];
        childSelectors = calloc(childKeys.count, sizeof(SEL));
        for (NSUInteger i = 0; i < childKeys.count; i++) {
            childSelectors[i] = NSSelectorFromString(childKeys[i]);
        }
    });
    for (NSUInteger i = 0; i < childKeys.count; i++) {
        if ([object respondsToSelector:childSelectors[i]]
            && MTContainsMacroParameter([object valueForKey:childKeys[i]])) {
            return YES;
        }
    }
    return NO;
}

/** How deep macro expansion may nest before it is declared runaway. Expansion
 recurses once per level of macro-inside-macro-argument nesting, so without a
 budget a deep enough chain runs the stack out instead of reporting anything. Real
 templates nest one or two levels. */
static const NSUInteger kMTMaxMacroExpansionDepth = 32;

@interface MTMathList ()

/** Returns a copy of this list with every top-level MTMacroAtom replaced by its
 RAW (non-finalized) expansion. Non-macro atoms are carried over by reference. */
- (MTMathList *)expandMacros;

/** @param depth how many macro expansions are already on the stack. */
- (MTMathList *)expandMacrosAtDepth:(NSUInteger)depth;

@end

@interface MTMacroAtom ()

/** The RAW (non-finalized) atom stream this invocation stands for. */
- (MTMathList *)expansion;

/** @param depth how many macro expansions are already on the stack. Throws once
 it reaches kMTMaxMacroExpansionDepth. */
- (MTMathList *)expansionAtDepth:(NSUInteger)depth;

/** Moves this atom's scripts onto the last scriptable atom of `expansion`,
 appending an empty Ordinary when there is no free target. */
- (void)transferScriptsToExpansion:(MTMathList *)expansion;

@end

@interface MTMathListBuilder (MTMathListSerializationSupport)

+ (NSString*)delimToString:(MTMathAtom*)delim;
+ (NSDictionary*)spaceToCommands;
+ (NSDictionary*)styleToCommands;

@end

static NSString* fractionCommandForDelimiterPair(NSString* leftDelimiter, NSString* rightDelimiter)
{
    if (!leftDelimiter && !rightDelimiter) {
        return @"atop";
    } else if ([leftDelimiter isEqualToString:@"("] && [rightDelimiter isEqualToString:@")"]) {
        return @"choose";
    } else if ([leftDelimiter isEqualToString:@"{"] && [rightDelimiter isEqualToString:@"}"]) {
        return @"brace";
    } else if ([leftDelimiter isEqualToString:@"["] && [rightDelimiter isEqualToString:@"]"]) {
        return @"brack";
    }
    return [NSString stringWithFormat:@"atopwithdelims%@%@", leftDelimiter, rightDelimiter];
}

#pragma mark - MTMathAtom

@interface MTMathAtom ()

@property (nonatomic) NSRange indexRange;

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value NS_DESIGNATED_INITIALIZER;

@end

@implementation MTMathAtom {
    NSMutableArray* _fusedAtoms;
}

+ (instancetype)atomWithType:(MTMathAtomType)type value:(NSString *)value
{
    switch (type) {
        case kMTMathAtomFraction:
            return [[MTFraction alloc] init];
            
        case kMTMathAtomPlaceholder:
            // A placeholder is created with a white square.
            return [[[self class] alloc] initWithType:kMTMathAtomPlaceholder value:@"\u25A1"];
            
        case kMTMathAtomRadical:
            return [[MTRadical alloc] init];
            
        case kMTMathAtomLargeOperator:
            // Default setting of limits is true
            return [[MTLargeOperator alloc] initWithValue:value limits:YES];
            
        case kMTMathAtomInner:
            return [[MTInner alloc] init];
            
        case kMTMathAtomOverline:
            return [[MTOverLine alloc] init];
            
        case kMTMathAtomUnderline:
            return [[MTUnderLine alloc] init];
            
        case kMTMathAtomAccent:
            return [[MTAccent alloc] initWithValue:value];

        case kMTMathAtomStack:
            return [[MTMathStack alloc] init];

        case kMTMathAtomText:
            return [[MTTextAtom alloc] initWithText:value ?: @""
                                             style:kMTTextStyleRoman];

        case kMTMathAtomBox:
            return [[MTMathBox alloc] init];

        case kMTMathAtomOrdGroup:
            return [[MTMathGroup alloc] init];

        case kMTMathAtomSpace:
            return [[MTMathSpace alloc] initWithSpace:0];

        case kMTMathAtomColor:
            return [[MTMathColor alloc] init];
            
        case kMTMathAtomColorbox:
            return [[MTMathColorbox alloc] init];

        case kMTMathAtomMacro:
            // Falling through to the default would mint a plain MTMathAtom carrying
            // type 22 — an atom that claims to be a macro but cannot expand.
            @throw [NSException exceptionWithName:@"InvalidMethod"
                                           reason:@"A macro atom cannot be created by type. Use -[MTMacroAtom initWithCommand:arguments:templateExpression:] instead."
                                         userInfo:nil];

        default:
            return [[MTMathAtom alloc] initWithType:type value:value];
    }
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    self = [super init];
    if (self) {
        _type = type;
        _nucleus = [value copy];
    }
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathAtom init] cannot be called. Use [MTMathAtom initWithType:value:] instead."
                                 userInfo:nil];
}

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithString:self.nucleus];
    if (self.superScript) {
        [str appendFormat:@"^{%@}", self.superScript.stringValue];
    }
    if (self.subScript) {
        [str appendFormat:@"_{%@}", self.subScript.stringValue];
    }
    return str;
}

// Note this is a deep copy.
- (id)copyWithZone:(NSZone *)zone
{
    MTMathAtom* atom = [[[self class] allocWithZone:zone] initWithType:self.type value:self.nucleus];
    atom.type = self.type;
    atom.nucleus = self.nucleus;
    atom.subScript = [self.subScript copyWithZone:zone];
    atom.superScript = [self.superScript copyWithZone:zone];
    atom.indexRange = self.indexRange;
    atom.fontStyle = self.fontStyle;
    return atom;
}

- (bool)scriptsAllowed
{
    return (self.type < kMTMathAtomBoundary);
}

- (void)setSubScript:(MTMathList *)subScript
{
    if (subScript && !self.scriptsAllowed) {
        @throw [[NSException alloc] initWithName:@"Error"
                                          reason:[NSString stringWithFormat:@"Subscripts not allowed for atom of type %@", typeToText(self.type)]
                                        userInfo:nil];
    }
    _subScript = subScript;
}

- (void)setSuperScript:(MTMathList *)superScript
{
    if (superScript && !self.scriptsAllowed) {
        @throw [[NSException alloc] initWithName:@"Error"
                                          reason:[NSString stringWithFormat:@"Superscripts not allowed for atom of type %@", typeToText(self.type)]
                                        userInfo:nil];
    }
    _superScript = superScript;
}

- (NSString *)description
{
    NSMutableString* str = [NSMutableString stringWithString:typeToText(self.type)];
    [str appendFormat:@": %@", self.stringValue];
    return str;
}

- (void)fuse:(MTMathAtom *)atom
{
    NSAssert(!self.subScript, @"Cannot fuse into an atom which has a subscript: %@", self);
    NSAssert(!self.superScript, @"Cannot fuse into an atom which has a superscript: %@", self);
    NSAssert(atom.type == self.type, @"Only atoms of the same type can be fused. %@, %@", self, atom);
    
    // Update the fused atoms list
    if (!_fusedAtoms) {
        _fusedAtoms = [NSMutableArray arrayWithObject:[self copy]];
    }
    if (atom.fusedAtoms) {
        [_fusedAtoms addObjectsFromArray:atom.fusedAtoms];
    } else {
        [_fusedAtoms addObject:atom];
    }    
    
    // Update the nucleus
    NSMutableString* str = self.nucleus.mutableCopy;
    [str appendString:atom.nucleus];
    self.nucleus = str;
    
    // Update the range
    NSRange newRange = self.indexRange;
    newRange.length += atom.indexRange.length;
    self.indexRange = newRange;
    
    // Update super/sub scripts
    self.subScript = atom.subScript;
    self.superScript = atom.superScript;
}

- (instancetype)finalized
{
    MTMathAtom* newNode = [self copy];
    if (newNode.superScript) {
        newNode.superScript = newNode.superScript.finalized;
    }
    if (newNode.subScript) {
        newNode.subScript = newNode.subScript.finalized;
    }
    return newNode;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    if (self.nucleus.length == 0) {
        [str appendString:@"{}"];
    } else if ([self.nucleus isEqualToString:@"\u2236"]) {
        // math colon
        [str appendString:@":"];
    } else if ([self.nucleus isEqualToString:@"\u2212"]) {
        // math minus
        [str appendString:@"-"];
    } else {
        NSString* command = [MTMathAtomFactory latexSymbolNameForAtom:self];
        if (command) {
            [str appendFormat:@"\\%@ ", command];
        } else {
            [str appendString:self.nucleus];
        }
    }
}

@end

#pragma mark - MTFraction

@implementation MTFraction

- (instancetype)init
{
    return [self initWithRule:true];
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomFraction) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTFraction initWithType:value:] cannot be called. Use [MTFraction init] instead."
                                 userInfo:nil];
}

- (instancetype)initWithRule:(BOOL)hasRule
{
    // fractions have no nucleus
    self = [super initWithType:kMTMathAtomFraction value:@""];
    if (self) {
        _hasRule = hasRule;
    }
    return self;
}

- (NSString *)stringValue
{
    NSMutableString* str = [[NSMutableString alloc] init];
    if (self.hasRule) {
        [str appendString:@"\\frac"];
    } else {
        [str appendString:@"\\atop"];
    }
    if (self.leftDelimiter || self.rightDelimiter) {
        [str appendFormat:@"[%@][%@]", self.leftDelimiter, self.rightDelimiter];
    }
    
    [str appendFormat:@"{%@}{%@}", self.numerator.stringValue, self.denominator.stringValue];
    if (self.superScript) {
        [str appendFormat:@"^{%@}", self.superScript.stringValue];
    }
    if (self.subScript) {
        [str appendFormat:@"_{%@}", self.subScript.stringValue];
    }
    return str;
}

- (id)copyWithZone:(NSZone *)zone
{
    MTFraction* frac = [super copyWithZone:zone];
    frac.numerator = [self.numerator copyWithZone:zone];
    frac.denominator = [self.denominator copyWithZone:zone];
    frac->_hasRule = self.hasRule;
    frac.leftDelimiter = [self.leftDelimiter copyWithZone:zone];
    frac.rightDelimiter = [self.rightDelimiter copyWithZone:zone];
    frac.styleOverride = self.styleOverride;
    frac.isContinuedFraction = self.isContinuedFraction;
    frac.numeratorAlignment = self.numeratorAlignment;
    return frac;
}

- (instancetype)finalized
{
    MTFraction* newFrac = [super finalized];
    newFrac.numerator = newFrac.numerator.finalized;
    newFrac.denominator = newFrac.denominator.finalized;
    return newFrac;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    NSString* numLatex = [MTMathListBuilder mathListToString:self.numerator];
    NSString* denLatex = [MTMathListBuilder mathListToString:self.denominator];
    NSString* (^wrap)(NSString*) = ^NSString*(NSString* inner) {
        switch (self.styleOverride) {
            case kMTFractionStyleDisplay:
                return [NSString stringWithFormat:@"\\displaystyle{%@}", inner];
            case kMTFractionStyleText:
                return [NSString stringWithFormat:@"\\textstyle{%@}", inner];
            case kMTFractionStyleScript:
                return [NSString stringWithFormat:@"\\scriptstyle{%@}", inner];
            case kMTFractionStyleScriptScript:
                return [NSString stringWithFormat:@"\\scriptscriptstyle{%@}", inner];
            case kMTFractionStyleAuto:
            default:
                return inner;
        }
    };
    NSString* numWrapped = wrap(numLatex);
    NSString* denWrapped = wrap(denLatex);
    if (self.hasRule) {
        [str appendFormat:@"\\frac{%@}{%@}", numWrapped, denWrapped];
        return;
    }
    NSString* command = fractionCommandForDelimiterPair(self.leftDelimiter, self.rightDelimiter);
    [str appendFormat:@"{%@ \\%@ %@}", numWrapped, command, denWrapped];
}

@end

#pragma mark - MTRadical

@implementation MTRadical

- (instancetype)init
{
    // radicals have no nucleus
    self = [super initWithType:kMTMathAtomRadical value:@""];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomRadical) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTRadical initWithType:value:] cannot be called. Use [MTRadical init] instead."
                                 userInfo:nil];
}

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithString:@"\\sqrt"];
    if (self.degree) {
        [str appendFormat:@"[%@]", self.degree.stringValue];
    }
    [str appendFormat:@"{%@}", self.radicand.stringValue];

    if (self.superScript) {
        [str appendFormat:@"^{%@}", self.superScript.stringValue];
    }
    if (self.subScript) {
        [str appendFormat:@"_{%@}", self.subScript.stringValue];
    }
    return str;
}

- (id)copyWithZone:(NSZone *)zone
{
    MTRadical* rad = [super copyWithZone:zone];
    rad.radicand = [self.radicand copyWithZone:zone];
    rad.degree = [self.degree copyWithZone:zone];
    return rad;
}

- (instancetype)finalized
{
    MTRadical* newRad = [super finalized];
    newRad.radicand = newRad.radicand.finalized;
    newRad.degree = newRad.degree.finalized;
    return newRad;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    [str appendString:@"\\sqrt"];
    if (self.degree) {
        [str appendFormat:@"[%@]", [MTMathListBuilder mathListToString:self.degree]];
    }
    [str appendFormat:@"{%@}", [MTMathListBuilder mathListToString:self.radicand]];
}

@end

#pragma mark - MTLargeOperator

@implementation MTLargeOperator

- (instancetype) initWithValue:(NSString*) value limits:(BOOL) limits
{
    self = [super initWithType:kMTMathAtomLargeOperator value:value];
    if (self) {
        _limits = limits;
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomLargeOperator) {
        return [self initWithValue:value limits:false];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTLargeOperator initWithType:value:] cannot be called. Use [MTLargeOperator initWithValue:limits:] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTLargeOperator* op = [super copyWithZone:zone];
    op->_limits = self.limits;
    return op;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    NSString* command = [MTMathAtomFactory latexSymbolNameForAtom:self];
    MTLargeOperator* originalOp = (MTLargeOperator*) [MTMathAtomFactory atomForLatexSymbolName:command];
    [str appendFormat:@"\\%@ ", command];
    if (originalOp.limits != self.limits) {
        [str appendString:(self.limits ? @"\\limits " : @"\\nolimits ")];
    }
}

@end

#pragma mark - MTInner

@implementation MTInner

- (instancetype)init
{
    // inner atoms have no nucleus
    self = [super initWithType:kMTMathAtomInner value:@""];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomInner) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTInner initWithType:value:] cannot be called. Use [MTInner init] instead."
                                 userInfo:nil];
}

- (void)setLeftBoundary:(MTMathAtom *)leftBoundary
{
    if (leftBoundary && leftBoundary.type != kMTMathAtomBoundary) {
        @throw [[NSException alloc] initWithName:@"Error"
                                          reason:[NSString stringWithFormat:@"Left boundary must be of type kMTMathAtomBoundary"]
                                        userInfo:nil];
    }
    _leftBoundary = leftBoundary;
}

- (void)setRightBoundary:(MTMathAtom *)rightBoundary
{
    if (rightBoundary && rightBoundary.type != kMTMathAtomBoundary) {
        @throw [[NSException alloc] initWithName:@"Error"
                                          reason:[NSString stringWithFormat:@"Left boundary must be of type kMTMathAtomBoundary"]
                                        userInfo:nil];
    }
    _rightBoundary = rightBoundary;
}

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithString:@"\\inner"];
    if (self.leftBoundary) {
        [str appendFormat:@"[%@]", self.leftBoundary.nucleus];
    }
    [str appendFormat:@"{%@}", self.innerList.stringValue];
    if (self.rightBoundary) {
        [str appendFormat:@"[%@]", self.rightBoundary.nucleus];
    }
    
    if (self.superScript) {
        [str appendFormat:@"^{%@}", self.superScript.stringValue];
    }
    if (self.subScript) {
        [str appendFormat:@"_{%@}", self.subScript.stringValue];
    }
    return str;
}

- (id)copyWithZone:(NSZone *)zone
{
    MTInner* inner = [super copyWithZone:zone];
    inner.innerList = [self.innerList copyWithZone:zone];
    inner.leftBoundary = [self.leftBoundary copyWithZone:zone];
    inner.rightBoundary = [self.rightBoundary copyWithZone:zone];
    return inner;
}

- (instancetype)finalized
{
    MTInner *newInner = [super finalized];
    newInner.innerList = newInner.innerList.finalized;
    return newInner;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    if (self.leftBoundary || self.rightBoundary) {
        if (self.leftBoundary) {
            [str appendFormat:@"\\left%@ ", [MTMathListBuilder delimToString:self.leftBoundary]];
        } else {
            [str appendString:@"\\left. "];
        }
        [str appendString:[MTMathListBuilder mathListToString:self.innerList]];
        if (self.rightBoundary) {
            [str appendFormat:@"\\right%@ ", [MTMathListBuilder delimToString:self.rightBoundary]];
        } else {
            [str appendString:@"\\right. "];
        }
        return;
    }
    [str appendFormat:@"{%@}", [MTMathListBuilder mathListToString:self.innerList]];
}

@end

#pragma mark - MTOverline

@implementation MTOverLine

- (instancetype)init
{
    self = [super initWithType:kMTMathAtomOverline value:@""];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomOverline) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTOverline initWithType:value:] cannot be called. Use [MTOverline init] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTOverLine* op = [super copyWithZone:zone];
    op.innerList = [self.innerList copyWithZone:zone];
    return op;
}

- (instancetype)finalized
{
    MTOverLine* newOverline = [super finalized];
    newOverline.innerList = newOverline.innerList.finalized;
    return newOverline;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    [str appendFormat:@"\\overline{%@}", [MTMathListBuilder mathListToString:self.innerList]];
}

@end

#pragma mark - MTUnderline

@implementation MTUnderLine

- (instancetype)init
{
    self = [super initWithType:kMTMathAtomUnderline value:@""];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomUnderline) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTUnderline initWithType:value:] cannot be called. Use [MTUnderline init] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTUnderLine* op = [super copyWithZone:zone];
    op.innerList = [self.innerList copyWithZone:zone];
    return op;
}

- (instancetype)finalized
{
    MTUnderLine* newUnderline = [super finalized];
    newUnderline.innerList = newUnderline.innerList.finalized;
    return newUnderline;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    [str appendFormat:@"\\underline{%@}", [MTMathListBuilder mathListToString:self.innerList]];
}

@end

#pragma mark - MTAccent

@implementation MTAccent

- (instancetype)initWithValue:(NSString *)value
{
    self = [super initWithType:kMTMathAtomAccent value:value];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomAccent) {
        return [self initWithValue:value];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTAccent initWithType:value:] cannot be called. Use [MTAccent initWithValue:] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTAccent* op = [super copyWithZone:zone];
    op.innerList = [self.innerList copyWithZone:zone];
    return op;
}

- (instancetype)finalized
{
    MTAccent* newAccent = [super finalized];
    newAccent.innerList = newAccent.innerList.finalized;
    return newAccent;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    [str appendFormat:@"\\%@{%@}", [MTMathAtomFactory accentName:self], [MTMathListBuilder mathListToString:self.innerList]];
}

@end

#pragma mark - MTLargeDelimiter

@implementation MTLargeDelimiter

- (instancetype)initWithDelimiterNucleus:(NSString *)nucleus
                               mathClass:(MTMathAtomType)mathClass
                                    size:(MTDelimiterSize)size
{
    NSParameterAssert(nucleus);
    NSAssert(mathClass == kMTMathAtomOrdinary || mathClass == kMTMathAtomOpen
             || mathClass == kMTMathAtomClose || mathClass == kMTMathAtomRelation,
             @"Large delimiter math class must be Ordinary, Open, Close, or Relation");
    NSAssert(size >= kMTDelimiterSize1 && size <= kMTDelimiterSize4,
             @"Large delimiter size must be in the range 1…4");
    self = [super initWithType:mathClass value:nucleus];
    if (self) {
        _delimiterSize = size;
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomOrdinary || type == kMTMathAtomOpen
        || type == kMTMathAtomClose || type == kMTMathAtomRelation) {
        return [self initWithDelimiterNucleus:value ?: @""
                                    mathClass:type
                                         size:kMTDelimiterSize1];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTLargeDelimiter initWithType:value:] cannot be called. Use [MTLargeDelimiter initWithDelimiterNucleus:mathClass:size:] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTLargeDelimiter* copy = [[MTLargeDelimiter allocWithZone:zone] initWithDelimiterNucleus:self.nucleus
                                                                                   mathClass:self.type
                                                                                        size:self.delimiterSize];
    copy.subScript = [self.subScript copyWithZone:zone];
    copy.superScript = [self.superScript copyWithZone:zone];
    copy.indexRange = self.indexRange;
    copy.fontStyle = self.fontStyle;
    return copy;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    NSString* prefix = nil;
    switch (self.delimiterSize) {
        case kMTDelimiterSize1:
            prefix = @"big";
            break;
        case kMTDelimiterSize2:
            prefix = @"Big";
            break;
        case kMTDelimiterSize3:
            prefix = @"bigg";
            break;
        case kMTDelimiterSize4:
            prefix = @"Bigg";
            break;
    }
    NSString* suffix = nil;
    switch (self.type) {
        case kMTMathAtomOrdinary:
            suffix = @"";
            break;
        case kMTMathAtomOpen:
            suffix = @"l";
            break;
        case kMTMathAtomClose:
            suffix = @"r";
            break;
        case kMTMathAtomRelation:
            suffix = @"m";
            break;
        default:
            NSAssert(NO, @"Unsupported large delimiter class %lu", (unsigned long)self.type);
            suffix = @"";
            break;
    }
    MTMathAtom* boundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:self.nucleus];
    [str appendFormat:@"\\%@%@%@", prefix, suffix, [MTMathListBuilder delimToString:boundary]];
}

@end

#pragma mark - MTMathSpace

@implementation MTMathSpace

- (instancetype)initWithSpace:(CGFloat)space
{
    self = [super initWithType:kMTMathAtomSpace value:@""];
    if (self) {
        _space = space;
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomSpace) {
        return [self initWithSpace:0];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathSpace initWithType:value:] cannot be called. Use [MTMathSpace initWithSpace:] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTMathSpace* op = [super copyWithZone:zone];
    op->_space = self.space;
    return op;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    NSString* command = [MTMathListBuilder spaceToCommands][@(self.space)];
    if (command) {
        [str appendFormat:@"\\%@ ", command];
    } else {
        [str appendFormat:@"\\mkern%.1fmu", self.space];
    }
}

@end

#pragma mark - MTMathStyle

@implementation MTMathStyle

- (instancetype)initWithStyle:(MTLineStyle)style
{
    self = [super initWithType:kMTMathAtomStyle value:@""];
    if (self) {
        _style = style;
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomStyle) {
        return [self initWithStyle:kMTLineStyleDisplay];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathStyle initWithType:value:] cannot be called. Use [MTMathStyle initWithStyle:] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTMathStyle* op = [super copyWithZone:zone];
    op->_style = self.style;
    return op;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    NSString* command = [MTMathListBuilder styleToCommands][@(self.style)];
    [str appendFormat:@"\\%@ ", command];
}

@end

#pragma mark - MTMathColor

@implementation MTMathColor


- (instancetype)init
{
    self = [super initWithType:kMTMathAtomColor value:@""];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomColor) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathColor initWithType:value:] cannot be called. Use [MTMathColor init] instead."
                                 userInfo:nil];
}

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithString:@"\\color"];
    [str appendFormat:@"{%@}{%@}", self.colorString, self.innerList.stringValue];
    return str;
}

- (id)copyWithZone:(NSZone *)zone
{
    MTMathColor* op = [super copyWithZone:zone];
    op.innerList = [self.innerList copyWithZone:zone];
    op->_colorString = self.colorString;
    return op;
}

- (instancetype)finalized
{
    MTMathColor *newInner = [super finalized];
    newInner.innerList = newInner.innerList.finalized;
    return newInner;
}

@end

#pragma mark - MTMathColorbox

@implementation MTMathColorbox


- (instancetype)init
{
    self = [super initWithType:kMTMathAtomColorbox value:@""];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomColorbox) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathColorbox initWithType:value:] cannot be called. Use [MTMathColorbox init] instead."
                                 userInfo:nil];
}

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithString:@"\\colorbox"];
    [str appendFormat:@"{%@}{%@}", self.colorString, self.innerList.stringValue];
    return str;
}

- (id)copyWithZone:(NSZone *)zone
{
    MTMathColorbox* op = [super copyWithZone:zone];
    op.innerList = [self.innerList copyWithZone:zone];
    op->_colorString = self.colorString;
    return op;
}

- (instancetype)finalized
{
    MTMathColorbox *newInner = [super finalized];
    newInner.innerList = newInner.innerList.finalized;
    return newInner;
}

@end


#pragma mark - MTMathBox

@implementation MTMathBox

- (instancetype)init
{
    self = [super initWithType:kMTMathAtomBox value:@""];
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomBox) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathBox initWithType:value:] cannot be called. Use [MTMathBox init] instead."
                                 userInfo:nil];
}

// Closest LaTeX command for this box variant (cancel / phantom / lap / smash),
// picked from the flag matrix. Shared by stringValue and appendLaTeXToString:.
- (NSString *)latexCommand
{
    if (self.strikeStyle != kMTStrikeNone) {
        switch (self.strikeStyle) {
            case kMTStrikeForward:    return @"\\cancel";
            case kMTStrikeBackward:   return @"\\bcancel";
            case kMTStrikeCross:      return @"\\xcancel";
            case kMTStrikeHorizontal: return @"\\sout";
            case kMTStrikeNone:       // unreachable (guarded above)
            default:
                NSAssert(NO, @"Unknown MTStrikeStyle %lu", (unsigned long)self.strikeStyle);
                return @"\\cancel";
        }
    }
    if (!self.drawChild) {
        // phantom family
        if (self.keepWidth && self.keepHeight && self.keepDepth)      return @"\\phantom";
        else if (self.keepWidth)                                       return @"\\hphantom";
        else                                                          return @"\\vphantom"; // covers \mathstrut -> \vphantom{(}
    } else if (!self.keepWidth) {
        // lap family
        switch (self.hAlign) {
            case kMTBoxHAlignRight:  return @"\\llap";
            case kMTBoxHAlignCenter: return @"\\clap";
            case kMTBoxHAlignLeft:
            default:                 return @"\\rlap";
        }
    } else {
        // smash family
        if (!self.keepHeight && !self.keepDepth)      return @"\\smash";
        else if (self.keepDepth && !self.keepHeight)  return @"\\smash[t]";
        else                                          return @"\\smash[b]";
    }
}

// Lossy by design (LLD §3.4): the inner list uses the simplified stringValue form
// (symbols rendered as their Unicode glyph, not their LaTeX command).
- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@{%@}", self.latexCommand, self.innerList.stringValue ?: @""];
}

// Round-trip serializer: unlike stringValue, serialize the inner list via
// mathListToString: (as every other container atom does) so a symbol atom emits
// e.g. \alpha rather than the raw glyph α.
- (void)appendLaTeXToString:(NSMutableString *)str
{
    [str appendFormat:@"%@{%@}", self.latexCommand,
     [MTMathListBuilder mathListToString:self.innerList]];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTMathBox* op = [super copyWithZone:zone];
    op.innerList = [self.innerList copyWithZone:zone];
    op->_keepWidth = self.keepWidth;
    op->_keepHeight = self.keepHeight;
    op->_keepDepth = self.keepDepth;
    op->_drawChild = self.drawChild;
    op->_hAlign = self.hAlign;
    op->_strikeStyle = self.strikeStyle;
    return op;
}

- (instancetype)finalized
{
    MTMathBox *newBox = [super finalized];
    newBox.innerList = newBox.innerList.finalized;
    return newBox;
}

@end

#pragma mark - MTMathGroup

@implementation MTMathGroup

- (instancetype)init
{
    self = [super initWithType:kMTMathAtomOrdGroup value:@""];
    if (self) {
        _innerList = [MTMathList new];
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomOrdGroup) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathGroup initWithType:value:] cannot be called. Use [MTMathGroup init] instead."
                                 userInfo:nil];
}

// Standalone string (description / error messages): braces + this atom's scripts.
- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithFormat:@"{%@}",
                            [MTMathListBuilder mathListToString:self.innerList]];
    if (self.superScript) {
        [str appendFormat:@"^{%@}", self.superScript.stringValue];
    }
    if (self.subScript) {
        [str appendFormat:@"_{%@}", self.subScript.stringValue];
    }
    return str;
}

// List serializer: emit ONLY {inner}. mathListToString: appends this atom's own
// ^{…}/_{…} afterwards, so emitting scripts here would double them.
- (void)appendLaTeXToString:(NSMutableString *)str
{
    [str appendFormat:@"{%@}", [MTMathListBuilder mathListToString:self.innerList]];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTMathGroup* group = [super copyWithZone:zone];
    group.innerList = [self.innerList copyWithZone:zone];
    return group;
}

- (instancetype)finalized
{
    MTMathGroup* newGroup = [super finalized];
    newGroup.innerList = newGroup.innerList.finalized;
    return newGroup;
}

@end

#pragma mark - MTMathTable

@interface MTMathTable ()

@property (nonatomic, nonnull) NSMutableArray<NSNumber*>* alignments;
@property (nonatomic, nonnull) NSMutableArray<NSMutableArray<MTMathList*>*>* cells;

@end

@implementation MTMathTable

- (MTMathList *)serializedCellAtRow:(NSUInteger)row column:(NSUInteger)column
{
    MTMathList* cell = self.cells[row][column];
    if ([self.environment isEqualToString:@"eqalign"] || [self.environment isEqualToString:@"aligned"] || [self.environment isEqualToString:@"split"]) {
        if (column == 1 && cell.atoms.count >= 1 && cell.atoms[0].type == kMTMathAtomOrdinary && cell.atoms[0].nucleus.length == 0) {
            NSArray* atoms = [cell.atoms subarrayWithRange:NSMakeRange(1, cell.atoms.count - 1)];
            return [MTMathList mathListWithAtomsArray:atoms];
        }
    }
    if ([self.environment isEqualToString:@"alignedat"]) {
        if (column % 2 == 1 && cell.atoms.count >= 1 && cell.atoms[0].type == kMTMathAtomOrdinary && cell.atoms[0].nucleus.length == 0) {
            NSArray* atoms = [cell.atoms subarrayWithRange:NSMakeRange(1, cell.atoms.count - 1)];
            return [MTMathList mathListWithAtomsArray:atoms];
        }
    }
    return cell;
}

- (instancetype)initWithEnvironment:(NSString *)env
{
    self = [super initWithType:kMTMathAtomTable value:@""];
    if (self) {
        self.alignments = [NSMutableArray array];
        self.cells = [NSMutableArray array];
        self.interRowAdditionalSpacing = 0;
        self.interColumnSpacing = 0;
        self.cellStyle = kMTLineStyleInherit;
        self.verticalLines = [NSArray array];
        self.horizontalLines = [NSArray array];
        _environment = env;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithEnvironment:nil];
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomTable) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathTable initWithType:value:] cannot be called. Use [MTMathTable init] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    MTMathTable* op = [super copyWithZone:zone];
    op.interRowAdditionalSpacing = self.interRowAdditionalSpacing;
    op.interColumnSpacing = self.interColumnSpacing;
    op.cellStyle = self.cellStyle;
    op->_environment = self.environment;
    op.alignments = [NSMutableArray arrayWithArray:self.alignments];
    // The copy setters take an immutable snapshot, so a plain assignment suffices.
    op.verticalLines = self.verticalLines;
    op.horizontalLines = self.horizontalLines;
    // Perform a deep copy of the cells.
    NSMutableArray* cellCopy = [NSMutableArray arrayWithCapacity:self.cells.count];
    for (NSMutableArray* row in self.cells) {
        [cellCopy addObject:[[NSMutableArray alloc] initWithArray:row copyItems:YES]];
    }
    op.cells = cellCopy;
    return op;
}

- (instancetype)finalized
{
    MTMathTable* table = [super finalized];
    for (NSMutableArray<MTMathList*>* row in table.cells) {
        for (int i = 0; i < row.count; i++) {
            row[i] = row[i].finalized;
        }
    }
    return table;
}

- (void)setCell:(MTMathList *)list forRow:(NSInteger)row column:(NSInteger)column
{
    NSParameterAssert(list);
    
    if (self.cells.count <= row) {
        // Add more rows
        for (NSInteger i = self.cells.count;  i <= row; i++) {
            _cells[i] = [NSMutableArray array];
        }
    }
    NSMutableArray<MTMathList*> *rowArray = _cells[row];
    if (rowArray.count <= column) {
        // Add more columns
        for (NSInteger i = rowArray.count;  i < column; i++) {
            rowArray[i] = [[MTMathList alloc] init];
        }
    }
    rowArray[column] = list;
}

- (void)setAlignment:(MTColumnAlignment)alignment forColumn:(NSInteger)column
{
    if (self.alignments.count < column) {
        // Add more columns
        for (NSInteger i = self.alignments.count; i < column; i++) {
            _alignments[i] = @(kMTColumnAlignmentCenter);
        }
    }
    _alignments[column] = @(alignment);
}

- (MTColumnAlignment)getAlignmentForColumn:(NSInteger)column
{
    if (self.alignments.count <= column) {
        return kMTColumnAlignmentCenter;
    } else {
        return self.alignments[column].integerValue;
    }
}

- (NSUInteger) numColumns
{
    NSUInteger numColumns = 0;
    for (NSArray* row in self.cells) {
        numColumns = MAX(numColumns, row.count);
    }
    return numColumns;
}

- (NSUInteger) numRows
{
    return self.cells.count;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    BOOL isArray = [self.environment isEqualToString:@"array"];
    if (self.environment) {
        [str appendFormat:@"\\begin{%@}", self.environment];
        if ([self.environment isEqualToString:@"alignedat"]) {
            [str appendFormat:@"{%ld}", (long) (self.numColumns / 2)];
        } else if (isArray) {
            [str appendString:@"{"];
            NSUInteger cols = self.numColumns;
            for (NSUInteger i = 0; i <= cols; i++) {
                NSInteger v = (i < self.verticalLines.count) ? self.verticalLines[i].integerValue : 0;
                for (NSInteger k = 0; k < v; k++) { [str appendString:@"|"]; }
                if (i < cols) {
                    switch ([self getAlignmentForColumn:i]) {
                        case kMTColumnAlignmentLeft:   [str appendString:@"l"]; break;
                        case kMTColumnAlignmentCenter: [str appendString:@"c"]; break;
                        case kMTColumnAlignmentRight:  [str appendString:@"r"]; break;
                    }
                }
            }
            [str appendString:@"}"];
        }
    }
    NSUInteger numRows = self.numRows;
    NSInteger bottomHLines = (isArray && numRows < self.horizontalLines.count)
        ? self.horizontalLines[numRows].integerValue : 0;
    for (NSUInteger i = 0; i < numRows; i++) {
        if (isArray && i < self.horizontalLines.count) {
            for (NSInteger k = 0; k < self.horizontalLines[i].integerValue; k++) {
                [str appendString:@"\\hline "];
            }
        }
        NSArray<MTMathList*>* row = self.cells[i];
        for (NSUInteger j = 0; j < row.count; j++) {
            [str appendString:[MTMathListBuilder mathListToString:[self serializedCellAtRow:i column:j]]];
            if (j < row.count - 1) {
                [str appendString:@"&"];
            }
        }
        BOOL lastRow = (i == numRows - 1);
        if (!lastRow) {
            [str appendString:@"\\\\ "];
        } else if (bottomHLines > 0) {
            // A bottom \hline needs a row terminator before it.
            [str appendString:@"\\\\ "];
        }
    }
    if (isArray) {
        for (NSInteger k = 0; k < bottomHLines; k++) {
            [str appendString:@"\\hline "];
        }
    }
    if (self.environment) {
        [str appendFormat:@"\\end{%@}", self.environment];
    }
}

@end

#pragma mark - MTMathStackConstruction

@implementation MTMathStackConstruction

+ (instancetype)extensibleWithGlyph:(NSString*)glyph
{
    NSParameterAssert(glyph);
    MTMathStackConstruction* c = [[self alloc] init];
    c->_kind = kMTMathStackConstructionExtensible;
    c->_glyph = [glyph copy];
    return c;
}

+ (instancetype)mathListWithList:(MTMathList*)list
{
    NSParameterAssert(list);
    MTMathStackConstruction* c = [[self alloc] init];
    c->_kind = kMTMathStackConstructionMathList;
    c->_list = [list copy];
    return c;
}

+ (instancetype)ruleWithThickness:(CGFloat)thickness
{
    MTMathStackConstruction* c = [[self alloc] init];
    c->_kind = kMTMathStackConstructionRule;
    c->_ruleThickness = thickness;
    return c;
}

- (id)copyWithZone:(NSZone*)zone
{
    MTMathStackConstruction* copy = [[MTMathStackConstruction allocWithZone:zone] init];
    copy->_kind = _kind;
    copy->_glyph = [_glyph copyWithZone:zone];
    copy->_list = [_list copyWithZone:zone];
    copy->_ruleThickness = _ruleThickness;
    return copy;
}

@end

#pragma mark - MTMathStack

@implementation MTMathStack

- (instancetype)init
{
    self = [super initWithType:kMTMathAtomStack value:@""];
    if (self) {
        _displayClass = kMTMathAtomOrdinary;
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomStack) {
        return [self init];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMathStack initWithType:value:] cannot be called. Use [MTMathStack init] instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone*)zone
{
    MTMathStack* copy = [super copyWithZone:zone];
    copy.innerList = [self.innerList copyWithZone:zone];
    copy.over = [self.over copyWithZone:zone];
    copy.under = [self.under copyWithZone:zone];
    copy->_displayClass = self.displayClass;
    return copy;
}

- (instancetype)finalized
{
    MTMathStack* newStack = [super finalized];
    newStack.innerList = newStack.innerList.finalized;
    if (newStack.over && newStack.over.kind == kMTMathStackConstructionMathList) {
        newStack.over = [MTMathStackConstruction mathListWithList:newStack.over.list.finalized];
    }
    if (newStack.under && newStack.under.kind == kMTMathStackConstructionMathList) {
        newStack.under = [MTMathStackConstruction mathListWithList:newStack.under.list.finalized];
    }
    return newStack;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    BOOL overIsMathList  = self.over  && self.over.kind  == kMTMathStackConstructionMathList;
    BOOL underIsMathList = self.under && self.under.kind == kMTMathStackConstructionMathList;
    NSString* inner = [MTMathListBuilder mathListToString:self.innerList];
    if (overIsMathList && underIsMathList) {
        // Programmatic both-rows stack: no single command exists, so emit nested
        // \underset{under}{\overset{over}{base}}. Reparses to two nested stacks
        // (equivalent, not byte-identical — see LLD §6.5).
        [str appendFormat:@"\\underset{%@}{\\overset{%@}{%@}}",
             [MTMathListBuilder mathListToString:self.under.list],
             [MTMathListBuilder mathListToString:self.over.list],
             inner];
        return;
    }
    NSString* cmd = [MTMathAtomFactory stackCommandForStack:self];
    if (cmd && (overIsMathList || underIsMathList)) {
        MTMathList* row = overIsMathList ? self.over.list : self.under.list;
        [str appendFormat:@"\\%@{%@}{%@}", cmd, [MTMathListBuilder mathListToString:row], inner];
    } else if (cmd) {
        // Extensible (single-arg) commands, unchanged.
        [str appendFormat:@"\\%@{%@}", cmd, inner];
    } else {
        // Programmatically-built stack with non-canonical constructions — emit only the inner list.
        [str appendString:inner];
    }
}

@end

#pragma mark - MTTextAtom

@implementation MTTextAtom

- (instancetype)initWithText:(NSString *)text style:(MTTextStyle)style
{
    NSParameterAssert(text);
    NSParameterAssert(style <= kMTTextStyleTypewriter);
    // The nucleus is set to the raw text so existing consumers reading
    // nucleus (e.g. description, stringValue) work reasonably without
    // changes. fontStyle is left at kMTFontStyleDefault so
    // mathListToString: does not wrap the atom in a \mathrm{...} group.
    self = [super initWithType:kMTMathAtomText value:text];
    if (self) {
        _text = [text copy];
        _textStyle = style;
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomText) {
        return [self initWithText:value ?: @"" style:kMTTextStyleRoman];
    }
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTTextAtom initWithType:value:] cannot be called. Use [MTTextAtom initWithText:style:] instead."
                                 userInfo:nil];
}

- (void)setText:(NSString *)text
{
    NSParameterAssert(text);
    NSString* copiedText = [text copy] ?: @"";
    _text = copiedText;
    [super setNucleus:copiedText];
}

- (void)setNucleus:(NSString *)nucleus
{
    NSParameterAssert(nucleus);
    NSString* copiedNucleus = [nucleus copy] ?: @"";
    [super setNucleus:copiedNucleus];
    _text = copiedNucleus;
}

- (id)copyWithZone:(NSZone *)zone
{
    // [super copyWithZone:] uses [[[self class] alloc] initWithType:self.type value:self.nucleus]
    // which dispatches to our overridden initWithType:value: (defaulting to Roman style),
    // and copies fontStyle, indexRange, sub/superScript. We then restore the textStyle
    // and ensure text is set from the source.
    MTTextAtom* copy = [super copyWithZone:zone];
    copy->_text = [self.text copyWithZone:zone];
    copy->_textStyle = self.textStyle;
    return copy;
}

- (instancetype)finalized
{
    MTTextAtom* fin = [super finalized];
    fin->_text = [self.text copy];
    fin->_textStyle = self.textStyle;
    return fin;
}

+ (NSCharacterSet *)latexEscapableCharacterSet
{
    static NSCharacterSet *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSCharacterSet characterSetWithCharactersInString:@"\\{}_^%&#$"];
    });
    return set;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    NSString* command = [MTMathAtomFactory commandNameForTextStyle:self.textStyle];
    [str appendFormat:@"\\%@{", command];

    NSCharacterSet* escapable = [MTTextAtom latexEscapableCharacterSet];
    for (NSUInteger i = 0; i < self.text.length; i++) {
        unichar c = [self.text characterAtIndex:i];
        if ([escapable characterIsMember:c]) {
            [str appendFormat:@"\\%C", c];
        } else {
            [str appendFormat:@"%C", c];
        }
    }
    [str appendString:@"}"];
}

@end

#pragma mark - MTMathList

@implementation MTMathList {
    NSMutableArray* _atoms;
}

+ (instancetype)mathListWithAtoms:(MTMathAtom *)firstAtom, ...
{
    MTMathList* list = [[MTMathList alloc] init];
    va_list args;
    va_start(args, firstAtom);
    for (MTMathAtom* atom = firstAtom; atom != nil; atom = va_arg(args, MTMathAtom*))
    {
        [list addAtom:atom];
    }
    va_end(args);
    return list;
}

+ (instancetype)mathListWithAtomsArray:(NSArray<MTMathAtom *> *)atoms
{
    MTMathList* list = [[MTMathList alloc] init];
    [list->_atoms addObjectsFromArray:atoms];
    return list;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _atoms = [NSMutableArray array];
    }
    return self;
}

- (bool) isAtomAllowed:(MTMathAtom*) atom
{
    return atom.type != kMTMathAtomBoundary;
}

- (void)addAtom:(MTMathAtom *)atom
{
    NSParameterAssert(atom);
    if (![self isAtomAllowed:atom]) {
        @throw [[NSException alloc] initWithName:@"Error"
                                          reason:[NSString stringWithFormat:@"Cannot add atom of type %@ in a mathlist", typeToText(atom.type)]
                                        userInfo:nil];
    }
    [_atoms addObject:atom];
}

- (void)insertAtom:(MTMathAtom *)atom atIndex:(NSUInteger) index
{
    if (![self isAtomAllowed:atom]) {
        @throw [[NSException alloc] initWithName:@"Error"
                                          reason:[NSString stringWithFormat:@"Cannot add atom of type %@ in a mathlist", typeToText(atom.type)]
                                        userInfo:nil];
    }
    [_atoms insertObject:atom atIndex:index];
}

- (void)append:(MTMathList *)list
{
    [_atoms addObjectsFromArray:list.atoms];
}

- (void)removeLastAtom
{
    if (_atoms.count > 0) {
        [_atoms removeLastObject];
    }
}

- (void) removeAtomAtIndex:(NSUInteger)index
{
    [_atoms removeObjectAtIndex:index];
}

- (void) removeAtomsInRange:(NSRange) range
{
    [_atoms removeObjectsInRange:range];
}

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString string];
    for (MTMathAtom* atom in self.atoms) {
        [str appendString:atom.stringValue];
    }
    return str;
}

- (NSString *)description
{
    return self.atoms.description;
}

/** Reclassifies the list: demotes Bin to Unary at the boundaries where TeX does,
 fuses adjacent numbers, and assigns index ranges. Macros are expanded first —
 finalization is irreversible and context-dependent (a Bin demoted to Unary at one
 boundary cannot be restored), so the reclassifying pass must see the flat raw
 stream a macro stands for, not the macro atom. */
- (MTMathList *)finalized
{
    MTMathList* expanded = [self expandMacros];

    MTMathList* finalized = [MTMathList new];
    NSRange zeroRange = NSMakeRange(0, 0);

    MTMathAtom* prevNode = nil;
    for (MTMathAtom* atom in expanded.atoms) {
        // -expandMacros dispatches on class, so a real MTMacroAtom is already gone.
        // What this catches is a plain MTMathAtom whose settable public -type was
        // forced to kMTMathAtomMacro: it walks through expansion untouched and would
        // otherwise reach the typesetter, which drops it.
        NSAssert(atom.type != kMTMathAtomMacro,
                 @"Atom %@ claims to be a macro but is not an MTMacroAtom; -type must not be set to kMTMathAtomMacro.",
                 atom.stringValue);
        NSAssert(![atom isKindOfClass:[MTMacroParameterAtom class]],
                 @"Macro parameter placeholder %@ escaped a template; expansion must consume it.",
                 atom.nucleus);
        MTMathAtom* newNode = [atom finalized];
        // Each character is given a separate index.
        if (NSEqualRanges(zeroRange, atom.indexRange)) {
            NSUInteger index = (prevNode == nil) ? 0 : prevNode.indexRange.location + prevNode.indexRange.length;
            newNode.indexRange = NSMakeRange(index, 1);
        }

        switch (newNode.type) {
            case kMTMathAtomBinaryOperator: {
                if (isNotBinaryOperator(prevNode)) {
                    newNode.type = kMTMathAtomUnaryOperator;
                }
                break;
            }
            case kMTMathAtomRelation:
            case kMTMathAtomPunctuation:
            case kMTMathAtomClose:
                if (prevNode && prevNode.type == kMTMathAtomBinaryOperator) {
                    prevNode.type = kMTMathAtomUnaryOperator;
                }
                break;
                
            case kMTMathAtomNumber:
                // combine numbers together
                if (prevNode && prevNode.type == kMTMathAtomNumber && !prevNode.subScript && !prevNode.superScript) {
                    [prevNode fuse:newNode];
                    // skip the current node, we are done here.
                    continue;
                }
                break;
                
            default:
                break;
        }
        [finalized addAtom:newNode];
        prevNode = newNode;
    }
    if (prevNode && prevNode.type == kMTMathAtomBinaryOperator) {
        // it isn't a binary since there is noting after it. Make it a unary
        prevNode.type = kMTMathAtomUnaryOperator;
    }
    return finalized;
}

- (MTMathList *)expandMacros
{
    return [self expandMacrosAtDepth:0];
}

- (MTMathList *)expandMacrosAtDepth:(NSUInteger)depth
{
    MTMathList* expanded = [MTMathList new];
    for (MTMathAtom* atom in self.atoms) {
        // isKindOfClass: rather than atom.type: `type` is a settable public property,
        // so a plain MTMathAtom can carry kMTMathAtomMacro without responding to
        // -expansion. Same idiom as the MTMacroParameterAtom check above.
        if (![atom isKindOfClass:[MTMacroAtom class]]) {
            // Carried through by reference and WITHOUT descending into sub-lists
            // (numerator/denominator/radicand/innerList/cells/scripts). Every
            // container's -finalized calls the public -finalized on its children,
            // which expands those lists in turn — so this code needs to understand
            // zero container types. Sharing is safe because -finalized copies every
            // atom it keeps, via [atom finalized].
            [expanded addAtom:atom];
            continue;
        }
        [expanded append:[(MTMacroAtom*)atom expansionAtDepth:depth]];
    }
    return expanded;
}

#pragma mark NSCopying

// Makes a deep copy of the list
- (id)copyWithZone:(NSZone *)zone
{
    MTMathList* list = [[[self class] allocWithZone:zone] init];
    list->_atoms = [[NSMutableArray alloc] initWithArray:self.atoms copyItems:YES];
    return list;
}

@end

#pragma mark - MTMacroAtom

@implementation MTMacroAtom

- (instancetype)initWithCommand:(NSString*)command
                      arguments:(NSArray<MTMathList*>*)arguments
             templateExpression:(MTMathList*)templateExpression
{
    NSParameterAssert(command);
    NSParameterAssert(arguments);
    NSParameterAssert(templateExpression);
    // -expansion substitutes #N only at the top level of the template, so a
    // placeholder buried in a sub-list (\frac{#1}{2}, {#1}, x^{#1}) would survive
    // into the finalized list and render as a literal "#1". Catch it here, where the
    // mistake was made, rather than letting it surface one recursion level down.
    //
    // An assert, not an exception: templates are authored in this library, never by
    // the person writing the LaTeX, so a nested placeholder is a programming error to
    // be caught in testing. If assertions are compiled out, construction proceeds and
    // the stray placeholder renders as a visible literal "#1" — wrong, but never
    // silently dropped.
    for (MTMathAtom* templateAtom in templateExpression.atoms) {
        if ([templateAtom isKindOfClass:[MTMacroParameterAtom class]]) {
            continue;
        }
        NSAssert(!MTContainsMacroParameter(templateAtom),
                 @"Template for \\%@ nests a #N placeholder inside %@; macro templates must keep their argument references at the top level.",
                 command, NSStringFromClass([templateAtom class]));
    }
    self = [super initWithType:kMTMathAtomMacro value:@""];
    if (self) {
        _command = [command copy];
        _arguments = MTDeepCopyMathListArray(arguments);
        _templateExpression = [templateExpression copy];
    }
    return self;
}

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString*)value
{
    // NS_UNAVAILABLE in the header already blocks statically typed callers; this
    // catches the dynamic ones. Unlike MTInner/MTMathColorbox there is no valid
    // zero-argument construction to fall back to — command, arguments and template
    // are all required — so it throws rather than redirecting to a bare -init.
    @throw [NSException exceptionWithName:@"InvalidMethod"
                                   reason:@"[MTMacroAtom initWithType:value:] cannot be called. Use -initWithCommand:arguments:templateExpression: instead."
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    // Cannot route through [super copyWithZone:], which would call the throwing
    // -initWithType:value:. The designated initializer already deep-copies both
    // arguments and template, so only the MTMathAtom fields need carrying over.
    MTMacroAtom* copy = [[[self class] allocWithZone:zone] initWithCommand:self.command
                                                                 arguments:self.arguments
                                                        templateExpression:self.templateExpression];
    copy.subScript = [self.subScript copyWithZone:zone];
    copy.superScript = [self.superScript copyWithZone:zone];
    copy.indexRange = self.indexRange;
    copy.fontStyle = self.fontStyle;
    return copy;
}

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithFormat:@"\\%@", self.command];
    for (MTMathList* arg in self.arguments) {
        [str appendFormat:@"{%@}", arg.stringValue];
    }
    if (self.superScript) {
        [str appendFormat:@"^{%@}", self.superScript.stringValue];
    }
    if (self.subScript) {
        [str appendFormat:@"_{%@}", self.subScript.stringValue];
    }
    return str;
}

- (void)appendLaTeXToString:(NSMutableString *)str
{
    // Command-faithful, argument-canonical: the invocation round-trips as \pmod{…},
    // and the argument is re-serialized by the usual serializer rather than
    // preserved character-for-character. +mathListToString: appends the ^{…}/_{…}
    // tail for us.
    [str appendFormat:@"\\%@", self.command];
    if (self.arguments.count == 0) {
        // Nothing would terminate the command name otherwise, so a zero-argument
        // \noargs followed by x would re-parse as the single command \noargsx.
        [str appendString:@" "];
    }
    for (MTMathList* arg in self.arguments) {
        [str appendFormat:@"{%@}", [MTMathListBuilder mathListToString:arg]];
    }
}

- (MTMathList *)expansion
{
    return [self expansionAtDepth:0];
}

- (MTMathList *)expansionAtDepth:(NSUInteger)depth
{
    if (depth >= kMTMaxMacroExpansionDepth) {
        // Note this does NOT catch a cyclic atom graph ([macro.arguments[0]
        // addAtom:macro]). That overflows in -copyWithZone: before expansion runs,
        // exactly as [group.innerList addAtom:group] does for MTMathGroup — every
        // container here assumes a tree, which is a broader concern than macros.
        @throw [NSException exceptionWithName:@"RunawayMacroExpansion"
                                       reason:[NSString stringWithFormat:@"Expansion of \\%@ exceeded the maximum depth of %lu; check for a macro nested inside its own argument.", self.command, (unsigned long)kMTMaxMacroExpansionDepth]
                                     userInfo:nil];
    }
    MTMathList* out = [MTMathList new];
    for (MTMathAtom* templateAtom in self.templateExpression.atoms) {
        if (![templateAtom isKindOfClass:[MTMacroParameterAtom class]]) {
            // Deep copies throughout, so the stored template and arguments stay
            // pristine for serialization, for post-parse mutation, and for repeated
            // -finalized calls.
            [out addAtom:[templateAtom copy]];
            continue;
        }
        NSUInteger index = [(MTMacroParameterAtom*)templateAtom argumentIndex];
        if (index < 1 || index > self.arguments.count) {
            // Template and invocation disagree on arity — a bug in the built-in macro
            // table, not something the LaTeX author can cause, so it asserts. With
            // assertions compiled out the placeholder is carried through instead of
            // dropped, so the mismatch renders as a visible literal "#2" rather than
            // making the argument silently vanish.
            NSAssert(NO, @"Macro \\%@ template references #%lu but %lu argument(s) were parsed.",
                     self.command, (unsigned long)index, (unsigned long)self.arguments.count);
            [out addAtom:[templateAtom copy]];
            continue;
        }
        [out append:[self.arguments[index - 1] copy]];
    }
    // The template, or an argument, may itself contain a macro. Re-scan so the
    // returned list is macro-free at its top level — and so script transfer below
    // targets a real atom rather than an unexpanded MTMacroAtom.
    MTMathList* flat = [out expandMacrosAtDepth:depth + 1];
    [self transferScriptsToExpansion:flat];
    return flat;
}

- (void)transferScriptsToExpansion:(MTMathList *)expansion
{
    if (!self.superScript && !self.subScript) {
        return;
    }
    MTMathAtom* target = nil;
    for (MTMathAtom* candidate in expansion.atoms.reverseObjectEnumerator) {
        // -scriptsAllowed is type < kMTMathAtomBoundary, which already excludes
        // Space (201), Style (202) and every other non-noad (MTMathList.m:222-225).
        if (candidate.scriptsAllowed) {
            target = candidate;
            break;
        }
    }
    // Slots are evaluated as a unit: if there is no target, or either slot we need
    // is taken, BOTH scripts go on a fresh empty Ordinary so a ^/_ pair is never
    // split. This is what the builder already does for x^2^3 and for a leading ^2
    // (MTMathListBuilder.m:211-216, 224-228), so \mod{n^2}^3 behaves like
    // \mod{n^2}{}^3 — iosMath's long-standing divergence from TeX, not a new one.
    BOOL collides = (target == nil)
        || (self.superScript && target.superScript)
        || (self.subScript && target.subScript);
    if (collides) {
        target = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
        [expansion addAtom:target];
    }
    if (self.superScript) {
        target.superScript = [self.superScript copy];
    }
    if (self.subScript) {
        target.subScript = [self.subScript copy];
    }
}

@end

#pragma mark - MTMacroParameterAtom

@implementation MTMacroParameterAtom

- (instancetype)initWithArgumentIndex:(NSUInteger)argumentIndex
{
    NSParameterAssert(argumentIndex >= 1 && argumentIndex <= 9);
    // Ordinary + a visible "#N" nucleus: if a placeholder ever did leak into a
    // rendered list (it must not — -finalized asserts), it shows up as literal "#1"
    // rather than crashing on an unhandled enum value.
    self = [super initWithType:kMTMathAtomOrdinary
                         value:[NSString stringWithFormat:@"#%lu", (unsigned long)argumentIndex]];
    if (self) {
        _argumentIndex = argumentIndex;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    // MTMathAtom's -copyWithZone: allocates [self class] and calls
    // -initWithType:value:, which this class does not override — so the copy is a
    // MTMacroParameterAtom with the right nucleus but a zero index. Restore it.
    MTMacroParameterAtom* copy = [super copyWithZone:zone];
    copy->_argumentIndex = self.argumentIndex;
    return copy;
}

@end
