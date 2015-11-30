//
//  K12CameraView.m
//  TakePhoto
//
//  Created by mengkai on 15/9/25.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12CameraTakePictureView.h"
#import "K12ImageLuminance.h"
#import <Photos/Photos.h>
@import CoreImage;

@interface K12CameraTakePictureView()<K12FocusViewControlDelegate,K12CameraZoomViewControlDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@end

NSString * const K12CameraTakePictureViewAmbientDidChangeNotification = @"K12.CameraTakePictureView.AmbientDidChange.Notification";
NSString * const K12CameraTakePictureViewAmbientStatusKey = @"K12.CameraTakePictureView.AmbientStatus.Key";
NSString * const K12CameraTakePictureViewAmbientStatusGloom = @"K12.CameraTakePictureView.AmbientStatus.Gloom";
NSString * const K12CameraTakePictureViewAmbientStatusBrightness = @"K12.CameraTakePictureView.AmbientStatus.Brightness";

NSString * const K12CameraTakePictureViewTorchActiveDidChangeNotification = @"K12.CameraTakePictureView.TorchActiveDidChange.Notification";
NSString * const K12CameraTakePictureViewTorchActiveKey = @"K12.CameraTakePictureView.TorchActive.Key";

static void * K12CapturingStillImageContext = &K12CapturingStillImageContext;
static void * K12SessionRunningContext = &K12SessionRunningContext;
static void * K12CaptureDeviceFocusPointOfInterest = &K12CaptureDeviceFocusPointOfInterest;
static void * K12CaptureDeviceFocusMode = &K12CaptureDeviceFocusMode;
static void * K12CaptureDeviceAjustingFocus = &K12CaptureDeviceAjustingFocus;
static void * K12CaptureDeviceFlashActive = &K12CaptureDeviceFlashActive;
static void * K12CaptureDeviceTorchActive = &K12CaptureDeviceTorchActive;

static CGFloat const K12ImageLuminanceThreshold = 0.15;

@implementation K12CameraTakePictureView
+ (Class)layerClass{
    return [AVCaptureVideoPreviewLayer class];
}
- (AVCaptureSession *)session{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
}
- (void)setSession:(AVCaptureSession *)session{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.session = session;
}

#pragma mark - getter
- (dispatch_queue_t)sessionQueue{
    return _sessionQueue;
}

- (dispatch_queue_t)videoDataOutputQueue{
    return _videoDataOutputQueue;
}

- (AVCaptureFlashMode)flashMode{
    if(_setupResult == K12CamSetupResultSuccess){
        __block AVCaptureDevice *device = nil;
        dispatch_sync(self.sessionQueue, ^{
            device = _videoDeviceInput.device;
        });
        if(device) return device.flashMode;
    }
    return AVCaptureFlashModeOff;
}

- (AVCaptureTorchMode)torchMode{
    if(_setupResult == K12CamSetupResultSuccess){
        __block AVCaptureDevice *device = nil;
        dispatch_sync(self.sessionQueue, ^{
            device = _videoDeviceInput.device;
        });
        if(device) return device.torchMode;
    }
    return AVCaptureTorchModeOff;
}

- (void)dealloc{
    if([self isSessionRunning]){
        if(_setupResult == K12CamSetupResultSuccess){
            [self.session stopRunning];
            [self removeFlashObserverWithCaptureDevice];
            [self removeFocusObserverWithCaptureDevice];
            [self removeTorchObserverWithCaptureDevice];
            [self removeGeneralObservers];
        }
    }
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        //创建图像捕捉环境
        _sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
        _videoDataOutputQueue = dispatch_queue_create( "video data output queue", DISPATCH_QUEUE_CONCURRENT);
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        self.session = session;
        _captureVideoOrientation = AVCaptureVideoOrientationPortrait;
        _captureDeviceFocusType = K12CaptureDeviceFocusTypeNone;
        _captureDeviceAmbientStatus = K12CaptureDeviceAmbientStatusBrightness;
        _ambientChangeTimestamp = 0;
        _setupResult = K12CamSetupResultUnkown;
        
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        K12CameraRulerView *camerRulerView = [[K12CameraRulerView alloc]initWithFrame:self.bounds];
        camerRulerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:camerRulerView];
        _camerRulerView = camerRulerView;
        
        //识别各种手势的视图
        UIView *gestureRecognizeView = [[UIView alloc]initWithFrame:self.bounds];
        gestureRecognizeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        gestureRecognizeView.backgroundColor = [UIColor clearColor];
        [self addSubview:gestureRecognizeView];
        _gestureRecognizeView = gestureRecognizeView;
        
        //创建聚焦和曝光层
        K12CameraFocusViewControl *cameraFocusViewControl = [K12CameraFocusViewControl focusViewControlWithView:gestureRecognizeView];
        cameraFocusViewControl.delegate = self;
        _cameraFocusViewControl = cameraFocusViewControl;
        
        //远近镜头控制
        K12CameraZoomViewControl *cameraZoomViewControl = [K12CameraZoomViewControl zoomViewControlWithView:gestureRecognizeView];
        cameraZoomViewControl.delegate = self;
        _cameraZoomViewControl = cameraZoomViewControl;
        
        [self configurationCaptureSession];
    }
    return self;
}

