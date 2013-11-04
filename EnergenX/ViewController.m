//
//  ViewController.m
//  EnergenX
//
//  Created by Sean Arietta on 11/3/13.
//  Copyright (c) 2013 Sean Arietta. All rights reserved.
//

#import "ViewController.h"

#include <CoreFoundation/CFByteOrder.h>
#import <CoreBluetooth/CoreBluetooth.h>

static NSString* EnergenXUUID = @"5AE7403B-E05A-DCAA-75A0-5A7E1C8CDDD4";

@interface ViewController ()

@end

@implementation ViewController

NSTimer* heartbeatTimer;

- (void) cleanup {
    if (self.peripheral) {
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self.manager scanForPeripheralsWithServices:nil
                                                 options:nil];
            break;
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to peripheral %@", peripheral);
    
    // Clears the data that we may already have
    [self.data setLength:0];
    // Sets the peripheral delegate
    [self.peripheral setDelegate:self];
    // Asks the peripheral to discover the service
    //[self.peripheral discoverServices:@[ [CBUUID UUIDWithString:EnergenXUUID] ]];
    [self.peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Discovered peripheral %@", peripheral);
    
    // Stops scanning for peripheral
    [self.manager stopScan];
    //[heartbeatTimer invalidate];
    
    if (self.peripheral != peripheral) {
        self.peripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        // Connects to the discovered peripheral
        [self.manager connectPeripheral:peripheral options:nil];
    }
}

- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    for (CBService *service in aPeripheral.services) {
        NSLog(@"Service found with UUID: %@", service.UUID);
        // Discovers the characteristics for a given service
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180F"]]) {
            [self.peripheral discoverCharacteristics:nil forService:service];
            //[self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID]]
            //                              forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180F"]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            NSLog(@"Characteristic found with UUID: %@", characteristic.UUID);
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A19"]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
#if 0
    // Exits if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
        return;
    }
#endif
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    uint8_t chargeLevel = 0;
    [[characteristic value] getBytes:&chargeLevel length:sizeof(chargeLevel)];
    
    //NSLog(@"Received notify: %@", characteristic.value);
    //NSLog(@"Converted: 0x%x", chargeLevel);
    
    NSInteger batteryLevel = (int) (100.0f * ((float) chargeLevel) / 15.0f);
    [self.batteryLevel setText:[NSString stringWithFormat:@"%d%%", batteryLevel]];
}

- (void) heartbeat {
    [self.manager scanForPeripheralsWithServices:nil
                                         options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    self.peripheral = nil;
    heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval: 1.5
                                                      target: self
                                                    selector: @selector(heartbeat) userInfo: nil repeats: YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
