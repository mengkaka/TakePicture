//
//  CMInputManager.m
//  ChunMiao
//
//  Created by super on 14-12-4.
//  Copyright (c) 2014年 baidu. All rights reserved.
//

#import "CMInputManager.h"
#import "CMTextInputbar.h"
#import "UITextView+SLKAdditions.h"
#import "UIView+SLKAdditions.h"
#import "SLKUIConstants.h"

@interface CMInputManager ()<UITextViewDelegate>
@property (nonatomic, weak)  UIView *superview;

@property (nonatomic, strong)UIView *containerView;
@property (nonatomic, strong)UIView *shadowView;
@property (nonatomic, strong)CMTextInputbar *textInputBar;

@property (nonatomic, strong)NSLayoutConstraint *textInputBarHC;
@property (nonatomic, strong)NSLayoutConstraint *textInputBarBC;

@end

@implementation CMInputManager

#pragma mark - init
+ (instancetype)defultManager{
    static id defultManager__ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defultManager__ = [self managerWithSuperView:[UIApplication sharedApplication].keyWindow];
    });
    return defultManager__;
}

+ (instancetype)managerWithSuperView:(UIView *)superview{
    NSAssert(superview, NSLocalizedString(@"", @"CMInputManager must specify superview"));
    CMInputManager *manager = [[CMInputManager alloc] initWithSuperview:superview];
    return manager;
}

- (id)init{
    return nil;
}

- (void)dealloc{
    [self unregisterNotifications];
}

- (id)initWithSuperview:(UIView *)superview{
    if(self = [super init]){
        _superview = superview;
        [self commonInit];
    }
    return self;
}

- (void)commonInit{
    self.maxTextLength = -1;
    self.showInputViewWhenHiddenKeyboard = NO;
    self.showSendButton = YES;
    self.autoHideSendButton = YES;
    
    [self.superview addSubview:self.containerView];
    [self.containerView addSubview:self.shadowView];
    [self.containerView addSubview:self.textInputBar];
    
    [self setupConstraints];
    [self registerNotifications];
}

- (void)registerNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:self.textInputBar.textView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self.textInputBar.textView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark - getter
- (CMTextInputbar *)textInputBar{
    if(!_textInputBar){
        _textInputBar = [CMTextInputbar new];
        _textInputBar.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_textInputBar setSendTextTarget:self action:@selector(sendTextAction:)];
    }
    return _textInputBar;
}

- (UIView *)containerView{
    if(!_containerView){
        _containerView = [UIView new];
        _containerView.translatesAutoresizingMaskIntoConstraints = NO;
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.userInteractionEnabled = NO;
    }
    return _containerView;
}

- (UIView *)shadowView{
    if(!_shadowView){
        _shadowView = [UIView new];
        _shadowView.translatesAutoresizingMaskIntoConstraints = NO;
        _shadowView.backgroundColor = [UIColor blackColor];
        _shadowView.alpha = 0.0;
        _shadowView.userInteractionEnabled = NO;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismiss)];
        [_shadowView addGestureRecognizer:tap];
    }
    return _shadowView;
}

- (UIButton *)rightButton{
    return self.textInputBar.sendButton;
}

- (BOOL)showSendButton{
    return self.textInputBar.showSendButton;
}

- (BOOL)autoHideSendButton{
    return self.textInputBar.autoHideSendButton;
}

- (BOOL)keyBoardIsShowing{
    return (self.textInputBarBC.constant > 0);
}

- (CGFloat)deltaInputbarHeight{
    return self.textInputBar.textView.intrinsicContentSize.height-self.textInputBar.textView.font.lineHeight;
}

- (CGFloat)minimumInputbarHeight{
    return self.textInputBar.intrinsicContentSize.height;
}

- (CGFloat)currentInputbarHeight{
    CGFloat height = [self deltaInputbarHeight];
    
    height += roundf(self.textInputBar.textView.font.lineHeight*self.textInputBar.textView.numberOfLines);
    height += (kTextViewVerticalPadding*2.0);
    
    return height;
}

- (CGFloat)maximumInputbarHeight{
    CGFloat height = [self deltaInputbarHeight];
    
    height += roundf(self.textInputBar.textView.font.lineHeight*self.textInputBar.textView.maxNumberOfLines);
    height += (kTextViewVerticalPadding*2.0);
    
    return height;
}

- (CGFloat)appropriateInputbarHeight{
    CGFloat height = 0.0;
    
    if (self.textInputBar.textView.numberOfLines == 1) {
        height = [self minimumInputbarHeight];
    }else if (self.textInputBar.textView.numberOfLines < self.textInputBar.textView.maxNumberOfLines) {
        height += [self currentInputbarHeight];
    }else{
        height += [self maximumInputbarHeight];
    }
    
    if (height < [self minimumInputbarHeight]) {
        height = [self minimumInputbarHeight];
    }
    
    return roundf(height);
}

#pragma mark - setter
- (void)setShowSendButton:(BOOL)showSendButton{
    self.textInputBar.showSendButton = showSendButton;
}

- (void)setAutoHideSendButton:(BOOL)autoHideSendButton{
    self.textInputBar.autoHideSendButton = autoHideSendButton;
}

