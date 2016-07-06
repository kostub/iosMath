//
//  MathAtomFactory.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathAtomFactory.h"
#import "MTMathListBuilder.h"

NSString *const MTSymbolMultiplication = @"\u00D7";
NSString *const MTSymbolDivision = @"\u00F7";
NSString *const MTSymbolFractionSlash = @"\u2044";
NSString *const MTSymbolWhiteSquare = @"\u25A1";
NSString *const MTSymbolBlackSquare = @"\u25A0";
NSString *const MTSymbolLessEqual = @"\u2264";
NSString *const MTSymbolGreaterEqual = @"\u2265";
NSString *const MTSymbolNotEqual = @"\u2260";
NSString *const MTSymbolSquareRoot = @"\u221A"; // \sqrt
NSString *const MTSymbolCubeRoot = @"\u221B";
NSString *const MTSymbolInfinity = @"\u221E"; // \infty
NSString *const MTSymbolAngle = @"\u2220"; // \angle
NSString *const MTSymbolDegree = @"\u00B0"; // \circ

@implementation MTMathAtomFactory

+ (MTMathAtom *)times
{
    return [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:MTSymbolMultiplication];
}

+ (MTMathAtom *)divide
{
    return [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:MTSymbolDivision];
}

+ (MTMathAtom *)placeholder
{
    return [MTMathAtom atomWithType:kMTMathAtomPlaceholder value:MTSymbolWhiteSquare];
}

+ (MTMathAtom *)openParens
{
    return [MTMathAtom atomWithType:kMTMathAtomOpen value:@"("];
}

+ (MTMathAtom *)closeParens
{
    return [MTMathAtom atomWithType:kMTMathAtomClose value:@")"];
}

+ (MTFraction *)placeholderFraction
{
    MTFraction *frac = [MTFraction new];
    frac.numerator = [MTMathList new];
    [frac.numerator addAtom:[self placeholder]];
    frac.denominator = [MTMathList new];
    [frac.denominator addAtom:[self placeholder]];
    return frac;
}

+ (MTRadical*) placeholderRadical
{
    MTRadical* rad = [MTRadical new];
    rad.degree = [MTMathList new];
    rad.radicand = [MTMathList new];
    [rad.degree addAtom:self.placeholder];
    [rad.radicand addAtom:self.placeholder];
    return rad;
}

+ (MTMathAtom *)placeholderSquareRoot
{
    MTRadical *rad = [MTRadical new];
    rad.radicand = [MTMathList new];
    [rad.radicand addAtom:[self placeholder]];
    return rad;
}

+ (MTMathAtom *)operatorWithName:(NSString *)name
{
    return [[MTLargeOperator alloc] initWithValue:name limits:NO];
}

+ (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits
{
    return [[MTLargeOperator alloc] initWithValue:name limits:limits];
}

+ (MTMathAtom *)atomForCharacter:(unichar)ch
{
    NSString *chStr = [NSString stringWithCharacters:&ch length:1];
    if (ch < 0x21 || ch > 0x7E) {
        // skip non ascii characters and spaces
        return nil;
    } else if (ch == '$' || ch == '%' || ch == '#' || ch == '&' || ch == '~' || ch == '\'') {
        // These are latex control characters that have special meanings. We don't support them.
        return nil;
    } else if (ch == '^' || ch == '_' || ch == '{' || ch == '}' || ch == '\\') {
        // more special characters for Latex.
        return nil;
    } else if (ch == '(' || ch == '[') {
        return [MTMathAtom atomWithType:kMTMathAtomOpen value:chStr];
    } else if (ch == ')' || ch == ']' || ch == '!' || ch == '?') {
        return [MTMathAtom atomWithType:kMTMathAtomClose value:chStr];
    } else if (ch == ',' || ch == ';') {
        return [MTMathAtom atomWithType:kMTMathAtomPunctuation value:chStr];
    } else if (ch == '=' || ch == '>' || ch == '<') {
        return [MTMathAtom atomWithType:kMTMathAtomRelation value:chStr];
    } else if (ch == ':') {
        // Math colon is ratio. Regular colon is \colon
        return [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2236"];
    } else if (ch == '-') {
        // Use the math minus sign
        return [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2212"];
    } else if (ch == '+' || ch == '*') {
        return [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:chStr];
    } else if (ch == '.' || (ch >= '0' && ch <= '9')) {
        return [MTMathAtom atomWithType:kMTMathAtomNumber value:chStr];
    } else if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
        return [MTMathAtom atomWithType:kMTMathAtomVariable value:chStr];
    } else if (ch == '"' || ch == '/' || ch == '@' || ch == '`' || ch == '|') {
        // just an ordinary character. The following are allowed ordinary chars
        // | / ` @ "
        return [MTMathAtom atomWithType:kMTMathAtomOrdinary value:chStr];
    } else {
        NSAssert(false, @"Unknown ascii character %@. Should have been accounted for.", @(ch));
        return nil;
    }
}

+ (MTMathAtom *)atomForLatexSymbol:(NSString *)symbol
{
    NSParameterAssert(symbol);
    NSDictionary* commands = [MTMathListBuilder supportedCommands];
    MTMathAtom* atom = commands[symbol];
    if (atom) {
        // Return a copy of the atom since atoms are mutable.
        return [atom copy];
    }
    return nil;
}

@end
