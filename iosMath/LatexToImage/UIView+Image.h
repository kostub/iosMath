//
//  UIView+Image.h
//  iosMath
//
//  Created by wpstarnice on 16/9/19.
//
//

#import <UIKit/UIKit.h>

typedef enum kLatexImageType{

    kLatexTypePng = 0,
    kLatexTypeJpj
    
}kLatexImageType;

@interface UIView (Image)

- (UIImage *)generateLatexImage;
- (NSData *)generateLatexImageWithType:(kLatexImageType)type;

@end
