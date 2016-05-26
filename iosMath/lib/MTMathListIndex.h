//
//  MTMathListIndex.h
//
//  Created by Kostub Deshmukh on 9/6/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

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

typedef enum {
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
    kMTSubIndexTypeDegree
} MTMathListSubIndexType;


/// The index of the associated atom.
@property (nonatomic, readonly) NSUInteger atomIndex;
@property (nonatomic, readonly) MTMathListSubIndexType subIndexType;
@property (nonatomic, readonly) MTMathListIndex* subIndex;

- (MTMathListIndex*) previous;
- (MTMathListIndex*) next;

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
- (MTMathListIndex*) levelUpWithSubIndex:(MTMathListIndex*) subIndex type:(MTMathListSubIndexType) type;
/** Creates a new index by removing the last index item. If this is the last one, then returns nil. */
- (MTMathListIndex*) levelDown;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;
- (NSString *)description;

+ (id) level0Index:(NSUInteger) index;
+ (id) indexAtLocation:(NSUInteger) location withSubIndex:(MTMathListIndex*) subIndex type:(MTMathListSubIndexType) type;


@end

@interface  MTMathListRange : NSObject

/// Creates a valid range.
+ (MTMathListRange*) makeRange:(MTMathListIndex*) start length:(NSUInteger) length;
/// Creates a range at level 0 from the give range.
+ (MTMathListRange *)makeRangeForRange:(NSRange)range;
/// Makes a range of length 1
+ (MTMathListRange*) makeRange:(MTMathListIndex*) start;
/// Makes a range of length 1 at the level 0 index start
+ (MTMathListRange*) makeRangeForIndex:(NSUInteger) start;

@property (nonatomic, readonly) MTMathListIndex* start;
@property (nonatomic, readonly) NSUInteger length;

- (MTMathListRange*) subIndexRange;
/// Appends the current range to range and returns the resulting range. Any elements between the two are included in the range.
- (MTMathListRange*) unionRange:(MTMathListRange*) range;
/// Unions all ranges in the given array of ranges
+ (MTMathListRange*) unionRanges:(NSArray*) ranges;

@end
