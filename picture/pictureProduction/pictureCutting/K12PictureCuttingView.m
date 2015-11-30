//
//  K12PictureCuttingView.m
//  TakePhoto
//
//  Created by mengkai on 15/10/10.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12PictureCuttingView.h"
#import "UIImage+Orientation.h"
#import <objc/runtime.h>

@interface NSTimer(K12PictureCuttingView)
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti withCompletion:(void (^ __nullable)(void))completion;
@end

@implementation NSTimer(K12PictureCuttingView)
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti withCompletion:(void (^ __nullable)(void))completion{
    if(!completion) return nil;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(scheduledSelecter:) userInfo:@{@"completion":[completion copy]} repeats:NO];
    return timer;
}
+ (void)scheduledSelecter:(NSTimer *)timer{
    if(timer.userInfo && [timer.userInfo objectForKey:@"completion"]){
        void (^completion)() = [timer.userInfo objectForKey:@"completion"];
        completion();
    }
}
@end

/** 图片裁剪视图 */
@implementation K12PictureCuttingView
const CGFloat __minCuttingWidth__ = 60;
const CGFloat __minCuttingHeight__ = 60;
const CGFloat __cuttingTouchWidth__ = 60;
const CGFloat __cuttingTouchHeight__ = 60;
const CGFloat __minimumZoomContentInset__ = 5;

static UIImage *pictureCuttingView_pictureCutting(UIImage *image, CGRect rect){
    if(![image isKindOfClass:UIImage.class] || image.size.width <=0 || image.size.height <= 0) return nil;
    
    CGImageRef imageRef = image.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, rect);
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, image.scale, image.scale);
    CGContextDrawImage(context, rect, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    
    return smallImage;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor whiteColor];
        _cuttingInset = UIEdgeInsetsZero;
        _defultCorpInset = UIEdgeInsetsZero;
        _cuttingOrientation = K12PictureCuttingOrientationPortrait;
        _panDirection = K12PictureCuttingPanOutside;
        _rotationning = NO;
        
        //控制图片缩放
        UIScrollView *scrollView = [[UIScrollView alloc]initWithFrame:self.bounds];
        scrollView.backgroundColor = [UIColor whiteColor];
        scrollView.alwaysBounceHorizontal = YES;
        scrollView.alwaysBounceVertical = YES;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.bouncesZoom = YES;
        scrollView.backgroundColor = [UIColor clearColor];
        scrollView.delegate = self;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 2.0;
        scrollView.zoomScale = 1.0;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        //scrollView.decelerationRate = 0.2;
        [self addSubview:scrollView];
        _scrollView = scrollView;
        _scrollView.userInteractionEnabled = NO;
        
        //显示图片容器
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        //imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.clipsToBounds = YES;
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [scrollView addSubview:imageView];
        _imageView = imageView;
        _imageView.hidden = YES;
        
        //识别各种收拾的视图
        K12PictureCuttingBackgroundView *gestureRecognizeView = [[K12PictureCuttingBackgroundView alloc]initWithFrame:self.bounds];
        gestureRecognizeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        gestureRecognizeView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        [self addSubview:gestureRecognizeView];
        gestureRecognizeView.userInteractionEnabled = NO;
        _grayFloatingView = gestureRecognizeView;
        _grayFloatingView.hidden = YES;
        
        //拖拽手势
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(doPanGestureAction:)];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        panGestureRecognizer.delegate = self;
        [scrollView addGestureRecognizer:panGestureRecognizer];
        _cropPanGestureRecognizer = panGestureRecognizer;
        
        //图片裁剪区域
        _cropView = [[K12PictureCuttingCropView alloc]initWithFrame:CGRectMake(100, 100, 200, 200)];
        _cropView.userInteractionEnabled = NO;
        [self addSubview:_cropView];
        gestureRecognizeView.overlayRect = _cropView.cuttingRect;
        _cropView.hidden = YES;
    }
    return self;
}

#pragma mark - Action
//使用nstimer执行操作，保证视图滑动、缩放等完成以后才开始进行操作
- (void)scheduledTimerWithCompletion:(void (^ __nullable)(void))completion{
    if(_timer) {[_timer invalidate], _timer = nil;}
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 withCompletion:completion];
}

