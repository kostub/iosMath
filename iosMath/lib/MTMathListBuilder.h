//
//  MTMathListBuilder.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import Foundation;

#import "MTMathList.h"

FOUNDATION_EXPORT NSString *const _Nonnull MTParseError;

/** `MTMathListBuilder` is a class for parsing LaTeX into an `MTMathList` that
 can be rendered and processed mathematically.
 */
@interface MTMathListBuilder : NSObject

/** Contains any error that occurred during parsing. */
@property (nonatomic, readonly, nullable) NSError* error;

- (nonnull instancetype) initWithString:(nonnull NSString*) str NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype) init NS_UNAVAILABLE;

/// Builds a mathlist from the given string. Returns nil if there is an error.
- (nullable MTMathList*) build;

/// List of commands that are supported.
+ (nonnull NSDictionary<NSString*, MTMathAtom*>*) supportedCommands;

/** Construct a math list from a given string. If there is parse error, returns
 nil. To retrieve the error use the function `[MTMathListBuilder buildFromString:error:]`.
 */
+ (nullable MTMathList*) buildFromString:(nonnull NSString*) str;

/** Construct a math list from a given string. If there is an error while
 constructing the string, this returns nil. The error is returned in the
 `error` parameter.
 */
+ (nullable MTMathList*) buildFromString:(nonnull NSString*) str error:( NSError* _Nullable * _Nullable) error;

/// This converts the MTMathList to LaTeX.
+ (nonnull NSString*) mathListToString:(nonnull MTMathList*) ml;

typedef NS_ENUM(NSUInteger, MTParseErrors) {
    MTParseErrorMismatchBraces = 1,
    MTParseErrorInvalidCommand,
    MTParseErrorCharacterNotFound,
    MTParseErrorMissingDelimiter,
    MTParseErrorInvalidDelimiter,
    MTParseErrorMissingRight,
    MTParseErrorMissingLeft,
};

@end
