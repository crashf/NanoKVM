import { useState } from 'react';
import { PoweroffOutlined, ReloadOutlined } from '@ant-design/icons';
import { Button, Space } from 'antd';
import { useTranslation } from 'react-i18next';

import * as api from '@/api/extensions/wireguard.ts';

import type { State } from './types.ts';

type HeaderProps = {
  state?: State;
  onSuccess: () => void;
};

export const Header = ({ state, onSuccess }: HeaderProps) => {
  const { t } = useTranslation();

  const [isStarting, setIsStarting] = useState(false);
  const [isRestarting, setIsRestarting] = useState(false);
  const [isStopping, setIsStopping] = useState(false);

  async function start() {
    if (isStarting) return;
    setIsStarting(true);

    try {
      const rsp = await api.start();
      if (rsp.code === 0) {
        onSuccess();
      }
    } finally {
      setIsStarting(false);
    }
  }

  async function restart() {
    if (isRestarting) return;
    setIsRestarting(true);

    try {
      const rsp = await api.restart();
      if (rsp.code === 0) {
        onSuccess();
      }
    } finally {
      setIsRestarting(false);
    }
  }

  async function stop() {
    if (isStopping) return;
    setIsStopping(true);

    try {
      const rsp = await api.stop();
      if (rsp.code === 0) {
        onSuccess();
      }
    } finally {
      setIsStopping(false);
    }
  }

  const showControls = state && state !== 'notInstall';

  return (
    <div className="flex items-center justify-between">
      <h3 className="m-0 text-xl font-bold">WireGuard VPN</h3>
      
      {showControls && (
        <Space>
          {state === 'notRunning' || state === 'notConfigured' ? (
            <Button
              type="primary"
              icon={<PoweroffOutlined />}
              loading={isStarting}
              onClick={start}
            >
              {t('settings.wireguard.start')}
            </Button>
          ) : (
            <>
              <Button
                icon={<ReloadOutlined />}
                loading={isRestarting}
                onClick={restart}
              >
                {t('settings.wireguard.restart')}
              </Button>
              <Button
                danger
                icon={<PoweroffOutlined />}
                loading={isStopping}
                onClick={stop}
              >
              {t('settings.wireguard.stop')}
            </Button>
          </>
        )}
      </Space>
      )}
    </div>
  );
};