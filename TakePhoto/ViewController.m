//
//  ViewController.m
//  TakePhoto
//
//  Created by mengkai on 15/9/23.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "ViewController.h"
@import AVFoundation;
@import AssetsLibrary;
@import Photos;
#import "ViewController1.h"
#import "ViewController2.h"
#import "K12TakePictureController.h"
#import "K12OfflineMistakenWriteController.h"
#import "K12OfflineMistakenProductionControllew.h"

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (IBAction)start:(UIButton *)sender {
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined){
        NSLog(@"PHAuthorizationStatusNotDetermined");
    }else if(status == PHAuthorizationStatusRestricted){
        NSLog(@"PHAuthorizationStatusRestricted");
    }else if(status == PHAuthorizationStatusDenied){
        NSLog(@"PHAuthorizationStatusDenied");
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            NSLog(@"%@",@(status).description);
        }];
        
    }else if(status == PHAuthorizationStatusAuthorized){
        NSLog(@"PHAuthorizationStatusAuthorized");
    }
    
    AVAuthorizationStatus status1 = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    NSLog(@"AVAuthorizationStatus: %@",@(status1).description);

    if(status1 == AVAuthorizationStatusDenied){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            NSLog(@"%@",@(granted).description);
        }];
    }
    
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusNotDetermined){
        NSLog(@"ALAuthorizationStatusNotDetermined");
    }else if(author == ALAuthorizationStatusRestricted){
        NSLog(@"ALAuthorizationStatusRestricted");
    }else if(author == ALAuthorizationStatusDenied){
        NSLog(@"ALAuthorizationStatusDenied");
    }else if(author == ALAuthorizationStatusAuthorized){
        NSLog(@"ALAuthorizationStatusAuthorized");
    }
    
    
    BOOL a = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    NSLog(@"UIImagePickerControllerSourceTypeCamera: 设备%@拍照",a?@"支持":@"不支持");
    a = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    NSLog(@"UIImagePickerControllerCameraDeviceRear: 设备%@后摄像头",a?@"支持":@"不支持");
    a = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
    NSLog(@"UIImagePickerControllerCameraDeviceFront: 设备%@前摄像头",a?@"支持":@"不支持");
    NSLog(@"\n\n");
    NSLog(@"%@",[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary]);
    NSLog(@"%@",[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera]);
    NSLog(@"%@",[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum]);
    NSLog(@"\n\n");
    a = [UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear];
    NSLog(@"UIImagePickerControllerCameraDeviceRear: 设备%@后摄像头",a?@"支持":@"不支持");
    a = [UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceFront];
    NSLog(@"UIImagePickerControllerCameraDeviceFront: 设备%@前摄像头",a?@"支持":@"不支持");

    NSLog(@"%@",[UIImagePickerController availableCaptureModesForCameraDevice:UIImagePickerControllerCameraDeviceRear]);
    NSLog(@"%@",[UIImagePickerController availableCaptureModesForCameraDevice:UIImagePickerControllerCameraDeviceFront]);
    
    
    
    
    __block BOOL isAvalible = NO;
    NSString *mediaType = AVMediaTypeAudio; // Or AVMediaTypeAudio
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];

    // This status is normally not visible—the AVCaptureDevice class methods for discovering devices do not return devices the user is restricted from accessing.
    if(authStatus == AVAuthorizationStatusRestricted){
        NSLog(@"Restricted");
    }
    
    // The user has explicitly denied permission for media capture.
    else if(authStatus == AVAuthorizationStatusDenied){
        NSLog(@"Denied");
        
    }
    
    // The user has explicitly granted permission for media capture, or explicit user permission is not necessary for the media type in question.
    else if(authStatus == AVAuthorizationStatusAuthorized){
        NSLog(@"Authorized");
        isAvalible = YES;
    }
    
    // Explicit user permission is required for media capture, but the user has not yet granted or denied such permission.
    else if(authStatus == AVAuthorizationStatusNotDetermined){
        
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if(granted){
                NSLog(@"Granted access to %@", mediaType);
            }
            else {
                NSLog(@"Not granted access to %@", mediaType);
            }
        }];
        
    }
    
    else {
        NSLog(@"Unknown authorization status");
    }
}

- (IBAction)startCamera:(UIButton *)sender {
    ViewController1 *ipvc = [ViewController1 new];
    ipvc.sourceType = UIImagePickerControllerSourceTypeCamera;
    //ipvc.showsCameraControls = NO;
    ipvc.allowsEditing = YES;
    ipvc.delegate = self;
    ipvc.mediaTypes = @[@"public.image"];
    
    CGSize screenBounds = [UIScreen mainScreen].bounds.size;
    CGFloat cameraAspectRatio = 4.0f/3.0f;
    CGFloat camViewHeight = screenBounds.width * cameraAspectRatio;
    CGFloat scale = screenBounds.height / camViewHeight;
    ipvc.cameraViewTransform = CGAffineTransformMakeTranslation(0, (screenBounds.height - camViewHeight) / 2.0);
    ipvc.cameraViewTransform = CGAffineTransformScale(ipvc.cameraViewTransform, scale, scale);
    
    [self presentViewController:ipvc animated:YES completion:NULL];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo NS_DEPRECATED_IOS(2_0, 3_0){
    NSLog(@"%@",editingInfo);
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSLog(@"%@",info);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    NSLog(@"cancel");
}

- (IBAction)start2:(UIButton *)sender {
    ViewController2 *viewController = [ViewController2 new];
    [self presentViewController:viewController animated:YES completion:NULL];
}
- (IBAction)start3:(UIButton *)sender {
    K12OfflineMistakenProductionControllew *viewController = [K12OfflineMistakenProductionControllew new];
    [self presentViewController:viewController animated:YES completion:NULL];

}

- (IBAction)start4:(UIButton *)sender {
    K12OfflineMistakenWriteController *VC = [K12OfflineMistakenWriteController new];
    [self presentViewController:VC animated:YES completion:NULL];
}

@end
