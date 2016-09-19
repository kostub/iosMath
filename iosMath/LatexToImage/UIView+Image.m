//
//  UIView+Image.m
//  iosMath
//
//  Created by wpstarnice on 16/9/19.
//
//

#import "UIView+Image.h"

@implementation UIView (Image)

- (UIImage *)generateLatexImage {

    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    // Make the CALayer to draw in "canvas".
    [self.layer renderInContext: UIGraphicsGetCurrentContext()];
    
    // Fetch an UIImage of our "canvas".
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIImage *flippedImage = [self rotateImage:image onDegrees:0];
    
    return flippedImage;
}

- (NSData *)generateLatexImageWithType:(kLatexImageType)type{
    
    UIImage *image = [self generateLatexImage];
    
    if ( type == kLatexTypePng) {
        return UIImagePNGRepresentation(image);
    }else{
        return UIImageJPEGRepresentation(image, 1.0);
    }
}

#pragma mark - private method

- (UIImage *)rotateImage:(UIImage *)image onDegrees:(float)degrees{
    
    CGFloat rads = M_PI * degrees / 180;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0);
    
    CGFloat height = image.size.height;
    CGFloat width  = image.size.width;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, width/2, height/2);
    CGContextRotateCTM(context, rads);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(-width/2,-height/2,width, height),image.CGImage);
    UIImage *modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return modifiedImage;
}

@end
