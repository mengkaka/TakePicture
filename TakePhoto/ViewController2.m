//
//  ViewController2.m
//  TakePhoto
//
//  Created by mengkai on 15/9/24.
//  Copyright © 2015年 baidu. All rights reserved.
//

/*
 Locked 指镜片处于固定位置
 AutoFocus 指一开始相机会先自动对焦一次，然后便处于 Locked 模式。
 ContinuousAutoFocus 指当场景改变，相机会自动重新对焦到画面的中心点。
 
 锁定对焦以后才能打开自动曝光，平时曝光是默认状态
 */

#import "ViewController2.h"
#import "K12CameraFocusView.h"
@import AVFoundation;

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

typedef NS_ENUM( NSInteger, K12CaptureDeviceFocusType) {
    K12CaptureDeviceFocusTypeNone,      //自动连续对焦
    K12CaptureDeviceFocusTypeFocus,     //手动对焦
    K12CaptureDeviceFocusTypeLockFocus  //手动对焦并锁定
};

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;
static void * AVCaptureDeviceFocusPointOfInterest = &AVCaptureDeviceFocusPointOfInterest;
static void * AVCaptureDeviceFocusMode = &AVCaptureDeviceFocusMode;
static void * AVCaptureDeviceaaAjustingFocus = &AVCaptureDeviceaaAjustingFocus;

@interface ViewController2 ()<K12CameraFocusViewDelegate>
@property (nonatomic, weak) ViewControllerView *previewView;
@property (nonatomic, weak) K12CameraFocusView *cameraFocusView;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic) K12CaptureDeviceFocusType captureDeviceFocusType;
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@end

@implementation ViewController2
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
        self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
        self.session = [[AVCaptureSession alloc] init];
        self.setupResult = AVCamSetupResultSuccess;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    //创建渲染视图
    ViewControllerView *previewView = [[ViewControllerView alloc]initWithFrame:self.view.bounds];
    previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:previewView];
    self.previewView = previewView;
    
    self.previewView.session = self.session;
    
    //创建聚焦和曝光层
    K12CameraFocusView *cameraFocusView = [[K12CameraFocusView alloc]initWithFrame:self.view.bounds];
    cameraFocusView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cameraFocusView.delegate = self;
    [self.view addSubview:cameraFocusView];
    self.cameraFocusView = cameraFocusView;

    //检查相册权限
    if(![self checkVideoAuthorizationStatus]){
        self.setupResult = AVCamSetupResultCameraNotAuthorized;
        return;
    }
    
    //子线程配置摄像头权限，可以让进入界面更快一点
    dispatch_async( self.sessionQueue, ^{
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [self.class configurationVideoDeviceInputWithPreferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if ( ! videoDeviceInput ) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        {
            if ( [self.session canAddInput:videoDeviceInput] ){
                [self.session addInput:videoDeviceInput];
                self.videoDeviceInput = videoDeviceInput;
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
                    previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                });
            }else {
                NSLog( @"Could not add video device input to the session" );
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            
            AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            if ( [self.session canAddOutput:stillImageOutput] ) {
                stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
                [self.session addOutput:stillImageOutput];
                self.stillImageOutput = stillImageOutput;
            }else {
                NSLog( @"Could not add still image output to the session" );
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            
            
        }
        [self.session commitConfiguration];
    });
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if(self.setupResult == AVCamSetupResultSuccess){
        dispatch_async( self.sessionQueue, ^{
            [self addObservers];
            [self addFocusObserverWithCaptureDevice];
            [self.session startRunning];
            self.sessionRunning = self.session.isRunning;
        });
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self configurationAutoFocusWithCaptureFocusMode:AVCaptureFocusModeContinuousAutoFocus andCGPoint:CGPointMake(0.5, 0.5)];
    [self configurationAutoExposureWithCaptureExposureMode:AVCaptureExposureModeContinuousAutoExposure andCGPoint:CGPointMake(0.5, 0.5)];
    [self.cameraFocusView autoFocusWithFocusPoint:[(AVCaptureVideoPreviewLayer *)self.previewView.layer pointForCaptureDevicePointOfInterest:CGPointMake(0.5, 0.5)]];
}