- (void)setCuttingOrientation:(K12PictureCuttingOrientation)cuttingOrientation{
    if(_scrollView.decelerating || _scrollView.dragging || _scrollView.tracking) return;
    if(_rotationning) return;
    _rotationning = YES;
    self.userInteractionEnabled = NO;
    if(_cuttingOrientation != cuttingOrientation){
        _cuttingOrientation = cuttingOrientation;
        
        CGFloat angle = 0;
        switch (cuttingOrientation) {
            case K12PictureCuttingOrientationLandscapeLeft:
                angle = M_PI_2;
                break;
            case K12PictureCuttingOrientationPortraitUpsideDown:
                angle = M_PI;
                break;
            case K12PictureCuttingOrientationLandscapeRight:
                angle = M_PI_2*3;
                break;
            default:
                break;
        }
        
        [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            //_grayFloatingView.alpha = 0.0;
            _cropView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGAffineTransform trans = CGAffineTransformMakeRotation(angle);
                self.transform = CGAffineTransformTranslate(trans, -self.frame.origin.x, -self.frame.origin.y);
                CGFloat width = _grayFloatingView.frame.size.width;
                CGFloat height = _grayFloatingView.frame.size.height;
                self.frame = CGRectMake(0, 0, MIN(width, height), MAX(width, height));
                
                _scrollView.delegate = nil;
                _scrollView.contentSize = _imageView.frame.size;
                _scrollView.contentOffset = CGPointZero;
                _scrollView.contentInset = UIEdgeInsetsZero;
                _scrollView.delegate = self;
                _panDirection = K12PictureCuttingPanDirection;
                _scrollView.zoomScale = 1.0;
                _panDirection = K12PictureCuttingPanOutside;
                
                [self resetImagesize];
                CGRect imgFrame = _imageView.frame;
                CGRect corpFrame = [_scrollView convertRect:imgFrame toView:self];
                if(cuttingOrientation == K12PictureCuttingOrientationPortrait || cuttingOrientation == K12PictureCuttingOrientationPortraitUpsideDown){
                    corpFrame = /*CGRectMake(_defultCorpInset.left, _defultCorpInset.top, CGRectGetWidth(corpFrame)-_defultCorpInset.left-_defultCorpInset.right, CGRectGetHeight(corpFrame)-_defultCorpInset.top-_defultCorpInset.bottom);//*/CGRectInset(corpFrame, corpFrame.size.width/3.0-(self.frame.size.width-CGRectGetWidth(corpFrame))/2.0, 0);
                }else{
                    corpFrame = CGRectInset(corpFrame, 0, corpFrame.size.height/3.0-(self.frame.size.width-CGRectGetHeight(corpFrame))/2.0);
                }
                _cropView.cuttingRect = corpFrame;
                _grayFloatingView.overlayRect = corpFrame;
            } completion:^(BOOL finished) {
                [self adjustScrollViewZoomScaleWithCGRect:_cropView.cuttingRect];
                [self adjustContentInsetWithCGRect:_cropView.cuttingRect];
                [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    _grayFloatingView.alpha = 1.0;
                    _cropView.alpha = 1.0;
                }completion:^(BOOL finished) {
                    _rotationning = NO;
                    self.userInteractionEnabled = YES;
                }];
            }];
        }];
    }
}

- (void)setCuttingImage:(UIImage *)image{
    if(!image && ![image isKindOfClass:UIImage.class] && image.size.width > 0 && image.size.height > 0){
        _cropView.hidden = YES;
        _imageView.hidden = YES;
        _scrollView.userInteractionEnabled = NO;
        _grayFloatingView.hidden = YES;
        _imageView.image = nil;
        return;
    }
    _cropView.hidden = NO;
    _imageView.hidden = NO;
    _scrollView.userInteractionEnabled = YES;
    _grayFloatingView.hidden = NO;
    _imageView.image = image;
    
    [self resetImagesize];
    CGRect imgFrame = _imageView.frame;
    CGRect corpFrame = [_scrollView convertRect:imgFrame toView:self];
    corpFrame = /*CGRectMake(_defultCorpInset.left, _defultCorpInset.top, CGRectGetWidth(corpFrame)-_defultCorpInset.left-_defultCorpInset.right, CGRectGetHeight(corpFrame)-_defultCorpInset.top-_defultCorpInset.bottom);//*/CGRectInset(corpFrame, corpFrame.size.width/3.0-(self.frame.size.width-CGRectGetWidth(corpFrame))/2.0, 0);
    _cropView.cuttingRect = corpFrame;
    _grayFloatingView.overlayRect = corpFrame;
    
    //调整scrollView的contentInset
    [self adjustContentInsetWithCGRect:_cropView.cuttingRect];
}

