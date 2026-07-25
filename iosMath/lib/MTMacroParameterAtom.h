//
//  MTMacroParameterAtom.h
//  iosMath
//
//  INTERNAL HEADER — deliberately not listed in iosMath/module.modulemap, so it
//  does not appear in the Swift module interface (same treatment as MTUnicode.h).
//

#import "MTMathList.h"

NS_ASSUME_NONNULL_BEGIN

/** A `#N` argument reference inside a macro's golden template list.

 This is a sentinel: it exists only between "the template was parsed" and "the
 macro was expanded", and every instance is consumed by
 `-[MTMacroAtom expansion]`. It keeps type `kMTMathAtomOrdinary` rather than
 claiming a new `MTMathAtomType`, because the public enum should not grow a value
 that can never legally reach a finalized list. Detect it with `isKindOfClass:`.

 Design: docs/lld/2026-07-13-modular-arithmetic.md §3.3.
 */
@interface MTMacroParameterAtom : MTMathAtom

/** The 1-based argument this placeholder stands for (1...9). */
@property (nonatomic, readonly) NSUInteger argumentIndex;

- (instancetype)initWithArgumentIndex:(NSUInteger)argumentIndex NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
