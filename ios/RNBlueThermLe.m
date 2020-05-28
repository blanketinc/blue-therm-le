
#import "RNBlueThermLe.h"
#import "ThermaLib/ThermaLib.h"
#import "ThermaLib/TLDevice.h"
#import "ThermaLib/TLSensor.h"

@implementation RNBlueThermLe
{
  bool hasListeners;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"onNewDeviceFound"];
}

// Will be called when this module's first listener is added
-(void)startObserving {
    hasListeners = YES;
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
}

-(void)sendEmitterEvent {
    NSArray *devices = [self getConverDeviceListToDict];
    if (hasListeners) {
      [self sendEventWithName:@"onNewDeviceFound" body:@{@"devices": devices}];
    }
}

- (NSString *) stringFromUnit:(TLDeviceUnit) unit {
    
    NSString *ret = @"Unknown";
    
    switch (unit){
            
        case TLDeviceUnitFahrenheit :
            ret = @"°F";
            break;
        case TLDeviceUnitCelsius :
            ret = @"°C";
            break;
        case TLDeviceUnitPH :
            ret = @"pH";
            break;
        case TLDeviceUnitRelativeHumidity :
            ret = @"%rh";
            break;
        default:
            break;
    }
    
    return ret;
    
}

- (NSArray *) getConverDeviceListToDict {
    NSMutableArray * devices = [[NSMutableArray alloc] init];
    NSArray * deviceList = [[ThermaLib sharedInstance] deviceList];
    if (deviceList.count > 0) {
        for (id<TLDevice> device in deviceList) {
            NSString *temperature;
            if(device.isReady){
                float reading1 = [device sensorAtIndex:1].reading;
                TLDeviceUnit unit1 = [device sensorAtIndex:1].displayUnit;
                temperature = [[device sensorAtIndex:1] isFault] ? @"FAULT" : [NSString stringWithFormat:@"%.1f %@", reading1, [self stringFromUnit:unit1]];
            } else {
                temperature = @"--";
            }
            NSString *deviceName = device.deviceName;
            NSString *deviceIdentifier = device.deviceIdentifier;
            NSString *deviceTypeName = device.deviceTypeName;
            NSString *batteryLevel = [@(device.batteryLevel) stringValue];
            NSDictionary *dict = @{
                @"deviceName" : deviceName,
                @"deviceIdentifier": deviceIdentifier,
                @"deviceTypeName": deviceTypeName,
                @"batteryLevel": batteryLevel,
                @"temperature": temperature,
            };
            [devices addObject:dict];
        }
    }
    return devices;
}

- (void) startScanAll {
    [ThermaLib.sharedInstance startDeviceScan];
}

- (void) stopDeviceScan {
    [ThermaLib.sharedInstance stopDeviceScan];
}

-(void) removeAllDevices {
    ThermaLib *tl = ThermaLib.sharedInstance;
    NSMutableArray<id<TLDevice>> *tempArray = [NSMutableArray array];
    for( id<TLDevice> device in tl.deviceList ) {
        [tempArray addObject:device];
    }
    for( id<TLDevice> device in tempArray ) {
        [tl removeDevice:device];
    }
}

- (void) startScanWithTransport:(TLTransport)transport retrieveSystemConnections:(BOOL)retrieveSystemConnections{
    if( ![ThermaLib.sharedInstance isTransportSupported:transport] ) {
        NSLog(@"Transport not supported");
    }
    else if( ![ThermaLib.sharedInstance isServiceConnected:transport] ) {
        NSLog(@"Service not connected for transport");
    }
    else {
        NSLog(@"StartScanWithTransport successfully");
        [ThermaLib.sharedInstance startDeviceScanWithTransport:transport retrieveSystemConnections:retrieveSystemConnections];
        [self setNotificationListeners];
    }
}

