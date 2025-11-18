import { useEffect, useState } from 'react';
import { ArrowDownOutlined, ArrowUpOutlined, ClockCircleOutlined } from '@ant-design/icons';
import { Button, Divider, Popconfirm, Switch, Tag } from 'antd';
import { useTranslation } from 'react-i18next';

import * as api from '@/api/extensions/wireguard.ts';

import type { Peer, Status } from './types.ts';

type DeviceProps = {
  status: Status;
  onUpdate: () => void;
  onConfigureClick: () => void;
};

export const Device = ({ status, onUpdate, onConfigureClick }: DeviceProps) => {
  const { t } = useTranslation();

  const [isRunning, setIsRunning] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [peers, setPeers] = useState<Peer[]>([]);
  const [errMsg, setErrMsg] = useState('');

  useEffect(() => {
    setIsRunning(status.isRunning);
    loadPeers();
  }, [status]);

  async function loadPeers() {
    try {
      const rsp = await api.getPeers(status.interface);
      if (rsp.code === 0) {
        setPeers(rsp.data.peers || []);
      }
    } catch (err) {
      console.error('Failed to load peers:', err);
    }
  }

  async function toggle() {
    if (isUpdating) return;
    setIsUpdating(true);

    try {
      const rsp = isRunning
        ? await api.down(status.interface)
        : await api.up(status.interface);
      
      if (rsp.code !== 0) {
        setErrMsg(rsp.msg);
        return;
      }

      setIsRunning(!isRunning);
      onUpdate();
    } finally {
      setIsUpdating(false);
    }
  }

  function formatBytes(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
  }

  function formatTimestamp(timestamp: number): string {
    if (timestamp === 0) return t('settings.wireguard.never');
    const now = Date.now() / 1000;
    const diff = now - timestamp;
    
    if (diff < 60) return t('settings.wireguard.justNow');
    if (diff < 3600) return `${Math.floor(diff / 60)}${t('settings.wireguard.minutesAgo')}`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}${t('settings.wireguard.hoursAgo')}`;
    return `${Math.floor(diff / 86400)}${t('settings.wireguard.daysAgo')}`;
  }

  return (
    <div className="flex flex-col space-y-6 pt-5">
      <div className="flex justify-between">
        <span>{t('settings.wireguard.enable')}</span>
        <Switch checked={isRunning} loading={isUpdating} onClick={toggle} />
      </div>

      <div className="flex justify-between">
        <span>{t('settings.wireguard.interface')}</span>
        <span className="font-mono">{status.interface}</span>
      </div>

      {status.address && (
        <div className="flex justify-between">
          <span>{t('settings.wireguard.address')}</span>
          <span className="font-mono">{status.address}</span>
        </div>
      )}

      {status.publicKey && (
        <div className="flex justify-between">
          <span>{t('settings.wireguard.publicKey')}</span>
          <span className="truncate font-mono text-xs">{status.publicKey.substring(0, 20)}...</span>
        </div>
      )}

      {status.listenPort && (
        <div className="flex justify-between">
          <span>{t('settings.wireguard.listenPort')}</span>
          <span>{status.listenPort}</span>
        </div>
      )}

      <Divider>{t('settings.wireguard.peers')} ({peers.length})</Divider>

      {peers.length === 0 ? (
        <div className="text-center text-neutral-500">
          {t('settings.wireguard.noPeers')}
        </div>
      ) : (
        <div className="space-y-4">
          {peers.map((peer, index) => (
            <div key={index} className="rounded border border-neutral-700 p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono text-neutral-400">
                  {peer.publicKey.substring(0, 16)}...
                </span>
                {peer.latestHandshake > 0 && (
                  <Tag color="green">{t('settings.wireguard.connected')}</Tag>
                )}
              </div>
              
              {peer.endpoint && (
                <div className="text-sm">
                  <span className="text-neutral-500">{t('settings.wireguard.endpoint')}: </span>
                  <span className="font-mono">{peer.endpoint}</span>
                </div>
              )}

              {peer.allowedIPs.length > 0 && (
                <div className="text-sm">
                  <span className="text-neutral-500">{t('settings.wireguard.allowedIPs')}: </span>
                  <span className="font-mono">{peer.allowedIPs.join(', ')}</span>
                </div>
              )}

              <div className="flex justify-between text-xs text-neutral-500">
                <span>
                  <ArrowDownOutlined className="mr-1" />
                  {formatBytes(peer.transferRx)}
                </span>
                <span>
                  <ArrowUpOutlined className="mr-1" />
                  {formatBytes(peer.transferTx)}
                </span>
                <span>
                  <ClockCircleOutlined className="mr-1" />
                  {formatTimestamp(peer.latestHandshake)}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      <Divider />

      <div className="flex justify-center space-x-4 pt-3">
        <Button
          type="default"
          size="large"
          shape="round"
          onClick={onConfigureClick}
        >
          {t('settings.wireguard.configure')}
        </Button>
      </div>

      {errMsg && <div className="text-center text-red-500">{errMsg}</div>}
    </div>
  );
};
