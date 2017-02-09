//
//  AppDelegate.h
//  锁屏状态
//
//  Created by fyb on 16/8/22.
//  Copyright © 2016年 fyb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenDoorTool.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(nonatomic,strong)OpenDoorTool * openDoorTool;
@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;

@end

