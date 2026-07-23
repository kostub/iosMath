//  MTMathUILabelInternal.h
//  Internal test/compose surface for MTMathUILabel. Not part of the public API.
#import "MTMathUILabel.h"
#import "MTMathListDisplay.h"

NS_ASSUME_NONNULL_BEGIN

// NOTE: `displayList` is already declared `readonly` on the public
// `MTMathUILabel` interface (MTMathUILabel.h); redeclaring it here would be
// an illegal class-extension redeclaration (Clang requires `readwrite` for a
// class-extension override of a `readonly` property). This header exists to
// expose `screenScale`, the other internal test/compose surface item 16/17
// need.
@interface MTMathUILabel ()

// Device-pixel scale used for rounding the reported size:
//  iOS  : contentScaleFactor
//  macOS: window.backingScaleFactor → layer.contentsScale → 1
- (CGFloat)screenScale;

// `sizeThatFits:` is implemented in MTMathUILabel.m and is public UIView API
// on iOS, but NSView has no such method on macOS, so it is otherwise
// invisible to callers outside the implementation file on that platform.
// Redeclared here (harmless on iOS, load-bearing on macOS) so tests can call
// it cross-platform without changing the public API surface.
- (CGSize)sizeThatFits:(CGSize)size;

// Same story as sizeThatFits: above — public UIView API on iOS, but
// implemented (not declared) on MTMathUILabel for macOS, where NSView uses
// layout/layoutSubtreeIfNeeded instead. Redeclared here so tests can drive
// layout directly and cross-platform.
- (void)layoutSubviews;

@end

NS_ASSUME_NONNULL_END