#pragma mark - 配置选项
//配置基本信息
- (void)configurationCaptureSession{
    //子线程配置摄像头权限，可以让进入界面更快一点
    dispatch_async( self.sessionQueue, ^{
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [self.class configurationVideoDeviceInputWithPreferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if ( ! videoDeviceInput ) {
            _setupResult = K12CamSetupResultSessionConfigurationFailed;
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        {
            if ( [self.session canAddInput:videoDeviceInput] ){
                [self.session addInput:videoDeviceInput];
                _videoDeviceInput = videoDeviceInput;
                
                //配置图像采集方向
                [self configurationCaptureVideoOrientation:_captureVideoOrientation];
            }else {
                _setupResult = K12CamSetupResultSessionConfigurationFailed;
                NSLog( @"Could not add video device input to the session" );
            }
            
            AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            if ( [self.session canAddOutput:stillImageOutput] ) {
                stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
                [self.session addOutput:stillImageOutput];
                _stillImageOutput = stillImageOutput;
            }else {
                _setupResult = K12CamSetupResultSessionConfigurationFailed;
                NSLog( @"Could not add still image output to the session" );
            }
            
            //实时监听拍摄内容，以检测环境光
            AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
            [videoDataOutput setVideoSettings:@{(__bridge id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
            [videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
            if([self.session canAddOutput:videoDataOutput]){
                [self.session addOutput:videoDataOutput];
                _videoDataOutput = videoDataOutput;
            }else{
                _setupResult = K12CamSetupResultSessionConfigurationFailed;
                NSLog( @"Could not add video data output to the session" );
            }
        }
        [self.session commitConfiguration];
        if(_setupResult == K12CamSetupResultUnkown){
            _setupResult = K12CamSetupResultSuccess;
        }
    });
}

//配置图像采集方向
- (void)configurationCaptureVideoOrientation:(AVCaptureVideoOrientation)orientation{
    @synchronized(self) {
        if(_videoDeviceInput){
            dispatch_async( dispatch_get_main_queue(), ^{
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
                previewLayer.connection.videoOrientation = orientation;
            });
        }
        _captureVideoOrientation = orientation;
    }
}

#pragma mark - 控制
- (void)startSessionRunning{
    if(_setupResult != K12CamSetupResultSessionConfigurationFailed){
        dispatch_async( self.sessionQueue, ^{
            if(_setupResult == K12CamSetupResultSuccess){
                [self addGeneralObservers];
                [self addFocusObserverWithCaptureDevice];
                [self addFlashObserverWithCaptureDevice];
                [self addTorchObserverWithCaptureDevice];
                [self.session startRunning];
                //[self performSelector:@selector(autoFocusWithFocus) withObject:nil afterDelay:1.0];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [_cameraFocusViewControl autoFocusWithFocusPoint:[(AVCaptureVideoPreviewLayer *)self.layer pointForCaptureDevicePointOfInterest:CGPointMake(0.5, 0.5)]];
                });
            }
        });
    }
}

- (void)autoFocusWithFocus{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_cameraFocusViewControl autoFocusWithFocusPoint:[(AVCaptureVideoPreviewLayer *)self.layer pointForCaptureDevicePointOfInterest:CGPointMake(0.5, 0.5)]];
    });
}

- (void)endSessionRunning{
    if(_setupResult != K12CamSetupResultSessionConfigurationFailed){
        dispatch_async( self.sessionQueue, ^{
            if(_setupResult == K12CamSetupResultSuccess){
                [self.session stopRunning];
                [self removeFlashObserverWithCaptureDevice];
                [self removeFocusObserverWithCaptureDevice];
                [self removeTorchObserverWithCaptureDevice];
                [self removeGeneralObservers];
            }
        });
    }
}

- (BOOL)isSessionRunning{
    return self.session.running;
}

- (void)takePictureWithCompletionHandler:(void(^)(UIImage *image))handler{
    if(_setupResult != K12CamSetupResultSessionConfigurationFailed){
        dispatch_async( self.sessionQueue, ^{
            if(_setupResult == K12CamSetupResultSuccess){
                AVCaptureConnection *connection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
                
                // Update the orientation on the still image output video connection before capturing.
                connection.videoOrientation = previewLayer.connection.videoOrientation;
                
                // Capture a still image.
                [_stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
                    if ( imageDataSampleBuffer ) {
                        // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                        if(handler) handler([UIImage imageWithData:imageData]);
                    }else {
                        if(handler) handler(nil);
                        NSLog( @"Could not capture still image: %@", error );
                    }
                }];
            }else{
                if(handler) handler(nil);
            }
        });
    }else{
        if(handler) handler(nil);
    }
}

