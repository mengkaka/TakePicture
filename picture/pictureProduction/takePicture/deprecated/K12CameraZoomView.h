//
//  K12CameraZoomView.h
//  TakePhoto
//
//  Created by mengkai on 15/9/28.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class K12CameraZoomView;
@protocol K12CameraZoomViewDelegate <NSObject>
- (void)cameraZoomView:(K12CameraZoomView *)cameraZoomView userDidZoomWithFactor:(CGFloat)factor;
@end

@interface K12CameraZoomView : UIView
{
    UIPinchGestureRecognizer *_pinchGesture;
    CGFloat _zoomFactor;    //缩放大小0.0～1.0
}
@property (nonatomic, weak)id <K12CameraZoomViewDelegate>delegate;
@end
