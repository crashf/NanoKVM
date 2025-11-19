import { useEffect, useState } from 'react';
import { Divider, Tabs } from 'antd';
import { LoaderCircleIcon } from 'lucide-react';
import { useTranslation } from 'react-i18next';

import * as api from '@/api/extensions/wireguard.ts';

import { ConfigEditor } from './config.tsx';
import { Device } from './device.tsx';
import { Header } from './header.tsx';
import type { Status } from './types.ts';

type WireGuardProps = {
  setIsLocked?: (isLocked: boolean) => void;
};

export const WireGuard = ({ }: WireGuardProps) => {
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
          {/* WireGuard is built into NanoKVM - no installation needed */}
          {/* Show config tab if not running or not configured, or if status is undefined */}
          {(!status || status?.state === 'notRunning' || status?.state === 'notConfigured') && (
            <Tabs
              activeKey={activeTab}
              onChange={setActiveTab}
              items={[
                {
                  key: 'config',
                  label: t('settings.wireguard.tabs.config'),
                  children: (
                    <ConfigEditor
                      interfaceName={status?.interface || 'wg0'}
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
          
          {/* Debug info - remove this after testing */}
          {!status && !errMsg && !isLoading && (
            <div className="pt-5 text-yellow-600">
              <p>No status data received. This might mean:</p>
              <ul className="list-disc pl-5 mt-2">
                <li>The backend is not running</li>
                <li>The API endpoint is not accessible</li>
                <li>Check browser console for errors</li>
              </ul>
            </div>
          )}
        </>
      )}
    </>
  );
};