- (UIImage *)beginCuttingImage{
    if(!_imageView.image) return nil;
    
    CGRect imgViewFrame = _imageView.frame;
    CGSize imgSize = _imageView.image.size;
    CGRect newImageRect = [self convertRect:_cropView.cuttingRect toView:_imageView];
    CGFloat zoomScale = _scrollView.zoomScale;
    CGFloat widthScale = imgViewFrame.size.width/imgSize.width;
    CGFloat heightScale = imgViewFrame.size.height/imgSize.height;
    
    newImageRect.origin.x = newImageRect.origin.x/widthScale*zoomScale;
    newImageRect.origin.y = newImageRect.origin.y/heightScale*zoomScale;
    newImageRect.size.width = newImageRect.size.width/widthScale*zoomScale;
    newImageRect.size.height = newImageRect.size.height/heightScale*zoomScale;
    
    UIImage *originImage = [_imageView.image reviseImageOrientation];
    UIImage *image = pictureCuttingView_pictureCutting(originImage, newImageRect);
    return image;
}

- (void)doPanGestureAction:(UIPanGestureRecognizer *)sender{
    CGPoint point = [sender locationInView:self];
    if(sender.state == UIGestureRecognizerStateBegan){
        _panDirection = [self confirmPanDirectionWithCGpoint:point];
        _panStartPoint = point;
        _cropViewPanStartFrame = _cropView.frame;
    }else if(sender.state == UIGestureRecognizerStateChanged){
        [self adjustCropViewFrameWithPoint:point];
    }else if(sender.state == UIGestureRecognizerStateEnded
             || sender.state == UIGestureRecognizerStateCancelled
             || sender.state == UIGestureRecognizerStateFailed){
        _panDirection = K12PictureCuttingPanOutside;
    }
}

- (enum K12PictureCuttingPanDirection)confirmPanDirectionWithCGpoint:(CGPoint)point{
    
    NSInteger panDirection = K12PictureCuttingPanOutside;
    do{
        CGRect rect = CGRectZero;
        CGRect frame = _cropView.frame;
        
        //默认无效裁剪拖动手势
        panDirection = K12PictureCuttingPanOutside;
        
        //左上角
        rect = CGRectMake(CGRectGetMinX(frame)-__cuttingTouchWidth__/2.0, CGRectGetMinY(frame)-__cuttingTouchHeight__/2.0, __cuttingTouchWidth__, __cuttingTouchHeight__);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanLeftTop;
            break;
        }
        
        //左下角
        rect = CGRectMake(CGRectGetMinX(frame)-__cuttingTouchWidth__/2.0, CGRectGetMaxY(frame)-__cuttingTouchHeight__/2.0, __cuttingTouchWidth__, __cuttingTouchHeight__);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanLeftBottom;
            break;
        }
        
        //右下角
        rect = CGRectMake(CGRectGetMaxX(frame)-__cuttingTouchWidth__/2.0, CGRectGetMaxY(frame)-__cuttingTouchHeight__/2.0, __cuttingTouchWidth__, __cuttingTouchHeight__);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanRightBottom;
            break;
        }
        
        //右上角
        rect = CGRectMake(CGRectGetMaxX(frame)-__cuttingTouchWidth__/2.0, CGRectGetMinY(frame)-__cuttingTouchHeight__/2.0, __cuttingTouchWidth__, __cuttingTouchHeight__);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanRightTop;
            break;
        }
        
        //向上
        rect = CGRectInset(CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), 0), 0, -__cuttingTouchHeight__/2.0);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanTop;
            break;
        }
        
        //向左
        rect = CGRectInset(CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), 0, CGRectGetHeight(frame)), -__cuttingTouchWidth__/2.0 , 0);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanLeft;
            break;
        }
        
        //向下
        rect = CGRectInset(CGRectMake(CGRectGetMinX(frame), CGRectGetMaxY(frame), CGRectGetWidth(frame), 0), 0, -__cuttingTouchHeight__/2.0);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanBottom;
            break;
        }
        
        //向右
        rect = CGRectInset(CGRectMake(CGRectGetMaxX(frame), CGRectGetMinY(frame), 0, CGRectGetHeight(frame)), -__cuttingTouchWidth__/2.0 , 0);
        if(CGRectContainsPoint(rect, point)){
            panDirection = K12PictureCuttingPanRight;
            break;
        }
        
        //拖动整个裁剪区框手势
        if(CGRectContainsPoint(frame, point)){
            panDirection = K12PictureCuttingPanCropView;
            break;
        }
    }while (0);
    
    return panDirection;
}

