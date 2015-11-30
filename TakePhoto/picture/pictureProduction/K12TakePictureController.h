//
//  K12TakePictureController.h
//  TakePhoto
//
//  Created by mengkai on 15/10/10.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "K12OfflineMistakenWriteController.h"
#import "K12CameraTakePictureView.h"

@class K12TakePictureController;
@protocol K12TakePictureControllerDelegate <NSObject>
- (void)takePictureController:(K12TakePictureController *)takePictureController onFinshedWithImage:(UIImage *)image;
- (void)takePictureControllerDidCancel:(K12TakePictureController *)takePictureController;
@end

@interface K12TakePictureController : UIViewController
{
    UIButton *_actionButton;    //拍照按钮
    UIButton *_closeButton;     //关闭按钮
    UIButton *_photoLibraryButton;  //相册按钮
    UIButton *_flashButton;     //闪光灯按钮
    
    UILabel *_cameraTips;  //方向提示文本
    BOOL _isViewDidLoad;        //首次进入动画标记
    
    UIView *_spaceView;         //空白的视图,相机视图未初始化之前显示
    K12CameraTakePictureView *_takePhotoView;   //照相视图
    
    __weak UIView *_notAuthorizationView; //第一次打开相机弹出的提示框
    __weak UIImageView *_firstTakePictureDisplayedView; //第一次打开相机弹出的提示框
}

@property (nonatomic, assign) BOOL shouldCuttingImage;  //是否需要裁剪照片 defult no
@property (nonatomic, assign) BOOL needSaveToPhotoLibrary;  //是否需要保存到裁剪相册 defult no
@property (nonatomic, weak) id<K12TakePictureControllerDelegate> delegate;
@end
