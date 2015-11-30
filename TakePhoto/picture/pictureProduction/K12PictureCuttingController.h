//
//  K12PictureCuttingController.h
//  TakePhoto
//
//  Created by mengkai on 15/10/10.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "K12PictureCuttingView.h"

@class K12PictureCuttingController;
@protocol K12PictureCuttingControllerDelegate <NSObject>
- (void)pictureCuttingController:(K12PictureCuttingController *)controller didCuttingImage:(UIImage *)image;
@end
@interface K12PictureCuttingController : UIViewController
{
    UIImage *_image;  //要裁剪的原图
    K12PictureCuttingView *_pictureCuttingView; //图片裁剪视图
    
    __weak UIImageView *_firstCuttingPictureDisplayedView; //第一次打开裁剪弹出的提示框
}
- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, weak) id<K12PictureCuttingControllerDelegate> delegate;
@property (nonatomic, assign) BOOL onFinishedShouldDismiss; //回调时是否需要dismiss defult yes
@end