- (void)viewDidDisappear:(BOOL)animated{
    if ( self.setupResult == AVCamSetupResultSuccess ) {
        dispatch_async( self.sessionQueue, ^{
            [self.session stopRunning];
            [self removeFocusObserverWithCaptureDevice];
            [self removeObservers];
            self.sessionRunning = self.session.isRunning;
        });
    }
    [super viewDidDisappear:animated];
}

//查看权限
- (BOOL)checkVideoAuthorizationStatus{
    __block BOOL result = NO;
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] ){
        case AVAuthorizationStatusAuthorized:{
            result = YES;
            break;
        }
        case AVAuthorizationStatusNotDetermined:{
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }else{
                    result = YES;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:{
            break;
        }
    }
    return result;
}

#pragma mark - observer
- (void)addObservers{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
}

- (void)removeObservers{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    [self.stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:CapturingStillImageContext];
}

- (void)sessionRuntimeError:(NSNotification *)notification{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );

    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
        } );
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if (isCapturingStillImage) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewView.layer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewView.layer.opacity = 1.0;
                }];
            });
        }
    }else if ( context == SessionRunningContext ) {

    }else if ( context == AVCaptureDeviceFocusPointOfInterest ) {

    }else if (context == AVCaptureDeviceFocusMode){
        [self observeValueForAVCaptureDeviceFocusModeOfchange:change];
    }else if(context == AVCaptureDeviceaaAjustingFocus){
        [self observeValueForAVCaptureDeviceAjustingFocusOfchange:change];
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 聚焦和曝光
- (void)addFocusObserverWithCaptureDevice{
    AVCaptureDevice *device = self.videoDeviceInput.device;
    if(!device) return;
    [self removeFocusObserverWithCaptureDevice];
    
    //监听聚焦位置发生改变
    if(device.focusPointOfInterestSupported){
        [device addObserver:self forKeyPath:@"focusPointOfInterest" options:NSKeyValueObservingOptionNew context:AVCaptureDeviceFocusPointOfInterest];
        [device addObserver:self forKeyPath:@"focusMode" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:AVCaptureDeviceFocusMode];
    }
    if(device.autoFocusRangeRestrictionSupported){
        [device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:AVCaptureDeviceaaAjustingFocus];
    }
    
    //监听照射区域发生变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
}

- (void)removeFocusObserverWithCaptureDevice{
    AVCaptureDevice *device = self.videoDeviceInput.device;
    if(!device) return;

    //取消监听聚焦位置发生改变
    @try {
        if(device.focusPointOfInterestSupported){
            [device removeObserver:self forKeyPath:@"focusPointOfInterest" context:AVCaptureDeviceFocusPointOfInterest];
        }
        [device removeObserver:self forKeyPath:@"focusMode" context:AVCaptureDeviceFocusMode];
        if(device.autoFocusRangeRestrictionSupported){
            [device removeObserver:self forKeyPath:@"adjustingFocus" context:AVCaptureDeviceaaAjustingFocus];
        }
    }@catch (NSException *exception) {}
    
    //监听照射区域发生变化
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
}

- (void)cameraFocusView:(K12CameraFocusView *)cameraFocusView userWillFocussingPoint:(CGPoint)point{
    point = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:point];
    self.captureDeviceFocusType = K12CaptureDeviceFocusTypeFocus;
    [self configurationAutoFocusWithCaptureFocusMode:AVCaptureFocusModeAutoFocus andCGPoint:point];
    [self configurationAutoExposureWithCaptureExposureMode:AVCaptureExposureModeContinuousAutoExposure andCGPoint:point];
}

- (void)cameraFocusView:(K12CameraFocusView *)cameraFocusView userWillLockFocusPoint:(CGPoint)point{
    point = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:point];
    self.captureDeviceFocusType = K12CaptureDeviceFocusTypeLockFocus;
    [self configurationAutoFocusWithCaptureFocusMode:AVCaptureFocusModeAutoFocus andCGPoint:point];
    [self configurationAutoExposureWithCaptureExposureMode:AVCaptureExposureModeAutoExpose andCGPoint:point];
}

