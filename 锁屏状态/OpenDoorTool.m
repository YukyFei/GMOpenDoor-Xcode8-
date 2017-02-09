//
//  OpenDoorTool.m
//  
//
//  Created by fyb on 2016/11/9.
//
//

#import "OpenDoorTool.h"

@interface OpenDoorTool ()<CBCentralManagerDelegate>


@property(nonatomic,assign) BOOL hasSendData;


//  @[@{mac1:array1},@{mac2:array2},@{mac3:array3}]
@property(nonatomic,strong) NSMutableArray * BTMac_RSSIs;     //每个蓝牙模块对应的靠近信号值集合

@property(nonatomic,strong) NSDictionary   * beaconMac_BTMac; // 从服务器拿到的beacon对应的蓝牙

@property(nonatomic,strong) NSMutableArray * beaconMacs;      // 所有的beacon地址，beaconMac_BTMac字典取出所有的值

@property(nonatomic,strong) NSMutableArray * BTMacs;          // 服务器获得的所有的蓝牙mac

@property(nonatomic,strong) NSString       * currentBTMac;    // 当前可以连接的蓝牙MAC


@property(nonatomic,strong) NSDictionary * minor_BTMac;       // beaconRegion的Minor对应的Mac
@property(nonatomic,strong) NSMutableArray * mMinors;

@end


static OpenDoorTool * tool = nil;
static BOOL isScreenLocked; //屏幕是否锁屏
@implementation OpenDoorTool


#pragma mark 懒加载

#pragma mark 多对一数组初始化

- (NSMutableArray *)BTMac_RSSIs
{
    if (!_BTMac_RSSIs) {
        
        _BTMac_RSSIs = [NSMutableArray array];
        
        for (NSString * btMac in self.BTMacs) {
            
            NSMutableArray * beaconRssiArray = [NSMutableArray array]; //存储ibeacon信号值
            
            NSDictionary * dict = [NSDictionary dictionaryWithObject:beaconRssiArray forKey:btMac];
            
            [_BTMac_RSSIs addObject:dict];
        }
    }
    return _BTMac_RSSIs;
}

- (NSDictionary *)beaconMac_BTMac
{
    if (!_beaconMac_BTMac) {
        
        _beaconMac_BTMac = [NSDictionary dictionaryWithObjectsAndKeys:BTMacAddress1,BeaconMacAddress1,BTMacAddress1, BeaconMacAddress2,nil];
    }
    return _beaconMac_BTMac;
}

- (NSMutableArray *)beaconMacs
{
    if (!_beaconMacs) {
        
        _beaconMacs = [NSMutableArray arrayWithArray:[self.beaconMac_BTMac allKeys]];
    }
    return _beaconMacs;
}


- (NSMutableArray *)BTMacs
{
    if (!_BTMacs) {
        
        NSArray * temp = [self.beaconMac_BTMac allValues];
        
        _BTMacs = [[NSMutableArray alloc]init];
        for (NSString *str in temp) {
            if (![_BTMacs containsObject:str]) {
                [_BTMacs addObject:str];
            }
        }
        NSLog(@"所有的蓝牙mac：%@",_BTMacs);

    }
    return _BTMacs;
}

#pragma mark BeaconRegion和蓝牙的对应关系
//- (CLBeaconRegion *)beaconRegion
//{
//    if (!_beaconRegion) {
//
//        _beaconRegion = [self beaconRegionInitWithProximityString:self.beaconUUIDString andMajorString:self.majorString andMinorString:self.minorString andIndentityString:self.identity];
//    }
//    return _beaconRegion;
//}

- (NSDictionary *)minor_BTMac
{
    if (!_minor_BTMac) {
        
        _minor_BTMac = [NSDictionary dictionaryWithObjectsAndKeys:BTMacAddress1,BeaconMinor_1,BTMacAddress1, BeaconMinor_2,nil];
    }
    return _minor_BTMac;
}

- (NSMutableArray *)mMinors
{
    if (!_mMinors) {
        
        _mMinors = [NSMutableArray arrayWithArray:[self.minor_BTMac allKeys]];
    }
    return _mMinors;
}

- (NSMutableArray *)mBeaconRegions
{
    if (!_mBeaconRegions) {
        
        _mBeaconRegions = [NSMutableArray array];
        for (NSString * minor in self.mMinors) {
            
            NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:BeaconUUID];
            CLBeaconRegion * region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[BeaconMajor integerValue] minor:[minor integerValue] identifier:[NSString stringWithFormat:@"BeaconRegion%@",minor]];
            
            [_mBeaconRegions addObject:region];
        }
    }
    return _mBeaconRegions;
}




- (CBCentralManager *)centralMgr
{
    if (!_centralMgr) {
        
        _centralMgr = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:nil];
    }
    return _centralMgr;
}

- (BabyBluetooth *)babyBlueTooth
{
    if (!_babyBlueTooth) {
        
        _babyBlueTooth = [BabyBluetooth shareBabyBluetooth];
        [self setBTOptions];
        [self babyDelegateWithBabyBluetooth:_babyBlueTooth];
    }
    return _babyBlueTooth;
}

- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (NSMutableArray *)scanBeaconArray
{
    if (!_scanBeaconArray) {
        
        _scanBeaconArray = [NSMutableArray array];
    }
    return _scanBeaconArray;
}

- (NSMutableArray *)scanedBeaconArray
{
    if (!_scanedBeaconArray) {
        
        _scanedBeaconArray = [NSMutableArray array];
    }
    return _scanedBeaconArray;
}

- (NSMutableArray *)devicesArray
{
    if (!_devicesArray) {
        
        _devicesArray = [NSMutableArray array];
    }
    return _devicesArray;
}

- (NSMutableArray *)devicesRSSIArray
{
    if (!_devicesRSSIArray) {
        
        _devicesRSSIArray = [NSMutableArray array];
    }
    return _devicesRSSIArray;
}




