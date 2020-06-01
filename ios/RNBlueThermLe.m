
#import "RNBlueThermLe.h"
#import "ThermaLib/ThermaLib.h"
#import "ThermaLib/TLDevice.h"
#import "ThermaLib/TLSensor.h"

@implementation RNBlueThermLe
{
  bool hasListeners;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"deviceListUpdated",@"notificationReceived"];
}

// Will be called when this module's first listener is added
- (void)startObserving {
    hasListeners = YES;
}

// Will be called when this module's last listener is removed, or on dealloc.
- (void)stopObserving {
    hasListeners = NO;
}

- (void)sendEmitterEvent {
    NSArray *devices = [self getConverDeviceListToDict];
    if (hasListeners) {
      [self sendEventWithName:@"deviceListUpdated" body:devices];
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
            float temperature;
            NSString *unit;
            NSString *modelNumber;
            NSString *serialNumber;
            if(device.isReady){
                modelNumber = device.modelNumber;
                serialNumber = device.serialNumber;
                temperature = [device sensorAtIndex:1].reading;
                TLDeviceUnit unit1 = [device sensorAtIndex:1].readingUnit;
                unit = [self stringFromUnit:unit1];
            } else {
                temperature = 0;
                unit = @"--";
                modelNumber = @"";
                serialNumber = @"";
            }
            NSString *deviceName = device.deviceName;
            NSString *manufacturerName = device.manufacturerName;
            NSString *deviceIdentifier = device.deviceIdentifier;
            NSString *deviceTypeName = device.deviceTypeName;
            NSString *batteryLevel = [@(device.batteryLevel) stringValue];
            NSString * connectionState;
            switch (device.connectionState) {
                case TLDeviceConnectionStateUnknown:
                    connectionState = @"Unknown";
                    break;
                case TLDeviceConnectionStateAvailable:
                    connectionState = @"Available";
                    break;
                case TLDeviceConnectionStateConnecting:
                    connectionState = @"Connecting";
                    break;
                case TLDeviceConnectionStateConnected:
                    connectionState = @"Connected";
                    break;
                case TLDeviceConnectionStateDisconnecting:
                    connectionState = @"Disconnecting";
                    break;
                case TLDeviceConnectionStateDisconnected:
                    connectionState = @"Disconnected";
                    break;
                case TLDeviceConnectionStateUnavailable:
                    connectionState = @"Unavailable";
                    break;
                case TLDeviceConnectionStateUnsupported:
                    connectionState = @"Unsupported";
                    break;
                case TLDeviceConnectionStateUnregistered:
                    connectionState = @"Unregistered";
                    break;
                default:
                    connectionState = @"Unknown";
                    break;
            }
            NSDictionary *dict = @{
                @"identifier": deviceIdentifier,
                @"name" : deviceName,
                @"type": deviceTypeName,
                @"manufacturerName": manufacturerName,
                @"modelNumber" : modelNumber,
                @"serialNumber" : serialNumber,
                @"batteryLevel": batteryLevel,
                @"unit": unit,
                @"connectionState": connectionState,
                @"temperature": [NSString stringWithFormat:@"%.1f", temperature],
            };
            [devices addObject:dict];
        }
    }
    return devices;
}

- (void) startScanWithTransport:(TLTransport)transport retrieveSystemConnections:(BOOL)retrieveSystemConnections{
    if( ![ThermaLib.sharedInstance isTransportSupported:transport] ) {
        printf("Transport not supported");
    }
    else if( ![ThermaLib.sharedInstance isServiceConnected:transport] ) {
        printf("Service not connected for transport");
    }
    else {
        printf("StartScanWithTransport successfully");
        [ThermaLib.sharedInstance startDeviceScanWithTransport:transport retrieveSystemConnections:retrieveSystemConnections];
    }
}

