//
//  ViewController2.h
//  TakePhoto
//
//  Created by mengkai on 15/9/24.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVCaptureSession;

@interface ViewController2 : UIViewController

@end


@interface ViewControllerView : UIView
@property (nonatomic) AVCaptureSession *session;
@end