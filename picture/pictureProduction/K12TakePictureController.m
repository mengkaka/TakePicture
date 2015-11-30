//
//  K12TakePictureController.m
//  TakePhoto
//
//  Created by mengkai on 15/10/10.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12TakePictureController.h"
#import "K12PhotoLibraryController.h"
#import "K12PictureCuttingController.h"
#import "K12PictureBrowserController.h"
#import "Masonry.h"
#import "K12ImageStorage.h"
#import "UIImage+Orientation.h"

@interface K12TakePictureController()<K12PhotoLibraryControllerDelegate,K12PictureCuttingControllerDelegate,K12PictureBrowserControllerDelegate>
@end
@implementation K12TakePictureController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
        _shouldCuttingImage = NO;
        _needSaveToPhotoLibrary = NO;
        _isViewDidLoad = NO;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //主要拍照界面
    K12CameraTakePictureView *takePhotoView = [[K12CameraTakePictureView alloc]initWithFrame:self.view.bounds];
    takePhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //[takePhotoView configurationCaptureVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    [self.view addSubview:takePhotoView];
    
    //监听周围环境
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(cameraTakePhotoViewAmbientDidChange:) name:K12CameraTakePictureViewAmbientDidChangeNotification object:takePhotoView];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(cameraTakePictureViewTorchActiveDidChange:) name:K12CameraTakePictureViewTorchActiveDidChangeNotification object:takePhotoView];
    _takePhotoView = takePhotoView;
    
    //手电筒按钮
    UIImage *flashImage = [UIImage imageNamed:@"k12_mistaken_cameraTorch_off"];
    UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [flashButton setImage:flashImage forState:UIControlStateNormal];
    [self.view addSubview:flashButton];
    [flashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0);
        make.left.equalTo(self.view).offset(0);
        make.width.equalTo(@(flashImage.size.width+30));
        make.height.equalTo(@(flashImage.size.height+30));
    }];
    [flashButton addTarget:self action:@selector(doTapFlashButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    _flashButton = flashButton;
    
    //提示旋转文案
    UILabel *cameraTips = [[UILabel alloc]init];
    cameraTips.backgroundColor = [UIColor clearColor];
    cameraTips.text = @"请横屏拍照，文字与参考线平行";
    cameraTips.font = [UIFont systemFontOfSize:14];
    cameraTips.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    cameraTips.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    cameraTips.shadowOffset = CGSizeMake(0, 2);
    cameraTips.layer.shadowOpacity = 0.2;
    cameraTips.layer.shadowRadius = 3.0;
    cameraTips.layer.shouldRasterize = YES;
    [self.view addSubview:cameraTips];
    [cameraTips mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(-105);
        make.centerY.equalTo(self.view);
    }];
    cameraTips.transform = CGAffineTransformMakeRotation(M_PI_2);
    cameraTips.alpha = 0.0;
    _cameraTips = cameraTips;
    
    //隔绝手势点击
    UIView *bottomBarView = [[UIView alloc]init];
    bottomBarView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.12];
    [self.view addSubview:bottomBarView];
    [bottomBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_bottom);
    }];
    
    //拍照按钮
    UIImage *actionImage = [UIImage imageNamed:@"k12_mistaken_takePicture"];
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton setImage:actionImage forState:UIControlStateNormal];
    [self.view addSubview:actionButton];
    [actionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view).offset(-15);
        make.width.equalTo(@(actionImage.size.width));
        make.height.equalTo(@(actionImage.size.height));
    }];
    [actionButton addTarget:self action:@selector(doTapActionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    _actionButton = actionButton;
    
    [bottomBarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(actionButton.mas_top).offset(-15);
    }];
    
    //关闭按钮
    UIImage *closeImage = [UIImage imageNamed:@"k12_mistaken_closeCamera"];
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:closeImage forState:UIControlStateNormal];
    [self.view addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-15);
        make.centerY.equalTo(actionButton.mas_centerY);
        make.width.equalTo(@(closeImage.size.width));
        make.height.equalTo(@(closeImage.size.height));
    }];
    [closeButton addTarget:self action:@selector(doTapCloseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    _closeButton = closeButton;
    
    //相册按钮
    UIImage *photoLibraryImage = [UIImage imageNamed:@"k12_mistaken_photoLibrary"];
    UIButton *photoLibraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [photoLibraryButton setImage:photoLibraryImage forState:UIControlStateNormal];
    [self.view addSubview:photoLibraryButton];
    [photoLibraryButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(15);
        make.centerY.equalTo(actionButton.mas_centerY);
        make.width.equalTo(@(photoLibraryImage.size.width));
        make.height.equalTo(@(photoLibraryImage.size.height));
    }];
    [photoLibraryButton addTarget:self action:@selector(doTapPhotoLibraryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    _photoLibraryButton = photoLibraryButton;
    
    //拍照界面没有初始化完时显示
    UIView *spaceView = [[UIView alloc]initWithFrame:self.view.bounds];
    spaceView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    spaceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:spaceView aboveSubview:cameraTips];
    _spaceView = spaceView;
    
    //检查权限,如果没有权限显示提示视图
    if(![takePhotoView checkTakePictureAuthorizationStatus]){
        UIView *notAuthorizationView = [[UIView alloc]initWithFrame:self.view.bounds];
        notAuthorizationView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        notAuthorizationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:notAuthorizationView aboveSubview:spaceView];
        _notAuthorizationView = notAuthorizationView;
        
        UIImage *image = [UIImage imageNamed:@"k12_mistaken_notCanmerAuthorization"];
        CGSize imageSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.width/image.size.width*image.size.height);
        CGRect imageViewRect = (CGRect){0,((self.view.frame.size.height-actionImage.size.height-30)-imageSize.height)/2.0,imageSize};
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:imageViewRect];
        imageView.image = image;
        [notAuthorizationView addSubview:imageView];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_takePhotoView startSessionRunning];
    [self beginButtonsAnimation];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(animated){ [UIView beginAnimations:nil context:NULL]; [UIView setAnimationDuration:0.35]; }
        _spaceView.alpha = 0.0;
        if(animated){ [UIView commitAnimations]; }
    });
}