#pragma mark 方法
+ (OpenDoorTool *)shareOpenDoorTool
{
    if (!tool) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            tool = [[OpenDoorTool alloc] init];

        });
    }
    return tool;
}


- (instancetype)init
{
    if (self = [super init]) {
        
        
        _locationMgr = [[CLLocationManager alloc] init];
        _locationMgr.delegate = self;
        [self enableLocaitonService];
        _babyBlueTooth = [BabyBluetooth shareBabyBluetooth];
        [self babyDelegateWithBabyBluetooth:_babyBlueTooth];
    }
    return self;
}





#pragma mark ibeacon定位相关方法
/********************************ibeacon相关方法********************************************/
/*
- (CLBeaconRegion *)beaconRegionInitWithProximityString:(NSString *)proximityStr andMajorString:(NSString *)majorStr andMinorString:(NSString *)minorStr andIndentityString:(NSString *)identityStr
{
    
    CLBeaconRegion * beaconRegion;
    
    self.beaconUUIDString = proximityStr;
    self.majorString = majorStr;
    self.minorString = minorStr;
    
    NSUUID * proximityUUID = [[NSUUID alloc] initWithUUIDString:proximityStr];

    if (proximityStr && majorStr && minorStr) {
        
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:[majorStr integerValue] minor:[minorStr integerValue] identifier:identityStr];
    }
    else if (proximityStr && majorStr)
    {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:[majorStr integerValue] identifier:identityStr];
    }
    else if (proximityStr)
    {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:[majorStr integerValue] identifier:identityStr];
    }

    beaconRegion.notifyEntryStateOnDisplay = YES;
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyOnExit = YES;
    return beaconRegion;
}
*/
/*----激活定位服务----*/
- (void)enableLocaitonService
{
    BOOL enable=[CLLocationManager locationServicesEnabled]; //定位服务是否可用
    
    int status=[CLLocationManager authorizationStatus];// 返回当前的定位授权状态
    
    if(!enable || status<3){
        
        [_locationMgr requestAlwaysAuthorization];  //请求权限，注意和info.plist NSLocationAlwaysUsageDescription文件中的对应
    }
    
}

// 开始扫描ibeacon
- (void)beginMonitorBeacon
{
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
    {
//        // 如果用户授权了监控
//        if (self.isAccreditedBeaconRegion) {
//            
//            if (self.mBeaconRegions.count) {
//                
//                self.isMonitoringBeaconRegion = YES;
//                for (CLBeaconRegion * region in self.mBeaconRegions) {
//                    
//                    [self startMonitorForRegion:region];
//                }
//            }
//            else
//            {
//                self.isMonitoringBeaconRegion = NO;
//                //NSLog(@"还没有定义要监控的beaconRegion");
//            }
        
        
//        }
//        else
//        {
//            [SVProgressHUD showErrorWithStatus:@"没有授权监控ibeacon"];
//        }
        [self startMonitorForRegion:nil];
        
    }
    else
    {
        self.isMonitoringBeaconRegion = NO;
        //NSLog(@"版本不支持CLBeaconRegion监控");
    }
    
    
}

//定位服务开启后，开始监控
- (void)startMonitorForRegion:(CLBeaconRegion *)region
{
    
//    [self.locationMgr startMonitoringForRegion:region]; //开始监控ibeacon区域
//    
//    [_locationMgr requestStateForRegion:region]; //当在区域范围内的时候，在监测信号强度；此方法调用后，会调用didDetermineState，获取当前手机的位置，判断是否在ibeacon区域内部
    
    if(self.isAccreditedBeaconRegion)
    {
        if (self.mBeaconRegions.count) {
            
            self.isMonitoringBeaconRegion = YES;
            
            for (CLBeaconRegion * tmpRegion in self.mBeaconRegions) {
                
                [self.locationMgr startMonitoringForRegion:tmpRegion];
                [self.locationMgr requestStateForRegion:tmpRegion]; //当在区域范围内的时候，在监测信号强度；此方法调用后，会调用didDetermineState，获取当前手机的位置，判断是否在ibeacon区域内部
            }

        }
        else
        {
            NSLog(@"self.mBeaconRegions = %@",self.mBeaconRegions);
            [SVProgressHUD showErrorWithStatus:@"没有注册监控区域"];
        }
        
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:@"没有授权监控ibeacon"];
    }
}

// 停止监控ibeacon
- (void)stopMonitorForRegion:(CLBeaconRegion *)region
{
    if (self.isMonitoringBeaconRegion) {
        
        self.isMonitoringBeaconRegion = NO;
        
        for (CLBeaconRegion * region in self.mBeaconRegions) {
            
            [self.locationMgr stopMonitoringForRegion:region];
            [self.locationMgr stopRangingBeaconsInRegion:region];
        }
       
    }
}

//判断是否为正在检测的beacon，收集beacon信号使用
- (BOOL)isMonitorBeaconWithBeacon:(CLBeacon *)beacon
{
    if ([beacon.proximityUUID.UUIDString isEqualToString:BeaconUUID]) {
        
        if (beacon.major) {
            
            if ([[beacon.major stringValue] isEqualToString:BeaconMajor]) {
                
                if(beacon.minor)
                {
                    if ([self.mMinors containsObject:[beacon.minor stringValue]]) {
                     
                        return YES;
                    }
                    return NO;
                }
                return YES;
            }
            return NO;
        }
        return YES;
    }
    return NO;
}

