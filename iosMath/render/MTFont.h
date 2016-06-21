//
//  MTFont.h
//  iosMath
//
//  Created by Kostub Deshmukh on 5/18/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import CoreText;
@import CoreGraphics;
@import Foundation;

/** MTFont wraps the inconvenient distinction between CTFont and CGFont as well
 as the data loaded from the math table.
 */
@interface MTFont : NSObject

/** Returns a copy of this font but with a different size. */
- (nonnull MTFont*) copyFontWithSize:(CGFloat) size;

/** The size of this font in points. */
@property (nonatomic, readonly) CGFloat fontSize;

@end
