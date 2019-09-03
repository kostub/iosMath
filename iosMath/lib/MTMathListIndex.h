//
//  MTMathListIndex.h
//
//  Created by Kostub Deshmukh on 9/6/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import Foundation;

/** 
 * An index that points to a particular character in the MTMathList. The index is a LinkedList that represents
 * a path from the beginning of the MTMathList to reach a particular atom in the list. The next node of the path
 * is represented by the subIndex. The path terminates when the subIndex is nil.
 *
 * If there is a subIndex, the subIndexType denotes what branch the path takes (i.e. superscript, subscript, 
 * numerator, denominator etc.).
 * e.g in the expression 25^{2/4} the index of the character 4 is represented as:
 * (1, superscript) -> (0, denominator) -> (0, none)
 * This can be interpreted as start at index 1 (i.e. the 5) go up to the superscript.
 * Then look at index 0 (i.e. 2/4) and go to the denominator. Then look up index 0 (i.e. the 4) which this final
 * index.
 * 
 * The level of an index is the number of nodes in the LinkedList to get to the final path.
 */
@interface MTMathListIndex : NSObject

/**
 @typedef MTMathListSubIndexType
 @brief The type of the subindex.
 
 The type of the subindex denotes what branch the path to the atom that this index points to takes.
 */
typedef NS_ENUM(unsigned int, MTMathListSubIndexType) {
    /// The index denotes the whole atom, subIndex is nil.
    kMTSubIndexTypeNone  = 0,
    /// The position in the subindex is an index into the nucleus
    kMTSubIndexTypeNucleus,
    /// The subindex indexes into the superscript.
    kMTSubIndexTypeSuperscript,
    /// The subindex indexes into the subscript
    kMTSubIndexTypeSubscript,
    /// The subindex indexes into the numerator (only valid for fractions)
    kMTSubIndexTypeNumerator,
    /// The subindex indexes into the denominator (only valid for fractions)
    kMTSubIndexTypeDenominator,
    /// The subindex indexes into the radicand (only valid for radicals)
    kMTSubIndexTypeRadicand,
    /// The subindex indexes into the degree (only valid for radicals)
    kMTSubIndexTypeDegree,
    /// The subindex indexes into the inner list (only valid for inner)
    kMTSubIndexTypeInner
};


/// The index of the associated atom.
@property (nonatomic, readonly) NSUInteger atomIndex;
/// The type of subindex, e.g. superscript, numerator etc.
@property (nonatomic, readonly) MTMathListSubIndexType subIndexType;
/// The index into the sublist.
@property (nonatomic, readonly, nullable) MTMathListIndex* subIndex;

/// Returns the previous index if present. Returns `nil` if there is no previous index.
- (nullable MTMathListIndex*) previous;
/// Returns the next index.
- (nonnull MTMathListIndex*) next;

/** 
 * Returns true if this index represents the beginning of a line. Note there may be multiple lines in a MTMathList,
 * e.g. a superscript or a fraction numerator. This returns true if the innermost subindex points to the beginning of a
 * line.
 */
- (BOOL) isAtBeginningOfLine;

/** Returns the type of the innermost sub index. */
- (MTMathListSubIndexType) finalSubIndexType;

/** Returns true if any of the subIndexes of this index have the given type. */
- (BOOL) hasSubIndexOfType:(MTMathListSubIndexType) subIndexType;

/** Creates a new index by attaching this index at the end of the current one. */
- (nonnull MTMathListIndex*) levelUpWithSubIndex:(nullable MTMathListIndex*) subIndex type:(MTMathListSubIndexType) type;
/** Creates a new index by removing the last index item. If this is the last one, then returns nil. */
- (nullable MTMathListIndex*) levelDown;

- (nonnull instancetype)init NS_UNAVAILABLE;
- (BOOL)isEqual:(nullable id)object;
- (NSUInteger)hash;
- (nonnull NSString *)description;

/** Factory function to create a `MTMathListIndex` with no subindexes.
    @param index The index of the atom that the `MTMathListIndex` points at.
 */
+ (nonnull instancetype) level0Index:(NSUInteger) index;

/** Factory function to create at `MTMathListIndex` with a given subIndex.
    @param location The location at which the subIndex should is present.
    @param subIndex The subIndex to be added. Can be nil.
    @param type The type of the subIndex.
 */
+ (nonnull instancetype) indexAtLocation:(NSUInteger) location withSubIndex:(nullable MTMathListIndex*) subIndex type:(MTMathListSubIndexType) type;

@end

/** A range of atoms in an `MTMathList`. This is similar to `NSRange` with a start and length, except that 
    the starting location is defined by a `MTMathListIndex` rather than an ordinary integer.
 */
@interface  MTMathListRange : NSObject

- (nonnull instancetype)init NS_UNAVAILABLE;

/// Creates a valid range.
+ (nonnull MTMathListRange*) makeRange:(nonnull MTMathListIndex*) start length:(NSUInteger) length;
/// Creates a range at level 0 from the give range.
+ (nonnull MTMathListRange *)makeRangeForRange:(NSRange)range;
/// Makes a range of length 1
+ (nonnull MTMathListRange*) makeRange:(nonnull MTMathListIndex*) start;
/// Makes a range of length 1 at the level 0 index start
+ (nonnull MTMathListRange*) makeRangeForIndex:(NSUInteger) start;

/// The starting location of the range. Cannot be `nil`.
@property (nonatomic, readonly, nonnull) MTMathListIndex* start;
/// The size of the range.
@property (nonatomic, readonly) NSUInteger length;

- (nullable MTMathListRange*) subIndexRange;
/// Appends the current range to range and returns the resulting range. Any elements between the two are included in the range.
- (nullable MTMathListRange*) unionRange:(nonnull MTMathListRange*) range;
/// Unions all ranges in the given array of ranges
+ (nullable MTMathListRange*) unionRanges:(nonnull NSArray<MTMathListRange*>*) ranges;

@end