/*
// 收集信号强度用于判断信号强度是否符合要求，是-蓝牙扫描，否，继续收集
- (void)canScanBluetoothWithBeacons:(NSArray *)beacons
{
    //NSLog(@"isNear = %hhd",self.isNear);
    //NSLog(@"beacons = %@",beacons);
    
    if(self.isNear == 0 && [self.babyBlueTooth findConnectedPeripherals].count != 0)
    {
        //NSLog(@"isnear = 0,蓝牙有连接");
        [self.babyBlueTooth cancelAllPeripheralsConnection];
    }
    NSMutableArray * array = [NSMutableArray array];
    //过滤信号为0的beacon
    for (CLBeacon * beacon in beacons) {
        
        if (beacon.rssi != 0) {
            
            if([self isMonitorBeaconWithBeacon:beacon]) //监测到的beacon是要对应的beaconRegion的标识
            {
                if (self.rssiArray.count == RSSI_Count) {
                    
                    [self.rssiArray removeObjectAtIndex:0];
                }
                [self.rssiArray addObject:[NSNumber numberWithInteger:beacon.rssi]];
            }
            
            
            if(beacon.rssi >= -50 && !self.isNear) //信号值够强，可以直接连接，不需要获取三次求平均值
            {
                [self scanBTWhenRssiOK];
                
                return;
            }
            else if(beacon.rssi < -70)
            {
                
                self.isNear = NO;
                if ([self.babyBlueTooth findConnectedPeripherals].count) {
                    //NSLog(@"远离ibeacon，蓝牙自动断开");
                    [self.babyBlueTooth cancelAllPeripheralsConnection];
                }
                return;
            }
            //[array addObject:beacon];
            
        }
    }
    
    if (self.rssiArray.count == RSSI_Count) {
        
        float sum = 0;
        
        for (NSNumber * temp in self.rssiArray) {
            
            sum += [temp floatValue];
        }

        if (sum/RSSI_Count > -55.0 && !self.isNear) {
            
            //NSLog(@"条件满足，可以扫描蓝牙。。。");
            [self scanBTWhenRssiOK];
            
        }
        else if(sum/RSSI_Count < -60.0) //信号强度弱时，自动断开蓝牙连接
        {
            self.isNear = NO;
            if ([self.babyBlueTooth findConnectedPeripherals].count) {
                //NSLog(@"远离ibeacon，蓝牙自动断开");
                [self.babyBlueTooth cancelAllPeripheralsConnection];
            }
        }
    }
}
*/
// 达到条件后，扫描蓝牙,并记录记录开始时间
- (void)scanBTWhenRssiOK
{
//    if(![self.babyBlueTooth.centralManager isScanning])
//    {
        [self setBTOptions];
        
        NSLog(@"+++++++++++++++++++++++开始扫描++++++++++++++++++++");
        self.babyBlueTooth.scanForPeripherals().and.then.connectToPeripherals().discoverServices().discoverCharacteristics().begin();
        
        //    self.babyBlueTooth.scanForPeripherals().begin();
        NSDate * currentDate = [NSDate date];
        
        self.beginConnectDate = currentDate;
//    }
    
}



#pragma mark -- locationManager代理方法

//应用程序的授权状态更改时调用 Invoked when the authorization status changes for this application.
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    //NSLog(@"CLAuthorizationStatus:%d",status);
    
#warning 只有用户定位始终开启可用，需优化
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        
        //切换状态后，开始监控ibeacon区域
        //NSLog(@"kCLAuthorizationStatusAuthorizedAlways");
//        [self startMonitorForRegion:self.beaconRegion];
        
    }
    else
    {
        //NSLog(@"定位服务未开启！");
        [_locationMgr requestAlwaysAuthorization];
    }
}

/*
 You can monitor beacon regions in two ways. To receive notifications when a device enters or exits the vicinity of a beacon, use the startMonitoringForRegion: method of your location manager object. While a beacon is in range, you can also call the startRangingBeaconsInRegion: method to begin receiving notifications when the relative distance to the beacon changes.
 */


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    /*
     CLRegionStateUnknown,
     CLRegionStateInside,
     CLRegionStateOutside
     */
    
    self.regionState = state;
    switch (state) {
        case CLRegionStateUnknown:
            NSLog(@"CLRegionStateUnknown");
            break;
        case CLRegionStateInside:
        {
            NSLog(@"CLRegionStateInside");
            
            // 已经扫描到的区域包含要扫描的区域，不在重新开始扫描
//            if ([self.scanedBeaconArray containsObject:region]) {
//                
//                break;
//            }[self.scanBeaconArray containsObject:region] &&
            if([CLLocationManager isRangingAvailable])
            {
                [self.locationMgr startRangingBeaconsInRegion:(CLBeaconRegion *)region]; //专门用来开始监控ibeacon的
                [self.scanedBeaconArray addObject:region];
            }
            break;
        }
        case CLRegionStateOutside:
            NSLog(@"CLRegionStateOutside");
            break;
        default:
            break;
    }
}

#pragma mark -- 锁屏操作
//程序在前台的时候锁屏，可以检测到，并进入这个方法
//1. 程序在前台，这种比较简单。直接使用Darwin层的通知就可以了：
static void screenLockStateChanged(CFNotificationCenterRef center,void* observer,CFStringRef name,const void* object,CFDictionaryRef userInfo){
    
    
    NSString* lockstate = (__bridge NSString*)name;
    
    //NSLog(@"lockstate:%@",lockstate);
    
    //(__bridge  NSString*)NotificationLock]桥接：将CoreFoundation框架的字符串转换为Foundation框架的字符串
    if ([lockstate isEqualToString:(__bridge  NSString*)NotificationLock]) {
        
        //NSLog(@"locked.锁屏");
        
        isScreenLocked = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            while (1) {
                if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground && isScreenLocked)
                {
                    // 扫描蓝牙设备
                    
                }
                
                
            }
        });
        
        
    }else{
        
        //NSLog(@"屏幕状态改变了");
        isScreenLocked = NO;
    }
    
}

