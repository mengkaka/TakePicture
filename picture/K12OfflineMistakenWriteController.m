//
//  K12MistakenWriteController.m
//  TakePhoto
//
//  Created by mengkai on 15/10/19.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12OfflineMistakenWriteController.h"
#import "K12PictureBrowserController.h"
#import "K12TextInputBar.h"
#import "Masonry.h"

@interface K12OfflineMistakenWriteController()<UIScrollViewDelegate,K12PictureBrowserControllerDelegate>
{
    UIView *_lastImageView;
}
@end
@implementation K12OfflineMistakenWriteController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
        _imageSet = [[NSMutableArray alloc]init];
    }
    return self;
}

- (BOOL)navigationBarHidden{
    return NO;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:K12TextInputBarHeightDidchangeNotification object:_inputManager];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    /*
     UIButton *rightBarButton = [UIButton buttonWithType:UIButtonTypeSystem];
     [rightBarButton setTitle:@"保存" forState:UIControlStateNormal];
     [rightBarButton setFrame:CGRectMake(0, 0, 58, 44)];
     [rightBarButton setTitleColor:HEXRGBCOLOR(0xfcf069) forState:UIControlStateNormal];
     [rightBarButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
     */
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSend:)];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(sendAction:)];
    [rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:252/255.0 green:240/255.0 blue:105/255.0 alpha:0.4]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    self.title = @"错题预览";
    
    self.view.backgroundColor = [UIColor whiteColor];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.right.equalTo(self.view);
    }];
    scrollView.delegate = self;
    _scrollView = scrollView;
    
    UIView *scrollContentView = [[UIView alloc]init];
    scrollContentView.backgroundColor = [UIColor redColor];
    [scrollView addSubview:scrollContentView];
    [scrollContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.right.equalTo(_scrollView);
    }];
    _scrollContentView = scrollContentView;
    
    _inputManager = [K12TextInputManager managerWithSuperView:self.view];
    _inputManager.placeholder = @"请输入错题备注";
    [_inputManager.textInputBar.topActionButton addTarget:self action:@selector(selectImage:) forControlEvents:UIControlEventTouchUpInside];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textInputBarHeightDidchangeAction:) name:K12TextInputBarHeightDidchangeNotification object:_inputManager];
    
    scrollView.contentInset = UIEdgeInsetsMake(0, 0, _inputManager.textInputBar.intrinsicContentSize.height, 0);
    scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, _inputManager.textInputBar.intrinsicContentSize.height, 0);
    [self updateScrollContentViewContent];
}

- (void)addMistakenImage:(UIImage *)image{
    [_imageSet addObject:image];
    if(_imageSet.count >= 2)_inputManager.buttonHidden = YES;
    [self updateScrollContentViewContent];
    
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:252/255.0 green:240/255.0 blue:105/255.0 alpha:1.0]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)updateScrollContentViewContent{
    for (UIView *subview in _scrollView.subviews) {
        if(_scrollContentView != subview){
            [subview removeFromSuperview];
        }
    }
    
    __block UIView *lastView = nil;
    UIImage *cloaseImage = [UIImage imageNamed:@"k12_mistaken_image_close"];
    [_imageSet enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        if([obj isKindOfClass:UIImage.class]){
            UIImage *image = (UIImage *)obj;
            
            CGSize size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.width/image.size.width*image.size.height);
            UIImageView *imageView = [[UIImageView alloc]init];
            imageView.backgroundColor = [UIColor clearColor];
            imageView.image = image;
            [_scrollView addSubview:imageView];
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(@0);
                make.top.equalTo((lastView)?lastView.mas_bottom:@0);
                make.width.equalTo(@(size.width));
                make.height.equalTo(@(size.height));
            }];
            lastView = imageView;
            imageView.tag = idx+100;
            
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapImageViewAction:)];
            [imageView addGestureRecognizer:tap];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setImage:cloaseImage forState:UIControlStateNormal];
            [button setImage:cloaseImage forState:UIControlStateHighlighted];
            [button addTarget:self action:@selector(closeThisImageAction:) forControlEvents:UIControlEventTouchUpInside];
            [imageView addSubview:button];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(@0);
                make.top.equalTo(@0);
                make.width.equalTo(@(cloaseImage.size.width+30));
                make.height.equalTo(@(cloaseImage.size.height+30));
            }];
            
        }
    }];
    
    if (lastView) {
        [_scrollContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(lastView.mas_bottom);
        }];
    }else{
        [_scrollContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
        }];
    }
    _lastImageView = lastView;
}

