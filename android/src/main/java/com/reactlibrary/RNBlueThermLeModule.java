package com.reactlibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.support.annotation.Nullable;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.Arrays;
import java.util.List;

import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.DeviceType;
import uk.co.etiltd.thermalib.Sensor;
import uk.co.etiltd.thermalib.ThermaLib;
import uk.co.etiltd.thermalib.ThermaLibException;

public class RNBlueThermLeModule extends ReactContextBaseJavaModule {

    private static final String TAG = "RNBlueThermLe";
    private final ReactApplicationContext reactContext;

    private ThermaLib mThermaLib;
    private Object mThermaLibCallbackHandle;    // set when mCallbacks are registered, and used to deregister

    private ThermaLib.ClientCallbacks mThermalibCallbacks = new ThermaLib.ClientCallbacksBase() {
        @Override
        public void onScanComplete(int transport, ThermaLib.ScanResult scanResult, int numDevices, String errorMsg) {
            super.onScanComplete(transport, scanResult, numDevices, errorMsg);
            Log.e(TAG, "onScanComplete : " + transport + " " + scanResult.getDesc() + " " + numDevices + "" + errorMsg);
            getAndSendDeviceList();
        }

        // new device discovered
        @Override
        public void onNewDevice(Device device, long timestamp) {
            Log.e(TAG, "onNewDevice : " + device.getIdentifier() + " " + timestamp);
            getAndSendDeviceList();
        }

        // device connection state change
        @Override
        public void onDeviceConnectionStateChanged(Device device, Device.ConnectionState newState, long timestamp) {
            Log.e(TAG, "onDeviceConnectionStateChanged : " + device.getIdentifier() + " " + newState.toString() + " " + timestamp);
            getAndSendDeviceList();
        }

        // device object updated, which can be stimulated by a device event (e.g. new reading) or an SDK event (e.g.
        // a call to a settings method such as setHighAlarm.
        @Override
        public void onDeviceUpdated(Device device, long timestamp) {
            Log.e(TAG, "onDeviceUpdated : " + device.getIdentifier() + " " + timestamp);
            getAndSendDeviceList();
        }

        // Not all devices report all events. Most events are currently reported only by Bluetooth LE events.
        @Override
        public void onDeviceNotificationReceived(Device device, int notificationType, byte[] payload, long timestamp) {
            super.onDeviceNotificationReceived(device, notificationType, payload, timestamp);
            Log.e(TAG, "onDeviceNotificationReceived : " + device.getIdentifier() + " " + notificationType);
            sendEvent(reactContext, "notificationReceived", notificationType);
        }

        @Override
        public void onDeviceRevokeRequestComplete(Device device, boolean succeeded, String errorMessage) {
            Log.e(TAG, "onDeviceRevokeRequestComplete : " + device.getIdentifier() + " " + succeeded);
            getAndSendDeviceList();
        }

        // called when a disconnection has occurred that is not correlated with client app action, such as a disconnection request.;
        @Override
        public void onUnexpectedDeviceDisconnection(Device device, String exceptionMessage, DeviceDisconnectionReason reason, long timestamp) {
            Log.e(TAG, "Unexpected Disconnection : " + device.getIdentifier() + " " + exceptionMessage);
        }
    };

    private void getAndSendDeviceList () {
        List<Device> deviceList = mThermaLib.getDeviceList();
        WritableArray array = Arguments.createArray();
        for (Device device : deviceList) {
            WritableMap map = Arguments.createMap();
            map.putString("identifier", device.getIdentifier());
            map.putString("name", device.getDeviceName());
            map.putString("type", getDeviceType(device));
            map.putString("manufactureName", device.getManufacturerName());
            map.putString("serialNumber", device.getSerialNumber());
            map.putString("modelNumber", device.getModelNumber());
            map.putString("connectionState", getConnectionState(device));
            map.putBoolean("isConnected", device.isConnected());
            map.putBoolean("isReady", device.isReady());
            map.putInt("maxSensorCount", device.getMaxSensorCount());
            map.putInt("batteryLevel", device.getBatteryLevel());
            if (device.isReady() && device.getMaxSensorCount() > 0) {
                Sensor sensor = device.getSensor(0);
                if (sensor.isEnabled() && !sensor.isFault()) {
                    map.putString("unit", getUnit(sensor));
                    map.putDouble("temperature", sensor.getReading());
                }
            }
            array.pushMap(map);
        }
        Log.e(TAG, "getAndSendDeviceList : " + array.size());
        sendEvent(reactContext, "deviceListUpdated", array);
    }

    private String getDeviceType(Device device) {
        DeviceType type = device.getDeviceType();
        String deviceType = "Unknown";
        switch(type) {
            case UNKNOWN:
                deviceType = "Unknown";
                break;
            case BT_ONE:
                deviceType = "BlueTherm® One";
                break;
            case Q_BLUE:
                deviceType = "ThermaQ® Blue";
                break;
            case PEN_BLUE:
                deviceType = "Thermapen® Blue";
                break;
            case WIFI_Q:
                deviceType = "ThermaQ® WiFi";
                break;
            case WIFI_TD:
                deviceType = "ThermaData® WiFi";
                break;
            case RT_BLUE:
                deviceType = "RayTemp Blue";
                break;
            case SIMULATED:
                deviceType = "Simulated";
                break;
            default:
                deviceType = "Unknown";
                break;
        }
        return deviceType;
    }