//2. 第二种是程序退后台后，这时再锁屏就收不到上面的那个通知了，需要另外一种方式, 以循环的方式一直来检测是否是锁屏状态，会消耗性能并可能被苹果挂起；
static bool setScreenStateCb()
{
    
    uint64_t locked;
    
    __block int token = 0;
    
    notify_register_dispatch("com.apple.springboard.lockstate",&token,dispatch_get_main_queue(),^(int t){
        
        //NSLog(@"notify_register_dispatch");
    });
    
    notify_get_state(token, &locked);
    
    //NSLog(@"锁屏状态：%d",(int)locked);
    if (locked) {
        
        return YES;
    }
    else
        return NO;
    
}

//找到ibeacon后扫描它的信息
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region
{
    if (!([[region.proximityUUID UUIDString] isEqualToString:BeaconUUID])) {
        
        [self stopMonitorForRegion:region];
        
        return;
    }
    NSLog(@"--------------------分割线------------------------");
    // 后台情况,直接通过ibeacon拿到的信号值来作为判断依据
    if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
/*
        NSLog(@"监控到的区域:%@",region);
        
        NSArray * btMacs = [self.minor_BTMac allValues];
       
        NSLog(@"btMacs = %@",btMacs);
        for (CLBeacon * beacon in beacons) {
            
            NSLog(@"beacon.minor = %@",beacon.minor);
            if (beacon.rssi >= -18) {
                
                continue;
            }
            NSString * btMacStr = [btMacs objectAtIndex:[beacon.minor integerValue]-1]; // 从蓝牙地址数组中取出beacon.minor对应的蓝牙mac
            
            for (NSDictionary * dict in self.BTMac_RSSIs) {
                
                if([dict objectForKey:btMacStr])
                {
                    BT_STATE state = [self isRssiOKWithRssi:[NSNumber numberWithInteger:beacon.rssi] andBeaconRssiArray:[dict objectForKey:btMacStr]];
                    if(state == BT_CAN_CONNECT)
                    {
                        self.currentBTMac = btMacStr;
                        [self scanBTWhenRssiOK]; //信号合格，扫描蓝牙
                        break;
                    }
                }
            }

            
        }
*/
        
        if(![self.babyBlueTooth.centralManager isScanning] && [self.babyBlueTooth findConnectedPeripherals].count == 0)
        {
            [self setBTOptions];
            self.babyBlueTooth.scanForPeripherals().begin();
        }
        

    }
    else
    {
        //前台情况：授权，蓝牙没有扫描，且没有靠近的状态下，才允许连接
        if(self.isAccreditedBeaconRegion)
        {
            if(![self.centralMgr isScanning] && self.isNear == NO)
                [self.centralMgr scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        }
    }
}


//发现进入ibeacon的回调
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    //NSLog(@"didEnterRegion");
    //    [self babyDelegateWithBabyBluetooth:_babyBlueTooth];
//    self.babyBlueTooth.scanForPeripherals().begin();
    
}


//离开区域的回调 离开区域，扫描ibeacon的蓝牙停止扫描
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"didExitRegion");
    
    if([self.centralMgr isScanning])
       [self.centralMgr stopScan];
}

#warning 此处报错
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    
//    NSLog(@"%@--error:%@",NSStringFromSelector(_cmd),error);
//    
//    if ([self.delegate respondsToSelector:@selector(openDoorTool:didRangingBeaconFailed:)]) {
//        
//        [self.delegate openDoorTool:self didRangingBeaconFailed:error];
//    }
}

//ragineBeacon失败
- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    //NSLog(@"%@--error:%@",NSStringFromSelector(_cmd),error);
    
//    if ([self.delegate respondsToSelector:@selector(openDoorTool:didRangingBeaconFailed:)]) {
//        
//        [self.delegate openDoorTool:self didRangingBeaconFailed:error];
//    }
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    //NSLog(@"Location manager failed: %@", error);
}






/*-----------------------------分割线-------------------------------------------*/

