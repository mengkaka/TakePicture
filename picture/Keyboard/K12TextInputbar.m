//
//  K12TextInputbar.m
//  TakePhoto
//
//  Created by mengkai on 15/10/19.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12TextInputbar.h"
#import "UIView+SLKAdditions.h"
#import "UITextView+SLKAdditions.h"
#import "SLKUIConstants.h"

@interface K12TextInputbar ()<UITextViewDelegate>
@property (nonatomic, strong) NSLayoutConstraint *topActionButtonHC;
@property (nonatomic, strong) NSLayoutConstraint *characterNumerLabelTC;
@property (nonatomic, strong) NSLayoutConstraint *characterNumerLabelHC;
@end

@interface K12CharacterNumerLabel : UILabel
@end
@implementation K12CharacterNumerLabel
- (CGSize)intrinsicContentSize{
    return CGSizeMake(UIViewNoIntrinsicMetric,kTextInputbarCharacterNumberHeight);
}
@end

@implementation K12TextInputbar

//获取文字长度 两个英文字母为一个汉字长度
static inline NSInteger stringDataLength(NSString *string){
    if(!string || ![string isKindOfClass:NSString.class]) return 0;
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData* da = [string dataUsingEncoding:enc];
    return ([da length]%2 == 0) ? [da length]/2 : ([da length]+1)/2;
}

- (id)init{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit{
    self.translucent = NO;
    _buttonHidden = NO;
    _maxCharacterNumber = 100;
    _currentCharacterNumber = 0;
    _showCharacterNumber = YES;
    
    if (!IOS7_OR_LATER) {
        self.tintColor = HEXRGBCOLOR(0xffffff);
    }else{
        self.barTintColor = HEXRGBCOLOR(0xffffff);
    }
    
    _lineView1 = [self lineView];
    _lineView2 = [self lineView];
    _lineView2.hidden = YES;
    [self addSubview:self.topActionButton];
    [self addSubview:self.textView];
    [self addSubview:self.characterNumerLabel];
    [self addSubview:_lineView1];
    [self addSubview:_lineView2];
    
    [self setupViewConstraints];
}

#pragma mark - getter
- (UIButton *)topActionButton{
    if (!_topActionButton){
        _topActionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _topActionButton.translatesAutoresizingMaskIntoConstraints = NO;
        _topActionButton.backgroundColor = [UIColor whiteColor];//[UIColor colorWithRed:249/255.0 green:249/255.0 blue:249/255.0 alpha:1];
        _topActionButton.titleLabel.font = [UIFont boldSystemFontOfSize:(UI_IS_IPHONE6PLUS?17.0:14.0)];
        [_topActionButton setTitleColor:[UIColor colorWithRed:61/255.0 green:151/255.0 blue:230/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_topActionButton setTitle:NSLocalizedString(@"  补拍此题", nil) forState:UIControlStateNormal];
        [_topActionButton setImage:[UIImage imageNamed:@"k12_mistaken_camera_icon"] forState:UIControlStateNormal];
        [_topActionButton setImage:[UIImage imageNamed:@"k12_mistaken_camera_icon"] forState:UIControlStateHighlighted];
    }
    return _topActionButton;
}

- (SLKTextView *)textView{
    if (!_textView){
        _textView = [SLKTextView new];
        _textView.backgroundColor = [UIColor whiteColor];//[UIColor colorWithRed:249/255.0 green:249/255.0 blue:249/255.0 alpha:1];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:17.0];
        _textView.placeholderColor = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1];
        _textView.maxNumberOfLines = [self defaultNumberOfLines];
        _textView.placeholder = @"请输入内容";
        
        _textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        _textView.spellCheckingType = UITextSpellCheckingTypeDefault;
        
        _textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textView.keyboardType = UIKeyboardTypeDefault;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, -1, 0, 1);
        _textView.delegate = self;
        
        //_textView.layer.cornerRadius = 5.0;
        //_textView.layer.borderWidth = 0.5;
        //_textView.layer.borderColor =  [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0].CGColor;
        
        // Registers the loupe gesture to detect when it will become visible
        for (UIGestureRecognizer *gesture in _textView.gestureRecognizers) {
            if ([gesture isKindOfClass:NSClassFromString(@"UIVariableDelayLoupeGesture")]) {
                [gesture addTarget:self action:@selector(willShowLoupe:)];
            }
        }
    }
    return _textView;
}

