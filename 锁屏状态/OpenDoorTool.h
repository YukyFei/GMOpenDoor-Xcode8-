//
//  OpenDoorTool.h
//  
//
//  Created by fyb on 2016/11/9.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <BabyBluetooth.h>
#import <UIKit/UIKit.h>
#include <notify.h>
#import "NearbyPeripheralInfo.h"
#import "SVProgressHUD.h"

#define NotificationLock CFSTR("com.apple.springboard.lockcomplete")

#define NotificationChange CFSTR("com.apple.springboard.lockstate")

#define NotificationPwdUI CFSTR("com.apple.springboard.hasBlankedScreen")



// beacon相关宏
#define BeaconUUID @"FDA50693-A4E2-4FB1-AFCF-C6EB07647825" //iBeacon的uuid可以换成自己设备的uuid
//#define BeaconMacAddress1 @"00:cd:ff:00:35:34" // BR517301（广播出来的localName）  BRDA（出厂名字）

//#define BeaconMacAddress1  @"00:cd:ff:0e:4e:ae" // BR517377
//#define BeaconMacAddress2 @"00:cd:ff:00:35:94" // BR517302

#define BeaconMacAddress1  @"00:cd:ff:0e:50:e8" // BR518062
#define BeaconMacAddress2 @"00:cd:ff:00:50:e9" // BR518061

#define BeaconMajor @"10"
#define BeaconMinor_1 @"1"
#define BeaconMinor_2 @"2"


//百思通蓝牙
#define SERVICE_UUID @"0000fee9-0000-1000-8000-00805f9b34fb"
#define NOTIFY_UUID  @"d44bc439-abfd-45a2-b575-925416129601"
#define WRITE_UUID   @"d44bc439-abfd-45a2-b575-925416129600"

//#define BTMacAddress1 @"08:7C:BE:23:33:E4" // 老板子
#define BTMacAddress1 @"08:7C:BE:23:34:A2" // 白盒子 蓝牙mac（以后从服务器接受，要和对应的beacon对应） --- 广播出来的是逆序的
//#define BTMacAddress1 @"08:7C:BE:23:32:C9"

//#define BTMacAddress1 @"08:7C:BE:23:35:FC" // 闸机内部
//#define BTMacAddress2 @"08:7C:BE:23:34:A2"

#define RSSI_Count 2
#define RSSI_Standard (-80.0)




typedef enum : NSUInteger {
    BT_CAN_CONNECT, //可以连接
    BT_DISCONNECT_CONNECT, //即将断开
    BT_KEEP_STATE, // 信号值均不符合要求，继续收集信号
} BT_STATE;

@class OpenDoorTool;
@protocol OpenDoorToolDelegate <NSObject>

@optional
- (void)openDoorTool:(OpenDoorTool *)openDoorTool refreshPeripherals:(NSMutableArray *)peripherals andRSSIArray:(NSMutableArray *)RSSIArray;


//蓝牙所有代理方法合集（暂时不用）
- (void)openDoorTool:(OpenDoorTool *)openDoorTool andBabyBlueTooth:(BabyBluetooth *)babyBlueTooth;


//蓝牙连接成功
- (void)openDoorTool:(OpenDoorTool *)openDoorTool didConnectBlueToothWithBabyBluetooth:(BabyBluetooth *)babyBlueTooth andBTName:(NSString *)btName;

//蓝牙断开成功
- (void)openDoorTool:(OpenDoorTool *)openDoorTool didDisconnectBlueToothWithBabyBluetooth:(BabyBluetooth *)babyBlueTooth;

//开门成功
- (void)openDoorTool:(OpenDoorTool *)openDoorTool didOpenDoorWithBabyBluetooth:(BabyBluetooth *)babyBlueTooth;


@optional //ibeacon CoreLocation相关

- (void)openDoorTool:(OpenDoorTool *)openDoorTool didRangingBeaconFailed:(NSError *)error;

@end

@interface OpenDoorTool : NSObject <CLLocationManagerDelegate>


@property(nonatomic,assign)id<OpenDoorToolDelegate>delegate;


//ibeacon相关属性

@property(nonatomic,strong)CLLocationManager * locationMgr; //定位服务管理