- (void) connectToDevice: (id<TLDevice>) device {
    if (device.connectionState == TLDeviceConnectionStateAvailable || device.connectionState == TLDeviceConnectionStateDisconnected) {
        if( [ThermaLib.sharedInstance isServiceConnected:device.transportType]) {
            [[ThermaLib sharedInstance] connectToDevice:device];
            NSLog(@"ConnectToDevice successfully");
        }
    }
}

- (void)setNotificationListeners {
    // Listen for new devices being discovered
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDeviceFound:) name:ThermaLibNewDeviceFoundNotificationName object:nil];
    
    // Listen for devices being deleted
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRemoved:) name:ThermaLibDeviceDeletedNotificationName object:nil];
    
    // Listen for device updates. This can be called several times while the device is initialising
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdatedNotificationReceived:) name:ThermaLibDeviceUpdatedNotificationName object:nil];
    
    // Listen for device disconnections. This can be called several times while the device is initialising
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDisconnectionNotificationReceived:) name:ThermaLibDeviceDisconnectionNotificationName object:nil];
    
    // Listen for sensor updates
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorUpdatedNotificationReceived:) name:ThermaLibSensorUpdatedNotificationName object:nil];
    
    // Listen for service connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceConnectionNotificationReceived:) name:ThermaLibServiceConnectedNotificationName object:nil];
}

- (void)newDeviceFound:(NSNotification *)sender
{
    // A new device has been found so refresh the table
    NSLog(@"New Device Found: %@", ((id<TLDevice>) sender.object).deviceName);
    [self sendEmitterEvent];
}

- (void)deviceRemoved:(NSNotification *)sender
{
    // A new device has been found so refresh the table
    [self sendEmitterEvent];
}

- (void)deviceUpdatedNotificationReceived:(NSNotification *)sender
{
    // The relevant device can be obtained from the notification
    [self sendEmitterEvent];
}

- (void)deviceDisconnectionNotificationReceived:(NSNotification *)sender
{
    TLDeviceDisconnectionReason reason = (TLDeviceDisconnectionReason) [[sender.userInfo valueForKey:ThermaLibDeviceDisconnectionNotificationReasonKey] integerValue];
    NSLog(@"%ld", (long)reason);
    [self sendEmitterEvent];
}


- (void)sensorUpdatedNotificationReceived:(NSNotification *)sender
{
    // The relevant sensor can be obtained from the notification
//    id<TLSensor> sensor = sender.object;
//    id<TLDevice> device = sensor.device;
    [self sendEmitterEvent];
}

- (void) serviceConnectionNotificationReceived:(NSNotification *)sender
{
    // The notification's object is the appKey to be used when setting up device access.
    // In this case, the appKey is known to be a string.
    //
    // Failure of connection is signalled by a nil object.
    //
    NSString *appKey = (NSString *)sender.object;
    
    if( appKey != nil ) {
        NSLog(@"%@", appKey);
    }
    else {
        NSLog(@"Service connection failed");
    }
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(scanDeviceWithBLETransport)
{
    [self startScanWithTransport:TLTransportBluetoothLE retrieveSystemConnections:NO];
}

RCT_EXPORT_METHOD(stopScan)
{
    [self stopDeviceScan];
}

RCT_EXPORT_METHOD(removeDeviceList)
{
    [self removeAllDevices];
}

RCT_EXPORT_METHOD(connectToSpecificDevice: (NSString *) deviceIdentifier)
{
    NSArray * deviceList = [[ThermaLib sharedInstance] deviceList];
    if (deviceList.count > 0) {
        for (id<TLDevice> device in deviceList) {
            NSString *identifier = device.deviceIdentifier;
            if ([identifier isEqualToString:deviceIdentifier]) {
                printf("connectToSpecificDevice successfully");
                [self connectToDevice:device];
            }
        }
    }
    [self stopDeviceScan];
}

RCT_EXPORT_METHOD(getDeviceList:(RCTResponseSenderBlock)callback)
{
    NSArray *devices = [self getConverDeviceListToDict];
    callback(@[[NSNull null], devices]);
}

@end
  