#pragma mark - 对焦与曝光
- (void)addFocusObserverWithCaptureDevice{
    AVCaptureDevice *device = _videoDeviceInput.device;
    if(!device) return;
    [self removeFocusObserverWithCaptureDevice];
    
    //监听聚焦位置发生改变
    if(device.focusPointOfInterestSupported){
        [device addObserver:self forKeyPath:@"focusPointOfInterest" options:NSKeyValueObservingOptionNew context:K12CaptureDeviceFocusPointOfInterest];
        [device addObserver:self forKeyPath:@"focusMode" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:K12CaptureDeviceFocusMode];
    }
    if(device.autoFocusRangeRestrictionSupported){
        [device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:K12CaptureDeviceAjustingFocus];
    }
    
    //监听照射区域发生变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:_videoDeviceInput.device];
}

- (void)removeFocusObserverWithCaptureDevice{
    AVCaptureDevice *device = _videoDeviceInput.device;
    if(!device) return;
    
    //取消监听聚焦位置发生改变
    @try {
        if(device.focusPointOfInterestSupported){
            [device removeObserver:self forKeyPath:@"focusPointOfInterest" context:K12CaptureDeviceFocusPointOfInterest];
        }
        [device removeObserver:self forKeyPath:@"focusMode" context:K12CaptureDeviceFocusMode];
        if(device.autoFocusRangeRestrictionSupported){
            [device removeObserver:self forKeyPath:@"adjustingFocus" context:K12CaptureDeviceAjustingFocus];
        }
    }@catch (NSException *exception) {}
    
    //监听照射区域发生变化
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:_videoDeviceInput.device];
}

- (void)cameraFocusViewControl:(K12CameraFocusViewControl *)focusViewControl userWillFocussingPoint:(CGPoint)point{
    point = [(AVCaptureVideoPreviewLayer *)self.layer captureDevicePointOfInterestForPoint:point];
    _captureDeviceFocusType = K12CaptureDeviceFocusTypeFocus;
    [self configurationAutoFocusWithCaptureFocusMode:AVCaptureFocusModeAutoFocus andCGPoint:point];
    [self configurationAutoExposureWithCaptureExposureMode:AVCaptureExposureModeContinuousAutoExposure andCGPoint:point];
}

- (void)cameraFocusViewControl:(K12CameraFocusViewControl *)focusViewControl userWillLockFocusPoint:(CGPoint)point{
    point = [(AVCaptureVideoPreviewLayer *)self.layer captureDevicePointOfInterestForPoint:point];
    _captureDeviceFocusType = K12CaptureDeviceFocusTypeLockFocus;
    [self configurationAutoFocusWithCaptureFocusMode:AVCaptureFocusModeAutoFocus andCGPoint:point];
    [self configurationAutoExposureWithCaptureExposureMode:AVCaptureExposureModeAutoExpose andCGPoint:point];
}

