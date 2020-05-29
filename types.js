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

export const ThermStatus = {
  Unknown: 'Unknown',
  Available: 'Available',
  Connecting: 'Connecting',
  Connected: 'Connected',
  Disconnecting: 'Disconnecting',
  Disconnected: 'Disconnected',
  Unavailable: 'Unavailable',
  Unsupported: 'Unsupported',
  REQUEST_REFRESH: 'Unregistered',
};
