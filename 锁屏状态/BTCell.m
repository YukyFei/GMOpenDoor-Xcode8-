//
//  BTCell.m
//  蓝牙连接demo
//
//  Created by fyb on 16/7/21.
//  Copyright © 2016年 fyb. All rights reserved.
//

#import "BTCell.h"




@implementation BTCell

+ (id)btCellWithTableView:(UITableView *)tableView
{
    static NSString * ident = @"BTcell";
    
    [tableView registerClass:[self class] forCellReuseIdentifier:ident];
    BTCell * cell = [tableView dequeueReusableCellWithIdentifier:ident];
//#ifdef BeaconMacTEST
//    
//    
//    UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:cell action:@selector(longPressHandle)];
//    longPress.minimumPressDuration = 0.7;
//    [cell addGestureRecognizer:longPress];
//#endif
    
    [UIColor redColor];
    return cell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        UILabel * name = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 60, 40)];
        name.text = @"设备名:";
        [self.contentView addSubview:name];
        UILabel * nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(name.frame), 10, self.bounds.size.width-CGRectGetMaxX(name.frame), 40)];
        self.nameLabel = nameLabel;
        [self.contentView addSubview:nameLabel];
        
        UILabel * RSSI = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(name.frame), 60, 40)];
        RSSI.text = @"RSSI:";
        [self.contentView addSubview:RSSI];
        UILabel * rssiLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(RSSI.frame), RSSI.frame.origin.y, self.bounds.size.width-CGRectGetMaxX(RSSI.frame), 40)];
        self.rssiLabel = rssiLabel;
        [self.contentView addSubview:rssiLabel];
        
        
    }
    return self;
}

#pragma mark - Public Method

- (void)setInfo:(NearbyPeripheralInfo *)info
{
    _info = info;
    [_nameLabel setText:info.name];
    [_rssiLabel setText:[NSString stringWithFormat:@"%d",[info.RSSI intValue]]];
    
}


//#ifdef BeaconMacTEST
//
//- (void)longPressHandle
//{
//    NSLog(@"长按");
//    if ([self isHighlighted]) {
//        
//        if ([self.delegate respondsToSelector:@selector(showMenu:)]) {
//            
//            [self.delegate showMenu:self];
//        }
//    }
//    
//}
//
//- (BOOL)canBecomeFirstResponder
//{
//    return YES;
//}
//
//- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
//{
//    if (action == @selector(connect:)) {
//        
//        return YES;
//    }
//    else if (action == @selector(disconnect:)) {
//        
//        return YES;
//    }
//    return NO;
//}
//
//- (void)disconnect:(id)sender
//{
//    
//    NSLog(@"断开连接");
//    
//    if ([self.delegate respondsToSelector:@selector(disconnectBTDevice:)]) {
//        
//        [self.delegate disconnectBTDevice:self];
//    }
//    
//}
//
//- (void)connect:(id)sender
//{
//    
//    NSLog(@"连接");
//    
//}
//
//#endif


- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