    private String getConnectionState(Device device) {
        Device.ConnectionState state = device.getConnectionState();
        String connectionState = "Unknown";
        switch(state) {
            case UNKNOWN:
                connectionState = "Unknown";
                break;
            case AVAILABLE:
                connectionState = "Available";
                break;
            case CONNECTING:
                connectionState = "Connecting";
                break;
            case CONNECTED:
                connectionState = "Connected";
                break;
            case DISCONNECTING:
                connectionState = "Disconnecting";
                break;
            case DISCONNECTED:
                connectionState = "Disconnected";
                break;
            case UNAVAILABLE:
                connectionState = "Unavailable";
                break;
            case UNSUPPORTED:
                connectionState = "Unsupported";
                break;
            case UNREGISTERED:
                connectionState = "Unregistered";
                break;
            default:
                connectionState = "Unknown";
                break;
        }
        return connectionState;
    }

    private String getUnit(Sensor sensor) {
        Device.Unit displayUnit = sensor.getDisplayUnit();
        // Try to match
        String unit = "Unknown";
        switch (displayUnit) {
            case FAHRENHEIT:
                unit = "°F";
                break;
            case CELSIUS:
                unit = "°C";
                break;
            case PH:
                unit = "pH";
                break;
            case RELATIVEHUMIDITY:
                unit = "%rh";
                break;
            case UNKNOWN:
            default:
                unit = "Unknown";
                break;
        }
        return unit;
    }

    private void sendEvent(ReactContext reactContext, String eventName, @Nullable Object params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    public RNBlueThermLeModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        mThermaLib = ThermaLib.instance(this.reactContext);
        mThermaLib.setSupportedTransports(Arrays.asList(ThermaLib.Transport.BLUETOOTH_LE));
    }

    @Override
    public String getName() {
        return "RNBlueThermLe";
    }

    @ReactMethod
    public void checkBluetooth(Callback callback) {
        boolean bOK = true;
        String error = "";
        final BluetoothManager bleManager = (BluetoothManager) reactContext.getSystemService(Context.BLUETOOTH_SERVICE);
        if (bleManager == null) {
            error = "Bluetooth is not available";
            bOK = false;
        } else {
            BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
            if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
                error = "Bluetooth is not enabled. Real Bluetooth devices will not be accessible.";
                bOK = false;
            } else if (!reactContext.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
                error = "Bluetooth Low Energy is not available on this Android phone/tablet. Real Bluetooth devices will not be accessible.";
                bOK = false;
            }
        }
        callback.invoke(bOK, error);
    }

    @ReactMethod
    public void subscribeDeviceListCallBack() {
        mThermaLibCallbackHandle = mThermaLib.registerCallbacks(mThermalibCallbacks, TAG);
    }

    @ReactMethod
    public void unsubscribeDeviceListCallBack() {
        if (mThermaLibCallbackHandle != null) {
            mThermaLib.deregisterCallbacks(mThermaLibCallbackHandle);
            mThermaLibCallbackHandle = null;
        }
    }

    @ReactMethod
    public void startScan() {
        mThermaLib.startScanForDevices(ThermaLib.Transport.BLUETOOTH_LE, 5);
    }

    @ReactMethod
    public void stopScan() {
        mThermaLib.stopScanForDevices();
    }

    @ReactMethod
    public void getDeviceList() {
        getAndSendDeviceList();
    }

    @ReactMethod
    public void removeDeviceList() {
        mThermaLib.reset();
    }

    @ReactMethod
    public void connectToDevice(String identifier) {
        Device device = mThermaLib.getDeviceWithIdentifierAndTransport(identifier, ThermaLib.Transport.BLUETOOTH_LE);
        if (device != null) {
            try {
                device.requestConnection();
            } catch (ThermaLibException e) {
                Log.e(TAG, e.toString());
            }
        }
    }

    @ReactMethod
    public void disconnectFromDevice(String identifier) {
        Device device = mThermaLib.getDeviceWithIdentifierAndTransport(identifier, ThermaLib.Transport.BLUETOOTH_LE);
        if (device != null) {
            device.requestDisconnection();
        }
    }

    @ReactMethod
    public void removeDevice(String identifier) {
        Device device = mThermaLib.getDeviceWithIdentifierAndTransport(identifier, ThermaLib.Transport.BLUETOOTH_LE);
        if (device != null) {
            mThermaLib.deleteDevice(device);
        }
    }

    @ReactMethod
    public void forgotDevice(String identifier) {
        Device device = mThermaLib.getDeviceWithIdentifierAndTransport(identifier, ThermaLib.Transport.BLUETOOTH_LE);
        if (device != null) {
            try {
                mThermaLib.revokeDeviceAccess(device);
            } catch (ThermaLibException e) {
                e.printStackTrace();
            }
        }
    }
}