- (void)deviceNotificationReceived:(NSNotification *)sender
{
    TLDeviceNotificationType notification = [sender.userInfo[ThermaLibNotificationReceivedNotificationTypeKey] integerValue];

    NSString *notificationName;
    NSNumber *number;
    switch (notification) {
        case TLDeviceNotificationTypeButtonPressed:
            number = @1;
            notificationName = @"Button Pressed";
            break;

        case TLDeviceNotificationTypeShutdown:
            notificationName = @"Shutdown";
            number = @2;
            break;

        case TLDeviceNotificationTypeInvalidSetting:
            notificationName = @"Invalid Setting";
            number = @3;
            break;

        case TLDeviceNotificationTypeInvalidCommand:
            notificationName = @"Invalid Command";
            number = @4;
            break;

        case TLDeviceNotificationTypeCommunicationError:
            number = @5;
            notificationName = @"Communication Error";
            break;
            
        case TLDeviceNotificationTypeCheckpoint:
            number = @7;
            notificationName = @"Checkpoint";
            break;
            
        case TLDeviceNotificationTypeRefreshRequest:
            number = @8;
            notificationName = @"Request to Refresh";
            break;
            
        case TLDeviceNotificationTypeNone:
            number = @0;
            notificationName = @"NotificationType:None";
            break;

        default:
            number = @0;
            notificationName = [NSString stringWithFormat:@"Unknown notification (%ld)", (long)notification];
            break;
    }
    if (hasListeners) {
        printf("%s", [notificationName UTF8String]);
      [self sendEventWithName:@"notificationReceived" body:number];
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

RCT_EXPORT_METHOD(startScan)
{
    [self startScanWithTransport:TLTransportBluetoothLE retrieveSystemConnections:NO];
}

RCT_EXPORT_METHOD(stopScan)
{
    [ThermaLib.sharedInstance stopDeviceScan];
}

RCT_EXPORT_METHOD(removeDeviceList)
{
    ThermaLib *tl = ThermaLib.sharedInstance;
    NSMutableArray<id<TLDevice>> *tempArray = [NSMutableArray array];
    for( id<TLDevice> device in tl.deviceList ) {
        [tempArray addObject:device];
    }
    for( id<TLDevice> device in tempArray ) {
        [tl removeDevice:device];
    }
}

RCT_EXPORT_METHOD(connectToDevice: (NSString *) deviceIdentifier)
{
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceWithIdentifier:deviceIdentifier];
    if (device) {
        if (device.connectionState == TLDeviceConnectionStateAvailable || device.connectionState == TLDeviceConnectionStateDisconnected) {
            if( [ThermaLib.sharedInstance isServiceConnected:device.transportType]) {
                [[ThermaLib sharedInstance] connectToDevice:device];
                [NSNotificationCenter.defaultCenter removeObserver:self name:ThermaLibNotificationReceivedNotificationName object:device];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceNotificationReceived:) name:ThermaLibNotificationReceivedNotificationName object:device];
                NSLog(@"ConnectToDevice successfully");
            }
        }
    }
}

RCT_EXPORT_METHOD(disconnectFromDevice: (NSString *) deviceIdentifier)
{
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceWithIdentifier:deviceIdentifier];
    if (device) {
        [ThermaLib.sharedInstance disconectFromDevice:device];
    }
}

RCT_EXPORT_METHOD(removeDevice: (NSString *) deviceIdentifier)
{
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceWithIdentifier:deviceIdentifier];
    if (device) {
        [ThermaLib.sharedInstance removeDevice:device];
    }
}

RCT_EXPORT_METHOD(forgotDevice: (NSString *) deviceIdentifier)
{
    id<TLDevice> device = [[ThermaLib sharedInstance] deviceWithIdentifier:deviceIdentifier];
    if (device) {
        [ThermaLib.sharedInstance revokeDeviceAccess:device];
        [ThermaLib.sharedInstance removeDevice:device];
    }
}

RCT_EXPORT_METHOD(getDeviceList:(RCTResponseSenderBlock)callback)
{
    NSArray *devices = [self getConverDeviceListToDict];
    callback(@[[NSNull null], devices]);
}

RCT_EXPORT_METHOD(subscribeDeviceListCallBack)
{
    [self setNotificationListeners];
}

RCT_EXPORT_METHOD(unsubscribeDeviceListCallBack)
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_EXPORT_METHOD(checkBluetooth: (RCTResponseSenderBlock)callback)
{
    if ([ThermaLib.sharedInstance isServiceConnected:TLTransportBluetoothLE]) {
        callback(@[@(true), @""]);
    } else {
        callback(@[@(false), @2]);
    }
}

@end
