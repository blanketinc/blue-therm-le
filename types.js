export const ThermNotificationType = {
  NONE: 0,
  BUTTON_PRESSED: 1,
  SHUTDOWN: 2,
  INVALID_SETTING: 3,
  INVALID_COMMAND: 4,
  COMMUNICATION_ERROR: 5,
  UNKNOWN: 6,
  CHECKPOINT: 7,
  REQUEST_REFRESH: 8,
};

export const ThermConnectionStatus = {
  UNKNOWN: 'Unknown',
  AVAILABLE: 'Available',
  CONNECTING: 'Connecting',
  CONNECTED: 'Connected',
  DISCONNECTING: 'Disconnecting',
  DISCONNECTED: 'Disconnected',
  UNAVAILABLE: 'Unavailable',
  UNSUPPORTED: 'Unsupported',
  UNREGISTERED: 'Unregistered',
};

export const ThermUnit = {
  FAHRENHEIT: '°F',
  CELSIUS: '°C',
  PH: 'pH',
  RELATIVEHUMIDITY: '%rh',
  UNKNOWN: 'Unknown',
};

export const ThermBlueToothErrorCode = {
  UNAVAILABLE: 1,
  DISABLED: 2,
  LE_DISABLED: 3,
};