//@property(nonatomic,strong)CLBeaconRegion * beaconRegion; //定义要监控的ibeaconRegion

@property(nonatomic,strong) NSMutableArray <CLBeaconRegion *> * mBeaconRegions; // 注册多个beacon区域，与蓝牙建立对应关系，为后台连接指定蓝牙做区分

//@property(nonatomic,copy)NSString * beaconUUIDString; // beaconUUidString
//@property(nonatomic,copy)NSString * majorString; // major
//@property(nonatomic,copy)NSString * minorString; // minor
//@property(nonatomic,copy)NSString * identity; // identity

@property(nonatomic,strong)NSMutableArray * beaconArr; //扫描到的ibeacon

@property(nonatomic,strong)NSMutableArray * scanBeaconArray; //要监控的ibeacon

@property(nonatomic,strong)NSMutableArray * scanedBeaconArray; //监控到的ibeacon

@property(nonatomic,assign)CLRegionState regionState; // region

@property(nonatomic,assign)BOOL isMonitoringBeaconRegion; // 是否正在监控beaconRegion

@property(nonatomic,assign)BOOL isAccreditedBeaconRegion; // 是否被授权使用ibeacon

@property(nonatomic,strong) CBCentralManager * centralMgr; // 用于扫描ibeacon的Manager

@property(nonatomic,assign)BOOL isNear; // 靠近了，开始扫描后，如果还是靠近就不再开启扫描服务

/*----设置要监控的ibeacon----*/
//注意：不能以init开头命名方法名
- (CLBeaconRegion *)beaconRegionInitWithProximityString:(NSString *)proximityStr andMajorString:(NSString *)majorStr andMinorString:(NSString *)minorStr andIndentityString:(NSString *)identityStr;


//开始监控ibeacon
- (void)beginMonitorBeacon;

// 停止监控ibeacon
- (void)stopMonitorForRegion:(CLBeaconRegion *)region;

//蓝牙相关属性

@property(nonatomic,assign) BOOL isConnected; //连接成功标志位，监控此属性，一旦连接成功，立刻断开，测试断开连接慢问题

@property(nonatomic,strong)BabyBluetooth * babyBlueTooth; //蓝牙第三方实例化对象

@property(nonatomic,strong)NSMutableArray * peripherals; //扫描到的目的外设总和

@property(nonatomic,strong)CBPeripheral * peripheral; //连接成功的外设

@property(nonatomic,strong) NSMutableArray * devicesArray; //扫描到的所有蓝牙设备
@property(nonatomic,strong) NSMutableArray * devicesRSSIArray; //与扫描到的所有蓝牙设备对应的信号值
/*
    CBCentralManagerScanOptionAllowDuplicatesKey
    CBCentralManagerScanOptionSolicitedServiceUUIDsKey
 */
@property(nonatomic,strong)NSDictionary * scanOptions; // 扫描参数（是否可以同时扫描多个）


/*
    CBConnectPeripheralOptionNotifyOnConnectionKey
    CBConnectPeripheralOptionNotifyOnDisconnectionKey
    CBConnectPeripheralOptionNotifyOnNotificationKey
 */
@property(nonatomic,strong)NSDictionary * connectOptions; // 连接参数


@property(nonatomic,copy)NSString * serviceStr; //服务uuid
@property(nonatomic,copy)NSString * readCharacterisicStr; //读特征值uuid
@property(nonatomic,copy)NSString * writeCharacterisicStr; //写特征值uuid

@property(nonatomic,copy)void(^block)(NSString *);

@property(nonatomic,strong)NSDate * beginConnectDate; //开始时间
@property(nonatomic,strong)NSDate * endConnectDate; //连接成功时间

@property(nonatomic,strong) NSString * BTMac_Address; // 用户输入的蓝牙的mac

// 设置扫描参数
- (void)setBTOptions;

// 设置babyBluetooth的代理
- (void)babyDelegateWithBabyBluetooth:(BabyBluetooth *)babyBT;



#pragma mark 卡号数据
@property(nonatomic,strong) NSString * cardNum;



+ (OpenDoorTool *)shareOpenDoorTool;





@end
