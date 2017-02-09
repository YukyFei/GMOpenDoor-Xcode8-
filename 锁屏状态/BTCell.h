//
//  BTCell.h
//  蓝牙连接demo
//
//  Created by fyb on 16/7/21.
//  Copyright © 2016年 fyb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "NearbyPeripheralInfo.h"



@class BTCell;

@protocol BTCellDelegate <NSObject>

- (void)showMenu:(BTCell *)cell;

- (void)disconnectBTDevice:(BTCell *)cell;

@end

@interface BTCell : UITableViewCell

@property(nonatomic,weak) UILabel * nameLabel;

@property(nonatomic,weak) UILabel * rssiLabel;

@property(nonatomic,weak) NearbyPeripheralInfo * info;

@property(nonatomic,assign)id<BTCellDelegate>delegate;


+ (id)btCellWithTableView:(UITableView *)tableView;
- (void)setPeripheral:(NearbyPeripheralInfo *)info;
@end
