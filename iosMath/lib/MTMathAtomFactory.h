//
//  MathAtomFactory.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

#import "MTMathList.h"

FOUNDATION_EXPORT NSString *const MTSymbolMultiplication;
FOUNDATION_EXPORT NSString *const MTSymbolDivision;
FOUNDATION_EXPORT NSString *const MTSymbolFractionSlash;
FOUNDATION_EXPORT NSString *const MTSymbolWhiteSquare;
FOUNDATION_EXPORT NSString *const MTSymbolBlackSquare;
FOUNDATION_EXPORT NSString *const MTSymbolLessEqual;
FOUNDATION_EXPORT NSString *const MTSymbolGreaterEqual;
FOUNDATION_EXPORT NSString *const MTSymbolNotEqual;
FOUNDATION_EXPORT NSString *const MTSymbolSquareRoot;
FOUNDATION_EXPORT NSString *const MTSymbolCubeRoot;
FOUNDATION_EXPORT NSString *const MTSymbolInfinity;
FOUNDATION_EXPORT NSString *const MTSymbolAngle;
FOUNDATION_EXPORT NSString *const MTSymbolDegree;

@interface MTMathAtomFactory : NSObject

+ (MTRadical *)placeholderSquareRoot;

+ (MTMathAtom*) times;    // \times or *

+ (MTMathAtom*) divide; // \div or /

+ (MTMathAtom*) placeholder;

+ (MTFraction*) placeholderFraction;

+ (MTMathAtom *)openParens;

+ (MTMathAtom *)closeParens;

/** Deprecated. Use (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits
 instead. This sets the limits to false. */
+ (MTMathAtom *) operatorWithName:(NSString*) name __deprecated;

+ (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits;

+ (MTRadical*) placeholderRadical;

@end
