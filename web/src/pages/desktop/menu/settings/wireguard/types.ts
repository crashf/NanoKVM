export type State =
  | 'notInstall'
  | 'notRunning'
  | 'notConfigured'
  | 'running'
  | 'connected';

export type Status = {
  state: State;
  interface: string;
  publicKey?: string;
  address?: string;
  listenPort?: number;
  peerCount: number;
  isRunning: boolean;
  isConnected: boolean;
};

export type Peer = {
  publicKey: string;
  endpoint?: string;
  allowedIPs: string[];
  latestHandshake: number;
  transferRx: number;
  transferTx: number;
  persistentKeepalive?: number;
};

export type ConfigData = {
  interface: string;
  config: string;
};

export type KeyPair = {
  privateKey: string;
  publicKey: string;
};
