//
//  K12PhotoLibraryController.h
//  TakePhoto
//
//  Created by mengkai on 15/10/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class K12PhotoLibraryController;
@protocol K12PhotoLibraryControllerDelegate <NSObject>
- (void)photoLibraryController:(K12PhotoLibraryController *)controller didConfirmImage:(UIImage *)image;//选取图片的回调
- (void)photoLibraryController:(K12PhotoLibraryController *)controller didCuttingImage:(UIImage *)image;//裁剪图片的回调
@end

@interface K12PhotoLibraryController : UIImagePickerController
{
    UIViewController *_willShowViewController;
}
@property (nonatomic, assign) BOOL shouldCuttingImage;  //是否需要裁剪照片 defult no
@property (nonatomic, assign) BOOL onFinishedShouldDismiss; //回调时是否需要dismiss defult yes
@property (nonatomic, weak) id <K12PhotoLibraryControllerDelegate> choiceDelegate;
@end
