//
//  K12PhotoLibraryController.m
//  TakePhoto
//
//  Created by mengkai on 15/10/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12PhotoLibraryController.h"
#import "K12PictureBrowserController.h"
#import "K12PictureCuttingController.h"
#import "UIImage+Orientation.h"

@interface K12PhotoLibraryController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,K12PictureBrowserControllerDelegate,K12PictureCuttingControllerDelegate,UIViewControllerTransitioningDelegate>
@end

@implementation K12PhotoLibraryController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
        _shouldCuttingImage = NO;
        _onFinishedShouldDismiss = YES;
        
        self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.delegate = self;
        self.mediaTypes = @[@"public.image"];
        //self.allowsEditing = YES;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
}

#pragma mark - rotation

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    K12PictureBrowserController *imageBrowser = [[K12PictureBrowserController alloc]initWithImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    imageBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController)];
    imageBrowser.delegate = self;
    [self pushViewController:imageBrowser animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerWithCompletion:NULL];
}

- (void)dismissViewController{
    [self dismissViewControllerWithCompletion:NULL];
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

- (void)pictureBrowserController:(K12PictureBrowserController *)controller didConfirmImage:(UIImage *)image{
    //不需要裁剪,dismiss后回调
    if(!self.shouldCuttingImage){
        if(self.onFinishedShouldDismiss){
            [self dismissViewControllerWithCompletion:^{
                if(_choiceDelegate && [_choiceDelegate respondsToSelector:@selector(photoLibraryController:didConfirmImage:)]){
                    [_choiceDelegate photoLibraryController:self didConfirmImage:image];
                }
            }];
        }else{
            if(_choiceDelegate && [_choiceDelegate respondsToSelector:@selector(photoLibraryController:didConfirmImage:)]){
                [_choiceDelegate photoLibraryController:self didConfirmImage:image];
            }
        }
        //需要裁剪，先回调，在进行裁剪
    }else{
        if(_choiceDelegate && [_choiceDelegate respondsToSelector:@selector(photoLibraryController:didConfirmImage:)]){
            [_choiceDelegate photoLibraryController:self didConfirmImage:image];
        }
        
        image = [[image reviseImageOrientation]reviseImageWithOrientation:K12ImageOrientationLandscapeRight];
        K12PictureCuttingController *pictureCuttingController = [[K12PictureCuttingController alloc]initWithImage:image];
        pictureCuttingController.onFinishedShouldDismiss = NO;
        pictureCuttingController.delegate = self;
        [self presentViewController:pictureCuttingController animated:YES completion:NULL];
    }
}

#pragma mark - Delegate
- (void)pictureCuttingController:(K12PictureCuttingController *)controller didCuttingImage:(UIImage *)image{
    if(self.onFinishedShouldDismiss){
        [self dismissViewControllerWithCompletion:^{
            if(_choiceDelegate && [_choiceDelegate respondsToSelector:@selector(photoLibraryController:didCuttingImage:)]){
                [_choiceDelegate photoLibraryController:self didCuttingImage:image];
            }
        }];
    }else{
        if(_choiceDelegate && [_choiceDelegate respondsToSelector:@selector(photoLibraryController:didCuttingImage:)]){
            [_choiceDelegate photoLibraryController:self didCuttingImage:image];
        }
    }
}
@end
