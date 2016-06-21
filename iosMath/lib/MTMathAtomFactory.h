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

NS_ASSUME_NONNULL_BEGIN

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

/** A factory to create commonly used MTMathAtoms. */
@interface MTMathAtomFactory : NSObject

/** Returns a square root with a placeholder as the radicand. */
+ (MTRadical *)placeholderSquareRoot;

/** Returns an atom for the multiplication sign. */
+ (MTMathAtom*) times;    // \times or *

/** Returns an atom for the division sign. */
+ (MTMathAtom*) divide; // \div or /

/** Returns an atom which is a placeholder square. */
+ (MTMathAtom*) placeholder;

/** Returns a fraction with a placeholder for the numerator and denominator */
+ (MTFraction*) placeholderFraction;

/** Returns an atom for the open parens sign. */
+ (MTMathAtom *)openParens;

/** Returns an atom for the close parens sign. */
+ (MTMathAtom *)closeParens;

/** Deprecated. Use (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits
 instead. This sets the limits to false. */
+ (MTMathAtom *) operatorWithName:(NSString*) name __deprecated;

/** Returns a large opertor for the given name. If limits is true, limits are set up on 
 the operator and displyed differently. */
+ (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits;

/** Returns a radical with a placeholder as the radicand. */
+ (MTRadical*) placeholderRadical;

@end

NS_ASSUME_NONNULL_END
