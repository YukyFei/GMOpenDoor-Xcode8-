//
//  AppDelegate.m
//  锁屏状态
//
//  Created by fyb on 16/8/22.
//  Copyright © 2016年 fyb. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#include <notify.h>


#define NotificationLock CFSTR("com.apple.springboard.lockcomplete")

#define NotificationChange CFSTR("com.apple.springboard.lockstate")

#define NotificationPwdUI CFSTR("com.apple.springboard.hasBlankedScreen")





//#define SERVICE_UUID @"fff0"
//#define NOTIFY_UUID  @"fff1"
//#define WRITE_UUID   @"fff2"

//#define SERVICE_UUID @"23d112e6-9d69-40af-8b75-88cf6292979b"
//#define NOTIFY_UUID @"a31a4994-a26f-469e-9d97-c8a3c5b85194"
//#define WRITE_UUID @"e6686ea6-ed6b-4219-8f37-201d05569314"


//#define SERVICE_UUID @"23d112e6-9d69-40af-8b75-88cf6292979b"
//#define NOTIFY_CHAR  @"a31a4994-a26f-469e-9d97-c8a3c5b85194"
//#define WRITE_CHAR   @"e6686ea6-ed6b-4219-8f37-201d05569314"


//#define SERVICE_UUID @"FFF0"
//#define NOTIFY_CHAR  @"FFF1"
//#define WRITE_CHAR   @"FFF2"

@interface AppDelegate ()<OpenDoorToolDelegate>

@property(nonatomic,assign)BOOL isBackground;

@property(nonatomic,weak)UIViewController * viewController;
@end

@implementation AppDelegate


#pragma mark 蓝牙初始化



#pragma mark -- 锁屏操作
//程序在前台的时候锁屏，可以检测到，并进入这个方法
//1. 程序在前台，这种比较简单。直接使用Darwin层的通知就可以了：
static void screenLockStateChanged(CFNotificationCenterRef center,void* observer,CFStringRef name,const void* object,CFDictionaryRef userInfo){
    
    
    NSString* lockstate = (__bridge NSString*)name;
    
    NSLog(@"lockstate:%@",lockstate);
    
    //(__bridge  NSString*)NotificationLock]桥接：将CoreFoundation框架的字符串转换为Foundation框架的字符串
    if ([lockstate isEqualToString:(__bridge  NSString*)NotificationLock]) {
        
        NSLog(@"locked.锁屏");
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            while (1) {
                if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
                {
                    sleep(1);
                    NSLog(@"当前线程:%@, 锁屏状态下执行操作...",[NSThread currentThread]);
                }
                
            }
        });
        

    }else{
        
        NSLog(@"屏幕状态改变了");
    }
   
}

//2. 第二种是程序退后台后，这时再锁屏就收不到上面的那个通知了，需要另外一种方式, 以循环的方式一直来检测是否是锁屏状态，会消耗性能并可能被苹果挂起；
static bool setScreenStateCb()
{

    uint64_t locked;

    __block int token = 0;
    
    notify_register_dispatch("com.apple.springboard.lockstate",&token,dispatch_get_main_queue(),^(int t){
//        NSLog(@"notify_register_dispatch");
    });
    
    notify_get_state(token, &locked);
    
    NSLog(@"锁屏状态：%d",(int)locked);
    if (locked) {
        
        return YES;
    }
    else
        return NO;
    
}

#pragma mark -- 生命周期
/**--------------------------APP生命周期-----------------*/

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSLog(@"%s",__FUNCTION__);
    
    //本地通知
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
    }
    
    // 6.后台刷新是否允许
    if(!([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable))
    {
        NSLog(@"后台刷新不允许！！！");
    }
    
    _openDoorTool = [OpenDoorTool shareOpenDoorTool];
//    openDoorTool.delegate = self;
    
    _openDoorTool.scanOptions = @{
                                 CBCentralManagerScanOptionAllowDuplicatesKey:@YES
                                 };
    _openDoorTool.connectOptions = @{
                                    CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                    CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                    CBConnectPeripheralOptionNotifyOnNotificationKey:@YES
                                    };
    
    
    _openDoorTool.serviceStr = [SERVICE_UUID uppercaseString];
    _openDoorTool.readCharacterisicStr = [NOTIFY_UUID uppercaseString];
    _openDoorTool.writeCharacterisicStr = [WRITE_UUID uppercaseString];
    
    if (self.openDoorTool.mBeaconRegions.count) {
        
        self.openDoorTool.isAccreditedBeaconRegion = YES; //授权可以监控ibeacon
        [self.openDoorTool beginMonitorBeacon];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

    NSLog(@"%s",__FUNCTION__);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        NSLog(@"后台");
        
        if ([_openDoorTool.babyBlueTooth.centralManager isScanning]) {
            
            [_openDoorTool.babyBlueTooth cancelScan];
        }
        if([_openDoorTool.babyBlueTooth findConnectedPeripherals].count)
        {
            [_openDoorTool.babyBlueTooth cancelAllPeripheralsConnection];
        }
        
        
        UIApplication*   app = [UIApplication sharedApplication];
        __block    UIBackgroundTaskIdentifier bgTask;
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bgTask != UIBackgroundTaskInvalid)
                {
                    bgTask = UIBackgroundTaskInvalid;
                }
            });
        }];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bgTask != UIBackgroundTaskInvalid)
                {
                    bgTask = UIBackgroundTaskInvalid;
                }
            });
        });
    }

    
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    NSLog(@"%s",__FUNCTION__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
 
    NSLog(@"%s",__FUNCTION__);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    if([_openDoorTool.babyBlueTooth findConnectedPeripherals].count)
    {
        [_openDoorTool.babyBlueTooth cancelAllPeripheralsConnection];
    }
    
    NSLog(@"%s",__FUNCTION__);
}

@end
