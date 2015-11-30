//
//  K12CameraZoomViewControl.h
//  TakePhoto
//
//  Created by mengkai on 15/9/28.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class K12CameraZoomViewControl;
@protocol K12CameraZoomViewControlDelegate <NSObject>
- (void)cameraZoomView:(K12CameraZoomViewControl *)cameraZoomView userDidZoomWithFactor:(CGFloat)factor;
@end

@interface K12CameraZoomViewControl : NSObject
{
    __weak UIView *_containerView;
    UISlider *_sliderView;
    UIPinchGestureRecognizer *_pinchGesture;
    CGFloat _zoomFactor;    //缩放大小0.0～1.0
    CGFloat _tempZoomFactor;
}
@property (readonly) UIPinchGestureRecognizer *pinchGesture;
@property (nonatomic, weak)id <K12CameraZoomViewControlDelegate>delegate;

+ (instancetype)zoomViewControlWithView:(UIView *)view;
- (void)setZoomViewControlEnabled:(BOOL)enable;

@end