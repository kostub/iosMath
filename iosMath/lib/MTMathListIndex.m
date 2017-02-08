//
//  MTMathListIndex.m
//
//  Created by Kostub Deshmukh on 9/6/13.
//  Copyright (C) 2013 MathChat
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathListIndex.h"

#pragma mark - MTMathListIndex

@interface MTMathListIndex ()

@property (nonatomic, readwrite) NSUInteger atomIndex;
@property (nonatomic, readwrite) MTSubIndexType subIndexType;
@property (nonatomic, readwrite, nullable) MTMathListIndex* subIndex;

@end

@implementation MTMathListIndex

+ (id)level0Index:(NSUInteger)index
{
    MTMathListIndex* mlIndex = [MTMathListIndex new];
    mlIndex.atomIndex = index;
    return mlIndex;
}

+ (instancetype)indexAtLocation:(NSUInteger)location withSubIndex:(MTMathListIndex *)subIndex type:(MTSubIndexType)type
{
    MTMathListIndex* index = [self level0Index:location];
    index.subIndexType = type;
    index.subIndex = subIndex;
    return index;
}

- (MTMathListIndex *)levelUpWithSubIndex:(MTMathListIndex *)subIndex type:(MTSubIndexType)type
{
    if (self.subIndexType == kMTSubIndexTypeNone) {
        return [MTMathListIndex indexAtLocation:self.atomIndex withSubIndex:subIndex type:type];
    }
    // we have to recurse
    return [MTMathListIndex indexAtLocation:self.atomIndex withSubIndex:[self.subIndex levelUpWithSubIndex:subIndex type:type] type:self.subIndexType];
}

- (MTMathListIndex *)levelDown
{
    if (self.subIndexType == kMTSubIndexTypeNone) {
        return nil;
    }
    // recurse
    MTMathListIndex* subIndexDown = self.subIndex.levelDown;
    if (subIndexDown) {
        return [MTMathListIndex indexAtLocation:self.atomIndex withSubIndex:subIndexDown type:self.subIndexType];
    } else {
        return [MTMathListIndex level0Index:self.atomIndex];
    }
}

- (MTMathListIndex *)previous
{
    if (self.subIndexType == kMTSubIndexTypeNone) {
        return [MTMathListIndex level0Index:MAX(self.atomIndex - 1, 0)];
    } else {
        MTMathListIndex* prevSubIndex = self.subIndex.previous;
        return [MTMathListIndex indexAtLocation:self.atomIndex withSubIndex:prevSubIndex type:self.subIndexType];
    }
}

- (MTMathListIndex *)next
{
    if (self.subIndexType == kMTSubIndexTypeNone) {
        return [MTMathListIndex level0Index:self.atomIndex + 1];
    } else {
        return [MTMathListIndex indexAtLocation:self.atomIndex withSubIndex:self.subIndex.next type:self.subIndexType];
    }
}

- (BOOL) isAffectedByChangesIn:(MTMathListIndex *)other
{
    if (self.subIndexType != other.subIndexType) return false;
    if (self.subIndex) [self.subIndex isAffectedByChangesIn:other.subIndex];
    return self.atomIndex >= other.atomIndex;
}

- (nullable MTMathListIndex *) relativeFrom:(nonnull MTMathListIndex *)index
{
    MTMathListIndex* selfCurrentIndex = self;
    MTMathListIndex* otherCurrentIndex = index;

    while ([selfCurrentIndex subIndexType] != kMTSubIndexTypeNone) {
        if ([selfCurrentIndex atomIndex] != [otherCurrentIndex atomIndex]) return nil;
        if ([selfCurrentIndex subIndexType] != [otherCurrentIndex subIndexType]) return nil;
        selfCurrentIndex = [selfCurrentIndex subIndex];
        otherCurrentIndex = [otherCurrentIndex subIndex];
    }

    NSInteger nextAtomIndex = selfCurrentIndex.atomIndex - otherCurrentIndex.atomIndex;

    if (nextAtomIndex < 0) return nil;

    return [MTMathListIndex indexAtLocation:nextAtomIndex
                               withSubIndex:otherCurrentIndex.subIndex
                                       type:otherCurrentIndex.subIndexType];
}

- (BOOL)hasSubIndexOfType:(MTSubIndexType)subIndexType
{
    if (self.subIndexType == subIndexType) {
        return true;
    } else {
        return [self.subIndex hasSubIndexOfType:subIndexType];
    }
}

- (BOOL) isAtBeginningOfLine
{
    return (self.finalIndex == 0);
}


