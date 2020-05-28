
import { NativeEventEmitter, NativeModules } from 'react-native';

const { RNBlueThermLe } = NativeModules;

const eventEmitter = new NativeEventEmitter(RNBlueThermLe);

export const subscribeToDeviceListUpdates = (listener) => {
  const emitterSubscription = eventEmitter.addListener('deviceListUpdated', listener);
  RNBlueThermLe.subscribeDeviceListCallBack();
  return () => {
    emitterSubscription.remove();
    RNBlueThermLe.unsubscribeDeviceListCallBack();
  };
};

export const subscribeToConnectedDeviceUpdates = (listener) => {
  const emitterSubscription = eventEmitter.addListener('notificationReceived', listener);
  return () => {
    emitterSubscription.remove();
  };
};

export default {
  subscribeToDeviceListUpdates,
  subscribeToConnectedDeviceUpdates,
  startScan: () => RNBlueThermLe.startScan(),
  stopScan: () => RNBlueThermLe.stopScan(),
  removeDeviceList: () => RNBlueThermLe.removeDeviceList(),
  connectToDevice: identifier => RNBlueThermLe.connectToDevice(identifier),
  disconnectFromDevice: identifier => RNBlueThermLe.disconnectFromDevice(identifier),
  removeDevice: identifier => RNBlueThermLe.removeDevice(identifier),
  forgotDevice: identifier => RNBlueThermLe.forgotDevice(identifier),
};
export * from './types';