- (UILabel *)characterNumerLabel{
    if(!_characterNumerLabel){
        _characterNumerLabel = [[UILabel alloc]init];
        _characterNumerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _characterNumerLabel.backgroundColor = [UIColor clearColor];
        _characterNumerLabel.font = [UIFont systemFontOfSize:kTextInputbarCharacterNumberHeight-1];
        _characterNumerLabel.textColor = [UIColor colorWithRed:98/255.0 green:99/255.0 blue:101/255.0 alpha:1.0];
        _characterNumerLabel.highlightedTextColor = [UIColor colorWithRed:227/255.0 green:10/255.0 blue:30/255.0 alpha:1.0];
        _characterNumerLabel.textAlignment = NSTextAlignmentRight;
        [self textViewDidChange:_textView];
    }
    return _characterNumerLabel;
}

- (void)setMaxCharacterNumber:(NSInteger)maxCharacterNumber{
    if(_maxCharacterNumber != maxCharacterNumber){
        _maxCharacterNumber = maxCharacterNumber;
        [self textViewDidChange:_textView];
    }
}

- (UIView *)lineView{
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor colorWithRed:215/255.0 green:215/255.0 blue:215/255.0 alpha:1.0];
    return view;
}

- (void)setPlaceholder:(NSString *)placeholder{
    self.textView.placeholder = placeholder;
}

- (NSString *)placeholder{
    return self.textView.placeholder;
}

#pragma mark - UIView Overrides

- (CGSize)intrinsicContentSize{
    return CGSizeMake(UIViewNoIntrinsicMetric,
                      (_buttonHidden?0.0:kTextInputbarTopActionButtonHeight)
                      +self.textView.intrinsicContentSize.height+kTextViewVerticalPadding*2
                      +(_showCharacterNumber?(kTextInputbarCharacterNumberHeight+kTextViewVerticalPadding):0.0));
}

+ (BOOL)requiresConstraintBasedLayout{
    return YES;
}

#pragma mark - Magnifying Glass handling

- (void)willShowLoupe:(UIGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.textView.loupeVisible = YES;
    }else {
        self.textView.loupeVisible = NO;
    }
    
    // We still need to notify a selection change in the textview after the magnifying class is dismissed
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self textViewDidChangeSelection:self.textView];
    }
}

#pragma mark - action
- (void)cleanText{
    self.textView.text = @"";
}

- (void)setButtonHidden:(BOOL)buttonHidden{
    [self setButtonHidden:buttonHidden animated:NO];
}

- (void)setButtonHidden:(BOOL)buttonHidden animated:(BOOL)animated{
    if(_buttonHidden != buttonHidden){
        _buttonHidden = buttonHidden;
        self.topActionButtonHC.constant = buttonHidden?0.0:kTextInputbarTopActionButtonHeight;
        self.topActionButton.alpha = buttonHidden?0.0:1.0;
        if(animated){
            [self animateLayoutIfNeededWithDuration:0.2
                                             bounce:NO
                                            options:UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                         animations:NULL];
        }else{
            [self layoutIfNeeded];
        }
    }
}

- (void)setShowCharacterNumber:(BOOL)showCharacterNumber{
    [self setShowCharacterNumber:showCharacterNumber animated:NO];
}