//根据AVCaptureFocusMode确认是否打开subjectAreaChangeMonitoringEnabled
- (void)observeValueForAVCaptureDeviceFocusModeOfchange:(NSDictionary *)change{
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    if(![newValue isEqual:change[NSKeyValueChangeOldKey]]){
        AVCaptureFocusMode mode = (AVCaptureFocusMode)[newValue integerValue];
        BOOL subjectAreaChangeMonitoringEnabled = (mode == AVCaptureFocusModeContinuousAutoFocus || mode == AVCaptureFocusModeAutoFocus)?NO:YES;
        dispatch_async( self.sessionQueue, ^{
            AVCaptureDevice *device = _videoDeviceInput.device;
            if(device.subjectAreaChangeMonitoringEnabled == subjectAreaChangeMonitoringEnabled) return;
            NSError *error = nil;
            if ( [device lockForConfiguration:&error] ) {
                device.subjectAreaChangeMonitoringEnabled = subjectAreaChangeMonitoringEnabled;
                [device unlockForConfiguration];
            }
            else {
                NSLog( @"Could not lock device for configuration: %@", error );
            }
        });
    }
}

//摄像头对焦前和对焦后的监听
- (void)observeValueForAVCaptureDeviceAjustingFocusOfchange:(NSDictionary *)change{
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    if(![newValue isEqual:change[NSKeyValueChangeOldKey]]){
        if(_captureDeviceFocusType == K12CaptureDeviceFocusTypeNone){
            if(![newValue boolValue]) return;
            
            AVCaptureDevice *device = _videoDeviceInput.device;
            if(device.isFocusPointOfInterestSupported){
                __block CGPoint point = device.focusPointOfInterest;
                dispatch_async(dispatch_get_main_queue(), ^{
                    point = [(AVCaptureVideoPreviewLayer *)self.layer pointForCaptureDevicePointOfInterest:point];
                    [_cameraFocusViewControl autoFocusWithFocusPoint:point];
                });
            }
        }else if(_captureDeviceFocusType == K12CaptureDeviceFocusTypeFocus){
            if([newValue boolValue]) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_cameraFocusViewControl userFocussingDidSucceed];
            });
        }else if(_captureDeviceFocusType == K12CaptureDeviceFocusTypeLockFocus){
            if([newValue boolValue]) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_cameraFocusViewControl userLockFocusDidSucceed];
            });
        }
    }
}

- (void)subjectAreaDidChange:(NSNotification *)note{
    if(_captureDeviceFocusType == K12CaptureDeviceFocusTypeFocus){
        _captureDeviceFocusType = K12CaptureDeviceFocusTypeNone;
        [self configurationAutoFocusWithCaptureFocusMode:AVCaptureFocusModeContinuousAutoFocus andCGPoint:CGPointMake(0.5, 0.5)];
        [self configurationAutoExposureWithCaptureExposureMode:AVCaptureExposureModeContinuousAutoExposure andCGPoint:CGPointMake(0.5, 0.5)];
        [_cameraFocusViewControl autoFocusWithFocusPoint:[(AVCaptureVideoPreviewLayer *)self.layer pointForCaptureDevicePointOfInterest:CGPointMake(0.5, 0.5)]];
    }
}

//设置自动聚焦
- (void)configurationAutoFocusWithCaptureFocusMode:(AVCaptureFocusMode)focusMode andCGPoint:(CGPoint)point{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = _videoDeviceInput.device;
        
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                if (device.focusMode == focusMode) return;
                
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            /*if(device.smoothAutoFocusSupported){
             device.smoothAutoFocusEnabled = YES;
             }*/
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    });
}

//设置自动曝光
- (void)configurationAutoExposureWithCaptureExposureMode:(AVCaptureExposureMode)exposureMode andCGPoint:(CGPoint)point{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = _videoDeviceInput.device;
        
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                if (device.exposureMode == exposureMode) return;
                
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    });
}

#pragma mark - 远近焦距
- (void)cameraZoomView:(K12CameraZoomViewControl *)cameraZoomView userDidZoomWithFactor:(CGFloat)factor{
    [self configurationCaptureDeviceVideoZoomFactorWithFactor:factor];
}