//监听聚焦位置发生改变
- (void)observeValueForAVCaptureDeviceFocusPointOfInterestOfchange:(NSDictionary<NSString *,id> *)change{
//    AVCaptureDevice *device = self.videoDeviceInput.device;
//    if(device.isFocusPointOfInterestSupported){
//        if(self.lastSetupFocusModel == AVCaptureFocusModeContinuousAutoFocus){
//            dispatch_async(dispatch_get_main_queue(), ^{
//                CGPoint point = [(NSNumber *)(change[NSKeyValueChangeNewKey]) CGPointValue];
//                point = [(AVCaptureVideoPreviewLayer *)self.previewView.layer pointForCaptureDevicePointOfInterest:point];
//                [self.cameraFocusView autoFocusWithFocusPoint:point];
//            });
//        }
//    }
}

//根据AVCaptureFocusMode确认是否打开subjectAreaChangeMonitoringEnabled
- (void)observeValueForAVCaptureDeviceFocusModeOfchange:(NSDictionary<NSString *,id> *)change{
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    if(![newValue isEqual:change[NSKeyValueChangeOldKey]]){
        AVCaptureFocusMode mode = (AVCaptureFocusMode)[newValue integerValue];
        BOOL subjectAreaChangeMonitoringEnabled = (mode == AVCaptureFocusModeContinuousAutoFocus || mode == AVCaptureFocusModeAutoFocus)?NO:YES;
        dispatch_async( self.sessionQueue, ^{
            AVCaptureDevice *device = self.videoDeviceInput.device;
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
- (void)observeValueForAVCaptureDeviceAjustingFocusOfchange:(NSDictionary<NSString *,id> *)change{
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    if(![newValue isEqual:change[NSKeyValueChangeOldKey]]){
        if(self.captureDeviceFocusType == K12CaptureDeviceFocusTypeNone){
            if(![newValue boolValue]) return;
            
            AVCaptureDevice *device = self.videoDeviceInput.device;
            if(device.isFocusPointOfInterestSupported){
                __block CGPoint point = device.focusPointOfInterest;
                dispatch_async(dispatch_get_main_queue(), ^{
                    point = [(AVCaptureVideoPreviewLayer *)self.previewView.layer pointForCaptureDevicePointOfInterest:point];
                    [self.cameraFocusView autoFocusWithFocusPoint:point];
                });
            }
        }else if(self.captureDeviceFocusType == K12CaptureDeviceFocusTypeFocus){
            if([newValue boolValue]) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.cameraFocusView userFocussingDidSucceed];
            });
        }else if(self.captureDeviceFocusType == K12CaptureDeviceFocusTypeLockFocus){
            if([newValue boolValue]) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.cameraFocusView userLockFocusDidSucceed];
            });
        }
    }
}

//监听照射区域发生变化
- (void)subjectAreaDidChange:(NSNotification *)note{
    if(self.captureDeviceFocusType == K12CaptureDeviceFocusTypeFocus){
        self.captureDeviceFocusType = K12CaptureDeviceFocusTypeNone;
        [self configurationAutoFocusWithCaptureFocusMode:AVCaptureFocusModeContinuousAutoFocus andCGPoint:CGPointMake(0.5, 0.5)];
        [self configurationAutoExposureWithCaptureExposureMode:AVCaptureExposureModeContinuousAutoExposure andCGPoint:CGPointMake(0.5, 0.5)];
        [self.cameraFocusView autoFocusWithFocusPoint:[(AVCaptureVideoPreviewLayer *)self.previewView.layer pointForCaptureDevicePointOfInterest:CGPointMake(0.5, 0.5)]];
    }
}

//设置自动聚焦
- (void)configurationAutoFocusWithCaptureFocusMode:(AVCaptureFocusMode)focusMode andCGPoint:(CGPoint)point{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        
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
        AVCaptureDevice *device = self.videoDeviceInput.device;
        
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

#pragma mark - 屏幕旋转
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self configurationCaptureVideoPreviewLayerOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self configurationCaptureVideoPreviewLayerOrientation];
}

- (void)configurationCaptureVideoPreviewLayerOrientation{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscapeLeft;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeLeft;
}

#pragma mark - 配置选项
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

#pragma mark - 渲染视图

@implementation ViewControllerView
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
@end
