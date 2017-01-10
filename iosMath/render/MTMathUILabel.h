//
//  MathUILabel.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import CoreText;

// Compatibility of iOS and Mac OS.
#import "MTConfig.h"

#import "MTFont.h"
#import "MTMathList.h"
#import "MTMathListDisplay.h"

/**
 @typedef MTMathUILabelMode
 @brief Different display styles supported by the `MTMathUILabel`.
 
 @note: The only significant difference between the two modes is how fractions
 and limits on large operators are displayed.
 */
typedef NS_ENUM(unsigned int, MTMathUILabelMode) {
    /// Display mode. Equivalent to $$ in TeX
    kMTMathUILabelModeDisplay,
    /// Text mode. Equivalent to $ in TeX.
    kMTMathUILabelModeText
};

/**
 @typedef MTTextAlignment
 @brief Horizontal text alignment for `MTMathUILabel`.
 */
typedef NS_ENUM(unsigned int, MTTextAlignment) {
    /// Align left.
    kMTTextAlignmentLeft,
    /// Align center.
    kMTTextAlignmentCenter,
    /// Align right.
    kMTTextAlignmentRight,
};

/** The main view for rendering math.
 
 `MTMathLabel` accepts either a string in LaTeX or an `MTMathList` to display. Use
 `MTMathList` directly only if you are building it programmatically (e.g. using an
 editor), otherwise using LaTeX is the preferable method.
 
 The math display is centered vertically in the label. The default horizontal alignment is
 is left. This can be changed by setting `textAlignment`. The math is default displayed in
 *Display* mode. This can be changed using `labelMode`.
 
 When created it uses `[MTFontManager defaultFont]` as its font. This can be changed using
 the `font` parameter.
 */
IB_DESIGNABLE @interface MTMathUILabel : MTView

/** The `MTMathList` to render. Setting this will remove any
 `latex` that has already been set. If `latex` has been set, this will
 return the parsed `MTMathList` if the `latex` parses successfully. Use this
 setting if the `MTMathList` has been programmatically constructed, otherwise it
 is preferred to use `latex`.
 */
@property (nonatomic, nullable) MTMathList* mathList;

/** The latex string to be displayed. Setting this will remove any `mathList` that
 has been set. If latex has not been set, this will return the latex output for the
 `mathList` that is set.
 @see error */
@property (nonatomic, nullable) IBInspectable NSString* latex;

/** This contains any error that occurred when parsing the latex. */
@property (nonatomic, readonly, nullable) NSError* error;

/** If true, if there is an error it displays the error message inline. Default true. */
@property (nonatomic) BOOL displayErrorInline;

/** The MTFont to use for rendering. */
@property (nonatomic, nonnull) MTFont* font;

/** Convenience method to just set the size of the font without changing the fontface. */
@property (nonatomic) IBInspectable CGFloat fontSize;

/** This sets the text color of the rendered math formula. The default color is black. */
@property (nonatomic, nonnull) IBInspectable MTColor* textColor;

/** The minimum distance from the margin of the view to the rendered math. This value is
 `UIEdgeInsetsZero` by default. This is useful if you need some padding between the math and
 the border/background color. sizeThatFits: will have its returned size increased by these insets.
 */
@property (nonatomic) IBInspectable MTEdgeInsets contentInsets;

/** The Label mode for the label. The default mode is Display */
@property (nonatomic) MTMathUILabelMode labelMode;

/** Horizontal alignment for the text. The default is align left. */
@property (nonatomic) MTTextAlignment textAlignment;

/** The internal display of the MTMathUILabel. This is for advanced use only. */
@property (nonatomic, readonly, nullable) MTMathListDisplay* displayList;

@end
