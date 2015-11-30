//
//  K12CameraView.h
//  TakePhoto
//
//  Created by mengkai on 15/9/25.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "K12CameraFocusViewControl.h"
#import "K12CameraZoomViewControl.h"
#import "K12CameraRulerView.h"
@import AVFoundation;
@import AssetsLibrary;

//检测周围环境通知,如果环境过暗应该提醒用户打开手电筒
extern NSString * const K12CameraTakePictureViewAmbientDidChangeNotification;
extern NSString * const K12CameraTakePictureViewAmbientStatusKey;
extern NSString * const K12CameraTakePictureViewAmbientStatusGloom;
extern NSString * const K12CameraTakePictureViewAmbientStatusBrightness;

//手电筒开关通知
extern NSString * const K12CameraTakePictureViewTorchActiveDidChangeNotification;
extern NSString * const K12CameraTakePictureViewTorchActiveKey;

@interface K12CameraTakePictureView : UIView
{
    //用户对焦方式枚举
    NS_ENUM( NSInteger, K12CaptureDeviceFocusType) {
        K12CaptureDeviceFocusTypeNone,      //自动连续对焦
        K12CaptureDeviceFocusTypeFocus,     //手动对焦
        K12CaptureDeviceFocusTypeLockFocus  //手动对焦并锁定
    } _captureDeviceFocusType;
    
    //配置照相机结果
    NS_ENUM( NSInteger, K12CamSetupResult ) {
        K12CamSetupResultUnkown,
        K12CamSetupResultSuccess,
        K12CamSetupResultSessionConfigurationFailed
    } _setupResult;
    
    UIView *_gestureRecognizeView; //识别点击、缩放等手势
    
    dispatch_queue_t _sessionQueue;
    dispatch_queue_t _videoDataOutputQueue;
    K12CameraRulerView  *_camerRulerView;                 //拍照时的标尺线
    K12CameraFocusViewControl *_cameraFocusViewControl;   //点击对焦/自动曝光
    K12CameraZoomViewControl *_cameraZoomViewControl;     //镜头远近控制
    
    NS_ENUM(NSInteger, K12CaptureDeviceAmbientStatus){
        K12CaptureDeviceAmbientStatusBrightness, //环境明亮
        K12CaptureDeviceAmbientStatusGloom       //环境昏暗
    }_captureDeviceAmbientStatus; //当前设备环境记录
    
    CFTimeInterval _ambientChangeTimestamp; //记录设备环境改变时使用的时间戳
    
    AVCaptureDeviceInput *_videoDeviceInput;
    AVCaptureStillImageOutput *_stillImageOutput;
    AVCaptureVideoDataOutput *_videoDataOutput; //使用sampleBuffer检测环境光
    AVCaptureVideoOrientation _captureVideoOrientation;
}

@property (nonatomic, readonly) AVCaptureSession *session;
@property (nonatomic, readonly) AVCaptureFlashMode flashMode;   //当前摄像头的闪光灯模式
@property (nonatomic, readonly) AVCaptureTorchMode torchMode;   //当前摄像头的手电筒模式

- (BOOL)checkTakePictureAuthorizationStatus; //查看是否有相机权限
- (void)configurationCaptureVideoOrientation:(AVCaptureVideoOrientation)orientation; //配置图像采集方向
- (void)configurationCaptureDeviceFlashMode:(AVCaptureFlashMode)flashMode;  //设置当前摄像头的闪光灯模式
- (void)configurationCaptureDeviceTorchMode:(AVCaptureTorchMode)torchMode;  //设置当前摄像头的手电筒模式

- (void)startSessionRunning;
- (void)endSessionRunning;
- (BOOL)isSessionRunning;

- (void)takePictureWithCompletionHandler:(void(^)(UIImage *image))handler;

@end
