package com.reactlibrary;

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
import uk.co.etiltd.thermalib.ThermaLib;
import uk.co.etiltd.thermalib.ThermaLibException;

public class RNBlueThermLeModule extends ReactContextBaseJavaModule {

    private static final String TAG = "RNBlueThermLe";
    private final ReactApplicationContext reactContext;

    private ThermaLib mThermaLib;
    private Object mThermaLibCallbackHandle;    // set when mCallbacks are registered, and used to deregister

    private ThermaLib.ClientCallbacks mThermalibCallbacks = new ThermaLib.ClientCallbacksBase() {
        @Override
        public void onScanComplete(int errorCode, int numDevices) {
            Log.e(TAG, "onScanComplete : " + errorCode + " " + numDevices);
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
            map.putString("type", device.getDeviceType().toString());
            map.putString("manufactureName", device.getManufacturerName());
            map.putString("serialNumber", device.getSerialNumber());
            map.putString("modelNumber", device.getModelNumber());
            map.putString("connectionState", device.getConnectionState().toString());
            map.putBoolean("isConnected", device.isConnected());
            map.putBoolean("isReady", device.isReady());
            map.putInt("maxSensorCount", device.getMaxSensorCount());
            map.putInt("batteryLevel", device.getBatteryLevel());
            array.pushMap(map);
        }
        sendEvent(reactContext, "deviceListUpdated", array);
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

//    @ReactMethod
//    public void subscribeCallBack(String stringArgument, int numberArgument, Callback callback) {
//        // TODO: Implement some actually useful functionality
//        callback.invoke("Received numberArgument: " + numberArgument + " stringArgument: " + stringArgument);
//    }
}
