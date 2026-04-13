#import <Foundation/Foundation.h>

NSBundle* iosMath_SWIFTPM_MODULE_BUNDLE() {
    NSURL *bundleURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"iosMath_iosMath.bundle"];

    NSBundle *preferredBundle = [NSBundle bundleWithURL:bundleURL];
    if (preferredBundle == nil) {
      return [NSBundle bundleWithPath:@"/Users/kostub/Work/iosmath/iosMath/.build/arm64-apple-macosx/debug/iosMath_iosMath.bundle"];
    }

    return preferredBundle;
}