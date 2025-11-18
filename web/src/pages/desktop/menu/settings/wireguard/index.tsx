import { useEffect, useState } from 'react';
import { Divider, Tabs } from 'antd';
import { LoaderCircleIcon } from 'lucide-react';
import { useTranslation } from 'react-i18next';

import * as api from '@/api/extensions/wireguard.ts';

import { ConfigEditor } from './config.tsx';
import { Device } from './device.tsx';
import { Header } from './header.tsx';
import { Install } from './install.tsx';
import type { Status } from './types.ts';

type WireGuardProps = {
  setIsLocked: (isLocked: boolean) => void;
};

export const WireGuard = ({ setIsLocked }: WireGuardProps) => {
  const { t } = useTranslation();

  const [isLoading, setIsLoading] = useState(false);
  const [status, setStatus] = useState<Status>();
  const [errMsg, setErrMsg] = useState('');
  const [activeTab, setActiveTab] = useState('status');

  useEffect(() => {
    getStatus();
  }, []);

  function getStatus() {
    if (isLoading) return;
    setIsLoading(true);

    api
      .getStatus()
      .then((rsp) => {
        if (rsp.code !== 0) {
          setErrMsg(rsp.msg);
          return;
        }

        setStatus(rsp.data);
      })
      .finally(() => {
        setIsLoading(false);
      });
  }

  return (
    <>
      <Header state={status?.state} onSuccess={getStatus} />
      <Divider />

      {isLoading ? (
        <div className="flex items-center justify-center space-x-2 pt-5 text-neutral-500">
          <LoaderCircleIcon className="animate-spin" size={18} />
          <span>{t('settings.wireguard.loading')}</span>
        </div>
      ) : (
        <>
          {status?.state === 'notInstall' && (
            <Install setIsLocked={setIsLocked} onSuccess={getStatus} />
          )}

          {(status?.state === 'notRunning' || status?.state === 'notConfigured') && (
            <Tabs
              activeKey={activeTab}
              onChange={setActiveTab}
              items={[
                {
                  key: 'config',
                  label: t('settings.wireguard.tabs.config'),
                  children: (
                    <ConfigEditor
                      interfaceName={status.interface}
                      onSuccess={getStatus}
                    />
                  )
                }
              ]}
            />
          )}

          {(status?.state === 'running' || status?.state === 'connected') && (
            <Tabs
              activeKey={activeTab}
              onChange={setActiveTab}
              items={[
                {
                  key: 'status',
                  label: t('settings.wireguard.tabs.status'),
                  children: (
                    <Device
                      status={status}
                      onUpdate={getStatus}
                      onConfigureClick={() => setActiveTab('config')}
                    />
                  )
                },
                {
                  key: 'config',
                  label: t('settings.wireguard.tabs.config'),
                  children: (
                    <ConfigEditor
                      interfaceName={status.interface}
                      onSuccess={getStatus}
                    />
                  )
                }
              ]}
            />
          )}

          {errMsg && <div className="pt-5 text-red-500">{errMsg}</div>}
        </>
      )}
    </>
  );
};