- (void)setShowCharacterNumber:(BOOL)showCharacterNumber animated:(BOOL)animated{
    if(_showCharacterNumber != showCharacterNumber){
        _showCharacterNumber = showCharacterNumber;
        self.characterNumerLabelTC.constant = showCharacterNumber?kTextViewVerticalPadding:0.0;
        self.characterNumerLabelHC.constant = showCharacterNumber?kTextInputbarCharacterNumberHeight:0.0;
        if(animated){
            [self animateLayoutIfNeededWithDuration:0.2
                                             bounce:NO
                                            options:UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                         animations:NULL];
        }else{
            [self layoutIfNeeded];
        }
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        [textView insertNewLineBreak];
        return NO;
        //不让用户输入emoji
    }else if([textView isFirstResponder] && ([[[textView textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textView textInputMode] primaryLanguage])){
        //删除内容
        if(range.length > 0 && range.length != NSNotFound){
            return YES;
        }else{
            return NO;
        }
    }else {
        NSDictionary *userInfo = @{@"text": text, @"range": [NSValue valueWithRange:range]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewTextWillChangeNotification object:self.textView userInfo:userInfo];
        
        return YES;
    }
}

- (void)textViewDidChange:(UITextView *)textView{
    if(_textView == textView){
        if(_showCharacterNumber){
            NSString *text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            _currentCharacterNumber =  stringDataLength(text);
            NSInteger characterNumber = (_maxCharacterNumber - _currentCharacterNumber);
            if(characterNumber >= 0){
                _characterNumerLabel.highlighted = NO;
                _characterNumerLabel.text = [NSString stringWithFormat:@"还可以输入%ld个字",characterNumber];
            }else{
                _characterNumerLabel.highlighted = YES;
                _characterNumerLabel.text = [NSString stringWithFormat:@"已超出%ld个字",ABS(characterNumber)];
            }
        }
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView{
    if (self.textView.isLoupeVisible) {
        return;
    }
    [self textViewDidChange:textView];
    NSDictionary *userInfo = @{@"range": [NSValue valueWithRange:textView.selectedRange]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewSelectionDidChangeNotification object:self.textView userInfo:userInfo];
}

- (BOOL)canPressSendButton{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return text.length > 0 ? YES : NO;
}


#pragma mark - auto layout
- (NSUInteger)defaultNumberOfLines{
    if (UI_IS_IPAD) {
        return 8;
    }
    if (UI_IS_IPHONE4) {
        return 3;
    }
    else {
        return 3;
    }
}

- (void)setupViewConstraints{
    NSDictionary *views = @{@"textView": self.textView,
                            @"topActionButton": self.topActionButton,
                            @"characterNumerLabel": _characterNumerLabel,
                            @"lineView1": _lineView1,
                            @"lineView2": _lineView2
                            };
    
    NSDictionary *metrics = @{@"topActionButtonHeight" : @(kTextInputbarTopActionButtonHeight),
                              @"textViewHeight" : @(self.textView.intrinsicContentSize.height),
                              @"characterNumberHeight" : @(kTextInputbarCharacterNumberHeight),
                              @"ver": @(kTextViewVerticalPadding),
                              @"hor": @(kTextViewHorizontalPadding)
                              };
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==0)-[topActionButton]-(==0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[textView]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[characterNumerLabel]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==0)-[topActionButton(==topActionButtonHeight)]-(==ver)-[textView(==textViewHeight@250)]-(==ver)-[characterNumerLabel(==characterNumberHeight@300)]-(==ver)-|" options:0 metrics:metrics views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView2 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView1 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView2 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:1]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView2 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:1]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView1 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.topActionButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_lineView2 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    
    
    self.topActionButtonHC = [self constraintForView:self.topActionButton andAttribute:NSLayoutAttributeHeight];
    self.characterNumerLabelTC = [self constraintForView:self.characterNumerLabel andAttribute:NSLayoutAttributeTop];
    self.characterNumerLabelHC = [self constraintForView:self.characterNumerLabel andAttribute:NSLayoutAttributeHeight];
    [self layoutIfNeeded];
}

@end