- (void)setShowInputViewWhenHiddenKeyboard:(BOOL)showInputViewWhenHiddenKeyboard{
    if(_showInputViewWhenHiddenKeyboard != showInputViewWhenHiddenKeyboard){
        _showInputViewWhenHiddenKeyboard = showInputViewWhenHiddenKeyboard;
        if(!self.keyBoardIsShowing){
            self.textInputBarBC.constant = showInputViewWhenHiddenKeyboard?0.0:(-self.textInputBarHC.constant);
        }
        BOOL bounces = (IOS7_OR_LATER?YES:NO);
        [self.containerView animateLayoutIfNeededWithBounce:bounces
                                                    options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                                 animations:NULL];;
    }
}

- (void)setPlaceholder:(NSString *)placeholder{
    self.textInputBar.placeholder = placeholder;
}

- (NSString *)placeholder{
    return self.textInputBar.placeholder;
}

#pragma mark - auto layout
- (void)setupConstraints{
    NSDictionary *views = @{@"containerView": self.containerView,};
    [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[containerView]|" options:0 metrics:nil views:views]];
    [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[containerView]|" options:0 metrics:nil views:views]];
    
    views = @{@"shadowView": self.shadowView,
              @"textInputBar": self.textInputBar,
              };
    NSDictionary *metrics = @{@"barHeight" : @(self.textInputBar.intrinsicContentSize.height),
                              @"barBottom" : @(0)};
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[shadowView]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[shadowView]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textInputBar]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[textInputBar(barHeight)]-(==barBottom)-|" options:0 metrics:metrics views:views]];
    
    self.textInputBarHC = [self.containerView constraintForView:self.textInputBar andAttribute:NSLayoutAttributeHeight];
    self.textInputBarBC = [self.containerView constraintForView:self.textInputBar andAttribute:NSLayoutAttributeBottom];
    
    self.textInputBarHC.constant = [self appropriateInputbarHeight];
    if(!self.showInputViewWhenHiddenKeyboard){
        self.textInputBarBC.constant = -self.textInputBarHC.constant;
    }
    [self.containerView layoutIfNeeded];
}

#pragma mark - action
- (void)sendTextAction:(NSString *)text{
    if(self.delegate && [self.delegate respondsToSelector:@selector(inputManager:willSendText:)]){
        [self.delegate inputManager:self willSendText:self.textInputBar.textView.text];
    }
}

- (void)didChangeTextViewText:(NSNotification *)notification{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textInputBar.textView]) {
        return;
    }
    
    [self textDidUpdate:YES];
}

- (void)willShowOrHideKeyboard:(NSNotification *)notification{
    if (self.textInputBar.textView.didNotResignFirstResponder) {
        return;
    }
    
    // Skips this if it's not the expected textView.
//    if (![self.textInputBar.textView isFirstResponder]) {
//        return;
//    }
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGFloat keyboardHeight = MIN(CGRectGetWidth(endFrame), CGRectGetHeight(endFrame));
    
    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    if(show){
        if(self.delegate && [self.delegate respondsToSelector:@selector(inputManagerWillShowKeyboard:)]){
            [self.delegate inputManagerWillShowKeyboard:self];
        }
    }else{
        if(self.delegate && [self.delegate respondsToSelector:@selector(inputManagerDidHiddenKeyboard:)]){
            [self.delegate inputManagerDidHiddenKeyboard:self];
        }
    }
    
    // Updates the height constraints' constant
    if(self.showInputViewWhenHiddenKeyboard){
        self.textInputBarBC.constant = show ? keyboardHeight : 0.0;
    }else{
        if(show){
            self.textInputBarBC.constant = keyboardHeight;
        }else{
            self.textInputBarBC.constant = -self.textInputBarHC.constant;
        }
    }
    
    if(show){
        [UIView animateWithDuration:0.25 animations:^{
            self.shadowView.alpha = 0.2;
        } completion:^(BOOL finished) {
            self.containerView.userInteractionEnabled = YES;
            self.shadowView.userInteractionEnabled = YES;
        }];
    }else{
        [UIView animateWithDuration:0.25 animations:^{
            self.shadowView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.containerView.userInteractionEnabled = NO;
            self.shadowView.userInteractionEnabled = NO;
        }];
    }
    
    // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
    [self.containerView animateLayoutIfNeededWithDuration:duration
                                          bounce:NO
                                         options:(curve<<16)|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                      animations:NULL];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification{

}

- (void)textDidUpdate:(BOOL)animated{
    CGFloat inputbarHeight = [self appropriateInputbarHeight];
    
    if (inputbarHeight != self.textInputBarHC.constant)
    {
        self.textInputBarHC.constant = inputbarHeight;
        if (animated) {
            BOOL bounces = (IOS7_OR_LATER?[self.textInputBar.textView isFirstResponder]:NO);
            [self.containerView animateLayoutIfNeededWithBounce:bounces
                                               options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                            animations:^{
                                                [self.textInputBar.textView scrollToCaretPositonAnimated:NO];
                                            }];
        }
        else {
            [self.containerView layoutIfNeeded];
        }
    }
}

#pragma mark - control

+(NSMutableSet *)cache{
    static NSMutableSet *cache__ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache__ = [NSMutableSet set];
    });
    return cache__;
}

- (NSMutableSet *)cache{
    return self.class.cache;
}

- (NSUInteger)defaultNumberOfLines{
    if (UI_IS_IPAD) {
        return 8;
    }
    if (UI_IS_IPHONE4) {
        return 4;
    }
    else {
        return 6;
    }
}

- (void)cleanText{
    [self.textInputBar cleanText];
}

- (void)present{
    [self.cache addObject:self];
    [self.textInputBar.textView becomeFirstResponder];
}

- (void)dismiss{
    [self.cache removeObject:self];
    [self.textInputBar.textView resignFirstResponder];
}
@end
