//
//  MTMathAtomFactory+Internal.h
//  iosMath
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathAtomFactory.h"

NS_ASSUME_NONNULL_BEGIN

/// Registry value: declared arity + the LaTeX template the expansion is parsed
/// from. Arity is declared rather than inferred from the template because a
/// future \newcommand declares [argc] and its body may ignore arguments.
@interface MTMacroDefinition : NSObject
@property (nonatomic, readonly) NSUInteger argumentCount;
@property (nonatomic, copy, readonly) NSString* templateString;
- (instancetype)initWithArgumentCount:(NSUInteger)argumentCount
                       templateString:(NSString*)templateString;
@end

/** Read side of the macro registry, used by the builder to expand a command.
 `+addMacro:argumentCount:template:` is the public write side; nothing outside
 the library needs to read a definition back. */
@interface MTMathAtomFactory (Internal)

/** The macro registered under `command`, or nil if it is not a macro. */
+ (nullable MTMacroDefinition*) macroDefinitionForCommand:(NSString*) command;

@end

NS_ASSUME_NONNULL_END