- (void)adjustCropViewFrameWithPoint:(CGPoint)point{
    if(_panDirection != K12PictureCuttingPanOutside){
        
        CGRect mainViewFrame = self.bounds;
        CGSize offset = CGSizeMake(point.x - _panStartPoint.x, point.y - _panStartPoint.y);
        mainViewFrame = CGRectMake(self.cuttingInset.left, self.cuttingInset.top, mainViewFrame.size.width-self.cuttingInset.right-self.cuttingInset.left, mainViewFrame.size.height-self.cuttingInset.bottom-self.cuttingInset.top);
        
        switch (_panDirection) {
                //拖动整个裁剪区框
            case K12PictureCuttingPanCropView:{
                CGPoint originCenter = CGPointMake(CGRectGetMidX(_cropViewPanStartFrame), CGRectGetMidY(_cropViewPanStartFrame));
                CGPoint center = CGPointMake(originCenter.x+offset.width, originCenter.y+offset.height);
                center.x = ceil(MIN(MAX(CGRectGetWidth(_cropViewPanStartFrame)/2.0+CGRectGetMinX(mainViewFrame), center.x),CGRectGetMaxX(mainViewFrame)-CGRectGetWidth(_cropViewPanStartFrame)/2.0));
                center.y = ceil(MIN(MAX(CGRectGetHeight(_cropViewPanStartFrame)/2.0+CGRectGetMinY(mainViewFrame), center.y),CGRectGetMaxY(mainViewFrame)-CGRectGetHeight(_cropViewPanStartFrame)/2.0));
                _cropView.center = center;
            }
                break;
                //向上
            case K12PictureCuttingPanTop:{
                CGFloat top = CGRectGetMinY(_cropViewPanStartFrame) + offset.height;
                top = ceil(MAX(MIN(CGRectGetMaxY(_cropViewPanStartFrame)-__minCuttingHeight__,top),CGRectGetMinY(mainViewFrame)));
                [_cropView setTopLinePosition:top];
            }
                break;
                //向左
            case K12PictureCuttingPanLeft:{
                CGFloat left = CGRectGetMinX(_cropViewPanStartFrame) + offset.width;
                left = ceil(MAX(MIN(CGRectGetMaxX(_cropViewPanStartFrame)-__minCuttingWidth__,left),CGRectGetMinX(mainViewFrame)));
                [_cropView setLeftLinePosition:left];
            }
                break;
                //向下
            case K12PictureCuttingPanBottom:{
                CGFloat bottom = CGRectGetMaxY(_cropViewPanStartFrame) + offset.height;
                bottom = ceil(MIN(MAX(CGRectGetMinY(_cropViewPanStartFrame)+__minCuttingHeight__,bottom),CGRectGetMaxY(mainViewFrame)));
                [_cropView setBottomLinePosition:bottom];
            }
                break;
                //向右
            case K12PictureCuttingPanRight:{
                CGFloat right = CGRectGetMaxX(_cropViewPanStartFrame) + offset.width;
                right = ceil(MIN(MAX(CGRectGetMinX(_cropViewPanStartFrame)+__minCuttingWidth__,right),CGRectGetMaxX(mainViewFrame)));
                [_cropView setRightLinePosition:right];
            }
                break;
                //左上方
            case K12PictureCuttingPanLeftTop:{
                CGPoint origin = CGPointMake(CGRectGetMinX(_cropViewPanStartFrame)+offset.width, CGRectGetMinY(_cropViewPanStartFrame)+offset.height);
                origin.x = ceil(MAX(MIN(CGRectGetMaxX(_cropViewPanStartFrame)-__minCuttingWidth__,origin.x),CGRectGetMinX(mainViewFrame)));
                origin.y = ceil(MAX(MIN(CGRectGetMaxY(_cropViewPanStartFrame)-__minCuttingHeight__,origin.y),CGRectGetMinY(mainViewFrame)));
                [_cropView setLeftTopPoint:origin];
            }
                break;
                //左下方
            case K12PictureCuttingPanLeftBottom:{
                CGPoint origin = CGPointMake(CGRectGetMinX(_cropViewPanStartFrame)+offset.width, CGRectGetMaxY(_cropViewPanStartFrame)+offset.height);
                origin.x = ceil(MAX(MIN(CGRectGetMaxX(_cropViewPanStartFrame)-__minCuttingWidth__,origin.x),CGRectGetMinX(mainViewFrame)));
                origin.y = ceil(MIN(MAX(CGRectGetMinY(_cropViewPanStartFrame)+__minCuttingHeight__,origin.y),CGRectGetMaxY(mainViewFrame)));
                [_cropView setLeftBottomPoint:origin];
            }
                break;
                //右下方
            case K12PictureCuttingPanRightBottom:{
                CGPoint origin = CGPointMake(CGRectGetMaxX(_cropViewPanStartFrame)+offset.width, CGRectGetMaxY(_cropViewPanStartFrame)+offset.height);
                origin.x = ceil(MIN(MAX(CGRectGetMinX(_cropViewPanStartFrame)+__minCuttingWidth__,origin.x),CGRectGetMaxX(mainViewFrame)));
                origin.y = ceil(MIN(MAX(CGRectGetMinY(_cropViewPanStartFrame)+__minCuttingHeight__,origin.y),CGRectGetMaxY(mainViewFrame)));
                [_cropView setRightBottomPoint:origin];
            }
                break;
                //右上方
            case K12PictureCuttingPanRightTop:{
                CGPoint origin = CGPointMake(CGRectGetMaxX(_cropViewPanStartFrame)+offset.width, CGRectGetMinY(_cropViewPanStartFrame)+offset.height);
                origin.x = ceil(MIN(MAX(CGRectGetMinX(_cropViewPanStartFrame)+__minCuttingWidth__,origin.x),CGRectGetMaxX(mainViewFrame)));
                origin.y = ceil(MAX(MIN(CGRectGetMaxY(_cropViewPanStartFrame)-__minCuttingHeight__,origin.y),CGRectGetMinY(mainViewFrame)));
                [_cropView setRightTopPoint:origin];
            }
                break;
            default:
                break;
        }
        
        _grayFloatingView.overlayRect = _cropView.cuttingRect;
        [self adjustScrollViewZoomScaleWithCGRect:_cropView.cuttingRect];
        [self adjustContentInsetWithCGRect:_cropView.cuttingRect];
    }
}

