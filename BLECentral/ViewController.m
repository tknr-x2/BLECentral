//
//  ViewController.m
//  BLECentral
//
//  Created by takanori uehara on 2014/11/13.
//  Copyright (c) 2014年 takanori uehara. All rights reserved.
//

#import "ViewController.h"

#define peripheralListCellHeight 30

@interface ViewController() {
    UILabel *connectionStatusLabel;
    UITableView *peripheralListView;
    UILabel *peripheralInfoLabel;
    
    NSMutableArray *peripheralListDataSource;
    
    CBCharacteristic *readCharacteristic;
}

@end

@implementation ViewController

- (void)display {
    CGFloat displayWidth = self.view.frame.size.width;
    CGFloat displayHeight = self.view.frame.size.height;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, displayWidth, 30)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"BLE Central DEMO";
    label.font = [UIFont systemFontOfSize:32];
    label.textColor = [UIColor blackColor];
    [self.view addSubview:label];
    
    connectionStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 110, displayWidth, 30)];
    connectionStatusLabel.textAlignment = NSTextAlignmentCenter;
    connectionStatusLabel.text = @"Searching ...";
    connectionStatusLabel.font = [UIFont systemFontOfSize:24];
    connectionStatusLabel.textColor = [UIColor blackColor];
    [self.view addSubview:connectionStatusLabel];
    
    peripheralListDataSource = [[NSMutableArray alloc] initWithArray:@[]];
    
    peripheralListView = [[UITableView alloc] initWithFrame:CGRectMake(0, 160, displayWidth, peripheralListCellHeight*5) style:UITableViewStylePlain];
    peripheralListView.delegate = self;
    peripheralListView.dataSource = self;
    [self.view addSubview:peripheralListView];
    
    peripheralInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, peripheralListView.frame.origin.y+peripheralListView.frame.size.height+60, displayWidth, 100)];
    peripheralInfoLabel.textAlignment = NSTextAlignmentCenter;
    peripheralInfoLabel.numberOfLines = 0;
    peripheralInfoLabel.text = @"";
    peripheralInfoLabel.font = [UIFont systemFontOfSize:12];
    peripheralInfoLabel.textColor = [UIColor blackColor];
    [self.view addSubview:peripheralInfoLabel];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [peripheralListDataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary *data = [peripheralListDataSource objectAtIndex:indexPath.row];
    
    [cell.textLabel setFont:[UIFont systemFontOfSize:12]];
    cell.textLabel.text = [data objectForKey:@"title"];
    
    return cell;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        
    } else if(editingStyle == UITableViewCellEditingStyleInsert){
        
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *data = [peripheralListDataSource objectAtIndex:indexPath.row];
        CBPeripheral *peripheral = data[@"peripheral"];
        
        connectionStatusLabel.text = @"Connecting ...";
        
        peripheralInfoLabel.text = [NSString stringWithFormat:@"Local Name: %@\nService UUID: %@",
                                    data[@"localName"],
                                    data[@"serviceUUID"]
                                    ];
        
        // 検索停止
        [self.centralManager stopScan];
        
        // 接続処理
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    
    NSLog(@"CBCentralManagerScanOptionAllowDuplicatesKey = %@", CBCentralManagerScanOptionAllowDuplicatesKey);
    NSLog(@"CBAdvertisementDataLocalNameKey = %@", CBAdvertisementDataLocalNameKey);
    NSLog(@"CBAdvertisementDataServiceUUIDsKey = %@", CBAdvertisementDataServiceUUIDsKey);
    
    [self display];
    
    // CentralManager のオプション
    NSDictionary *options = @{
                              CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO] // 単一デバイスの発見イベントを重複して発行させない
                              };
    
    // CBCentralManager 生成
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
}

// ペリフェラル検索開始
- (void)startScanPeripherals {
    NSLog(@"startScanPeripherals");
    
    // オプション
    NSDictionary *options = @{
                              CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO] // 単一デバイスの発見イベントを重複して発行させない
                              };
    
    [self.centralManager scanForPeripheralsWithServices:nil options:options];
}