#pragma mark Babybluetooth代理方法
//蓝牙所有代理方法合集
- (void)babyDelegateWithBabyBluetooth:(BabyBluetooth *)babyBT
{
    __weak typeof(self) weakSelf = self;
    
    __weak typeof(babyBT) weakBabyBT = babyBT;
    
    // 设置取消扫描回调
    [babyBT setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        NSLog(@"取消扫描");
    }];
    
    [babyBT setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        
        if (central.state == CBCentralManagerStatePoweredOn) {
            
            NSLog(@"设备打开成功，开始扫描设备");
        }
    }];
    
    
    // 设备扫描到设备的委托
    [babyBT setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        if(RSSI.integerValue >= -18) return;
        
        if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
        {
            NSLog(@"name = %@ , advertisementData = %@",peripheral.name,advertisementData);
            
            NSString * btMacStr = [self getBTMacFromAdvertisementData:advertisementData];
            
            // 扫描到的蓝牙设备是闸机内的蓝牙
            if ([self.BTMacs containsObject:btMacStr]) {
                
                for (NSDictionary * dict in self.BTMac_RSSIs) {
                    
                    if([dict objectForKey:btMacStr])
                    {
                        BT_STATE state = [self isRssiOKWithRssi:RSSI andBeaconRssiArray:[dict objectForKey:btMacStr]];
                        if(state == BT_CAN_CONNECT)
                        {
                            self.currentBTMac = btMacStr;
                           
                            weakSelf.babyBlueTooth.having(peripheral).and.then.connectToPeripherals().discoverServices().discoverCharacteristics().begin();
                            break;
                        }
                    }
                }

            }
            
        }
        else
        {
            [self updateBTDeviceInfoWithPeripheral:peripheral andRssi:RSSI]; //更新扫描到的蓝牙设备信息，目前貌似没有用
            
            NSString * givenBTMac = nil;
            
            if(self.BTMac_Address)
                givenBTMac = self.BTMac_Address;
            else
                givenBTMac = BTMacAddress1;
            
            if([self isScanedBTMacOKWith:advertisementData andGivenBTMac:givenBTMac]) {
                
                
                
                
                /*            if (RSSI.integerValue > -50) {
                 weakSelf.babyBlueTooth.having(peripheral).and.then.connectToPeripherals().discoverServices().discoverCharacteristics().begin();
                 }
                 */
                self.isNear = YES;
                if((![weakSelf.peripherals containsObject:peripheral]) && peripheral.services.count!=0)
                {
                    
                    [weakSelf.peripherals addObject:peripheral];
                }
                
            }
        }
        
        
    }];
    
    [babyBT setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
//        BOOL returnData;
//        if(self.BTMac_Address)
//            returnData = [self isScanedBTMacOKWith:advertisementData andGivenBTMac:self.BTMac_Address];
//        else
//            returnData = [self isScanedBTMacOKWith:advertisementData andGivenBTMac:BTMacAddress1];
//        
//        return returnData;
        return YES;

    }];
    
    [babyBT setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
    
        NSLog(@"self.currentBTMac = %@",self.currentBTMac);
        if(self.currentBTMac && self.currentBTMac.length>0)
        {
            return [self isScanedBTMacOKWith:advertisementData andGivenBTMac:self.currentBTMac];
        }
        else if(self.BTMac_Address && self.BTMac_Address.length>0)
        {
            return YES;
        }
        else
        {
            return NO;
        }

    }];
    
    [babyBT setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        NSLog(@"连接成功");
        self.isConnected = YES;

        [weakSelf.babyBlueTooth cancelScan];
        
        self.currentBTMac = nil;
        
        
        
        
//        self.peripheral = peripheral;
//        if([self.delegate respondsToSelector:@selector(openDoorTool:didConnectBlueToothWithBabyBluetooth:andBTName:)])
//        {
//            [self.delegate openDoorTool:self didConnectBlueToothWithBabyBluetooth:self.babyBlueTooth andBTName:(NSString *)peripheral.name];
//        }
        
    }];
    
    
    [babyBT setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        
        //NSLog(@"连接失败:%@,%@",peripheral.name,error);
        self.isNear = NO; //标志位复位，靠近后可以开始蓝牙扫描
        [SVProgressHUD showErrorWithStatus:@"蓝牙连接失败！！"];
        
        [SVProgressHUD dismissWithDelay:1.0];
//        [weakSelf.locationMgr startMonitoringForRegion:weakSelf.beaconRegion];
//        [weakSelf.locationMgr startRangingBeaconsInRegion:weakSelf.beaconRegion];
        [weakSelf startMonitorForRegion:nil];
        
    }];
    
    // 发现外设的service
    [babyBT setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        
        NSLog(@"发现services");
    }];
    
    // 发现外设的characteristic
    [babyBT setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        
        NSLog(@"发现特征值");
        
        for (CBCharacteristic * tempChar in service.characteristics) {
            
            //NSLog(@"Characteristic:%@",tempChar);
            //            weakBabyBT.readValueForCharacteristic(peripheral,tempChar); //获取characteristic的value和全部description及description的value
            
            //            weakBabyBT.readValueForCharacteristic(); // 修改characteristic属性值后更新（初步认为）
            if ([[tempChar.UUID.UUIDString lowercaseString] isEqualToString:NOTIFY_UUID]) {
                NSLog(@"READ");
                
                CBCharacteristicProperties property = tempChar.properties;
                //NSLog(@"property -- %lu",(unsigned long)property); // -- 16 --> 0x10
                //                [peripheral setNotifyValue:YES forCharacteristic:tempChar];
                //通知方式监听一个characteristic的值
                [weakBabyBT notify:peripheral characteristic:tempChar block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                    
                    
                    if(error)
                    {
                        //NSLog(@"设置Notify失败:%@",error);
                    }
                    //NSLog(@"设置notify");
                }];
                
            }
            else if ([[tempChar.UUID.UUIDString lowercaseString] isEqualToString:WRITE_UUID]) {
                NSLog(@"发现写特征。。。");
                
                //property=12，0x08 | 0x04 ---> 确定写数据的type = CBCharacteristicWriteWithoutResponse
                CBCharacteristicProperties property = tempChar.properties;
                //NSLog(@"property -- %lu",(unsigned long)property);

                if(!self.hasSendData)
                {
                    NSData * openDoorData = nil;
                    if(self.cardNum && ![self.cardNum isEqualToString:@""])
                        openDoorData = [self setPackageWithCardNum:[self.cardNum intValue]];
                    else
                        openDoorData = [self setPackageWithCardNum:0x11223344];
                    
                    NSLog(@"发送卡号数据...");
                    //                [peripheral writeValue:openDoorData forCharacteristic:tempChar type:CBCharacteristicWriteWithoutResponse];
                    
                    [peripheral writeValue:openDoorData forCharacteristic:tempChar type:CBCharacteristicWriteWithoutResponse];
                    self.hasSendData = YES; //发送过数据后，置为YES，在重新扫描连接时，延时执行
                    
                    
                    if([self.delegate respondsToSelector:@selector(openDoorTool:didOpenDoorWithBabyBluetooth:)])
                    {
                        [self.delegate openDoorTool:self didOpenDoorWithBabyBluetooth:self.babyBlueTooth];
                        
                    }
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        self.hasSendData = NO;
                    });

                }
                
                Byte cancelByte[] = {0xa5,0xc3};
                
                NSData * cancelData = [NSData dataWithBytes:cancelByte length:2];
                
                NSLog(@"发送关闭蓝牙数据...");
                [peripheral writeValue:cancelData forCharacteristic:tempChar type:CBCharacteristicWriteWithoutResponse];
            }
        }
        
        
    }];
    
    [babyBT setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
        //NSLog(@"setBlockOnReadValueForCharacteristic");
    }];
    
    // 订阅状态改变的block
    [babyBT setBlockOnDidUpdateNotificationStateForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        
        //NSLog(@"setBlockOnDidUpdateNotificationStateForCharacteristic");
    }];
    
    // 向蓝牙设备写数据成功回调
    [babyBT setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        
        if (error) {
            NSLog(@"写数据报错：%@",error);
        }
        
        [SVProgressHUD showSuccessWithStatus:@"发送开门数据成功"];
        
    }];
    
    // 从蓝牙设备读数据或收到Notify更新回调
    [babyBT setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
        if (error) {
            
            NSLog(@"读数据失败原因:%@",error);
            return;
        }
        NSLog(@"读数据成功");
        
        [weakBabyBT cancelNotify:peripheral characteristic:characteristic];
        
    }];
    

    // 设置取消所有设备连接回调
    [babyBT setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        
        NSLog(@"成功取消所有设备连接");
        self.peripheral = nil;
        self.isConnected = NO;
        self.isNear = NO; //标志位复位，靠近后可以开始蓝牙扫描
        
        [self startMonitorForRegion:nil];
        
        if([self.delegate respondsToSelector:@selector(openDoorTool:didDisconnectBlueToothWithBabyBluetooth:)])
        {
            [self.delegate openDoorTool:self didDisconnectBlueToothWithBabyBluetooth:self.babyBlueTooth];
        }
    }];
    
    
    
    // 取消扫描回调
    [babyBT setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        
        //NSLog(@"取消扫描");
    }];
    
    // 特征描述回调
    [babyBT setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
    }];
    
}

