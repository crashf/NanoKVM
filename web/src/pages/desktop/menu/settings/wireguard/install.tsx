import { useState } from 'react';
import { DownloadOutlined, InfoCircleOutlined } from '@ant-design/icons';
import { Button, Card, Result } from 'antd';
import { useTranslation } from 'react-i18next';

import * as api from '@/api/extensions/wireguard.ts';

type InstallProps = {
  setIsLocked: (setIsLocked: boolean) => void;
  onSuccess: () => void;
};

export const Install = ({ setIsLocked, onSuccess }: InstallProps) => {
  const { t } = useTranslation();

  const [state, setState] = useState('');

  function install() {
    if (state === 'installing') return;
    setState('installing');
    setIsLocked(true);

    api
      .install()
      .then((rsp) => {
        if (rsp.code !== 0) {
          setState('failed');
          return;
        }

        onSuccess();
      })
      .finally(() => {
        setState('');
        setIsLocked(false);
      });
  }

  return (
    <>
      {state !== 'failed' ? (
        <Result
          icon={<DownloadOutlined />}
          subTitle={t('settings.wireguard.notInstall')}
          extra={
            <Button
              key="install"
              type="primary"
              size="large"
              loading={state === 'installing'}
              onClick={install}
            >
              {state === 'installing'
                ? t('settings.wireguard.installing')
                : t('settings.wireguard.install')}
            </Button>
          }
        />
      ) : (
        <Result
          status="warning"
          title={t('settings.wireguard.failed')}
          subTitle={t('settings.wireguard.retry')}
          icon={<InfoCircleOutlined />}
          extra={
            <Card key="tips" styles={{ body: { padding: 0 } }}>
              <ul className="list-decimal text-left font-mono text-sm text-neutral-300">
                <li>{t('settings.wireguard.manualInstall1')}</li>
                <li>{t('settings.wireguard.manualInstall2')}</li>
                <li>{t('settings.wireguard.manualInstall3')}</li>
                <li>{t('settings.wireguard.refresh')}</li>
              </ul>
            </Card>
          }
        />
      )}
    </>
  );
};
