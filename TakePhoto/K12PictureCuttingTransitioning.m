//
//  K12PictureCuttingTransitioning.m
//  TakePhoto
//
//  Created by mengkai on 15/10/21.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12PictureCuttingTransitioning.h"
#import "K12PictureCuttingController.h"

@interface K12PictureCuttingTransitioning()
{
    UIImageView *_imageView;
    K12ModalPresentingType _presentingType;
}
@end

@implementation K12PictureCuttingTransitioning
- (void)resetImageView:(UIImageView *)imageView andPresentingType:(K12ModalPresentingType)type{
    _imageView = [[UIImageView alloc]initWithImage:imageView.image];
    _imageView.frame = imageView.frame;
    [_imageView.superview addSubview:_imageView];
    _presentingType = type;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext{
    return 0.6;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    if(!_imageView){[transitionContext completeTransition:NO]; return;}
    UIView *containerView = transitionContext.containerView;
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    CGRect rect = CGRectZero;
    if(_imageView.superview){
        rect = [containerView convertRect:_imageView.frame fromView:_imageView.superview];
    }else{
        rect = _imageView.frame;
    }
    
    CGRect toRect = CGRectZero;
    if(_presentingType == K12ModalPresentingTypePresent){
        if(![toViewController isKindOfClass:K12PictureCuttingController.class]){
            [transitionContext completeTransition:NO]; return;
        }
        
        toViewController.view.alpha = 0.0;
        [containerView addSubview:toViewController.view];
        _imageView.frame = rect;
        [containerView addSubview:_imageView];
        
        toRect = [self cuttingControllerImageRectWithController:toViewController];
        if(CGRectEqualToRect(toRect, CGRectZero)) toRect = rect;
    }else{
        if(![fromViewController isKindOfClass:K12PictureCuttingController.class]){
            [transitionContext completeTransition:NO]; return;
        }
        
        toRect = rect;
        rect = [self cuttingControllerImageRectWithController:fromViewController];
        if(CGRectEqualToRect(rect, CGRectZero)) rect = toRect;
        
        [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
        _imageView.frame = rect;
        [containerView addSubview:_imageView];
    }
    
    CGFloat duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration*0.7 delay:duration*0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if(_presentingType == K12ModalPresentingTypePresent){
            _imageView.frame = toRect;
            _imageView.transform = CGAffineTransformIdentity;
            _imageView.alpha = 0.2;
        }else{
             _imageView.frame = toRect;
            _imageView.transform = CGAffineTransformIdentity;
            _imageView.alpha = 0.2;
        }
    } completion:NULL];
    
    [UIView animateWithDuration:duration*0.4 delay:duration*0.6 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if(_presentingType == K12ModalPresentingTypePresent){
            toViewController.view.alpha = 1.0;
        }else{
            fromViewController.view.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        [_imageView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

- (CGRect)cuttingControllerImageRectWithController:(UIViewController *)controller{
    UIView *view = [controller valueForKeyPath:@"_pictureCuttingView._imageView"];
    if(view) return view.frame;
    return CGRectZero;
}
@end
