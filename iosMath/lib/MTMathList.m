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
        case kMTMathAtomBoundary:
            return @"Boundary";
    }
}

#pragma mark - MTMathAtom

@interface MTMathAtom ()

@property (nonatomic) NSRange indexRange;
@property (nonatomic, readwrite) MTMathAtomType type;
@property (nonatomic, readwrite) NSString* nucleus;

- (instancetype)initWithType:(MTMathAtomType)type value:(NSString *)value NS_DESIGNATED_INITIALIZER;

@end

@implementation MTMathAtom {
    NSMutableArray* _fusedAtoms;
}

+ (instancetype)atomWithType:(MTMathAtomType)type value:(NSString *)value
{
    if (type == kMTMathAtomFraction) {
        return [[MTFraction alloc] init];
    } else if (type == kMTMathAtomPlaceholder) {
        // A placeholder is created with a white square.
        return [[[self class] alloc] initWithType:kMTMathAtomPlaceholder value:@"\u25A1"];
    } else if (type == kMTMathAtomRadical) {
        return [[MTRadical alloc] init];
    } else if (type == kMTMathAtomLargeOperator) {
        // Default setting of limits is true
        return [[MTLargeOperator alloc] initWithValue:value limits:YES];
    } else if (type == kMTMathAtomInner) {
        return [[MTInner alloc] init];
    }
    return [[[self class] alloc] initWithType:type value:value];
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

@end

#pragma mark - MTFraction

@implementation MTFraction

- (instancetype)init
{
    // fractions have no nucleus
    self = [super initWithType:kMTMathAtomFraction value:@""];
    return self;
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

- (NSString *)stringValue
{
    NSMutableString* str = [NSMutableString stringWithFormat:@"\\frac{%@}{%@}", self.numerator.stringValue, self.denominator.stringValue];
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
    return frac;
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

@end

#pragma mark - MTMathList

@implementation MTMathList {
    NSMutableArray* _atoms;
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

- (MTMathList *)finalized
{
    MTMathList* finalized = [MTMathList new];
    NSRange zeroRange = NSMakeRange(0, 0);
    
    MTMathAtom* prevNode = nil;
    for (MTMathAtom* atom in self.atoms) {
        MTMathAtom* newNode = [atom copy];
        // Each character is given a separate index.
        if (NSEqualRanges(zeroRange, atom.indexRange)) {
            NSUInteger index = (prevNode == nil) ? 0 : prevNode.indexRange.location + prevNode.indexRange.length;
            newNode.indexRange = NSMakeRange(index, 1);
        }
        if (newNode.superScript) {
            newNode.superScript = newNode.superScript.finalized;
        }
        if (newNode.subScript) {
            newNode.subScript = newNode.subScript.finalized;
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
                
            case kMTMathAtomFraction: {
                MTFraction* frac = (MTFraction*) atom;
                MTFraction* newFrac = (MTFraction*) newNode;
                newFrac.numerator = frac.numerator.finalized;
                newFrac.denominator = frac.denominator.finalized;
                break;
            }

            case kMTMathAtomRadical: {
                MTRadical* rad = (MTRadical*) atom;
                MTRadical* newRad = (MTRadical*) newNode;
                newRad.radicand = rad.radicand.finalized;
                newRad.degree = rad.degree.finalized;
                break;
            }
                
            case kMTMathAtomInner: {
                MTInner *inner = (MTInner*) atom;
                MTInner *newInner = (MTInner*) newNode;
                newInner.innerList = inner.innerList.finalized;
                break;
            }
                
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

#pragma mark NSCopying

// Makes a deep copy of the list
- (id)copyWithZone:(NSZone *)zone
{
    MTMathList* list = [[[self class] allocWithZone:zone] init];
    list->_atoms = [[NSMutableArray alloc] initWithArray:self.atoms copyItems:YES];
    return list;
}

@end
