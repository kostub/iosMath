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

/** Returns an atom for the multiplication sign. */
+ (MTMathAtom*) times;    // \times or *

/** Returns an atom for the division sign. */
+ (MTMathAtom*) divide; // \div or /

#pragma mark - Placeholders

/** Returns an atom which is a placeholder square. */
+ (MTMathAtom*) placeholder;

/** Returns a fraction with a placeholder for the numerator and denominator */
+ (MTFraction*) placeholderFraction;

/** Returns a square root with a placeholder as the radicand. */
+ (MTRadical *)placeholderSquareRoot;

/** Returns a radical with a placeholder as the radicand. */
+ (MTRadical*) placeholderRadical;

#pragma mark -

/** Returns an atom for the open parens sign. */
+ (MTMathAtom *)openParens __deprecated_msg("Use [MTMathAtomFactory atomForCharacter:'('] instead");

/** Returns an atom for the close parens sign. */
+ (MTMathAtom *)closeParens __deprecated_msg("Use [MTMathAtomFactory atomForCharacter:')'] instead");

/** Gets the atom with the right type for the given character. If an atom
 cannot be determined for a given character this returns nil. 
 This function follows latex conventions for assigning types to the atoms.
 The following characters are not supported and will return nil:
 - Any non-ascii character.
 - Any control character or spaces (< 0x21)
 - Latex control chars: $ % # & ~ '
 - Chars with special meaning in latex: ^ _ { } \
 All other characters will have a non-nil atom returned.
 */
+ (MTMathAtom*) atomForCharacter:(unichar) ch;

/** Returns an atom with the right type for a given latex symbol (e.g. theta)
 If the latex symbol is unknown this will return nil.
 @note: This function does not support latex aliases.
 */
+ (MTMathAtom*) atomForLatexSymbol:(NSString*) symbol;

/** Deprecated. Use (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits
 instead. This sets the limits to false. */
+ (MTMathAtom *) operatorWithName:(NSString*) name __deprecated;

/** Returns a large opertor for the given name. If limits is true, limits are set up on 
 the operator and displyed differently. */
+ (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits;

@end

NS_ASSUME_NONNULL_END
