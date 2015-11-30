//
//  K12OfflineMistakenProductionControllew.m
//  TakePhoto
//
//  Created by mengkai on 15/10/20.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12OfflineMistakenProductionControllew.h"
#include <unicode/utf8.h>

static CGFloat imageMaxCompressionSize = 1024*1024;

@implementation K12OfflineMistakenProductionControllew
static NSString *removeEmojiWithString(NSString *string){
    NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if(!d) return nil;
    const char *buf = d.bytes;
    unsigned int len = (unsigned int)[d length];
    char *s = (char *)malloc(len);
    unsigned int ii = 0, oi = 0; // in index, out index
    UChar32 uc;
    while (ii < len) {
        U8_NEXT_UNSAFE(buf, ii, uc);
        if(0x2100 <= uc && uc <= 0x26ff) continue;
        if(0x1d000 <= uc && uc <= 0x1f77f) continue;
        U8_APPEND_UNSAFE(s, oi, uc);
    }
    return [[NSString alloc] initWithBytesNoCopy:s length:oi encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
        
        _takePictureController = [[K12TakePictureController alloc]init];
        _takePictureController.shouldCuttingImage = YES;
        _takePictureController.needSaveToPhotoLibrary = YES;
        _takePictureController.delegate = self;
        
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    //self.transitioningDelegate = self;
    
    [_takePictureController willMoveToParentViewController:self];
    [self.view addSubview:_takePictureController.view];
    [self addChildViewController:_takePictureController];
    [_takePictureController didMoveToParentViewController:self];
    _currentViewController = _takePictureController;
}

#pragma mark - Delegate
//拍照界面拍照或图片选取完成
- (void)takePictureController:(K12TakePictureController *)takePictureController onFinshedWithImage:(UIImage *)image{
    if(!_offlineMistakenWriteController){
        _offlineMistakenWriteController = [[K12OfflineMistakenWriteController alloc]init];
        _offlineMistakenWriteController.delegate = self;
        _offlinMistakenNavigationController = [[UINavigationController alloc]initWithRootViewController:_offlineMistakenWriteController];
    }
    [_offlineMistakenWriteController addMistakenImage:image];
    
    [self.topPresentedViewController presentViewController:_offlinMistakenNavigationController animated:YES completion:NULL];
}

//拍照界面点击关闭
- (void)takePictureControllerDidCancel:(K12TakePictureController *)takePictureController{
    if(!_offlineMistakenWriteController){
        [self dismissViewControllerWithCompletion:NULL];
    }else{
        [self.topPresentedViewController presentViewController:_offlinMistakenNavigationController animated:YES completion:NULL];
    }
}

//要上传时回调
- (void)offlineMistakenWriteController:(K12OfflineMistakenWriteController *)controller willUploadWithSummary:(NSString *)summary withImages:(NSArray *)images{
    
}

//取消以后回调
- (void)offlineMistakenWriteControllerDidCancel:(K12OfflineMistakenWriteController *)controller{
    [self dismissViewControllerWithCompletion:NULL];
}

//继续添加照片回调
- (void)offlineMistakenWriteControllerWillAddMistakenImage:(K12OfflineMistakenWriteController *)controller{
    [_takePictureController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dismissAction:(UIViewController *)viewController withCompletion:(void (^ __nullable)(void))completion{
    UIViewController *presentingVC = viewController.presentingViewController;
    [presentingVC dismissViewControllerAnimated:YES completion:^{
        if(presentingVC.presentingViewController){
            [self dismissAction:presentingVC withCompletion:completion];
        }else{
            if(completion) completion();
        }
    }];
}

- (void)dismissViewControllerWithCompletion:(void (^ __nullable)(void))completion{
    //UIViewController *viewController = self.topPresentedViewController;
    //[self dismissAction:viewController withCompletion:completion];
    
    if(self.presentingViewController) {
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

#pragma mark - rotation

- (void)transitionToViewController:(UIViewController *)viewController{
    if(viewController != _takePictureController && viewController != _offlinMistakenNavigationController) return;
    if(viewController == _currentViewController) return;
    
    BOOL isPresent = YES;
    if(viewController == _takePictureController) isPresent = NO;
    UIViewController *fromVC = _currentViewController;
    UIViewController *toVC = viewController;
    
    [toVC willMoveToParentViewController:self];
    if(isPresent){
        toVC.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
        [self.view addSubview:toVC.view];
    }else{
        toVC.view.transform = CGAffineTransformIdentity;
        [self.view insertSubview:toVC.view belowSubview:fromVC.view];
    }
    [self addChildViewController:toVC];
    [self transitionFromViewController:fromVC toViewController:toVC duration:0.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if(isPresent){
            toVC.view.transform = CGAffineTransformIdentity;
        }else{
            toVC.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
        }
    } completion:^(BOOL finished) {
        [fromVC.view removeFromSuperview];
        [fromVC removeFromParentViewController];
        _currentViewController = toVC;
        [toVC didMoveToParentViewController:self];
    }];
}

- (UIViewController *)topPresentedViewController{
    UIViewController *viewController = self;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
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

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation{
    return [_takePictureController preferredStatusBarUpdateAnimation];
}

- (BOOL)prefersStatusBarHidden{
    return [_takePictureController prefersStatusBarHidden];
}
@end