/**
 *  刷新信号值
 *
 *  @return 无
 */

- (void)updateBTDeviceInfoWithPeripheral:(CBPeripheral *)peripheral andRssi:(NSNumber *)RSSI
{
    for (CBPeripheral * temp in self.devicesArray) {
        
        if ([temp.name isEqualToString:peripheral.name]) {
            
            //已经扫描过某个设备,将最新的信号值更新
            NSUInteger index = [self.devicesArray indexOfObject:temp];
            [self.devicesRSSIArray replaceObjectAtIndex:index withObject:RSSI];
        }
        else if(temp == [self.devicesArray lastObject])
        {
            //新增设备，添加到devicesArray中
            [self.devicesArray addObject:peripheral];
            [self.devicesRSSIArray addObject:RSSI];
        }
        else
        {
            continue;
        }
        
        
    }
    
    if ([self.delegate respondsToSelector:@selector(openDoorTool:refreshPeripherals:andRSSIArray:)]) {
        
        [self.delegate openDoorTool:self refreshPeripherals:self.devicesArray andRSSIArray:self.devicesRSSIArray];
    }
}

#pragma mark 设置扫描参数：涉及到后台要扫描的蓝牙service，查找的Characteristic，扫描和连接的Options，程序一开始初始化
// 设置扫描参数
- (void)setBTOptions
{
    NSDictionary * scanOptions = nil;
    NSDictionary * connectOptions = nil;
    CBUUID * serviceUUID = nil;
    CBUUID * readCharUUID = nil;
    CBUUID * writeCharUUID = nil;
    
    NSMutableArray * servicesArray = [NSMutableArray array];
    NSMutableArray * characteristicsArray = [NSMutableArray array];
    
    
    scanOptions = self.scanOptions; //扫描参数
    connectOptions = self.connectOptions; //连接参数
    
    
    if (self.serviceStr) {
        serviceUUID = [CBUUID UUIDWithString:self.serviceStr];
        [servicesArray addObject:serviceUUID];
    }
    
    if (!servicesArray.count) {
        
        servicesArray = nil;
    }
    
    if (self.readCharacterisicStr) {
        
        readCharUUID = [CBUUID UUIDWithString:self.readCharacterisicStr];
        [characteristicsArray addObject:readCharUUID];
    }
    if (self.writeCharacterisicStr) {
        
        writeCharUUID = [CBUUID UUIDWithString:self.writeCharacterisicStr];
        [characteristicsArray addObject:writeCharUUID];
    }
    
    if (!characteristicsArray.count) {
        
        characteristicsArray = nil;
    }
    
    //NSLog(@"servicesArray : %@",servicesArray);
    [self.babyBlueTooth setBabyOptionsWithScanForPeripheralsWithOptions:scanOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:servicesArray discoverWithServices:servicesArray discoverWithCharacteristics:characteristicsArray];
}

//刷新蓝牙设备信息，用于显示给用户信号值的变化
- (void)refreshDevicesDataWithPeripheral:(CBPeripheral *)peripheral andRSSI:(NSNumber *)RSSI andAdvertisementData:(NSDictionary *)advertisementData
{
    NearbyPeripheralInfo * info = [[NearbyPeripheralInfo alloc] init];
    
    info.name = peripheral.name;
    info.RSSI = RSSI;
    info.advertisementData = advertisementData;
    
    __weak typeof(self) weakSelf = self;
    // 用于显示蓝牙信号值
    if (weakSelf.devicesArray.count) {
        
        NSArray * array = [NSArray arrayWithArray:weakSelf.devicesArray];
        for (NearbyPeripheralInfo * temp in array) {
            
            if ([temp.name isEqualToString:peripheral.name]) {
                
                [weakSelf.devicesArray replaceObjectAtIndex:[array indexOfObject:temp] withObject:info];
                break;
            }
            else if(temp == [array lastObject])
            {
                [weakSelf.devicesArray addObject:info];
            }
            else
                continue;
        }
    }
    else
    {
        [weakSelf.devicesArray addObject:info];
    }
    
    if([weakSelf.delegate respondsToSelector:@selector(openDoorTool:refreshPeripherals:andRSSIArray:)])
    {
        [weakSelf.delegate openDoorTool:self refreshPeripherals:self.devicesArray andRSSIArray:nil];
    }
    
}




