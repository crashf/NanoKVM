import { useEffect, useState } from 'react';
import { CopyOutlined, KeyOutlined, SaveOutlined } from '@ant-design/icons';
import { Button, Input, message, Space } from 'antd';
import { useTranslation } from 'react-i18next';

import * as api from '@/api/extensions/wireguard.ts';

import type { KeyPair } from './types.ts';

type ConfigEditorProps = {
  interfaceName: string;
  onSuccess: () => void;
};

export const ConfigEditor = ({ interfaceName, onSuccess }: ConfigEditorProps) => {
  const { t } = useTranslation();

  const [config, setConfig] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);

  useEffect(() => {
    loadConfig();
  }, [interfaceName]);

  function loadConfig() {
    setIsLoading(true);
    api
      .getConfig(interfaceName)
      .then((rsp) => {
        if (rsp.code === 0) {
          setConfig(rsp.data.config);
        }
      })
      .finally(() => {
        setIsLoading(false);
      });
  }

  function saveConfig() {
    if (isSaving) return;
    setIsSaving(true);

    api
      .saveConfig(config, interfaceName)
      .then((rsp) => {
        if (rsp.code !== 0) {
          message.error(rsp.msg);
          return;
        }

        message.success(t('settings.wireguard.configSaved'));
        onSuccess();
      })
      .finally(() => {
        setIsSaving(false);
      });
  }

  function generateKeys() {
    if (isGenerating) return;
    setIsGenerating(true);

    api
      .generateKeys()
      .then((rsp) => {
        if (rsp.code !== 0) {
          message.error(rsp.msg);
          return;
        }

        const keys: KeyPair = rsp.data;
        message.success(t('settings.wireguard.keysGenerated'));
        
        // Update config with new private key if it's empty or update existing
        if (!config.includes('PrivateKey')) {
          const newConfig = `[Interface]\nPrivateKey = ${keys.privateKey}\nAddress = 10.0.0.2/24\nListenPort = 51820\n\n${config}`;
          setConfig(newConfig);
        }

        // Copy public key to clipboard
        navigator.clipboard.writeText(keys.publicKey);
        message.info(t('settings.wireguard.publicKeyCopied'));
      })
      .finally(() => {
        setIsGenerating(false);
      });
  }

  function getDefaultConfig() {
    return `[Interface]
PrivateKey = <your-private-key>
Address = 10.0.0.2/24
ListenPort = 51820

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server.com:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25`;
  }

  return (
    <div className="flex flex-col space-y-4 pt-5">
      <div className="flex justify-between">
        <span className="text-neutral-400">{t('settings.wireguard.interface')}</span>
        <span className="font-mono">{interfaceName}</span>
      </div>

      <Space>
        <Button
          icon={<KeyOutlined />}
          loading={isGenerating}
          onClick={generateKeys}
        >
          {t('settings.wireguard.generateKeys')}
        </Button>
        <Button
          icon={<CopyOutlined />}
          onClick={() => {
            setConfig(getDefaultConfig());
            message.info(t('settings.wireguard.templateLoaded'));
          }}
        >
          {t('settings.wireguard.loadTemplate')}
        </Button>
      </Space>

      <Input.TextArea
        value={config}
        onChange={(e) => setConfig(e.target.value)}
        placeholder={getDefaultConfig()}
        rows={15}
        className="font-mono text-sm"
        disabled={isLoading}
      />

      <div className="text-xs text-neutral-500">
        {t('settings.wireguard.configHelp')}
      </div>

      <Button
        type="primary"
        size="large"
        icon={<SaveOutlined />}
        loading={isSaving}
        onClick={saveConfig}
        block
      >
        {t('settings.wireguard.saveConfig')}
      </Button>
    </div>
  );
};
