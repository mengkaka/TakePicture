//
//  K12FocusViewControl.m
//  TakePhoto
//
//  Created by mengkai on 15/9/28.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12CameraFocusViewControl.h"

@interface K12CameraFocusViewControl()
{
    BOOL _isLockFocus;
}
@property (nonatomic, weak)K12CameraFocusCrucialView *crucialView;
@end

@implementation K12CameraFocusViewControl
- (void)setContainerView:(UIView *)containerView{
    _containerView = containerView;
}

+ (instancetype)focusViewControlWithView:(UIView *)view{
    K12CameraFocusViewControl *control = [[K12CameraFocusViewControl alloc]init];
    [control setContainerView:view];
    [control configurationIndicatorAndGesture];
    return control;
}

- (UITapGestureRecognizer *)tapGesture{
    return _tapGesture;
}

- (UILongPressGestureRecognizer *)longPressGesture{
    return _longPressGesture;
}

- (void)configurationIndicatorAndGesture{
    _isLockFocus = NO;
    
    K12CameraFocusCrucialView *crucialView = [[K12CameraFocusCrucialView alloc] init];
    crucialView.frame = CGRectMake(0, 0, 150, 150);
    crucialView.center = CGPointMake(_containerView.frame.size.width/2, _containerView.frame.size.height/2);
    crucialView.hidden = YES;
    [_containerView addSubview:crucialView];
    _crucialView = crucialView;
    
    //单击
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doTapAction:)];
    [_containerView addGestureRecognizer:tapGesture];
    _tapGesture = tapGesture;
    
    //长按
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(doLongPressAction:)];
    [_containerView addGestureRecognizer:longPressGesture];
    [tapGesture requireGestureRecognizerToFail:longPressGesture];
    _longPressGesture = longPressGesture;
}

- (void)setFocusViewControlEnabled:(BOOL)enable{
    _tapGesture.enabled = enable;
    _longPressGesture.enabled = enable;
    _crucialView.hidden = YES;
}

- (void)autoFocusWithFocusPoint:(CGPoint)point{
    //[self.class cancelPreviousPerformRequestsWithTarget:self];
    
    self.crucialView.hidden = YES;
    self.crucialView.alpha = 1.0;
    self.crucialView.center = point;
    self.crucialView.transform = CGAffineTransformIdentity;
    self.crucialView.hidden = NO;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView commitAnimations];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.crucialView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.crucialView.alpha = 0.5;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.crucialView.alpha = 0.0;
            } completion:NULL];
        }];
    }];
}

- (void)userFocussingDidSucceed{
    [UIView beginAnimations:nil context:NULL];
    self.crucialView.alpha = 0.5;
    [UIView commitAnimations];
}

- (void)userFocussingDidFailed{
    [UIView beginAnimations:nil context:NULL];
    self.crucialView.alpha = 0.5;
    [UIView commitAnimations];
}

- (void)userLockFocusDidSucceed{
    if(_isLockFocus) return;
    _isLockFocus = YES;
    self.crucialView.transform = CGAffineTransformIdentity;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationRepeatCount:2];
    self.crucialView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView commitAnimations];
}

- (void)userLockFocusDidFailed{
    if(_isLockFocus) return;
    _isLockFocus = YES;
    self.crucialView.transform = CGAffineTransformIdentity;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationRepeatCount:2];
    self.crucialView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView commitAnimations];
}

- (void)doTapAction:(UITapGestureRecognizer *)sender{
    //[self.class cancelPreviousPerformRequestsWithTarget:self];
    CGPoint point = [sender locationInView:_containerView];
    NSLog(@"%@",NSStringFromCGPoint(point));
    self.crucialView.hidden = YES;
    self.crucialView.alpha = 1.0;
    self.crucialView.center = point;
    self.crucialView.transform = CGAffineTransformIdentity;
    self.crucialView.hidden = NO;
    
    [UIView beginAnimations:nil context:NULL];
    self.crucialView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [UIView commitAnimations];
    
    if(_delegate && [_delegate respondsToSelector:@selector(cameraFocusViewControl:userWillFocussingPoint:)]){
        [_delegate cameraFocusViewControl:self userWillFocussingPoint:point];
    }
    
    //[self performSelector:@selector(userFocussingDidSucceed) withObject:nil afterDelay:1];
}

