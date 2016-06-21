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
@import UIKit;

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
- (id) debugQuickLookObject;

@property (nonatomic, readonly) CGFloat ascent;  // height
@property (nonatomic, readonly) CGFloat descent; // depth
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic) CGPoint position;
/// The range of characters supported by this item
@property (nonatomic, readonly) NSRange range;
@property (nonatomic) BOOL hasScript;

@end

/// A rendering of a single CTLine as an MTDisplay
@interface MTCTLineDisplay : MTDisplay

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

typedef NS_ENUM(unsigned int, MTLinePosition)  {
    /// Regular
    kMTLinePositionRegular,
    /// Positioned at a subscript
    kMTLinePositionSubscript,
    /// Positioned at a superscript
    kMTLinePositionSuperscript
};

/// Where the line is positioned
@property (nonatomic, readonly) MTLinePosition type;
@property (nonatomic, readonly) NSArray<MTDisplay*>* subDisplays;
/// If a subscript or superscript this denotes the location in the parent MTList. For a
/// regular list this is NSNotFound
@property (nonatomic, readonly) NSUInteger index;

@end

/// Rendering of an MTFraction as an MTDisplay
@interface MTFractionDisplay : MTDisplay

@property (nonatomic, readonly) MTMathListDisplay* numerator;
@property (nonatomic, readonly) MTMathListDisplay* denominator;

@end

/// Rendering of an MTRadical as an MTDisplay
@interface MTRadicalDisplay : MTDisplay

@property (nonatomic, readonly) MTMathListDisplay* radicand;
@property (nonatomic, readonly, nullable) MTMathListDisplay* degree;

@end

/// Rendering a large operator with limits as an MTDisplay
@interface MTLargeOpLimitsDisplay : MTDisplay

@property (nonatomic, readonly, nullable) MTMathListDisplay* upperLimit;
@property (nonatomic, readonly, nullable) MTMathListDisplay* lowerLimit;

@end

typedef NS_ENUM(unsigned int, MTLineStyle)  {
    kMTLineStyleDisplay,
    kMTLineStyleText,
    kMTLineStyleScript,
    kMTLineStypleScriptScript
};

/// This class does all the LaTeX typesetting logic.
/// For ADVANCED use only.
@interface MTTypesetter : NSObject

/// Renders a MTMathList as a list of displays.
+ (MTMathListDisplay*) createLineForMathList:(MTMathList*) mathList font:(MTFont*) font style:(MTLineStyle) style;

@end

NS_ASSUME_NONNULL_END
