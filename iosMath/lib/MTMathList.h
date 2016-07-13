//
//  MathList.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MTMathList;

/**
 @typedef MTMathAtomType
 @brief The type of atom in a `MTMathList`.
 
 The type of the atom determines how it is rendered, and spacing between the atoms.
 */
typedef NS_ENUM(NSUInteger, MTMathAtomType)
{
    /// A number or text in ordinary format - Ord in TeX
    kMTMathAtomOrdinary = 1,
    /// A number - Does not exist in TeX
    kMTMathAtomNumber,
    /// A variable (i.e. text in italic format) - Does not exist in TeX
    kMTMathAtomVariable,
    /// A large operator such as (sin/cos, integral etc.) - Op in TeX
    kMTMathAtomLargeOperator,
    /// A binary operator - Bin in TeX
    kMTMathAtomBinaryOperator,
    /// A unary operator - Does not exist in TeX.
    kMTMathAtomUnaryOperator,
    /// A relation, e.g. = > < etc. - Rel in TeX
    kMTMathAtomRelation,
    /// Open brackets - Open in TeX
    kMTMathAtomOpen,
    /// Close brackets - Close in TeX
    kMTMathAtomClose,
    /// An fraction e.g 1/2 - generalized fraction noad in TeX
    kMTMathAtomFraction,
    /// A radical operator e.g. sqrt(2)
    kMTMathAtomRadical,
    /// Punctuation such as , - Punct in TeX
    kMTMathAtomPunctuation,
    /// A placeholder square for future input. Does not exist in TeX
    kMTMathAtomPlaceholder,
    /// An inner atom, i.e. an embedded math list - Inner in TeX
    kMTMathAtomInner,
    /// An underlined atom - Under in TeX
    kMTMathAtomUnderline,
    /// An overlined atom - Over in TeX
    kMTMathAtomOverline,
    /// An accented atom - Accent in TeX
    kMTMathAtomAccent,
    
    // Atoms after this point do not support subscripts or superscripts
    
    /// A left atom - Left & Right in TeX. We don't need two since we track boundaries separately.
    kMTMathAtomBoundary = 101,
};

/** A `MTMathAtom` is the basic unit of a math list. Each atom represents a single character
 or mathematical operator in a list. However certain atoms can represent more complex structures
 such as fractions and radicals. Each atom has a type which determines how the atom is rendered and
 a nucleus. The nucleus contains the character(s) that need to be rendered. However the nucleus may
 be empty for certain types of atoms. An atom has an optional subscript or superscript which represents
 the subscript or superscript that is to be rendered.
 
 Certain types of atoms inherit from `MTMathAtom` and may have additional fields.
 */
@interface MTMathAtom : NSObject<NSCopying>

/// Do not use init. Use `atomWithType:value:` to instantiate atoms.
- (instancetype)init NS_UNAVAILABLE;

/** Factory function to create an atom with a given type and value.
 @param type The type of the atom to instantiate.
 @param value The value of the atoms nucleus. The value is ignored for fractions and radicals.
 */
+ (instancetype) atomWithType: (MTMathAtomType) type value:(NSString*) value;

/** Returns a string representation of the MTMathAtom */
@property (nonatomic, readonly) NSString *stringValue;

/** The type of the atom. */
@property (nonatomic) MTMathAtomType type;
/** The nucleus of the atom. */
@property (nonatomic, copy) NSString* nucleus;
/** An optional superscript. */
@property (nonatomic, nullable) MTMathList* superScript;
/** An optional subscript. */
@property (nonatomic, nullable) MTMathList* subScript;

/** Returns true if this atom allows scripts (sub or super). */
- (bool) scriptsAllowed;

/// If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one.
/// This is used in the finalizing and preprocessing steps.
@property (nonatomic, readonly, nullable) NSArray<MTMathAtom*>* fusedAtoms;

/// The index range in the MTMathList this MTMathAtom tracks. This is used by the finalizing and preprocessing steps
/// which fuse MTMathAtoms to track the position of the current MTMathAtom in the original list.
@property (nonatomic, readonly) NSRange indexRange;

/// Fuse the given atom with this one by combining their nucleii.
- (void) fuse:(MTMathAtom*) atom;

/// Makes a deep copy of the atom
- (id)copyWithZone:(nullable NSZone *)zone;

@end

/** An atom of type fraction. This atom has a numerator and denominator. */
@interface MTFraction : MTMathAtom

/// Creates an empty fraction with a rule.
- (instancetype)init;

/// Creates an empty fraction with the given value of hasRule.
- (instancetype)initWithRule:(BOOL) hasRule NS_DESIGNATED_INITIALIZER;