//调整最小缩放比例
- (void)adjustScrollViewZoomScaleWithCGRect:(CGRect)rect{
    CGRect imgFrame = _imageView.frame;
    CGFloat zoomScale = _scrollView.zoomScale;
    CGFloat minimumZoomScale = _scrollView.minimumZoomScale;
    
    NSInteger panDirection = _panDirection;
    //先确认方向
    switch (panDirection) {
            //左上方/左下方/右下方/右上方
        case K12PictureCuttingPanLeftTop:
        case K12PictureCuttingPanLeftBottom:
        case K12PictureCuttingPanRightBottom:
        case K12PictureCuttingPanRightTop:{
            if(rect.size.width/imgFrame.size.width <= rect.size.height/imgFrame.size.height){
                panDirection = K12PictureCuttingPanTop;
            }else{
                panDirection = K12PictureCuttingPanLeft;
            }
        }
            break;
        default:
            break;
    }
    
    //决定放大缩小比率
    switch (panDirection) {
            //向上/向下
        case K12PictureCuttingPanTop:
        case K12PictureCuttingPanBottom:{
            //调整最小放大比率
            if(rect.size.height > imgFrame.size.height){
                CGFloat scale = rect.size.height/_scaleOriginRect.size.height;
                zoomScale = scale;
                minimumZoomScale = scale;
            }else{
                if(rect.size.width/imgFrame.size.width <= rect.size.height/imgFrame.size.height){
                    CGFloat scale = rect.size.height/_scaleOriginRect.size.height;
                    minimumZoomScale = MAX(1.0, scale);
                }
            }
        }
            break;
            //向左/向右
        case K12PictureCuttingPanLeft:
        case K12PictureCuttingPanRight:{
            //调整最小放大比率
            if(rect.size.width > imgFrame.size.width){
                CGFloat scale = rect.size.width/_scaleOriginRect.size.width;
                zoomScale = scale;
                minimumZoomScale = scale;
            }else{
                if(rect.size.width/imgFrame.size.width >= rect.size.height/imgFrame.size.height){
                    CGFloat scale = rect.size.width/_scaleOriginRect.size.width;
                    minimumZoomScale = MAX(1.0, scale);
                }
            }
        }
            break;
        default:
            break;
    }
    
    _scrollView.zoomScale = zoomScale;
    _scrollView.minimumZoomScale = minimumZoomScale;
}