- (void)viewDidDisappear:(BOOL)animated{
    [_takePhotoView endSessionRunning];
    _spaceView.alpha = 1.0;
    
    [super viewDidDisappear:animated];
}

#pragma mark - Action

- (void)beginButtonsAnimation{
    if(!_isViewDidLoad){
        _isViewDidLoad = YES;
        [UIView animateWithDuration:0.2
                              delay:1.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.7
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _actionButton.transform = CGAffineTransformMakeRotation(-M_PI_4);
                             _closeButton.transform = CGAffineTransformMakeRotation(-M_PI_4);
                             _photoLibraryButton.transform = CGAffineTransformMakeRotation(-M_PI_4);
                             _flashButton.transform = CGAffineTransformMakeRotation(-M_PI_4);
                         }completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.35
                                                   delay:0.0
                                  usingSpringWithDamping:0.5
                                   initialSpringVelocity:1.5
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  _actionButton.transform = CGAffineTransformMakeRotation(M_PI_2);
                                                  _closeButton.transform = CGAffineTransformMakeRotation(M_PI_2);
                                                  _photoLibraryButton.transform = CGAffineTransformMakeRotation(M_PI_2);
                                                  _flashButton.transform = CGAffineTransformMakeRotation(M_PI_2);
                                              }completion:^(BOOL finished) {
                                                  [UIView animateWithDuration:0.2 animations:^{
                                                      _cameraTips.alpha = 1.0;
                                                  }];
                                              }];
                         }];
    }
}

//监听周围光环境
- (void)cameraTakePhotoViewAmbientDidChange:(NSNotification *)note{
    [UIView beginAnimations:nil context:NULL];
    if([[note.userInfo objectForKey:K12CameraTakePictureViewAmbientStatusKey] isEqualToString:K12CameraTakePictureViewAmbientStatusGloom]
       && _takePhotoView.torchMode != AVCaptureTorchModeOn){
        _cameraTips.text = @"拍照环境太暗，请开启手电筒";
        
        UIImage *flashImage = [UIImage imageNamed:@"k12_mistaken_cameraTorch_off"];
        if([[_flashButton imageForState:UIControlStateNormal] isEqual:flashImage]){
            [self startFlashButtonAnimation];
        }
    }else{
        _cameraTips.text = @"请横屏拍照，文字与参考线平行";
        [self removeFlashButtonAnimation];
    }
    [UIView commitAnimations];
}

- (void)startFlashButtonAnimation{
    CAKeyframeAnimation *keyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    keyFrameAnimation.values = @[@1.0,@0.3,@1.0];
    keyFrameAnimation.duration = 1.0;
    keyFrameAnimation.keyTimes = @[@0.0,@0.5,@1.0];
    keyFrameAnimation.repeatCount = CGFLOAT_MAX;
    [_flashButton.layer addAnimation:keyFrameAnimation forKey:@"flashButton.keyFrameAnimation"];
}

- (void)removeFlashButtonAnimation{
    [_flashButton.layer removeAnimationForKey:@"flashButton.keyFrameAnimation"];
}