- (void)closeThisImageAction:(UIButton *)sender{
    /*if (_imageSet.count == 1) {
     [MBProgressHUD showMessage:@"至少得上传一张图片～" view:nil];
     return;
     }else */if(_imageSet.count == 2){
         _inputManager.buttonHidden = NO;
     }
    NSInteger index = sender.superview.tag;
    UIView *deleteView = [_scrollView viewWithTag:index];
    [deleteView removeFromSuperview];
    [_imageSet removeObjectAtIndex:index-100];
    [self updateScrollContentViewContent];
    [_scrollView layoutIfNeeded];
    
    if(_imageSet.count == 0){
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:252/255.0 green:240/255.0 blue:105/255.0 alpha:0.4]} forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    /*_scrollView.userInteractionEnabled = NO;
     NSInteger index = sender.superview.tag;
     UIView *deleteView = [_scrollView viewWithTag:index];
     [deleteView mas_updateConstraints:^(MASConstraintMaker *make) {
     make.left.equalTo(@(-self.view.frame.size.width));
     make.right.equalTo(_scrollView.left);
     }];
     [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
     [_scrollView layoutIfNeeded];
     } completion:^(BOOL finished) {
     UIView *bottomView = [_scrollView viewWithTag:index+1];
     UIView *topView = [_scrollView viewWithTag:index-1];
     if(bottomView){
     [bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
     make.top.equalTo((topView?@(CGRectGetMaxY(topView.frame)):@0));
     }];
     }
     
     [deleteView removeFromSuperview];
     [_imageSet removeObjectAtIndex:index-100];
     
     for (NSInteger i = index+1; i < _imageSet.count; i++ ) {
     [[_scrollView viewWithTag:i] setTag:i-1];
     }
     
     UIView *lastImageView = [_scrollView viewWithTag:100+(_imageSet.count-1)];
     if (_lastImageView != lastImageView) {
     if(lastImageView){
     [_scrollContentView mas_updateConstraints:^(MASConstraintMaker *make) {
     make.bottom.equalTo(_lastImageView.mas_bottom);
     }];
     }else{
     [_scrollContentView mas_updateConstraints:^(MASConstraintMaker *make) {
     make.bottom.equalTo(@0);
     }];
     }
     _lastImageView = lastImageView;
     }
     [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
     [_scrollView layoutIfNeeded];
     } completion:^(BOOL finished) {
     _scrollView.userInteractionEnabled = YES;
     }];
     }];*/
}

- (void)tapImageViewAction:(UITapGestureRecognizer *)sender{
}

//键盘高度发生变化
- (void)textInputBarHeightDidchangeAction:(NSNotification *)note{
    CGFloat animationDuration = [[note.userInfo objectForKey:K12TextInputBarAnimationDurationUserInfoKey] floatValue];
    CGFloat inputBarHeight = [[note.userInfo objectForKey:K12TextInputBarHeightUserInfoKey] floatValue];
    
    CGFloat bottomOffset = _scrollView.contentOffset.y+_scrollView.frame.size.height-_scrollView.contentInset.bottom;
    [UIView animateWithDuration:animationDuration animations:^{
        _scrollView.contentInset = UIEdgeInsetsMake(64, 0, inputBarHeight, 0);
        _scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, inputBarHeight, 0);
        if(_scrollView.contentSize.height > CGRectGetHeight(_scrollView.frame)-64-_scrollView.contentInset.bottom){
            _scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x, bottomOffset-(_scrollView.frame.size.height-_scrollView.contentInset.bottom));
        }
    }];
}

- (void)selectImage:(UIButton *)sender{
    if(self.delegate && [self.delegate respondsToSelector:@selector(offlineMistakenWriteControllerWillAddMistakenImage:)]){
        [self.delegate offlineMistakenWriteControllerWillAddMistakenImage:self];
    }
}

- (void)cancelSend:(UIBarButtonItem *)sender{
    [_inputManager dismiss];
    if(self.delegate && [self.delegate respondsToSelector:@selector(offlineMistakenWriteControllerDidCancel:)]){
        [self.delegate offlineMistakenWriteControllerDidCancel:self];
    }
}

- (void)sendAction:(UIBarButtonItem *)sender{
    [_inputManager dismiss];
    NSString *text = _inputManager.textInputBar.textView.text;
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(!text || !text.length){
        //[MBProgressHUD showMessage:@"请输入描述文字～" view:nil];
        //return;
    }
    
    //判断文字长度
    if(_inputManager.textInputBar.maxCharacterNumber < _inputManager.textInputBar.currentCharacterNumber){
        return;
    }
    if(self.delegate && [self.delegate respondsToSelector:@selector(offlineMistakenWriteController:willUploadWithSummary:withImages:)]){
        [self.delegate offlineMistakenWriteController:self willUploadWithSummary:text withImages:_imageSet];
    }
}

#pragma mark - Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [_inputManager dismiss];
}

- (void)pictureBrowserController:(K12PictureBrowserController *)controller didConfirmImage:(UIImage *)image{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
