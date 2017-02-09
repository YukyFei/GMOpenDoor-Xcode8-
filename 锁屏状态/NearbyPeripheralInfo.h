//
//  NearbyPeripheralInfo.h
//  锁屏状态
//
//  Created by fyb on 2016/12/12.
//  Copyright © 2016年 fyb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NearbyPeripheralInfo : NSObject

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSDictionary *advertisementData;
@property (nonatomic,strong) NSNumber *RSSI;

@end
