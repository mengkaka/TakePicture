//
//  UIImage+Orientation.h
//  wenku-k12
//
//  Created by mengkai on 15/11/4.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, K12ImageOrientation){
    K12ImageOrientationPortrait,
    K12ImageOrientationPortraitUpsideDown,
    K12ImageOrientationLandscapeLeft,
    K12ImageOrientationLandscapeRight,
};

@interface UIImage (Orientation)
//解决图片方向问题
- (UIImage *)reviseImageOrientation;

//设置图片方向
- (UIImage *)reviseImageWithOrientation:(K12ImageOrientation)orientation;
@end