//调整contentInset
- (void)adjustContentInsetWithCGRect:(CGRect)rect{
    CGRect imgFrame = _imageView.frame;
    
    //调整contentInset,保证在白框中都能看见裁剪的图
    CGRect scrollFrame = _scrollView.frame;
    CGFloat top = 0, bottom = 0, left = 0, right = 0;
    if(imgFrame.size.height <= scrollFrame.size.height){
        //改变contentsize
        CGSize size = _scrollView.contentSize;
        size.height = MAX(size.height, scrollFrame.size.height)-CGRectGetMinY(imgFrame)*2;
        _scrollView.contentSize = size;
        
        //修改imageview的大小
        CGPoint center = _imageView.center;
        //CGFloat originCenterY = size.height/2.0;
        //CGFloat yOffset = (center.y-originCenterY);
        center.y = _scrollView.frame.size.height/2.0;
        _imageView.center = center;
        imgFrame = _imageView.frame;
        
        top = rect.origin.y-CGRectGetMinY(imgFrame);
        bottom = CGRectGetHeight(scrollFrame)-CGRectGetMaxY(rect)+CGRectGetMinY(imgFrame);//-(size.height-CGRectGetMaxY(imgFrame));
    }else{
        top = rect.origin.y;
        bottom = CGRectGetHeight(scrollFrame)-CGRectGetMaxY(rect);
    }
    
    if(imgFrame.size.width <= scrollFrame.size.width){
        //改变contentsize
        CGSize size = _scrollView.contentSize;
        size.width = MAX(size.width, scrollFrame.size.width)-CGRectGetMinX(imgFrame)*2;
        _scrollView.contentSize = size;
        
        //修改imageview的大小
        CGPoint center = _imageView.center;
        center.x = _scrollView.frame.size.width/2.0;
        _imageView.center = center;
        imgFrame = _imageView.frame;
        
        left = rect.origin.x-CGRectGetMinX(imgFrame);
        right = CGRectGetWidth(scrollFrame)-CGRectGetMaxX(rect)+CGRectGetMinX(imgFrame);//-(size.width-CGRectGetMaxX(imgFrame));
    }else{
        left = rect.origin.x;
        right = CGRectGetWidth(scrollFrame)-CGRectGetMaxX(rect);
    }
    _scrollView.contentInset = UIEdgeInsetsMake(top, left, bottom, right);
}


//重新设置图片大小
- (void)resetImagesize{
    CGSize imgSize = _imageView.image.size;
    CGSize scrollSize = _scrollView.frame.size;
    
    //判断首先缩放的值
    float scaleX = scrollSize.width/imgSize.width;
    float scaleY = scrollSize.height/imgSize.height;
    
    CGRect scaleOriginRect = CGRectZero;
    //倍数小的，先到边缘
    if (scaleX > scaleY){
        //Y方向先到边缘
        float imgViewWidth = imgSize.width*scaleY;
        CGFloat maximumZoomScale1 = scrollSize.width*2/imgViewWidth;//默认可以放到宽*2
        CGFloat maximumZoomScale2 = imgSize.width/scrollSize.width;//原图正常比例
        _scrollView.maximumZoomScale = MAX(MAX(maximumZoomScale1,maximumZoomScale2),2.0);
        
        //比屏幕宽度缩进一点
        CGFloat minimumZoomScale = (scrollSize.height-__minimumZoomContentInset__*2)/scrollSize.height;
        imgViewWidth = imgViewWidth*minimumZoomScale;
        CGFloat imgViewHeight = scrollSize.height*minimumZoomScale;
        
        scaleOriginRect = (CGRect){scrollSize.width/2-imgViewWidth/2,__minimumZoomContentInset__,imgViewWidth,imgViewHeight};
    }else{
        //X先到边缘
        float imgViewHeight = imgSize.height*scaleX;
        CGFloat maximumZoomScale1 = scrollSize.height*2/imgViewHeight;//默认可以放到高*2
        CGFloat maximumZoomScale2 = imgSize.height/scrollSize.height;//原图正常比例
        _scrollView.maximumZoomScale = MAX(MAX(maximumZoomScale1,maximumZoomScale2),2.0);
        
        //比屏幕高度缩进一点
        CGFloat minimumZoomScale = (scrollSize.width-__minimumZoomContentInset__*2)/scrollSize.width;
        imgViewHeight = imgViewHeight*minimumZoomScale;
        CGFloat imgViewWidth = scrollSize.width*minimumZoomScale;
        
        scaleOriginRect = (CGRect){__minimumZoomContentInset__,scrollSize.height/2-imgViewHeight/2,imgViewWidth,imgViewHeight};
    }
    
    _imageView.frame = scaleOriginRect;
    _scaleOriginRect = scaleOriginRect;
}

