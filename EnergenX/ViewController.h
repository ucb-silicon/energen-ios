//
//  ViewController.h
//  EnergenX
//
//  Created by Sean Arietta on 11/3/13.
//  Copyright (c) 2013 Sean Arietta. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager* manager;
@property (nonatomic, strong) NSMutableData* data;
@property (nonatomic, strong) CBPeripheral* peripheral;

@property (strong, nonatomic) IBOutlet UILabel* batteryLevel;

@end
