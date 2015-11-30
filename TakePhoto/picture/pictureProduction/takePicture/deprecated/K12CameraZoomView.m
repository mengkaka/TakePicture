//
//  K12CameraZoomView.m
//  TakePhoto
//
//  Created by mengkai on 15/9/28.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12CameraZoomView.h"

@implementation K12CameraZoomView
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.exclusiveTouch = NO;
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(doPinchAction:)];
        [self addGestureRecognizer:pinchGesture];
        _pinchGesture = pinchGesture;
    }
    return self;
}

- (void)doPinchAction:(UIPinchGestureRecognizer *)sender{
    NSLog(@"doPinchAction: %f",sender.scale);
}
@end
