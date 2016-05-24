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

#import <Foundation/Foundation.h>

#import "MTMathList.h"

FOUNDATION_EXPORT NSString *const MTParseError;

/** `MTMathListBuilder` is a class for parsing LaTeX into an `MTMathList` that
 can be rendered and processed mathematically.
 */
@interface MTMathListBuilder : NSObject

@property (nonatomic, readonly) NSError* error;

- (id) initWithString:(NSString*) str;

/// Builds a mathlist from the given string. Returns nil if there is an error.
- (MTMathList*) build;

/// List of commands that are supported.
+ (NSDictionary*) supportedCommands;

/// Construct a math list from a given string.
+ (MTMathList*) buildFromString:(NSString*) str;

/// This converts the MTMathList to LaTeX.
+ (NSString*) mathListToString:(MTMathList*) ml;

enum MTParseErrors {
    MTParseErrorMismatchBraces = 1,
    MTParseErrorInvalidCommand,
    MTParseErrorCharacterNotFound,
};

@end