/// Numerator of the fraction
@property (nonatomic) MTMathList* numerator;
/// Denominator of the fraction
@property (nonatomic) MTMathList* denominator;

/**If true, the fraction has a rule (i.e. a line) between the numerator and denominator.
 The default value is true. */
@property (nonatomic, readonly) BOOL hasRule;

/** An optional delimiter for a fraction on the left. */
@property (nonatomic, nullable) NSString* leftDelimiter;
/** An optional delimiter for a fraction on the right. */
@property (nonatomic, nullable) NSString* rightDelimiter;

@end

/** An atom of type radical (square root). */
@interface MTRadical : MTMathAtom

/// Creates an empty radical
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// Denotes the term under the square root sign
@property (nonatomic, nullable) MTMathList* radicand;

/// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
/// This can be null if there is no degree.
@property (nonatomic, nullable) MTMathList* degree;

@end

/** A `MTMathAtom` of type `kMTMathAtomLargeOperator`. */
@interface MTLargeOperator : MTMathAtom

/** Designated initializer. Initialize a large operator with the given
 value and setting for limits.
 */
- (instancetype) initWithValue:(NSString*) value limits:(BOOL) limits NS_DESIGNATED_INITIALIZER;

/** Indicates whether the limits (if present) should be displayed
 above and below the operator in display mode.  If limits is false
 then the limits (if present) and displayed like a regular subscript/superscript.
 */
@property (nonatomic, readonly) BOOL limits;

@end

/** An inner atom. This denotes an atom which contains a math list inside it. An inner atom
 has optional boundaries. Note: Only one boundary may be present, it is not required to have
 both. */
@interface MTInner : MTMathAtom

/// Creates an empty inner
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// The inner math list
@property (nonatomic, nullable) MTMathList* innerList;
/// The left boundary atom. This must be a node of type kMTMathAtomBoundary
@property (nonatomic, nullable) MTMathAtom* leftBoundary;
/// The right boundary atom. This must be a node of type kMTMathAtomBoundary
@property (nonatomic, nullable) MTMathAtom* rightBoundary;

@end

/** A representation of a list of math objects.

    This list can be constructed directly or built with
    the help of the MTMathListBuilder. It is not required that the mathematics represented make sense
    (i.e. this cn represent something like "x 2 = +". This list can be used for display using MTLine
    or can be a list of tokens to be used by a parser after finalizedMathList is called.
 
    @note This class is for ADVANCED usage only.
 */
@interface MTMathList : NSObject<NSCopying>

/// A list of MathAtoms
@property (nonatomic, readonly) NSArray* atoms;

/** Initializes an empty math list. */
- (instancetype) init NS_DESIGNATED_INITIALIZER;

/** Add an atom to the end of the list.
 @param atom The atom to be inserted. This cannot be `nil` and cannot have the type `kMTMathAtomBoundary`.
 @throws NSException if the atom is of type `kMTMathAtomBoundary`
 @throws NSInvalidArgumentException if the atom is `nil` */
- (void) addAtom:(MTMathAtom*) atom;

/** Inserts an atom at the given index. If index is already occupied, the objects at index and beyond are 
 shifted by adding 1 to their indices to make room.
 
 @param atom The atom to be inserted. This cannot be `nil` and cannot have the type `kMTMathAtomBoundary`.
 @param index The index where the atom is to be inserted. The index should be less than or equal to the
 number of elements in the math list.
 @throws NSException if the atom is of type kMTMathAtomBoundary
 @throws NSInvalidArgumentException if the atom is nil
 @throws NSRangeException if the index is greater than the number of atoms in the math list. */
- (void) insertAtom:(MTMathAtom *)atom atIndex:(NSUInteger) index;

/** Append the given list to the end of the current list.
 @param list The list to append.
 */
- (void) append:(MTMathList*) list;

/** Removes the last atom from the math list. If there are no atoms in the list this does nothing. */
- (void) removeLastAtom;

/** Removes the atom at the given index.
 @param index The index at which to remove the atom. Must be less than the number of atoms
 in the list.
 */
- (void) removeAtomAtIndex:(NSUInteger) index;

/** Removes all the atoms within the given range. */
- (void) removeAtomsInRange:(NSRange) range;

/// converts the MTMathList to a string form. Note: This is not the LaTeX form.
@property (nonatomic, readonly) NSString *stringValue;

/// Create a new math list as a final expression and update atoms
/// by combining like atoms that occur together and converting unary operators to binary operators.
/// This function does not modify the current MTMathList
- (MTMathList*) finalized;

/// Makes a deep copy of the list
- (id)copyWithZone:(nullable NSZone *)zone;

@end

NS_ASSUME_NONNULL_END
