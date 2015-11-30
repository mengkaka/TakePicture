//
//  K12FocusAndExposureView.m
//  TakePhoto
//
//  Created by mengkai on 15/9/24.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12CameraFocusView.h"

@interface K12CameraFocusView()
{
    BOOL _isLockFocus;
}
@property (nonatomic, weak)UIImageView *crucialView;
@end

@implementation K12CameraFocusView

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _isLockFocus = NO;
        self.backgroundColor = [UIColor clearColor];
        
        UIImageView *crucialView = [[UIImageView alloc] init];
        crucialView.backgroundColor = [UIColor clearColor];
        crucialView.frame = CGRectMake(0, 0, 150, 150);
        crucialView.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        crucialView.hidden = YES;
        crucialView.image = [UIImage imageNamed:@"对焦成功_1242.png"];
        [self addSubview:crucialView];
        _crucialView = crucialView;
        
        //单击
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doTapAction:)];
        [self addGestureRecognizer:tapGesture];
        _tapGesture = tapGesture;
        
        //长按
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(doLongPressAction:)];
        [self addGestureRecognizer:longPressGesture];
        [tapGesture requireGestureRecognizerToFail:longPressGesture];
        _longPressGesture = longPressGesture;
    }
    return self;
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
    CGPoint point = [sender locationInView:self];
    NSLog(@"%@",NSStringFromCGPoint(point));
    self.crucialView.hidden = YES;
    self.crucialView.alpha = 1.0;
    self.crucialView.center = point;
    self.crucialView.transform = CGAffineTransformIdentity;
    self.crucialView.hidden = NO;
    
    [UIView beginAnimations:nil context:NULL];
    self.crucialView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [UIView commitAnimations];
    
    if(_delegate && [_delegate respondsToSelector:@selector(cameraFocusView:userWillFocussingPoint:)]){
        [_delegate cameraFocusView:self userWillFocussingPoint:point];
    }
    
    //[self performSelector:@selector(userFocussingDidSucceed) withObject:nil afterDelay:1];
}

- (void)doLongPressAction:(UILongPressGestureRecognizer *)sender{

    if(sender.state == UIGestureRecognizerStateBegan){
        //[self.class cancelPreviousPerformRequestsWithTarget:self];
        _isLockFocus = NO;

        CGPoint point = [sender locationInView:self];
        self.crucialView.hidden = YES;
        self.crucialView.center = point;
        self.crucialView.alpha = 1.0;
        self.crucialView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.crucialView.hidden = NO;
        
        if(_delegate && [_delegate respondsToSelector:@selector(cameraFocusView:userWillLockFocusPoint:)]){
            [_delegate cameraFocusView:self userWillLockFocusPoint:point];
        }
        
        //[self performSelector:@selector(userLockFocusDidSucceed) withObject:nil afterDelay:2.0];
    }else if(sender.state == UIGestureRecognizerStateEnded
             || sender.state == UIGestureRecognizerStateCancelled
             || sender.state == UIGestureRecognizerStateFailed){
        //[self.class cancelPreviousPerformRequestsWithTarget:self];
        CGPoint point = [sender locationInView:self];
        
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
            if(_delegate && [_delegate respondsToSelector:@selector(cameraFocusView:userWillFocussingPoint:)]){
                [_delegate cameraFocusView:self userWillFocussingPoint:point];
            }
        }
    }
}

@end