// CentralManager ステータス変更時
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState:: central.state = %ld", (long)central.state);
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            // 不明な状態 (初期値)
            NSLog(@"unknown state (default)");
            break;
        case CBCentralManagerStateResetting:
            // 一時的に切断され、再設定された
            NSLog(@"resetting");
            break;
        case CBCentralManagerStateUnsupported:
            // BLE がサポートされていない
            NSLog(@"BLE is unsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            // BLE が許可されていない
            NSLog(@"BLE is unauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            // Bluetooth がオフ
            NSLog(@"bluetooth power off");
            break;
        case CBCentralManagerStatePoweredOn:
            // Bluetooth がオン
            NSLog(@"bluetooth power on");
            
            [self startScanPeripherals];
            
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"centralManager:didDiscoverPeripheral:advertisementData:RSSI:");
    
    NSLog(@"peripheral = %@", peripheral);
    NSLog(@"advertisementData = %@", advertisementData);
    
    NSString *name = peripheral.name;
    NSLog(@"name = %@", name);
    
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"localName = %@", localName);
    NSArray *serviceUUIDs = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
    NSString *serviceUUID = [serviceUUIDs count]>0?serviceUUIDs[0]:nil;
    NSLog(@"serviceUUIDs = %@", serviceUUIDs);
    NSLog(@"serviceUUID = %@", serviceUUID);
    
    if (localName == nil) {
        NSLog(@"localName is null");
        return;
    }
    
    if (serviceUUID == nil) {
        NSLog(@"serviceUUID is null");
        return;
    }
    
    int rssi = [RSSI intValue];
    NSLog(@"RSSI = %@", RSSI);
    
    // ペリフェラルリスト最終行に追加
    [peripheralListDataSource insertObject:@{
                                             @"title": [NSString stringWithFormat:@"%ld: %@ / RSSI: %d", (long)[peripheralListDataSource count], localName?localName:@"<null>", rssi],
                                             @"peripheral": peripheral,
                                             @"advertisementData": advertisementData,
                                             @"rssi": RSSI,
                                             @"localName": localName,
                                             @"serviceUUIDs": serviceUUIDs,
                                             @"serviceUUID": serviceUUID,
                                             }
                                   atIndex:[peripheralListDataSource count]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[peripheralListDataSource count]-1 inSection:0];
    [peripheralListView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
}

// ペリフェラル接続時
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"centralManager:didConnectPeripheral:");
    
    // サービス検索
    connectionStatusLabel.text = @"Service searching ...";
    peripheral.delegate = self;
    [peripheral discoverServices:@[
                                   [CBUUID UUIDWithString:@"00000000-0000-0000-0000-000000000000"],
                                   ]];
}

// サービス検知時
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"centralManager:didDiscoverServices:error:");
    
    if (error) {
        NSLog(@"error = %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", error] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    
    // キャラクタリスティック検索
    connectionStatusLabel.text = @"Characteristic searching ...";
    for (CBService * service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// キャラクタリスティック検知時
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"centralManager:didDiscoverCharacteristicsForService:error:");
    
    if (error) {
        NSLog(@"error = %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", error] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    
    connectionStatusLabel.text = @"Connected";
    
    for (CBService *service in peripheral.services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            // notification を許可する
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            readCharacteristic = characteristic;
        }
    }
    
    // ペリフェラルデータ読み取り要求
    [peripheral readValueForCharacteristic:readCharacteristic];
}

// キャラクタリスティックの値取得時
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"centralManager:didUpdateValueForCharacteristic:error:");
    
    if (error) {
        NSLog(@"error = %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", error] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    
    NSLog(@"characteristic value = %@", characteristic.value);
//    NSDictionary *data= [NSKeyedUnarchiver unarchiveObjectWithData:characteristic.value];
    NSString *data = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"data = %@", data);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update" message:[NSString stringWithFormat:@"%@", data] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
