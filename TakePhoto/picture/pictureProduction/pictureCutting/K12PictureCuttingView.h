//
//  K12PictureCuttingView.h
//  TakePhoto
//
//  Created by mengkai on 15/10/10.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 图片裁剪视图 */
@class K12PictureCuttingCropView, K12PictureCuttingBackgroundView;

typedef NS_ENUM(NSInteger, K12PictureCuttingOrientation){
    K12PictureCuttingOrientationPortrait,
    K12PictureCuttingOrientationPortraitUpsideDown,
    K12PictureCuttingOrientationLandscapeLeft,
    K12PictureCuttingOrientationLandscapeRight,
};

@interface K12PictureCuttingView : UIView<UIScrollViewDelegate,UIGestureRecognizerDelegate>
{
    UIScrollView *_scrollView;  //控制图片缩放
    UIImageView *_imageView;    //显示图片容器
    
    K12PictureCuttingCropView *_cropView;   //显示裁剪的区域
    K12PictureCuttingBackgroundView *_grayFloatingView;  //灰色背景内容
    
    UIPanGestureRecognizer *_cropPanGestureRecognizer;  //裁剪区域推拽手势

    //滑动方向的枚举
    NS_ENUM(NSInteger, K12PictureCuttingPanDirection){
        K12PictureCuttingPanTop,        //向上方滑动
        K12PictureCuttingPanLeft,       //向左方滑动
        K12PictureCuttingPanBottom,     //向下方滑动
        K12PictureCuttingPanRight,      //向右方滑动
        K12PictureCuttingPanLeftTop,    //向左上滑动
        K12PictureCuttingPanLeftBottom, //向左下滑动
        K12PictureCuttingPanRightBottom,//向右下滑动
        K12PictureCuttingPanRightTop,   //向右上滑动
        
        K12PictureCuttingPanCropView,   //拖动整个裁剪区域
        
        K12PictureCuttingPanOutside     //拖动区域无效
    } _panDirection;
    
    
    CGPoint _panStartPoint;  //拖动开始时点击的点
    CGRect _cropViewPanStartFrame;  //拖动开始时cropView的frame
    CGRect _scaleOriginRect;    //scrollview的缩放比例为1时，图片尺寸
    
    NSTimer *_timer;    //计时器
    BOOL _rotationning; //旋转中flag
}


@property (nonatomic, assign) UIEdgeInsets cuttingInset;    //指定裁剪区域的inset
@property (nonatomic, assign) UIEdgeInsets defultCorpInset;    //指定裁剪框的inset
@property (nonatomic, assign) K12PictureCuttingOrientation cuttingOrientation;  //裁剪的方向

- (void)setCuttingImage:(UIImage *__nullable)image;
- (UIImage *__nullable)beginCuttingImage;
@end


/** 图片裁剪时用到的方框 */
@interface K12PictureCuttingCropView : UIView
{

}
@property(nonatomic, readonly) CALayer *overlayLayer;   //正常需要覆盖的层
@property(nonatomic, assign) CGRect   cuttingRect;    //图片裁剪区域
- (void)setTopLinePosition:(CGFloat)point;
- (void)setLeftLinePosition:(CGFloat)point;
- (void)setBottomLinePosition:(CGFloat)point;
- (void)setRightLinePosition:(CGFloat)point;

- (void)setLeftTopPoint:(CGPoint)point;
- (void)setLeftBottomPoint:(CGPoint)point;
- (void)setRightBottomPoint:(CGPoint)point;
- (void)setRightTopPoint:(CGPoint)point;
@end

/** 图片裁剪区域背景 */
@interface K12PictureCuttingBackgroundView : UIView
@property(nonatomic, assign) CGRect overlayRect;   //不需要显示背景的区域
@end