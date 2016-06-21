//
//  MTTypesetter.h
//  iosMath
//
//  Created by Kostub Deshmukh on 6/21/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import Foundation;

#import "MTMathListDisplay.h"

NS_ASSUME_NONNULL_BEGIN

/// This class does all the LaTeX typesetting logic.
/// For ADVANCED use only.
@interface MTTypesetter : NSObject

/// Renders a MTMathList as a list of displays.
+ (MTMathListDisplay*) createLineForMathList:(MTMathList*) mathList font:(MTFont*) font style:(MTLineStyle) style;

@end

NS_ASSUME_NONNULL_END
