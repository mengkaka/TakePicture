//
//  ViewController1.m
//  TakePhoto
//
//  Created by mengkai on 15/9/23.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "ViewController1.h"
@import AVFoundation;

@interface ViewController1()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong)UIImagePickerController *ipvc;
@end

@implementation ViewController1

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    AVCaptureDevice *camDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    int flags =NSKeyValueObservingOptionNew;
    //[camDevice addObserver:self forKeyPath:@"focusMode" options:flags context:nil];
    //[camDevice addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
    //[camDevice addObserver:self forKeyPath:@"focusPointOfInterest" options:flags context:nil];
    //[camDevice addObserver:self forKeyPath:@"autoFocusRangeRestriction" options:flags context:nil];
    //[camDevice addObserver:self forKeyPath:@"smoothAutoFocusEnabled" options:flags context:nil];

    //[camDevice addObserver:self forKeyPath:@"subjectAreaChangeMonitoringEnabled" options:flags context:nil];
    
    //[camDevice addObserver:self forKeyPath:@"exposureMode" options:flags context:nil];
    //[camDevice addObserver:self forKeyPath:@"adjustingExposure" options:flags context:nil];
    
    [camDevice addObserver:self forKeyPath:@"videoZoomFactor" options:flags context:nil];



}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"focusMode"] || [keyPath isEqualToString:@"focusPointOfInterest"] || [keyPath isEqualToString:@"autoFocusRangeRestriction"] || [keyPath isEqualToString:@"subjectAreaChangeMonitoringEnabled"] || [keyPath isEqualToString:@"smoothAutoFocusEnabled"] || [keyPath isEqualToString:@"adjustingFocus"] || [keyPath isEqualToString:@"exposureMode"] || [keyPath isEqualToString:@"adjustingExposure"] || [keyPath isEqualToString:@"videoZoomFactor"]) {
        NSLog(@"%@ = %@",keyPath,change);
        //NSLog(@"%@",@([AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo].focusMode));
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

/*
 //根据某一手势对象创建相同手势对象
 - (UIGestureRecognizer *)gestureRecognizerWithGesture:(UIGestureRecognizer *)gesture{
 Class gestureClass = gesture.class;
 
 NSMutableArray *targets = [gesture valueForKeyPath:@"targets"];
 if(!targets || !targets.count) return nil;
 id targetContainer = targets[0];
 id targetOfGesture = [targetContainer valueForKeyPath:@"target"];
 if(!targetOfGesture) return nil;
 SEL action = ((SEL (*)(id, const char*))object_getIvar)(targetContainer, class_getInstanceVariable([targetContainer class], "_action"));
 if(action == NULL) return nil;
 
 UIGestureRecognizer *newGesture = (UIGestureRecognizer *)[[gestureClass alloc]init];
 newGesture.delaysTouchesBegan = gesture.delaysTouchesBegan;
 newGesture.delaysTouchesEnded = gesture.delaysTouchesEnded;
 newGesture.cancelsTouchesInView = gesture.cancelsTouchesInView;
 newGesture.delegate = gesture.delegate;
 [newGesture addTarget:targetOfGesture action:action];
 
 return gesture;
 }*/