//设置远近焦距
- (void)configurationCaptureDeviceVideoZoomFactorWithFactor:(CGFloat)factor{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = _videoDeviceInput.device;
        CGFloat factor1 = MIN(MAX(factor, 0.0),1.0);
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            //AVCaptureDeviceFormat *deviceFormat = device.activeFormat;//videoZoomFactorUpscaleThreshold//videoMaxZoomFactor
            CGFloat minValue = 1.0;
            CGFloat maxValue = 5.0;
            device.videoZoomFactor = minValue+(maxValue-minValue)*factor1;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    });
}

#pragma mark - 闪光灯
- (void)addFlashObserverWithCaptureDevice{
    AVCaptureDevice *device = _videoDeviceInput.device;
    if(!device) return;
    [self removeFlashObserverWithCaptureDevice];
    
    //监听拍照时是否打开闪光灯
    if(device.hasFlash){
        [device addObserver:self forKeyPath:@"flashActive" options:NSKeyValueObservingOptionNew context:K12CaptureDeviceFlashActive];
    }
}

- (void)removeFlashObserverWithCaptureDevice{
    AVCaptureDevice *device = _videoDeviceInput.device;
    if(!device) return;
    
    //取消监听拍照时是否打开闪光灯
    @try {
        if(device.hasFlash){
            [device removeObserver:self forKeyPath:@"flashActive" context:K12CaptureDeviceFlashActive];
        }
    }@catch (NSException *exception) {}
}

- (void)configurationCaptureDeviceFlashMode:(AVCaptureFlashMode)flashMode{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = _videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if(device.hasFlash && device.flashAvailable && [device isFlashModeSupported:flashMode]){
                device.flashMode = flashMode;
            }
            [device unlockForConfiguration];
        }else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    });
}

//监听拍照时是否打开闪光灯
- (void)observeValueForAVCaptureDeviceFlashActiveOfchange:(NSDictionary *)change{
    //BOOL flashActive = [change[NSKeyValueChangeNewKey] boolValue];
    //[[NSNotificationCenter defaultCenter]postNotificationName:K12CameraTakePictureViewAmbientDidChangeNotification object:self userInfo:@{K12CameraCameraTakePictureViewAmbientStatusKey:(flashActive?K12CameraTakePictureViewAmbientStatusGloom:K12CameraTakePictureViewAmbientStatusBrightness)}];
}

#pragma mark - 手电筒
- (void)addTorchObserverWithCaptureDevice{
    AVCaptureDevice *device = _videoDeviceInput.device;
    if(!device) return;
    [self removeTorchObserverWithCaptureDevice];
    
    //监听拍照时是否打开闪光灯
    if(device.hasFlash){
        [device addObserver:self forKeyPath:@"torchMode" options:NSKeyValueObservingOptionNew context:K12CaptureDeviceTorchActive];
    }
}

- (void)removeTorchObserverWithCaptureDevice{
    AVCaptureDevice *device = _videoDeviceInput.device;
    if(!device) return;
    
    //取消监听拍照时是否打开闪光灯
    @try {
        if(device.hasFlash){
            [device removeObserver:self forKeyPath:@"torchMode" context:K12CaptureDeviceTorchActive];
        }
    }@catch (NSException *exception) {}
}

- (void)configurationCaptureDeviceTorchMode:(AVCaptureTorchMode)torchMode{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = _videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if(device.hasTorch && device.torchAvailable && [device isTorchModeSupported:torchMode]){
                device.torchMode = torchMode;
            }
            [device unlockForConfiguration];
        }else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    });
}

- (void)observeValueForAVCaptureDeviceTorchActiveOfchange:(NSDictionary *)change{
    if(![change[NSKeyValueChangeOldKey] isEqualToValue:change[NSKeyValueChangeNewKey]]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]postNotificationName:K12CameraTakePictureViewTorchActiveDidChangeNotification object:self userInfo:@{K12CameraTakePictureViewTorchActiveKey:(change[NSKeyValueChangeNewKey])?:@NO}];
        });
    }
}