#warning 系统蓝牙代理方法,用于前台运行时，通过蓝牙扫描，收集信号速度更快
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //    CBCentralManagerStateUnknown = 0,
    //    CBCentralManagerStateResetting,
    //    CBCentralManagerStateUnsupported,
    //    CBCentralManagerStateUnauthorized,
    //    CBCentralManagerStatePoweredOff,
    //    CBCentralManagerStatePoweredOn,
    NSLog(@"CentralManager state = %d",central.state);
    if (central.state == CBCentralManagerStatePoweredOn) {
        
        //NSLog(@"蓝牙已打开");
    }
}

/*
 功能：获取ibeacon的信号强度，判断是不是要靠近的ibeacon
 
 **/
// 注意：peripheral.name是蓝牙外设的初始化名字  应以广播里的localName为准
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
//    NSLog(@"advertisementData = %@",advertisementData);
    
//    NSLog(@"***********蓝牙扫描ibeacon信号***************");
    if([RSSI integerValue] >= 0)
        return;
    //iBeacon_871E3E  Seekcy2541 BR517302

    
    NSDictionary * dict = advertisementData[@"kCBAdvDataServiceData"];
    NSString * beaconMacAddress = nil;
    //获取ibeacon的mac地址
    if (dict) {
        
        if ([dict objectForKey:[CBUUID UUIDWithString:@"5242"]]) {
            
            NSString * str = [NSMutableString stringWithFormat:@"%@",[dict objectForKey:[CBUUID UUIDWithString:@"5242"]]];
            str = [str substringWithRange:NSMakeRange(5, 13)];
            //            str = [str substringFromIndex:5];
            str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            NSString * retStr = [str substringWithRange:NSMakeRange(0, 2)];
            for(int i=2;i<str.length;i=i+2)
            {
                NSString * tmpStr = [str substringWithRange:NSMakeRange(i, 2)];
                retStr = [NSString stringWithFormat:@"%@:%@",retStr,tmpStr];
            }
            beaconMacAddress = retStr;
//            NSLog(@"扫描到的beaconMacAddress = %@",beaconMacAddress);
        }
        
    }
    
//    NSLog(@"所有的beacon地址：%@",self.beaconMacs);
    
    //所有的beaconMac是否包含当前扫描到的
    if ([self.beaconMacs containsObject:beaconMacAddress]) {
        
        NSString * tempBTMac = [self.beaconMac_BTMac objectForKey:beaconMacAddress]; // 拿到beacon对应的蓝牙mac
        
        for (NSDictionary * dict in self.BTMac_RSSIs) {
            
            NSMutableArray * mBeaconRssiArray = [dict objectForKey:tempBTMac];
            if(mBeaconRssiArray)
            {
                BT_STATE state = [self isRssiOKWithRssi:RSSI andBeaconRssiArray:mBeaconRssiArray];
                
                if(state == BT_CAN_CONNECT)
                {
                    self.currentBTMac = tempBTMac;
                    [self cancelScanBeaconAndStopRangeBeacon];
                    [self scanBTWhenRssiOK]; //信号合格，扫描蓝牙
                    break;
                }
                break;
            }
            
        }
        
    }
}

/*
- (BT_STATE)isRssiOKWithRssi:(NSNumber *)RSSI
{
    //    BT_CAN_CONNECT, //可以连接
    //    BT_DISCONNECT_CONNECT, //即将断开
    //    BT_KEEP_STATE,
    // 1. 收集信号值
    if (self.rssiArray.count == RSSI_Count) {
        
        [self.rssiArray removeObjectAtIndex:0];
    }
    [self.rssiArray addObject:RSSI];
    
    NSLog(@"当前信号值:%@",RSSI);
    NSLog(@"当前信号集合:%@",self.rssiArray);
    if([RSSI floatValue] >= -50.0)      // 2. 信号值够强，可以直接连接，不需要获取三次求平均值
    {
        NSLog(@"beacon信号足够强，扫描指定蓝牙设备");
        [self cancelScanBeaconAndStopRangeBeacon];
        return BT_CAN_CONNECT;
    }
    else if([RSSI floatValue] < -90.0)  // 3. 信号值够强，可以直接连接，不需要获取三次求平均值
    {
        NSLog(@"beacon信号太弱，断开蓝牙设备连接");
        return BT_DISCONNECT_CONNECT;
    }
    else                                // 4. 算平均值，确定连接还是断开
    {
        if (self.rssiArray.count == RSSI_Count) {
            
            float sum = 0;
            
            for (NSNumber * temp in self.rssiArray) {
                
                sum += [temp floatValue];
            }
            
            if (sum/RSSI_Count > -60.0) {
                
                NSLog(@"beacon信号合格，扫描指定蓝牙设备");
//                [self cancelScanBeaconAndStopRangeBeacon];
                return BT_CAN_CONNECT;
            }
            else if(sum/RSSI_Count < -90.0)
            {
                NSLog(@"beacon信号远离，断开蓝牙设备连接");
                return BT_DISCONNECT_CONNECT;
            }
            else
            {
                NSLog(@"beacon信号不达标");
                return BT_KEEP_STATE;
            }
            
        }
        else
        {
            NSLog(@"信号收集还没有完成");
            return BT_KEEP_STATE;
        }
    }
}
*/