#pragma mark - Delegate
- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    CGSize boundsSize = scrollView.bounds.size;
    CGRect imgFrame = _imageView.frame;
    CGSize contentSize = scrollView.contentSize;
    
    CGPoint centerPoint = CGPointMake(contentSize.width/2, contentSize.height/2);
    
    // center horizontally
    if (imgFrame.size.width <= boundsSize.width){
        centerPoint.x = boundsSize.width/2;
    }
    
    // center vertically
    if (imgFrame.size.height <= boundsSize.height){
        centerPoint.y = boundsSize.height/2;
    }
    
    _imageView.center = centerPoint;
    
    if(_panDirection == K12PictureCuttingPanOutside){
        [self adjustContentInsetWithCGRect:_cropView.cuttingRect];
    }
}

//通过imageview大小计算imageview中心点
- (CGPoint)imageOnScrollViewCenterWithSize:(CGSize)size{
    CGSize boundsSize = _scrollView.bounds.size;
    CGSize contentSize = _scrollView.contentSize;
    
    CGPoint centerPoint = CGPointMake(contentSize.width/2, contentSize.height/2);
    
    // center horizontally
    if (size.width <= boundsSize.width){
        centerPoint.x = boundsSize.width/2;
    }
    
    // center vertically
    if (size.height <= boundsSize.height){
        centerPoint.y = boundsSize.height/2;
    }
    
    return centerPoint;
}

//处理手势冲突
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if([gestureRecognizer isEqual:_cropPanGestureRecognizer]){
        CGPoint point = [gestureRecognizer locationInView:self];
        NSInteger direction = [self confirmPanDirectionWithCGpoint:point];
        if(direction != K12PictureCuttingPanOutside){
            return NO;
        }
    }
    return YES;
}

@end


/** 图片裁剪时用到的方框 */
@implementation K12PictureCuttingCropView

const CGFloat lineWidth = 2.0;
const CGFloat arcRadius = 4.0;
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (CGRect)cuttingRect{
    //图片裁剪区域
    return CGRectInset(self.frame, arcRadius, arcRadius);
}

- (void)setCuttingRect:(CGRect)cuttingRect{
    self.frame = CGRectInset(cuttingRect, -arcRadius, -arcRadius);
    [self setNeedsDisplay];
}

