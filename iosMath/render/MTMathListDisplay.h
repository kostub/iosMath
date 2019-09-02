//
//  MTLine.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/27/13.
//  Copyright (C) 2013 MathChat
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import Foundation;
@import QuartzCore;

// This header file is imported by Foudation.
//#include <TargetConditionals.h>

#import "MTConfig.h"

#import "MTFont.h"
#import "MTMathList.h"

NS_ASSUME_NONNULL_BEGIN

/// The base class for rendering a math equation.
@interface MTDisplay : NSObject

/// Draws itself in the given graphics context.
- (void) draw:(CGContextRef) context;
/// Gets the bounding rectangle for the MTDisplay
- (CGRect) displayBounds;

/// For debugging. Shows the object in quick look in Xcode.
#if TARGET_OS_IPHONE
- (id) debugQuickLookObject;
#endif

/// The distance from the axis to the top of the display
@property (nonatomic, readonly) CGFloat ascent;
/// The distance from the axis to the bottom of the display
@property (nonatomic, readonly) CGFloat descent;
/// The width of the display
@property (nonatomic, readonly) CGFloat width;
/// Position of the display with respect to the parent view or display.
@property (nonatomic) CGPoint position;
/// The range of characters supported by this item
@property (nonatomic, readonly) NSRange range;
/// Whether the display has a subscript/superscript following it.
@property (nonatomic, readonly) BOOL hasScript;
/// The text color for this display
@property (nonatomic, nullable) MTColor *textColor;
// The local color, if the color was mutated local with the color
// command
@property (nonatomic, nullable) MTColor *localTextColor;
/// The background color for this display.
@property (nonatomic, nullable) MTColor *localBackgroundColor;
@end

/// A rendering of a single CTLine as an MTDisplay
@interface MTCTLineDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/// The CTLine being displayed
@property (nonatomic, readonly) CTLineRef line;
/// The attributed string used to generate the CTLineRef. Note setting this does not reset the dimensions of
/// the display. So set only when
@property (nonatomic) NSAttributedString* attributedString;

/// An array of MTMathAtoms that this CTLine displays. Used for indexing back into the MTMathList
@property (nonatomic, readonly) NSArray<MTMathAtom*>* atoms;

@end

/// An MTLine is a rendered form of MTMathList in one line.
/// It can render itself using the draw method.
@interface MTMathListDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/**
 @typedef MTLinePosition
 @brief The type of position for a line, i.e. subscript/superscript or regular.
 */
typedef NS_ENUM(unsigned int, MTLinePosition)  {
    /// Regular
    kMTLinePositionRegular,
    /// Positioned at a subscript
    kMTLinePositionSubscript,
    /// Positioned at a superscript
    kMTLinePositionSuperscript,
    /// Positioned at an inner
    kMTLinePositionInner
};

/// Where the line is positioned
@property (nonatomic, readonly) MTLinePosition type;
/// An array of MTDisplays which are positioned relative to the position of the
/// the current display.
@property (nonatomic, readonly) NSArray<MTDisplay*>* subDisplays;
/// If a subscript or superscript this denotes the location in the parent MTList. For a
/// regular list this is NSNotFound
@property (nonatomic, readonly) NSUInteger index;

@end

/// Rendering of an MTFraction as an MTDisplay
@interface MTFractionDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/** A display representing the numerator of the fraction. It's position is relative
 to the parent and is not treated as a sub-display.
 */
@property (nonatomic, readonly) MTMathListDisplay* numerator;
/** A display representing the denominator of the fraction. It's position is relative
 to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly) MTMathListDisplay* denominator;

@end

/// Rendering of an MTRadical as an MTDisplay
@interface MTRadicalDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/** A display representing the radicand of the radical. It's position is relative
 to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly) MTMathListDisplay* radicand;
/** A display representing the degree of the radical. It's position is relative
 to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly, nullable) MTMathListDisplay* degree;

@end

/// Rendering a glyph as a display
@interface MTGlyphDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

@end

/// Rendering a large operator with limits as an MTDisplay
@interface MTLargeOpLimitsDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/** A display representing the upper limit of the large operator. It's position is relative
 to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly, nullable) MTMathListDisplay* upperLimit;
/** A display representing the lower limit of the large operator. It's position is relative
 to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly, nullable) MTMathListDisplay* lowerLimit;

@end

/// Rendering of an list with an overline or underline
@interface MTLineDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/** A display representing the inner list that is underlined. It's position is relative
 to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly) MTMathListDisplay* inner;

@end

/// Rendering an accent as a display
@interface MTAccentDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/** A display representing the inner list that is accented. It's position is relative
 to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly) MTMathListDisplay* accentee;

/** A display representing the accent. It's position is relative to the current display.
 */
@property (nonatomic, readonly) MTGlyphDisplay* accent;

@end

/// Rendering of an list with delimiters
@interface MTInnerDisplay : MTDisplay

- (instancetype)init NS_UNAVAILABLE;

/** A display representing the inner list that can be wrapped in delimiters.
 It's position is relative to the parent is not treated as a sub-display.
 */
@property (nonatomic, readonly) MTMathListDisplay* inner;

/** A display representing the delimiters. Their position is relative
 to the parent are not treated as a sub-display.
 */
@property (nonatomic, readonly, nullable) MTDisplay* leftDelimiter;
@property (nonatomic, readonly, nullable) MTDisplay* rightDelimiter;

/// Denotes the location in the parent MTList.
@property (nonatomic, readonly) NSUInteger index;

@end

NS_ASSUME_NONNULL_END
