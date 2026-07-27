//
//  MTMacroParameterAtom.h
//  iosMath
//
//  INTERNAL HEADER — deliberately not listed in iosMath/module.modulemap, so it
//  does not appear in the Swift module interface.
//

#import "MTMathList.h"

NS_ASSUME_NONNULL_BEGIN

/** A `#N` argument reference inside a macro's golden template.

 This is a sentinel: it exists only between "the template was parsed" and "the
 macro was expanded", and every instance is consumed by
 `-[MTMacroAtom expansion]`. It keeps type `kMTMathAtomOrdinary` rather than
 claiming a new `MTMathAtomType`, because the public enum should not grow a value
 that can never legally reach a finalized list. Detect it with `isKindOfClass:`.
 */
@interface MTMacroParameterAtom : MTMathAtom

/** The 1-based argument this placeholder stands for (1...9). */
@property (nonatomic, readonly) NSUInteger argumentIndex;

// Deliberately NOT NS_DESIGNATED_INITIALIZER: -copyWithZone: depends on
// MTMathAtom's -initWithType:value: staying reachable to rebuild the copy, which
// is exactly what a designated initializer here would forbid.
- (instancetype)initWithArgumentIndex:(NSUInteger)argumentIndex;

@end

NS_ASSUME_NONNULL_END
