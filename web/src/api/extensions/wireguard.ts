import { http } from '@/lib/http.ts';

// install wireguard
export function install() {
  return http.post('/api/extensions/wireguard/install');
}

// uninstall wireguard
export function uninstall() {
  return http.post('/api/extensions/wireguard/uninstall');
}

// get wireguard status
export function getStatus(interfaceName?: string) {
  const params = interfaceName ? { interface: interfaceName } : {};
  return http.get('/api/extensions/wireguard/status', { params });
}

// start wireguard
export function start() {
  return http.post('/api/extensions/wireguard/start');
}

// restart wireguard
export function restart() {
  return http.post('/api/extensions/wireguard/restart');
}

// stop wireguard
export function stop() {
  return http.post('/api/extensions/wireguard/stop');
}

// bring interface up
export function up(interfaceName?: string) {
  return http.post('/api/extensions/wireguard/up', {
    interface: interfaceName || 'wg0'
  });
}

// bring interface down
export function down(interfaceName?: string) {
  return http.post('/api/extensions/wireguard/down', {
    interface: interfaceName || 'wg0'
  });
}

// get configuration
export function getConfig(interfaceName?: string) {
  const params = interfaceName ? { interface: interfaceName } : {};
  return http.get('/api/extensions/wireguard/config', { params });
}

// save configuration
export function saveConfig(config: string, interfaceName?: string) {
  return http.post('/api/extensions/wireguard/config', {
    interface: interfaceName || 'wg0',
    config
  });
}

// generate keypair
export function generateKeys() {
  return http.post('/api/extensions/wireguard/genkey');
}

// get peers
export function getPeers(interfaceName?: string) {
  const params = interfaceName ? { interface: interfaceName } : {};
  return http.get('/api/extensions/wireguard/peers', { params });
}
