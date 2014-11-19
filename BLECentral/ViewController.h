//
//  ViewController.h
//  BLECentral
//
//  Created by takanori uehara on 2014/11/13.
//  Copyright (c) 2014年 takanori uehara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) NSMutableSet *peripherals;

@end

