//
//  K12CameraZoomViewControl.m
//  TakePhoto
//
//  Created by mengkai on 15/9/28.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12CameraZoomViewControl.h"

@implementation K12CameraZoomViewControl
- (void)setContainerView:(UIView *)containerView{
    _containerView = containerView;
}

+ (instancetype)zoomViewControlWithView:(UIView *)view{
    K12CameraZoomViewControl *control = [[K12CameraZoomViewControl alloc]init];
    [control setContainerView:view];
    [control configurationIndicatorAndGesture];
    return control;
}

- (UIPinchGestureRecognizer *)pinchGesture{
    return _pinchGesture;
}

- (void)configurationIndicatorAndGesture{
    _zoomFactor = 0.0;
    
    //滑动视图
    UISlider *sliderView = [[UISlider alloc]init];
    sliderView.translatesAutoresizingMaskIntoConstraints = NO;
    sliderView.alpha = 0.0;
    [sliderView addTarget:self action:@selector(sliderControlAction:) forControlEvents:UIControlEventValueChanged];
    [_containerView addSubview:sliderView];
    _sliderView = sliderView;
    NSDictionary *views = @{@"sliderView" : sliderView};
    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==20)-[sliderView]-(==20)-|" options:0 metrics:nil views:views]];
    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[sliderView(==30)]-(==80)-|" options:0 metrics:nil views:views]];
    
    //捏合手势
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(doPinchAction:)];
    [_containerView addGestureRecognizer:pinchGesture];
    _pinchGesture = pinchGesture;
}

- (void)setZoomViewControlEnabled:(BOOL)enable{
    _pinchGesture.enabled = enable;
    [self performSelector:@selector(hiddenSliderView) withObject:nil afterDelay:1.0];
}

- (void)setZoomFactor:(CGFloat)zoomFactor{
    [self.class cancelPreviousPerformRequestsWithTarget:self];
    
    zoomFactor = MAX(MIN(zoomFactor, 1.0),0.0);
    if(_zoomFactor != zoomFactor){
        _sliderView.value = zoomFactor;
        _zoomFactor = zoomFactor;
        
        //回调方法
        if(_delegate && [_delegate respondsToSelector:@selector(cameraZoomView:userDidZoomWithFactor:)]){
            [_delegate cameraZoomView:self userDidZoomWithFactor:_zoomFactor];
        }
    }
}

- (void)doPinchAction:(UIPinchGestureRecognizer *)sender{
    NSLog( @" --- selnder  =  : %f",sender.scale );
    if(sender.state == UIGestureRecognizerStateBegan){
        _sliderView.alpha = 1.0;
        _tempZoomFactor = _zoomFactor;
    }else if(sender.state == UIGestureRecognizerStateChanged){
        self.zoomFactor = (_tempZoomFactor+(sender.scale-1.0)/3.0);
    }else if(sender.state == UIGestureRecognizerStateEnded
             || sender.state == UIGestureRecognizerStateCancelled
             || sender.state == UIGestureRecognizerStateFailed){
        [self performSelector:@selector(hiddenSliderView) withObject:nil afterDelay:1.0];
    }
}

- (void)sliderControlAction:(UISlider *)sender{
    [self setZoomFactor:sender.value];
}

- (void)hiddenSliderView{
    [UIView beginAnimations:nil context:NULL];
    _sliderView.alpha = 0.0;
    [UIView commitAnimations];
}

@end