#pragma mark - 检测环境光发生变化
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //计算图片的明暗度决定当前设备环境，
    //连续3S明暗度<K12ImageLuminanceThreshold视为当前环境较暗，反之；
    double luminance = [K12ImageLuminance luminanceWithCMSampleBuffer:sampleBuffer];
    //NSLog(@"image luminance: %@",@(luminance).stringValue);
    if(_captureDeviceAmbientStatus == K12CaptureDeviceAmbientStatusBrightness){
        if(luminance >= K12ImageLuminanceThreshold){
            _ambientChangeTimestamp = 0;
        }else{
            if(_ambientChangeTimestamp == 0){
                _ambientChangeTimestamp = CFAbsoluteTimeGetCurrent();
            }else if(_ambientChangeTimestamp > 0 && (CFAbsoluteTimeGetCurrent() - _ambientChangeTimestamp) > 1.5){
                _ambientChangeTimestamp = 0;
                _captureDeviceAmbientStatus = K12CaptureDeviceAmbientStatusGloom;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]postNotificationName:K12CameraTakePictureViewAmbientDidChangeNotification object:self userInfo:@{K12CameraTakePictureViewAmbientStatusKey:K12CameraTakePictureViewAmbientStatusGloom}];
                });
            }
        }
    }else if(_captureDeviceAmbientStatus == K12CaptureDeviceAmbientStatusGloom){
        if(luminance < K12ImageLuminanceThreshold){
            _ambientChangeTimestamp = 0;
        }else{
            if(_ambientChangeTimestamp == 0){
                _ambientChangeTimestamp = CFAbsoluteTimeGetCurrent();
            }else if(_ambientChangeTimestamp > 0 && (CFAbsoluteTimeGetCurrent() - _ambientChangeTimestamp) > 1.5){
                _ambientChangeTimestamp = 0;
                _captureDeviceAmbientStatus = K12CaptureDeviceAmbientStatusBrightness;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]postNotificationName:K12CameraTakePictureViewAmbientDidChangeNotification object:self userInfo:@{K12CameraTakePictureViewAmbientStatusKey:K12CameraTakePictureViewAmbientStatusBrightness}];
                });
            }
        }
    }
    
    
}

#pragma mark - kvo
- (void)addGeneralObservers{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:K12SessionRunningContext];
    [_stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:K12CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
}

- (void)removeGeneralObservers{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    @try {
        [self.session removeObserver:self forKeyPath:@"running" context:K12SessionRunningContext];
        [_stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:K12CapturingStillImageContext];
    }@catch (NSException *exception) { }
}

- (void)sessionRuntimeError:(NSNotification *)note{
    NSError *error = note.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
            }
        } );
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if(context == K12SessionRunningContext){
        
    }else if(context == K12CapturingStillImageContext){
        [self observeValueForAVCapturingStillImageOfchange:change];
    }else if(context == K12CaptureDeviceFocusPointOfInterest){
        
    }else if(context == K12CaptureDeviceFocusMode){
        [self observeValueForAVCaptureDeviceFocusModeOfchange:change];
    }else if(context == K12CaptureDeviceAjustingFocus){
        [self observeValueForAVCaptureDeviceAjustingFocusOfchange:change];
    }else if(context == K12CaptureDeviceFlashActive){
        [self observeValueForAVCaptureDeviceFlashActiveOfchange:change];
    }else if(context == K12CaptureDeviceTorchActive){
        [self observeValueForAVCaptureDeviceTorchActiveOfchange:change];
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

//session进行拍照监听
- (void)observeValueForAVCapturingStillImageOfchange:(NSDictionary *)change{
    BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
    if ( isCapturingStillImage ) {
        dispatch_async( dispatch_get_main_queue(), ^{
            self.layer.opacity = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                self.layer.opacity = 1.0;
            }];
        } );
    }
}

#pragma mark - 权限
- (BOOL)checkTakePictureAuthorizationStatus{
    __block BOOL result = NO;
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] ){
        case AVAuthorizationStatusAuthorized:{
            result = YES;
            break;
        }
        case AVAuthorizationStatusNotDetermined:{
            dispatch_suspend( self.sessionQueue );
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if (granted) {
                    result = YES;
                }
                dispatch_semaphore_signal(semaphore);
                dispatch_resume(self.sessionQueue);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            break;
        }
        default:{
            break;
        }
    }
    return result;
}

#pragma mark - 工具
+ (AVCaptureDevice *)configurationVideoDeviceInputWithPreferringPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = devices.firstObject;
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

@end
