//
//  K12PictureCuttingController.m
//  TakePhoto
//
//  Created by mengkai on 15/10/10.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12PictureCuttingController.h"
#import "K12PictureCuttingView.h"
#import "Masonry.h"
#import "UIImage+Orientation.h"

@implementation K12PictureCuttingController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image{
    if(self = [super init]){
        _image = image;
        _onFinishedShouldDismiss = YES;
    }
    return self;
}

- (void)dealloc{
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:16/255.0 green:32/255.0 blue:42/255.0 alpha:1.0];
    
    //图片裁剪视图
    K12PictureCuttingView *cropView = [[K12PictureCuttingView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-90)];
    [cropView setCuttingImage:_image];
    [self.view addSubview:cropView];
    cropView.backgroundColor = [UIColor colorWithRed:16/255.0*3.52 green:32/255.0*3.52 blue:42/255.0*3.52 alpha:1.0];
    //cropView.cuttingInset = UIEdgeInsetsMake(20, 20, 20, 20);
    cropView.defultCorpInset = UIEdgeInsetsMake(0, 50, 0, 50);
    _pictureCuttingView = cropView;
    
    //确认按钮
    UIImage *actionImage = [UIImage imageNamed:@"k12_mistaken_finishCutting"];
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
    actionButton.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    //关闭按钮
    UIImage *closeImage = [UIImage imageNamed:@"k12_mistaken_closeCutting"];
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
    closeButton.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    //旋转按钮
    UIImage *rotateImage = [UIImage imageNamed:@"k12_mistaken_cuttingRotation"];
    UIButton *rotateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rotateButton setImage:rotateImage forState:UIControlStateNormal];
    [self.view addSubview:rotateButton];
    [rotateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(15);
        make.centerY.equalTo(actionButton.mas_centerY);
        make.width.equalTo(@(rotateImage.size.width));
        make.height.equalTo(@(rotateImage.size.height));
    }];
    [rotateButton addTarget:self action:@selector(doTapRotateButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    rotateButton.transform = CGAffineTransformMakeRotation(M_PI_2);
}

- (void)doTapActionButtonAction:(UIButton *)sender{
    UIImage *image = [_pictureCuttingView beginCuttingImage];
    K12ImageOrientation orientation = K12ImageOrientationPortrait;
    switch (_pictureCuttingView.cuttingOrientation) {
        case K12PictureCuttingOrientationPortrait:
            orientation = K12ImageOrientationLandscapeLeft;
            break;
        case K12PictureCuttingOrientationLandscapeLeft:
            orientation = K12ImageOrientationPortrait;
            break;
        case K12PictureCuttingOrientationPortraitUpsideDown:
            orientation = K12ImageOrientationLandscapeRight;
            break;
        case K12PictureCuttingOrientationLandscapeRight:
            orientation = K12ImageOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
    image = [image reviseImageWithOrientation:orientation];
    if(self.onFinishedShouldDismiss){
        [self dismissViewControllerWithCompletion:^{
            if(self.delegate && [self.delegate respondsToSelector:@selector(pictureCuttingController:didCuttingImage:)]){
                [self.delegate pictureCuttingController:self didCuttingImage:image];
            }
        }];
    }else{
        if(self.delegate && [self.delegate respondsToSelector:@selector(pictureCuttingController:didCuttingImage:)]){
            [self.delegate pictureCuttingController:self didCuttingImage:image];
        }
    }
}

- (void)doTapCloseButtonAction:(UIButton *)sender{
    [self dismissViewControllerWithCompletion:NULL];
}

- (void)doTapRotateButtonAction:(UIButton *)sender{
    _pictureCuttingView.cuttingOrientation = [self nextOrientationWithOrientation:_pictureCuttingView.cuttingOrientation];
}

- (K12PictureCuttingOrientation)nextOrientationWithOrientation:(K12PictureCuttingOrientation)orientation{
    K12PictureCuttingOrientation newOrientation = K12PictureCuttingOrientationPortrait;
    switch (orientation) {
        case K12PictureCuttingOrientationPortrait:
            newOrientation = K12PictureCuttingOrientationLandscapeLeft;
            break;
        case K12PictureCuttingOrientationLandscapeLeft:
            newOrientation = K12PictureCuttingOrientationPortraitUpsideDown;
            break;
        case K12PictureCuttingOrientationPortraitUpsideDown:
            newOrientation = K12PictureCuttingOrientationLandscapeRight;
        default:
            break;
    }
    return newOrientation;
}

- (void)dismissViewControllerWithCompletion:(void (^ __nullable)(void))completion{
    if(self.presentingViewController){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:completion];
    }else if(self.navigationController){
        if(self.navigationController.presentingViewController){
            [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:completion];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
            if(completion) completion();
        }
    }
}

- (BOOL)shouldAutorotate{
    return YES;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation{
    return UIStatusBarAnimationFade;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

@end