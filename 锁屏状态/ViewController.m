//
//  ViewController.m
//  锁屏状态
//
//  Created by fyb on 16/8/22.
//  Copyright © 2016年 fyb. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "OpenDoorTool.h"
#import "BTCell.h"
//#import <IQKeyboardManager.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController ()<OpenDoorToolDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *cardNumTextField; //输入的卡号
@property (weak, nonatomic) IBOutlet UITextField *BTMacTextField; // 输入的要连接蓝牙的mac地址


@property (weak, nonatomic) IBOutlet UIButton *disableIbeaconButton;

@property (weak, nonatomic) IBOutlet UIButton *startConnectBluetoothButton;

@property (weak, nonatomic) IBOutlet UIButton *disconnectBluetoothButton;

@property (weak, nonatomic) IBOutlet UILabel *RSSILabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(nonatomic,assign) BOOL isEnableIbeacon; // 屏蔽ibeacon标志位

@property(nonatomic,strong) OpenDoorTool * tool;

@property(nonatomic,strong) NSMutableArray * devicesArray; //设备信息
@property(nonatomic,strong) NSMutableArray * devicesRSSIArray; //设备信息

@property(nonatomic,weak) BTCell * cell;

@end

@implementation ViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [IQKeyboardManager sharedManager].enable = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tool  = [OpenDoorTool shareOpenDoorTool];
    
    self.tool.delegate = self;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"cardNum"]) {
        self.cardNumTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"cardNum"];
        
        self.tool.cardNum = self.cardNumTextField.text;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"BTMac"]) {
        self.BTMacTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"BTMac"];
        
        self.tool.BTMac_Address = [self.BTMacTextField.text uppercaseString];
    }
    
}

// 开启/关闭ibeacon扫描功能
// 注意：开启过程中，手动连接不可用
- (IBAction)disableIbeacon:(id)sender {
    
    if((self.isEnableIbeacon = !self.isEnableIbeacon))
    {
        NSLog(@"打开ibeacon扫描");
        
        {
            self.BTMacTextField.enabled = NO;
            self.cardNumTextField.enabled = NO;
        }
        
        [self.disableIbeaconButton setTitle:@"关闭ibeacon" forState:UIControlStateNormal];
        if (self.tool.mBeaconRegions.count) {
            
            self.tool.isAccreditedBeaconRegion = YES; //授权可以监控ibeacon
            [self.tool beginMonitorBeacon];
            self.startConnectBluetoothButton.enabled = NO;
            
        }
        else
        {
            NSLog(@"未指定要扫描的ibeacon");
        }
    }
    else
    {
        NSLog(@"关闭ibeacon扫描");
        
        {
            self.BTMacTextField.enabled = YES;
            self.cardNumTextField.enabled = YES;
        }
        
        self.tool.isAccreditedBeaconRegion = NO;
        
        if ([self.tool.centralMgr isScanning]) {
            
            [self.tool.centralMgr stopScan];
        }
        
        [self.disableIbeaconButton setTitle:@"打开ibeacon" forState:UIControlStateNormal];
        if (self.tool.mBeaconRegions.count) {
            
            // 如果正在监控，停止监控
            if (self.tool.isMonitoringBeaconRegion) {
                
                [self.tool stopMonitorForRegion:nil];
            }
            
            
            [self.tool.scanedBeaconArray removeAllObjects]; //移除所有的扫描到的ibeacon，为了以后能够扫描
            
            if(![self.tool.babyBlueTooth findConnectedPeripherals].count)
            {
                self.startConnectBluetoothButton.enabled = YES;
            }
        }
        else
        {
            NSLog(@"未指定要扫描的ibeacon");
        }
    }
    
}


- (IBAction)startConnectBluetooth:(UIButton *)sender {

    NSLog(@"-----------手动开始连接蓝牙-----------");
    NSDate * currentDate = [NSDate date];
    
    OpenDoorTool * tool = [OpenDoorTool shareOpenDoorTool];
    tool.beginConnectDate = currentDate;
    [tool setBTOptions];
    
    [tool babyDelegateWithBabyBluetooth:tool.babyBlueTooth];
    tool.babyBlueTooth.scanForPeripherals().and.then.connectToPeripherals().discoverServices().discoverCharacteristics().discoverDescriptorsForCharacteristic().begin();
}


// 断开所有蓝牙连接
- (IBAction)disconnectBtn:(id)sender {
    
    
    if ([self.tool.babyBlueTooth findConnectedPeripherals].count) {

        [self.tool.babyBlueTooth cancelAllPeripheralsConnection];
    }
    
    
}