- (void)setTopLinePosition:(CGFloat)point{
    CGRect frame = self.frame;
    CGFloat minY = frame.origin.y;
    CGFloat originHeight = frame.size.height;
    frame.size.height = originHeight+(minY-point);
    frame.origin.y = point;
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)setLeftLinePosition:(CGFloat)point{
    CGRect frame = self.frame;
    CGFloat minX = frame.origin.x;
    CGFloat originWidth = frame.size.width;
    frame.size.width = originWidth+(minX-point);
    frame.origin.x = point;
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)setBottomLinePosition:(CGFloat)point{
    CGRect frame = self.frame;
    CGFloat maxY = CGRectGetMaxY(frame);
    CGFloat originHeight = frame.size.height;
    frame.size.height = originHeight+(point-maxY);
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)setRightLinePosition:(CGFloat)point{
    CGRect frame = self.frame;
    CGFloat maxX = CGRectGetMaxX(frame);
    CGFloat originWidth = frame.size.width;
    frame.size.width = originWidth+(point-maxX);
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)setLeftTopPoint:(CGPoint)point{
    CGRect frame = self.frame;
    CGPoint origin = frame.origin;
    CGSize size = frame.size;
    frame.size = CGSizeMake(size.width+(origin.x-point.x), size.height+(origin.y-point.y));
    frame.origin = point;
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)setLeftBottomPoint:(CGPoint)point{
    CGRect frame = self.frame;
    CGPoint origin = CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame));
    CGSize size = frame.size;
    frame.size = CGSizeMake(size.width+(origin.x-point.x), size.height+(point.y-origin.y));
    frame.origin.x = point.x;
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)setRightBottomPoint:(CGPoint)point{
    CGRect frame = self.frame;
    CGPoint origin = CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame));
    CGSize size = frame.size;
    frame.size = CGSizeMake(size.width+(point.x-origin.x), size.height+(point.y-origin.y));
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)setRightTopPoint:(CGPoint)point{
    CGRect frame = self.frame;
    CGPoint origin = CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame));
    CGSize size = frame.size;
    frame.size = CGSizeMake(size.width+(point.x-origin.x), size.height+(origin.y-point.y));
    frame.origin.y = point.y;
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    CGRect cuttingRect = CGRectInset(rect, arcRadius, arcRadius);
    
    //背景清空
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextClearRect(contextRef, rect);
    CGContextAddRect(contextRef, rect);
    CGContextSetFillColorWithColor(contextRef, [UIColor clearColor].CGColor);
    CGContextFillPath(contextRef);
    
    CGContextSaveGState(contextRef);
    {
        //透明背景
        CGContextClearRect(contextRef, cuttingRect);
        CGContextAddRect(contextRef, cuttingRect);
        CGContextSetFillColorWithColor(contextRef, [UIColor clearColor].CGColor);
        CGContextFillPath(contextRef);
        
        //在四周划线
        CGContextSetStrokeColorWithColor(contextRef, [UIColor colorWithRed:75/255.0 green:172/255.0 blue:238/255.0 alpha:1.0].CGColor);
        CGContextSetLineWidth(contextRef, lineWidth);
        CGContextAddRect(contextRef, CGRectInset(rect, arcRadius, arcRadius));
        CGContextStrokePath(contextRef);
        
        //上下左右四个圈
        CGContextSetFillColorWithColor(contextRef, [UIColor colorWithRed:75/255.0 green:172/255.0 blue:238/255.0 alpha:1.0].CGColor);
        
        CGMutablePathRef cgPath1 = CGPathCreateMutable();
        CGPathAddArc(cgPath1, &CGAffineTransformIdentity, arcRadius, arcRadius, arcRadius, 0, M_PI*2, 1);
        CGContextAddPath(contextRef, cgPath1);
        
        CGMutablePathRef cgPath2 = CGPathCreateMutable();
        CGPathAddArc(cgPath2, &CGAffineTransformIdentity, rect.size.width-arcRadius, arcRadius, arcRadius, 0, M_PI*2, 1);
        CGContextAddPath(contextRef, cgPath2);
        
        CGMutablePathRef cgPath3 = CGPathCreateMutable();
        CGPathAddArc(cgPath3, &CGAffineTransformIdentity, arcRadius, rect.size.height-arcRadius, arcRadius, 0, M_PI*2, 1);
        CGContextAddPath(contextRef, cgPath3);
        
        CGMutablePathRef cgPath4 = CGPathCreateMutable();
        CGPathAddArc(cgPath4, &CGAffineTransformIdentity, rect.size.width-arcRadius, rect.size.height-arcRadius, arcRadius, 0, M_PI*2, 1);
        CGContextAddPath(contextRef, cgPath4);
        
        CGContextFillPath(contextRef);
    }
    CGContextRestoreGState(contextRef);
}
@end

/** 图片裁剪区域背景 */
@implementation K12PictureCuttingBackgroundView
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        _overlayRect = CGRectZero;
    }
    return self;
}

- (void)setOverlayRect:(CGRect)overlayRect{
    if(CGRectEqualToRect(overlayRect, _overlayRect)) return;
    _overlayRect = overlayRect;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    //背景清空
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextClearRect(contextRef, rect);
    CGContextAddRect(contextRef, rect);
    CGContextSetFillColorWithColor(contextRef, self.backgroundColor.CGColor);
    CGContextFillPath(contextRef);
    
    CGContextSaveGState(contextRef);
    {
        //透明背景
        CGContextClearRect(contextRef, _overlayRect);
        CGContextAddRect(contextRef, _overlayRect);
        CGContextSetFillColorWithColor(contextRef, [UIColor clearColor].CGColor);
        CGContextFillPath(contextRef);
    }
    CGContextRestoreGState(contextRef);
}
@end