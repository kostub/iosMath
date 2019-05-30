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

@import Foundation;
@import CoreGraphics;

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
    
    // Atoms after this are non-math TeX nodes that are still useful in math mode. They do not have
    // the usual structure.
    
    /// Spacing between math atoms. This denotes both glue and kern for TeX. We do not
    /// distinguish between glue and kern.
    kMTMathAtomSpace = 201,
    /// Denotes style changes during rendering.
    kMTMathAtomStyle,
    kMTMathAtomColor,
    kMTMathAtomColorbox,
    
    // Atoms after this point are not part of TeX and do not have the usual structure.
    
    /// An table atom. This atom does not exist in TeX. It is equivalent to the TeX command
    /// halign which is handled outside of the TeX math rendering engine. We bring it into our
    /// math typesetting to handle matrices and other tables.
    kMTMathAtomTable = 1001,
};

/**
 @typedef MTFontStyle
 @brief The font style of a character.

 The fontstyle of the atom determines what style the character is rendered in. This only applies to atoms
 of type kMTMathAtomVariable and kMTMathAtomNumber. None of the other atom types change their font style.
 */
typedef NS_ENUM(NSUInteger, MTFontStyle)
{
    /// The default latex rendering style. i.e. variables are italic and numbers are roman.
    kMTFontStyleDefault = 0,
    /// Roman font style i.e. \mathrm
    kMTFontStyleRoman,
    /// Bold font style i.e. \mathbf
    kMTFontStyleBold,
    /// Caligraphic font style i.e. \mathcal
    kMTFontStyleCaligraphic,
    /// Typewriter (monospace) style i.e. \mathtt
    kMTFontStyleTypewriter,
    /// Italic style i.e. \mathit
    kMTFontStyleItalic,
    /// San-serif font i.e. \mathss
    kMTFontStyleSansSerif,
    /// Fractur font i.e \mathfrak
    kMTFontStyleFraktur,
    /// Blackboard font i.e. \mathbb
    kMTFontStyleBlackboard,
    /// Bold italic
    kMTFontStyleBoldItalic,
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
/** The font style to be used for the atom. */
@property (nonatomic) MTFontStyle fontStyle;

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

/// Returns a finalized copy of the atom
- (instancetype) finalized;

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
@property (nonatomic) BOOL limits;

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

/** An atom with a line over the contained math list. */
@interface MTOverLine : MTMathAtom

/// Creates an empty over
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// The inner math list
@property (nonatomic, nullable) MTMathList* innerList;

@end

/** An atom with a line under the contained math list. */
@interface MTUnderLine : MTMathAtom

/// Creates an empty under
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// The inner math list
@property (nonatomic, nullable) MTMathList* innerList;

@end

/** An atom with an accent. */
@interface MTAccent : MTMathAtom

/** Creates a new `MTAccent` with the given value as the accent.
 */
- (instancetype)initWithValue:(NSString*) value NS_DESIGNATED_INITIALIZER;

/// The mathlist under the accent.
@property (nonatomic, nullable) MTMathList* innerList;

@end

/** An atom representing space.
 @note None of the usual fields of the `MTMathAtom` apply even though this
 class inherits from `MTMathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
@interface MTMathSpace : MTMathAtom

/** Creates a new `MTMathSpace` with the given spacing.
 @param space The amount of space in mu units.
 */
- (instancetype) initWithSpace:(CGFloat) space NS_DESIGNATED_INITIALIZER;

/** The amount of space represented by this object in mu units. */
@property (nonatomic, readonly) CGFloat space;

@end

/**
 @typedef MTLineStyle
 @brief Styling of a line of math
 */
typedef NS_ENUM(unsigned int, MTLineStyle)  {
    /// Display style
    kMTLineStyleDisplay,
    /// Text style (inline)
    kMTLineStyleText,
    /// Script style (for sub/super scripts)
    kMTLineStyleScript,
    /// Script script style (for scripts of scripts)
    kMTLineStyleScriptScript
};

/** An atom representing a style change.
 @note None of the usual fields of the `MTMathAtom` apply even though this
 class inherits from `MTMathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
@interface MTMathStyle : MTMathAtom

/** Creates a new `MTMathStyle` with the given style.
 @param style The style to be applied to the rest of the list.
 */
- (instancetype) initWithStyle:(MTLineStyle) style NS_DESIGNATED_INITIALIZER;

/** The style represented by this object. */
@property (nonatomic, readonly) MTLineStyle style;

@end

/** An atom representing an color element.
 @note None of the usual fields of the `MTMathAtom` apply even though this
 class inherits from `MTMathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
@interface MTMathColor : MTMathAtom

/// Creates an empty color with a nil environment
- (instancetype) init NS_DESIGNATED_INITIALIZER;

/** The style represented by this object. */
@property (nonatomic, nullable) NSString* colorString;

/// The inner math list
@property (nonatomic, nullable) MTMathList* innerList;

@end

/** An atom representing an colorbox element.
 @note None of the usual fields of the `MTMathAtom` apply even though this
 class inherits from `MTMathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
@interface MTMathColorbox : MTMathAtom

/// Creates an empty color with a nil environment
- (instancetype) init NS_DESIGNATED_INITIALIZER;

/** The style represented by this object. */
@property (nonatomic, nullable) NSString* colorString;

/// The inner math list
@property (nonatomic, nullable) MTMathList* innerList;

@end

/** An atom representing an table element. This atom is not like other
 atoms and is not present in TeX. We use it to represent the `\halign` command
 in TeX with some simplifications. This is used for matrices, equation
 alignments and other uses of multiline environments.
 
 The cells in the table are represented as a two dimensional array of
 `MTMathList` objects. The `MTMathList`s could be empty to denote a missing
 value in the cell. Additionally an array of alignments indicates how each
 column will be aligned.
 */
@interface MTMathTable : MTMathAtom

/**
 @typedef MTColumnAlignment
 @brief Alignment for a column of MTMathTable
 */
typedef NS_ENUM(NSInteger, MTColumnAlignment) {
    /// Align left.
    kMTColumnAlignmentLeft,
    /// Align center.
    kMTColumnAlignmentCenter,
    /// Align right.
    kMTColumnAlignmentRight,
};

/// Creates an empty table with a nil environment
- (instancetype)init;

/// Creates a table with a given environment
- (instancetype)initWithEnvironment:(nullable NSString*) env NS_DESIGNATED_INITIALIZER;

/// The alignment for each column (left, right, center). The default alignment
/// for a column (if not set) is center.
@property (nonatomic, nonnull, readonly) NSArray<NSNumber*>* alignments;
/// The cells in the table as a two dimensional array.
@property (nonatomic, nonnull, readonly) NSArray<NSArray<MTMathList*>*>* cells;
/// The name of the environment that this table denotes.
@property (nonatomic, nullable) NSString* environment;

/// Spacing between each column in mu units.
@property (nonatomic) CGFloat interColumnSpacing;
/// Additional spacing between rows in jots (one jot is 0.3 times font size).
/// If the additional spacing is 0, then normal row spacing is used are used.
@property (nonatomic) CGFloat interRowAdditionalSpacing;

/// Set the value of a given cell. The table is automatically resized to contain this cell.
- (void) setCell:(MTMathList*) list forRow:(NSInteger) row column:(NSInteger) column;

/// Set the alignment of a particular column. The table is automatically resized to
/// contain this column and any new columns added have their alignment set to center.
- (void) setAlignment:(MTColumnAlignment) alignment forColumn:(NSInteger) column;

/// Gets the alignment for a given column. If the alignment is not specified it defaults
/// to center.
- (MTColumnAlignment) getAlignmentForColumn:(NSInteger) column;

/// Number of columns in the table.
- (NSUInteger) numColumns;

/// Number of rows in the table.
- (NSUInteger) numRows;

@end

/** A representation of a list of math objects.

    This list can be constructed directly or built with
    the help of the MTMathListBuilder. It is not required that the mathematics represented make sense
    (i.e. this can represent something like "x 2 = +". This list can be used for display using MTLine
    or can be a list of tokens to be used by a parser after finalizedMathList is called.
 
    @note This class is for ADVANCED usage only.
 */
@interface MTMathList : NSObject<NSCopying>

/** Create a `MTMathList` given a list of atoms. The list of atoms should be
 terminated by `nil`.
 */
+ (instancetype) mathListWithAtoms:(MTMathAtom*) firstAtom, ... NS_REQUIRES_NIL_TERMINATION;

/** Create a `MTMathList` given a list of atoms. */
+ (instancetype) mathListWithAtomsArray:(NSArray<MTMathAtom*>*) atoms;

/// A list of MathAtoms
@property (nonatomic, readonly) NSArray<__kindof MTMathAtom*>* atoms;

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