- (BT_STATE)isRssiOKWithRssi:(NSNumber *)RSSI andBeaconRssiArray:(NSMutableArray *)mBeaconRssiArray
{
    //    BT_CAN_CONNECT, //可以连接
    //    BT_DISCONNECT_CONNECT, //即将断开
    //    BT_KEEP_STATE,
    
    // 1. 收集信号值
    if (mBeaconRssiArray.count >= RSSI_Count) {
        
        [mBeaconRssiArray removeObjectAtIndex:0];
    }
    [mBeaconRssiArray addObject:RSSI];
    
    NSLog(@"当前信号值:%@",RSSI);
    NSLog(@"当前信号集合:%@",mBeaconRssiArray);
    
    int standardRssi = -50;
    int strongRssi = -45;
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        standardRssi = -60;
        strongRssi = -50;
    }
    
    
    if([RSSI floatValue] >= strongRssi)      // 2. 信号值够强，可以直接连接，不需要获取三次求平均值
    {
        NSLog(@"beacon信号足够强，扫描指定蓝牙设备");
        [self cancelScanBeaconAndStopRangeBeacon];
        return BT_CAN_CONNECT;
    }
    else if([RSSI floatValue] < -90.0)  // 3. 信号值够强，可以直接连接，不需要获取三次求平均值
    {
        NSLog(@"beacon信号太弱");
        return BT_DISCONNECT_CONNECT;
    }
    else                                // 4. 算平均值，确定连接还是断开
    {
        if (mBeaconRssiArray.count == RSSI_Count) {
            
            float sum = 0;
            
            for (NSNumber * temp in mBeaconRssiArray) {
                
                sum += [temp floatValue];
            }
            
            if (sum/RSSI_Count > standardRssi) {
                
                NSLog(@"beacon信号合格，扫描指定蓝牙设备");
                //                [self cancelScanBeaconAndStopRangeBeacon];
                return BT_CAN_CONNECT;
            }
            else if(sum/RSSI_Count < -90.0)
            {
                NSLog(@"beacon信号远离，断开蓝牙设备连接");
                return BT_DISCONNECT_CONNECT;
            }
            else
                return BT_KEEP_STATE;
        }
        else
        {
            NSLog(@"信号收集还没有完成");
            return BT_KEEP_STATE;
        }
    }
}



#pragma mark 拼包---开门数据
- (NSData *)setPackageWithCardNum:(int)cardNum
{
    //包头（0xa3,0xef），有效数据，包尾(oxef,oxa3)，校验位（异或结果）
    
    int a = cardNum; //卡号
    
    //NSLog(@"卡号：%02x",a);
    //                Byte contentData[4] = {0}; //有效数据
    //
    //                Byte * tmp = (Byte *)&a;
    //                contentData[0] = *tmp;
    //                contentData[1] = *(tmp+1);
    //                contentData[2] = *(tmp+2);
    //                contentData[3] = *(tmp+3);
    
    Byte openData[9] = {0}; //整个包
    
    Byte headData[] = {0xa3,0xef}; //包头
    
    Byte tailData[] = {0xfe,0x3a}; // 包尾
    
    memcpy(openData, headData, sizeof(headData));
    memcpy(openData+sizeof(headData), &a, sizeof(a));
    memcpy(openData+sizeof(headData)+sizeof(a), tailData, sizeof(tailData));
    
    //计算校验位
    Byte checkData = 0x00;
    for (int i = 0; i < sizeof(openData)-1; i++) {
        
        checkData ^= openData[i];
    }
    
    checkData ^= 0xe1;
    checkData ^= 0xe2;
    
    memcpy(openData+2+4+2, &checkData, 1);
    
    for (int i = 0; i < 9; i++) {
        
        //NSLog(@"%@",[NSString stringWithFormat:@"%02x",openData[i]]);
    }
    
    NSData * openDoorData = [NSData dataWithBytes:openData length:sizeof(openData)];
    return openDoorData;
}

/**
 功能：判断扫描到的蓝牙mac是否是已知的mac
 参数1：advisementData 广播数据
 参数2：givenBTMac 已知的蓝牙mac地址
 
 */
- (BOOL)isScanedBTMacOKWith:(NSDictionary *)advertisementData andGivenBTMac:(NSString *)givenBTMac
{
    // 拿到当前广播到的蓝牙地址
 
    NSString * btMacAddress = [self getBTMacFromAdvertisementData:advertisementData];
    
    // 已知mac地址
    NSMutableString * macStr = [NSMutableString string];
//    if([givenBTMac containsString:@":"])
//    {
//        NSArray * macs = [givenBTMac componentsSeparatedByString:@":"]; //08:7C:BE:23:34:A2
//        
//        
//        for (int i = 0; i < (int)macs.count; i++) {
//            
//            [macStr appendString:macs[i]];
//        }
//    }
//    else
    macStr = (NSMutableString *)givenBTMac;
    
    // 当前mac地址和已知mac列表对比，相等则可连接
    if([btMacAddress isEqualToString:macStr]) // 扫描到的蓝牙mac是已知的mac地址
    {
        return YES;
    }
    else if(self.BTMac_Address && self.BTMac_Address.length > 0)
    {
        return YES;
    }
    
    return NO;
}

/**
    功能：广播数据提取蓝牙mac地址
    参数：（NSDictionary *）广播数据
 */
- (NSMutableString *)getBTMacFromAdvertisementData:(NSDictionary *)advertisementData
{
    NSData *data = advertisementData[@"kCBAdvDataManufacturerData"];
    if(!data) return nil;
    NSMutableString * btMacAddress = [NSMutableString string];
    Byte * byte = (Byte *)[data bytes];
    NSString * str = nil;
    for (int i = (int)data.length-1; i>=0; i--) {
        
        if (i==0) {
            
            str = [NSString stringWithFormat:@"%02x",byte[i]];
        }
        else
        {
            str = [NSString stringWithFormat:@"%02x:",byte[i]];
        }
        [btMacAddress appendString:str];
        
    }
    btMacAddress = (NSMutableString *)[btMacAddress uppercaseString];
    
//    NSLog(@"从广播数据中获取mac:%@",btMacAddress);
    return btMacAddress;
}


#warning 01-10添加关闭蓝牙扫描，貌似对于获取信号好些
- (void)cancelScanBeaconAndStopRangeBeacon
{
    if ([self.centralMgr isScanning]) {
        
        NSLog(@"停止蓝牙扫描beacon");
        [self.centralMgr stopScan];
    }
    
//    [self stopMonitorForRegion:self.beaconRegion];
}



@end
