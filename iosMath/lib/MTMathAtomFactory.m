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
    return [MTMathAtom atomWithType:kMTMathAtomLargeOperator value:name];
}

@end