#pragma mark 开门代理
- (void)openDoorTool:(OpenDoorTool *)openDoorTool didConnectBlueToothWithBabyBluetooth:(BabyBluetooth *)babyBlueTooth andBTName:(NSString *)btName
{
    NSLog(@"连接成功，设置按钮");
    NSDate * currentDate = [NSDate date];
    
    openDoorTool.endConnectDate = currentDate;
    
    NSTimeInterval beginTime = [openDoorTool.beginConnectDate timeIntervalSince1970];
    NSTimeInterval endTime = [openDoorTool.endConnectDate timeIntervalSince1970];
    
    NSString * successLog = [NSString stringWithFormat:@"连接%@成功，耗时:%.02fs,开门...",btName,endTime-beginTime];
    
    [SVProgressHUD showSuccessWithStatus:successLog];
//    [SVProgressHUD dismissWithDelay:1.0];
    
    self.startConnectBluetoothButton.enabled = NO;
    if(!self.isEnableIbeacon)
    {
        self.disableIbeaconButton.enabled = NO;
    }
}

- (void)openDoorTool:(OpenDoorTool *)openDoorTool didDisconnectBlueToothWithBabyBluetooth:(BabyBluetooth *)babyBlueTooth
{
    NSLog(@"断开连接，设置按钮");
//    NSDate * currentDate = [NSDate date];
//    
//    openDoorTool.beginConnectDate = currentDate;
    
    if([SVProgressHUD isVisible])
        [SVProgressHUD dismiss];
//    self.tool.babyBlueTooth = nil;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [SVProgressHUD showInfoWithStatus:@"蓝牙断开"];
    });
        
    
        

    
    
//    [SVProgressHUD dismissWithDelay:1.0];
    
//    [dispatch_after(1, dispatch_get_main_queue(), ^{
//        
//        [SVProgressHUD dis]
//        
//    })];
    if (!self.isEnableIbeacon) { //没有启动ibeacon扫描，再使能手动连接
        
        self.startConnectBluetoothButton.enabled = YES;
    }
    
    self.disableIbeaconButton.enabled = YES;
}

- (void)openDoorTool:(OpenDoorTool *)openDoorTool refreshPeripherals:(NSMutableArray *)peripherals andRSSIArray:(NSMutableArray *)RSSIArray
{
    self.devicesArray = peripherals;
    self.devicesRSSIArray = RSSIArray;
    [self.tableView reloadData];
}

//监控ibeacon失败代理
- (void)openDoorTool:(OpenDoorTool *)openDoorTool didRangingBeaconFailed:(NSError *)error
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"监控Beacon失败" message:@"请检查蓝牙是否打开..." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * action1 = [UIAlertAction actionWithTitle:@"检查蓝牙" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        //        if (UIApplicationOpenSettingsURLString != NULL) {
        //            NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        //            [[UIApplication sharedApplication] openURL:appSettings];
        //        }
        
        //蓝牙设置界面
        NSURL *url = [NSURL URLWithString:@"prefs:root=Bluetooth"];
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
    
    UIAlertAction * action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        
    }];
    
    [alert addAction:action1];[alert addAction:action2];
    
    [self presentViewController:alert animated:YES completion:^{
        
        
    }];
}

- (void)openDoorTool:(OpenDoorTool *)openDoorTool didOpenDoorWithBabyBluetooth:(BabyBluetooth *)babyBlueTooth
{
    [SVProgressHUD showSuccessWithStatus:@"发送开门数据成功"];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark tableView代理

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.devicesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BTCell * cell = [BTCell btCellWithTableView:tableView];
    self.cell = cell;
    CBPeripheral * perTmp = self.devicesArray[indexPath.row];
    cell.nameLabel.text = perTmp.name;
    cell.rssiLabel.text = [self.devicesRSSIArray[indexPath.row] stringValue];
    
    return cell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark textfield代理
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    NSLog(@"TextField.text = %@",textField.text);
    if (textField == self.cardNumTextField && ![textField.text isEqualToString:@""]) {
        
        self.tool.cardNum = textField.text;
        
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:@"cardNum"];
        
    
    }
    //
    if(textField == self.BTMacTextField && ![textField.text isEqualToString:@""]) {
        
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:@"BTMac"];
        self.tool.BTMac_Address = [self.BTMacTextField.text uppercaseString];
        [self.tool babyDelegateWithBabyBluetooth:self.tool.babyBlueTooth];
        
    }
        
    
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    return YES;
}


- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
 
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    return YES;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.cardNumTextField isFirstResponder]) {
        
        [self.cardNumTextField resignFirstResponder];
    }
    
    if ([self.BTMacTextField isFirstResponder]) {
        
        [self.BTMacTextField resignFirstResponder];
    }
}
@end
