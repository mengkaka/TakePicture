//
//  ViewController3.m
//  TakePhoto
//
//  Created by mengkai on 15/9/25.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "ViewController3.h"
#import "K12CameraTakePictureView.h"
#import "K12PhotoLibraryController.h"
#import "Masonry.h"
#import "K12PictureCuttingController.h"

@interface ViewController3 ()<UIViewControllerTransitioningDelegate,K12PhotoLibraryControllerDelegate>
{
    K12CameraTakePictureView *_takePhotoView;
    UIButton *_actionButton;
    UIButton *_closeButton;
    UIButton *_photoLibraryButton;
    UIButton *_flashButton;
    UILabel *_textLabel;
    UILabel *_textLabel1;
    BOOL _isViewDidLoad;
}
@end

@implementation ViewController3

- (void)viewDidLoad{
    [super viewDidLoad];
    _isViewDidLoad = YES;
    self.transitioningDelegate = self;
    //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChangeAction:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    self.view.backgroundColor = [UIColor whiteColor];
    _takePhotoView = [[K12CameraTakePictureView alloc]initWithFrame:self.view.bounds];
    _takePhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_takePhotoView];
    
    //[_takePhotoView setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(cameraTakePhotoViewAmbientDidChange:) name:K12CameraTakePictureViewAmbientDidChangeNotification object:_takePhotoView];
    
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)_takePhotoView.layer;
    previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    UIImage *actionImage = [UIImage imageNamed:@"拍照_640"];
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
    
    UIImage *closeImage = [UIImage imageNamed:@"关闭_640"];
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
    
    UIImage *photoLibraryImage = [UIImage imageNamed:@"相册_640"];
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
    
    UIImage *flashImage = [UIImage imageNamed:@"手电筒_640"];
    UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [flashButton setImage:flashImage forState:UIControlStateNormal];
    [self.view addSubview:flashButton];
    [flashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(15);
        make.left.equalTo(self.view).offset(15);
        make.width.equalTo(@(flashImage.size.width));
        make.height.equalTo(@(flashImage.size.height));
    }];
    [flashButton addTarget:self action:@selector(doTapFlashButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    _flashButton = flashButton;
    
    UILabel *textLabel = [[UILabel alloc]init];
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.text = @"请横评拍照，文字与参考线平行";
    textLabel.font = [UIFont systemFontOfSize:14];
    textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    textLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    textLabel.shadowOffset = CGSizeMake(0, 0);
    textLabel.layer.shadowOpacity = 5.0;
    textLabel.layer.shadowRadius = 2;
    [self.view addSubview:textLabel];
    [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(-105);
        make.centerY.equalTo(self.view);
    }];
    textLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
    textLabel.alpha = 0.0;
    _textLabel = textLabel;
    
    UILabel *textLabel1 = [[UILabel alloc]init];
    textLabel1.backgroundColor = [UIColor clearColor];
    textLabel1.text = @"光线太暗，请开启闪光灯";
    textLabel1.font = [UIFont systemFontOfSize:14];
    textLabel1.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    textLabel1.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    textLabel1.shadowOffset = CGSizeMake(0, 0);
    textLabel1.layer.shadowOpacity = 5.0;
    textLabel1.layer.shadowRadius = 2;
    [self.view addSubview:textLabel1];
    [textLabel1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
    }];
    textLabel1.transform = CGAffineTransformMakeRotation(M_PI_2);
    textLabel1.alpha = 0.0;
    _textLabel1 = textLabel1;
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_takePhotoView startSessionRunning];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(!_isViewDidLoad){_isViewDidLoad = YES;
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
                                                  _textLabel.alpha = 1.0;
                                              }];
                                          }];
                     }];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [_takePhotoView endSessionRunning];
    
    [super viewWillDisappear:animated];
}

- (void)cameraTakePhotoViewAmbientDidChange:(NSNotification *)note{
    NSLog(@"%@",[[note.userInfo objectForKey:K12CameraTakePictureViewAmbientStatusKey] isEqualToString:K12CameraTakePictureViewAmbientStatusGloom] ? @"环境过暗":@"环境明亮");
    [UIView beginAnimations:nil context:NULL];
    if([[note.userInfo objectForKey:K12CameraTakePictureViewAmbientStatusKey] isEqualToString:K12CameraTakePictureViewAmbientStatusGloom]
       && _takePhotoView.torchMode != AVCaptureTorchModeOn){
        _textLabel1.alpha = 1.0;
    }else{
        _textLabel1.alpha = 0.0;
    }
    [UIView commitAnimations];
}

- (void)doTapCloseButtonAction:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)doTapActionButtonAction:(UIButton *)sender{
    [_takePhotoView takePictureWithCompletionHandler:^(UIImage *image) {
        [self pictureCuttingWithImage:image];
    }];
}

- (void)doTapPhotoLibraryButtonAction:(UIButton *)sender{
    K12PhotoLibraryController *plc = [[K12PhotoLibraryController alloc]init];
    plc.choiceDelegate = self;
    [self presentViewController:plc animated:YES completion:NULL];
}

- (void)doTapFlashButtonAction:(UIButton *)sender{
    static int i = 1;
    if(i == 2) i = 0;
    [_takePhotoView configurationCaptureDeviceTorchMode:i++];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)_takePhotoView.layer;
    previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)toInterfaceOrientation;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator{
    [self configurationCaptureVideoPreviewLayerOrientation];
}

- (void)deviceOrientationDidChangeAction:(NSNotification *)note{
    [self configurationCaptureVideoPreviewLayerOrientation];
}

- (void)configurationCaptureVideoPreviewLayerOrientation{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)_takePhotoView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

#pragma mark - Delegate
- (void)photoLibraryController:(K12PhotoLibraryController *)controller didConfirmImage:(UIImage *)image{
    [self pictureCuttingWithImage:image];
}

- (void)pictureCuttingWithImage:(UIImage *)image{
    K12PictureCuttingController *pictureCuttingController = [[K12PictureCuttingController alloc]initWithImage:image];
    [self presentViewController:pictureCuttingController animated:NO completion:NULL];
}

@end