- (BOOL)isAtSameLevel:(MTMathListIndex *)other
{
    if (self.subIndexType != other.subIndexType) {
        return false;
    } else if (self.subIndexType == kMTSubIndexTypeNone) {
        // No subindexes, they are at the same level.
        return true;
    } else if (self.atomIndex != other.atomIndex) {
        // the subindexes are used in different atoms
        return false;
    } else {
        return [self.subIndex isAtSameLevel:other.subIndex];
    }
}

- (NSUInteger) finalIndex
{
    if (self.subIndexType == kMTSubIndexTypeNone) {
        return self.atomIndex;
    } else {
        return self.subIndex.finalIndex;
    }
}

- (MTSubIndexType) finalSubIndexType
{
    if (self.subIndex.subIndex) {
        return [self.subIndex finalSubIndexType];
    } else {
        return self.subIndexType;
    }
}

- (MTMathListIndex *) addingFinalIndex:(NSInteger) index
{
    if (self.subIndexType == kMTSubIndexTypeNone) {
        return [MTMathListIndex level0Index:self.atomIndex + index];
    } else {
        // Recurse
        return [MTMathListIndex indexAtLocation:self.atomIndex
                                   withSubIndex:[self.subIndex addingFinalIndex:index]
                                           type:self.subIndexType];
    }
}

- (NSString *)description
{
    if (self.subIndex) {
        return [NSString stringWithFormat:@"[%lu, %d:%@]", (unsigned long)self.atomIndex, self.subIndexType, [self.subIndex description]];
    }
    return [NSString stringWithFormat:@"[%lu]", (unsigned long)self.atomIndex];
}

- (BOOL)isEqualToIndex:(MTMathListIndex *)index
{
    if (self.atomIndex != index.atomIndex || self.subIndexType != index.subIndexType) {
        return NO;
    }
    if (self.subIndex) {
        return [self.subIndex isEqual:index.subIndex];
    } else {
        return (index.subIndex == nil);
    }
}

- (BOOL) isEqual:(id) anObject
{
    if (self == anObject) {
        return YES;
    }
    if (!anObject || ![anObject isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToIndex:anObject];
}

- (NSUInteger) hash
{
    const int prime = 31;
    NSUInteger hash = self.atomIndex;
    hash = hash * prime + self.subIndexType;
    hash = hash * prime + self.subIndex.hash;
    return hash;
}

@end

@interface MTMathListRange ()

- (instancetype)initWithStart:(MTMathListIndex*) start length:(NSUInteger) length NS_DESIGNATED_INITIALIZER;

@end

@implementation MTMathListRange

- (instancetype)initWithStart:(MTMathListIndex*) start length:(NSUInteger) length
{
    self = [super init];
    if (self) {
        _start = start;
        _length = length;
    }
    return self;
}

+ (MTMathListRange *)makeRange:(MTMathListIndex *)start length:(NSUInteger)length
{
    return [[MTMathListRange alloc] initWithStart:start length:length];
}

+ (MTMathListRange *)makeRange:(MTMathListIndex *)start
{
    return [self makeRange:start length:1];
}

+ (MTMathListRange *)makeRangeForIndex:(NSUInteger)start
{
    return [self makeRange:[MTMathListIndex level0Index:start]];
}

+ (MTMathListRange *)makeRangeForRange:(NSRange)range
{
    return [self makeRange:[MTMathListIndex level0Index:range.location] length:range.length];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"(%@, %lu)", self.start, (unsigned long)self.length];
}

- (MTMathListRange *)subIndexRange
{
    if (self.start.subIndexType != kMTSubIndexTypeNone) {
        return [MTMathListRange makeRange:self.start.subIndex length:self.length];
    }
    return nil;
}

- (NSRange) finalRange
{
    return NSMakeRange(self.start.finalIndex, self.length);
}

- (MTMathListRange *)unionRange:(MTMathListRange *)range
{
    if (![self.start isAtSameLevel:range.start]) {
        NSAssert(false, @"Cannot union ranges at different levels: %@, %@", self, range);
        return nil;
    }

    NSRange r1 = self.finalRange;
    NSRange r2 = range.finalRange;
    NSRange unionRange = NSUnionRange(r1, r2);
    MTMathListIndex* start;
    if (unionRange.location == r1.location) {
        start = self.start;
    } else {
        assert(unionRange.location == r2.location);
        start = range.start;
    }
    return [MTMathListRange makeRange:start length:unionRange.length];
}

+ (MTMathListRange *)unionRanges:(NSArray *)ranges
{
    NSAssert((ranges.count > 0), @"Need to union at least one range");

    MTMathListRange* unioned = ranges[0];
    for (int i = 1; i < ranges.count; i++) {
        MTMathListRange* next = ranges[i];
        [unioned unionRange:next];
    }
    return unioned;
}

@end
