//
//  K12CameraRulerView.m
//  TakePhoto
//
//  Created by mengkai on 15/9/28.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12CameraRulerView.h"

@implementation K12CameraRulerView
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
    CGContextSetFillColorWithColor(contextRef, [UIColor clearColor].CGColor);
    CGContextFillPath(contextRef);
    
    CGContextSaveGState(contextRef);
    {
        CGContextSetStrokeColorWithColor(contextRef, [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:0.4].CGColor);
        CGContextSetLineWidth(contextRef, 1.0);
        CGContextBeginPath(contextRef);
        {
            //画横线
            CGFloat rowInterval = rect.size.height/4.0;
            for (int i = 1; i < 4; i++) {
                if(i == 2)continue;
                CGContextMoveToPoint(contextRef, rect.size.width, rowInterval*i);
                CGContextAddLineToPoint(contextRef, 0, rowInterval*i);
            }
            
            //画纵线
            CGFloat rankInterval = rect.size.width/4.0;
            for (int i = 1; i < 4; i++) {
                if(i == 2)continue;
                CGContextMoveToPoint(contextRef, rankInterval*i, rect.size.height);
                CGContextAddLineToPoint(contextRef, rankInterval*i, 0);
            }
        }
        CGContextClosePath(contextRef);
        CGContextStrokePath(contextRef);
    }
    CGContextRestoreGState(contextRef);
}

@end