//检测手电筒开关
- (void)cameraTakePictureViewTorchActiveDidChange:(NSNotification *)note{
    NSNumber *number = [note.userInfo objectForKey:K12CameraTakePictureViewTorchActiveKey];
    BOOL active = (!number) ? NO : [number boolValue];
    if(active) [self removeFlashButtonAnimation];
    UIImage *flashImage = [UIImage imageNamed:((active)?@"k12_mistaken_cameraTorch_on":@"k12_mistaken_cameraTorch_off")];
    [_flashButton setImage:flashImage forState:UIControlStateNormal];
}

//关闭按钮
- (void)doTapCloseButtonAction:(UIButton *)sender{
    if(self.delegate && [self.delegate respondsToSelector:@selector(takePictureController:onFinshedWithImage:)]){
        [self.delegate takePictureControllerDidCancel:self];
    }
}

//拍照按钮
- (void)doTapActionButtonAction:(UIButton *)sender{
    [_takePhotoView takePictureWithCompletionHandler:^(UIImage *image) {
        if(image && self.needSaveToPhotoLibrary){
            UIImage *saveImage = [[image reviseImageOrientation] reviseImageWithOrientation:K12ImageOrientationLandscapeLeft];
            [K12ImageStorage writeImageToPhotoLibrary:saveImage completionBlock:NULL];
        }
        [self pictureCuttingWithImage:image];
    }];
}

//进入相册选照片
- (void)doTapPhotoLibraryButtonAction:(UIButton *)sender{
    K12PhotoLibraryController *plc = [[K12PhotoLibraryController alloc]init];
    plc.choiceDelegate = self;
    plc.shouldCuttingImage = self.shouldCuttingImage;
    plc.onFinishedShouldDismiss = NO;
    [self.topPresentedViewController presentViewController:plc animated:YES completion:NULL];
}

- (void)doTapFlashButtonAction:(UIButton *)sender{
    AVCaptureTorchMode torchMode = (_takePhotoView.torchMode == AVCaptureTorchModeOn)?AVCaptureTorchModeOff:AVCaptureTorchModeOn;
    [_takePhotoView configurationCaptureDeviceTorchMode:torchMode];
}

- (UIViewController *)topPresentedViewController{
    UIViewController *viewController = self;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
}

#pragma mark - Delegate
//照片库裁剪完照片回调
- (void)photoLibraryController:(K12PhotoLibraryController *)controller didCuttingImage:(UIImage *)image{
    //如果需要进行裁剪，进行回调
    if(controller.shouldCuttingImage){
        if(self.delegate && [self.delegate respondsToSelector:@selector(takePictureController:onFinshedWithImage:)]){
            [self.delegate takePictureController:self onFinshedWithImage:image];
        }
    }
}

//照片图选择完图片进行回调
- (void)photoLibraryController:(K12PhotoLibraryController *)controller didConfirmImage:(UIImage *)image{
    //如果不需要进行裁剪，直接进行回调
    if(!controller.shouldCuttingImage){
        if(self.delegate && [self.delegate respondsToSelector:@selector(takePictureController:onFinshedWithImage:)]){
            [self.delegate takePictureController:self onFinshedWithImage:image];
        }
    }
}

//拍照以后进行裁剪，裁剪图片，完成裁剪以后回调
- (void)pictureCuttingController:(K12PictureCuttingController *)controller didCuttingImage:(UIImage *)image{
    if(self.delegate && [self.delegate respondsToSelector:@selector(takePictureController:onFinshedWithImage:)]){
        [self.delegate takePictureController:self onFinshedWithImage:image];
    }
}

//拍照完成以后调用方法
- (void)pictureCuttingWithImage:(UIImage *)image{
    if(!image) return;
    if(self.shouldCuttingImage){
        K12PictureCuttingController *pictureCuttingController = [[K12PictureCuttingController alloc]initWithImage:image];
        pictureCuttingController.delegate = self;
        pictureCuttingController.onFinishedShouldDismiss = NO;
        [self.topPresentedViewController presentViewController:pictureCuttingController animated:NO completion:NULL];
    }else{
        if(self.delegate && [self.delegate respondsToSelector:@selector(takePictureController:onFinshedWithImage:)]){
            [self.delegate takePictureController:self onFinshedWithImage:image];
        }
    }
}

- (void)pictureBrowserController:(K12PictureBrowserController *)controller didConfirmImage:(UIImage *)image{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - InterfaceOrientation
- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation{
    return UIStatusBarAnimationFade;
}

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
@end