- (void)doLongPressAction:(UILongPressGestureRecognizer *)sender{
    
    if(sender.state == UIGestureRecognizerStateBegan){
        //[self.class cancelPreviousPerformRequestsWithTarget:self];
        _isLockFocus = NO;
        
        CGPoint point = [sender locationInView:_containerView];
        self.crucialView.hidden = YES;
        self.crucialView.center = point;
        self.crucialView.alpha = 1.0;
        self.crucialView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.crucialView.hidden = NO;
        
        if(_delegate && [_delegate respondsToSelector:@selector(cameraFocusViewControl:userWillLockFocusPoint:)]){
            [_delegate cameraFocusViewControl:self userWillLockFocusPoint:point];
        }
        
        //[self performSelector:@selector(userLockFocusDidSucceed) withObject:nil afterDelay:2.0];
    }else if(sender.state == UIGestureRecognizerStateEnded
             || sender.state == UIGestureRecognizerStateCancelled
             || sender.state == UIGestureRecognizerStateFailed){
        //[self.class cancelPreviousPerformRequestsWithTarget:self];
        CGPoint point = [sender locationInView:_containerView];
        
        [UIView beginAnimations:nil context:NULL];
        self.crucialView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView commitAnimations];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.crucialView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        } completion:^(BOOL finished) {
            if(_isLockFocus){
                self.crucialView.alpha = 0.5;
            }
        }];
        
        if(!_isLockFocus){
            if(_delegate && [_delegate respondsToSelector:@selector(cameraFocusViewControl:userWillFocussingPoint:)]){
                [_delegate cameraFocusViewControl:self userWillFocussingPoint:point];
            }
        }
    }
}
@end

/** 对焦小视图 */
@implementation K12CameraFocusCrucialView

static const CGFloat K12CrucialViewRadius = 10.0;
static const CGFloat K12CrucialViewLineWidth = 2.0;
static const CGFloat K12CrucialViewSpareWidth = 25.0;

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextClearRect(contextRef, rect);
    CGContextAddRect(contextRef, rect);
    CGContextSetFillColorWithColor(contextRef, self.backgroundColor.CGColor);
    CGContextFillPath(contextRef);
    
    CGContextSaveGState(contextRef);
    {
        CGContextSetStrokeColorWithColor(contextRef, [UIColor colorWithRed:74/255.0 green:203/255.0 blue:31/255.0 alpha:1.0].CGColor);
        CGContextSetLineWidth(contextRef, K12CrucialViewLineWidth);
        CGContextBeginPath(contextRef);
        {
            //整个圆角矩形
            CGContextMoveToPoint(contextRef, K12CrucialViewLineWidth/2.0, K12CrucialViewRadius+K12CrucialViewLineWidth/2.0);
            CGContextAddArc(contextRef, K12CrucialViewLineWidth/2.0+K12CrucialViewRadius, K12CrucialViewLineWidth/2.0+K12CrucialViewRadius, K12CrucialViewRadius, M_PI, M_PI_2*3, 0);
            CGContextAddLineToPoint(contextRef, CGRectGetWidth(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewRadius, K12CrucialViewLineWidth/2.0);
            CGContextAddArc(contextRef, CGRectGetWidth(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewRadius, K12CrucialViewLineWidth/2.0+K12CrucialViewRadius, K12CrucialViewRadius, M_PI_2*3, 0, 0);
            CGContextAddLineToPoint(contextRef, CGRectGetHeight(rect)-K12CrucialViewLineWidth/2.0, CGRectGetHeight(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewRadius);
            CGContextAddArc(contextRef, CGRectGetWidth(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewRadius, CGRectGetHeight(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewRadius, K12CrucialViewRadius, 0, M_PI_2, 0);
            CGContextAddLineToPoint(contextRef, K12CrucialViewLineWidth/2.0+K12CrucialViewRadius, CGRectGetHeight(rect)-K12CrucialViewLineWidth/2.0);
            CGContextAddArc(contextRef, K12CrucialViewLineWidth/2.0+K12CrucialViewRadius, CGRectGetHeight(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewRadius, K12CrucialViewRadius, M_PI_2, M_PI, 0);
            CGContextAddLineToPoint(contextRef, K12CrucialViewLineWidth/2.0, K12CrucialViewLineWidth/2.0+K12CrucialViewRadius);
            
            //四个小边儿
            CGContextMoveToPoint(contextRef, K12CrucialViewLineWidth/2.0, CGRectGetHeight(rect)/2.0);
            CGContextAddLineToPoint(contextRef, K12CrucialViewLineWidth/2.0+K12CrucialViewSpareWidth, CGRectGetHeight(rect)/2.0);
            
            CGContextMoveToPoint(contextRef, CGRectGetWidth(rect)/2.0, K12CrucialViewLineWidth/2.0);
            CGContextAddLineToPoint(contextRef, CGRectGetWidth(rect)/2.0, K12CrucialViewLineWidth/2.0+K12CrucialViewSpareWidth);
            
            CGContextMoveToPoint(contextRef, CGRectGetWidth(rect)-K12CrucialViewLineWidth/2.0, CGRectGetHeight(rect)/2.0);
            CGContextAddLineToPoint(contextRef, CGRectGetWidth(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewSpareWidth, CGRectGetHeight(rect)/2.0);
            
            CGContextMoveToPoint(contextRef, CGRectGetWidth(rect)/2.0, CGRectGetHeight(rect)-K12CrucialViewLineWidth/2.0);
            CGContextAddLineToPoint(contextRef, CGRectGetWidth(rect)/2.0, CGRectGetHeight(rect)-K12CrucialViewLineWidth/2.0-K12CrucialViewSpareWidth);
        }
        CGContextClosePath(contextRef);
        CGContextStrokePath(contextRef);
    }
    CGContextRestoreGState(contextRef);
}
@end
