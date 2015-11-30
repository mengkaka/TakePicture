//
//  K12OfflineMistakenProductionControllew.h
//  TakePhoto
//
//  Created by mengkai on 15/10/20.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "K12TakePictureController.h"
#import "K12OfflineMistakenWriteController.h"

@interface K12OfflineMistakenProductionControllew : UIViewController<K12TakePictureControllerDelegate,K12OfflineMistakenWriteControllerDelegate>
{
    K12TakePictureController *_takePictureController;
    
    K12OfflineMistakenWriteController *_offlineMistakenWriteController;
    UINavigationController *_offlinMistakenNavigationController;
    
    UIViewController *_currentViewController;
}
@end
