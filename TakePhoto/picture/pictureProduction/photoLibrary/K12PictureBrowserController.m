//
//  K12ImageBrowserViewController.m
//  TakePhoto
//
//  Created by mengkai on 15/10/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12PictureBrowserController.h"

@implementation K12PictureBrowserController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
        _statusBarHidden = NO;
        _showBottomBar = YES;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image{
    if(self = [super init]){
        _image = image;
    }
    return self;
}

- (void)dealloc{
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    if(!_image || ![_image isKindOfClass:UIImage.class]){
        return;
    }
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIScrollView *scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
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
    [self.view addSubview:scrollView];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
    _scrollView = scrollView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    //imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.image = _image;
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [scrollView addSubview:imageView];
    _imageView = imageView;
    [self resetImagesize];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    [scrollView addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapAction:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [scrollView addGestureRecognizer:singleTap];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    UIBarButtonItem *flexibleSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonAction:)];
    UIToolbar *toolBar = [[UIToolbar alloc]init];
    toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    [toolBar setItems:@[flexibleSpaceItem,barButtonItem]];
    [self.view addSubview:toolBar];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:toolBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:toolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:44.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:toolBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    _toolBar = toolBar;
    if(!_showBottomBar){
        toolBar.hidden = YES;
    }
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
}

#pragma mark - Action

- (void)setShowBottomBar:(BOOL)showBottomBar{
    if(_showBottomBar != showBottomBar){
        _showBottomBar = showBottomBar;
        if(_toolBar){
            _toolBar.hidden = _showBottomBar?NO:YES;
        }
    }
}

- (void)singleTapAction:(UITapGestureRecognizer *)sender{
    _statusBarHidden = !_statusBarHidden;
    [UIView animateWithDuration:0.2 animations:^{
        self.navigationController.navigationBar.alpha = _statusBarHidden?0.0:1.0;
        _toolBar.alpha = _statusBarHidden?0.0:1.0;
    } completion:^(BOOL finished) {
        self.view.backgroundColor = _statusBarHidden?UIColor.blackColor:UIColor.whiteColor;
        //self.navigationController.navigationBarHidden = _statusBarHidden?YES:NO;
        //_toolBar.hidden = _statusBarHidden?YES:NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)doubleTapAction:(UITapGestureRecognizer *)sender{
    if(!_statusBarHidden){
        [self singleTapAction:sender];
    }
    CGPoint pointInView = [sender locationInView:_imageView];
    [self zoomInZoomOut:pointInView];
}

- (void) zoomInZoomOut:(CGPoint)point{
    CGFloat newZoomScale = _scrollView.zoomScale == 1 ? _scrollView.maximumZoomScale : 1;
    
    CGSize scrollViewSize = _scrollView.bounds.size;
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = point.x - (w / 2.0f);
    CGFloat y = point.y - (h / 2.0f);
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    [_scrollView zoomToRect:rectToZoomTo animated:YES];
}

- (void)resetImagesize{
    CGSize imgSize = _imageView.image.size;
    
    //判断首先缩放的值
    float scaleX = _scrollView.frame.size.width/imgSize.width;
    float scaleY = _scrollView.frame.size.height/imgSize.height;
    
    CGRect scaleOriginRect = CGRectZero;
    //倍数小的，先到边缘
    if (scaleX > scaleY){
        //Y方向先到边缘
        float imgViewWidth = imgSize.width*scaleY;
        _scrollView.maximumZoomScale = MAX(_scrollView.frame.size.width/imgViewWidth,2.0);
        
        scaleOriginRect = (CGRect){_scrollView.frame.size.width/2-imgViewWidth/2,0,imgViewWidth,_scrollView.frame.size.height};
    }else{
        //X先到边缘
        float imgViewHeight = imgSize.height*scaleX;
        _scrollView.maximumZoomScale = MAX(_scrollView.frame.size.height/imgViewHeight,2.0);
        
        scaleOriginRect = (CGRect){0,_scrollView.frame.size.height/2-imgViewHeight/2,_scrollView.frame.size.width,imgViewHeight};
    }
    
    _imageView.frame = scaleOriginRect;
}

- (void)doneButtonAction:(UIBarButtonItem *)sender{
    if(_delegate && [_delegate respondsToSelector:@selector(pictureBrowserController:didConfirmImage:)]){
        [_delegate pictureBrowserController:self didConfirmImage:_image];
    }
}

- (void)resetImagePositionWithInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) return;
    CGFloat width = 0.0;
    CGFloat height = 0.0;
    if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        width = MAX(_scrollView.frame.size.width, _scrollView.frame.size.height);
        height = MIN(_scrollView.frame.size.width, _scrollView.frame.size.height);
    }else{
        width = MIN(_scrollView.frame.size.width, _scrollView.frame.size.height);
        height = MAX(_scrollView.frame.size.width, _scrollView.frame.size.height);
    }
    
    CGSize imgViewSize = _imageView.frame.size;
    
    CGRect scaleOriginRect = CGRectMake((width-imgViewSize.width)/2, (height-imgViewSize.height)/2, imgViewSize.width, imgViewSize.height);
    _imageView.frame = scaleOriginRect;
}

- (void)deviceOrientationDidChangeAction:(NSNotification *)note{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        [self resetImagePositionWithInterfaceOrientation:(UIInterfaceOrientation)deviceOrientation];
    }
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation{
    return UIStatusBarAnimationNone;
}

- (BOOL)prefersStatusBarHidden{
    return (_statusBarHidden && (self.navigationController == nil));
}

//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
//    //[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//
//    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
//    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
//        [self resetImagePositionWithInterfaceOrientation:(UIInterfaceOrientation)deviceOrientation];
//    }
//}

//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
//    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
//
//    [self resetImagePositionWithInterfaceOrientation:toInterfaceOrientation];
//}

@end