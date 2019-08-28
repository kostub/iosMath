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
+ (nullable MTMathAtom*) atomForCharacter:(unichar) ch;

/** Returns a `MTMathList` with one atom per character in the given string. This function
 does not do any LaTeX conversion or interpretation. It simply uses `atomForCharacter` to
 convert the characters to atoms. Any character that cannot be converted is ignored. */
+ (MTMathList*) mathListForCharacters:(NSString*) chars;

/** Returns an atom with the right type for a given latex symbol (e.g. theta)
 If the latex symbol is unknown this will return nil. This supports LaTeX aliases as well.
 */
+ (nullable MTMathAtom*) atomForLatexSymbolName:(NSString*) symbolName;

/** Finds the name of the LaTeX symbol name for the given atom. This function is a reverse
 of the above function. If no latex symbol name corresponds to the atom, then this returns `nil`
 If nucleus of the atom is empty, then this will return `nil`.
 @note: This is not an exact reverse of the above in the case of aliases. If an LaTeX alias
 points to a given symbol, then this function will return the original symbol name and not the
 alias.
 @note: This function does not convert MathSpaces to latex command names either.
 */
+ (nullable NSString*) latexSymbolNameForAtom:(MTMathAtom*) atom;

/** Define a latex symbol for rendering. This function allows defining custom symbols that are
 not already present in the default set, or override existing symbols with new meaning.
 e.g. to define a symbol for "lcm" one can call:
 `[MTMathAtomFactory addLatexSymbol:@"lcm" value:[MTMathAtomFactory operatorWithName:@"lcm" limits:NO]]` */
+ (void) addLatexSymbol:(NSString*) name value:(MTMathAtom*) atom;

/** Returns a list of all supported lated symbols names. */
+ (NSArray<NSString*>*) supportedLatexSymbolNames;

/** Returns a large opertor for the given name. If limits is true, limits are set up on
 the operator and displyed differently. */
+ (MTLargeOperator *)operatorWithName:(NSString *)name limits:(bool) limits;

/** Returns an accent with the given name. The name of the accent is the LaTeX name
 such as `grave`, `hat` etc. If the name is not a recognized accent name, this
 returns nil. The `innerList` of the returned `MTAccent` is nil.
 */
+ (nullable MTAccent*) accentWithName:(NSString*) accentName;

/** Returns the accent name for the given accent. This is the reverse of the above
 function. */
+(NSString*) accentName:(MTAccent*) accent;

/** Creates a new boundary atom for the given delimiter name. If the delimiter name
 is not recognized it returns nil. A delimiter name can be a single character such
 as '(' or a latex command such as 'uparrow'. 
 @note In order to distinguish between the delimiter '|' and the delimiter '\|' the delimiter '\|'
 the has been renamed to '||'.
 */
+(nullable MTMathAtom*) boundaryAtomForDelimiterName:(NSString*) delimiterName;

/** Returns the delimiter name for a boundary atom. This is a reverse of the above function.
 If the atom is not a boundary atom or if the delimiter value is unknown this returns `nil`.
 @note This is not an exact reverse of the above function. Some delimiters have two names (e.g.
 `<` and `langle`) and this function always returns the shorter name.
 */
+ (nullable NSString*) delimiterNameForBoundaryAtom:(MTMathAtom*) boundary;

/** Returns a font style associated with the name. If none is found returns NSNotFound. */
+ (MTFontStyle) fontStyleWithName:(NSString*) fontName;

/** Returns the latex font name for a given style. */
+ (NSString*) fontNameForStyle:(MTFontStyle) fontStyle;

/** Returns a fraction with the given numerator and denominator. */
+ (MTFraction*) fractionWithNumerator:(MTMathList*) num denominator:(MTMathList*) denom;

/** Simplification of above function when numerator and denominator are simple strings.
 This function uses `mathListForCharacters` to convert the strings to `MTMathList`s. */
+ (MTFraction*) fractionWithNumeratorStr:(NSString*) numStr denominatorStr:(NSString*) denomStr;

/** Builds a table for a given environment with the given rows. Returns a `MTMathAtom` containing the
 table and any other atoms necessary for the given environment. Returns nil and sets error
 if the table could not be built.
 @param env The environment to use to build the table. If the env is nil, then the default table is built.
 @note The reason this function returns a `MTMathAtom` and not a `MTMathTable` is because some
 matrix environments are have builtin delimiters added to the table and hence are returned as inner atoms.
 */
+ (nullable MTMathAtom*) tableWithEnvironment:(nullable NSString*) env rows:(NSArray<NSArray<MTMathList*>*>*) rows error:(NSError**) error;
@end

NS_ASSUME_NONNULL_END
