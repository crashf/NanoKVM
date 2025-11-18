const ja = {
  translation: {
    head: {
      desktop: 'リモートデスクトップ',
      login: 'ログイン',
      changePassword: 'パスワード変更',
      terminal: 'ターミナル',
      wifi: 'Wi-Fi'
    },
    auth: {
      login: 'ログイン',
      placeholderUsername: 'ユーザー名を入力してください',
      placeholderPassword: 'パスワードを入力してください',
      placeholderPassword2: '再度パスワードを入力してください',
      noEmptyUsername: 'ユーザー名は空にできません',
      noEmptyPassword: 'パスワードは空にできません',
      noAccount:
        'ユーザー情報の取得に失敗しました。ウェブページをリフレッシュするか、パスワードをリセットしてください。',
      invalidUser: '無効なユーザー名またはパスワード',
      error: '予期しないエラー',
      changePassword: 'パスワード変更',
      changePasswordDesc:
        'デバイスのセキュリティのために、ウェブログインのパスワードを変更してください。',
      differentPassword: 'パスワードが一致しません',
      illegalUsername: 'ユーザー名に不正な文字が含まれています',
      illegalPassword: 'パスワードに不正な文字が含まれています',
      forgetPassword: 'パスワードを忘れた',
      ok: 'OK',
      cancel: 'キャンセル',
      loginButtonText: 'ログイン',
      tips: {
        reset1:
          'To reset the passwords, pressing and holding the BOOT button on the NanoKVM for 10 seconds.',
        reset2: 'For detailed steps, please consult this document:',
        reset3: 'Web default account:',
        reset4: 'SSH default account:',
        change1: 'Please note that this action will change the following passwords:',
        change2: 'Web login password',
        change3: 'System root password (SSH login password)',
        change4: 'To reset the passwords, press and hold the BOOT button on the NanoKVM.'
      }
    },
    wifi: {
      title: 'Wi-Fi',
      description: 'Configure Wi-Fi for NanoKVM',
      success: 'Please check the network status of NanoKVM and visit the new IP address.',
      failed: 'Operation failed, please try again.',
      confirmBtn: 'Ok',
      finishBtn: 'Finished'
    },
    screen: {
      video: 'ビデオモード',
      resolution: '解像度',
      auto: '自動',
      autoTips:
        '特定の解像度で画面のティアリングやマウスのオフセットが発生する可能性があります。リモートホストの解像度を調整するか、自動モードを無効にすることを検討してください。',
      fps: 'FPS',
      customizeFps: 'カスタマイズ',
      quality: '品質',
      qualityLossless: 'ロスレス',
      qualityHigh: '高い',
      qualityMedium: '中くらい',
      qualityLow: '低い',
      frameDetect: 'フレーム検出',
      frameDetectTip:
        'フレーム間の差を計算します。リモートホストの画面で変更が検出されない場合、ビデオストリームの送信を停止します。',
      resetHdmi: 'Reset HDMI'
    },
    keyboard: {
      paste: '貼り付け',
      tips: '標準的なキーボードの文字と記号のみがサポートされています',
      placeholder: '入力してください',
      submit: '送信',
      virtual: 'キーボード',
      ctrlaltdel: 'Ctrl+Alt+Del'
    },
    mouse: {
      default: 'デフォルトカーソル',
      pointer: 'ポインターカーソル',
      cell: 'セルカーソル',
      text: 'テキストカーソル',
      grab: 'つかむカーソル',
      hide: 'カーソルを非表示',
      mode: 'マウスモード',
      absolute: '絶対モード',
      relative: '相対モード',
      requestPointer:
        '相対モードを使用中です。デスクトップをクリックしてマウスポインタを取得してください。',
      resetHid: 'HIDをリセット'
    },
    image: {
      title: 'イメージ',
      loading: '読み込み中...',
      empty: '見つかりませんでした',
      mountFailed: 'マウントに失敗しました',
      mountDesc:
        '一部のシステムでは、イメージをマウントする前にリモートホストで仮想ディスクをアンマウントする必要があります。',
      tips: {
        title: 'アップロード方法',
        usb1: 'NanoKVMをUSB経由でコンピュータに接続します。',
        usb2: '仮想ディスクがマウントされていることを確認します（設定 - 仮想ディスク）。',
        usb3: 'コンピュータ上で仮想ディスクを開き、イメージファイルを仮想ディスクのルートディレクトリにコピーします。',
        scp1: 'NanoKVMとコンピュータが同じローカルネットワークに接続されていることを確認します。',
        scp2: 'コンピュータのターミナルを開き、SCPコマンドを使用してイメージファイルをNanoKVMの/dataディレクトリにアップロードします。',
        scp3: '例: scp あなたのイメージパス root@あなたのナノKVMのIP:/data',
        tfCard: 'TFカード',
        tf1: 'この方法はLinuxシステムでサポートされています',
        tf2: 'NanoKVMからTFカードを取り出します（フルバージョンの場合、まずケースを分解してください）。',
        tf3: 'TFカードをカードリーダーに挿入し、コンピュータに接続します。',
        tf4: 'TFカードの/dataディレクトリにイメージファイルをコピーします。',
        tf5: 'TFカードをNanoKVMに挿入します。'
      }
    },
    script: {
      title: 'スクリプト',
      upload: 'アップロード',
      run: '実行',
      runBackground: 'バックグラウンドで実行',
      runFailed: '実行に失敗しました',
      attention: '注意',
      delDesc: 'このファイルを削除してもよろしいですか？',
      confirm: 'はい',
      cancel: 'いいえ',
      delete: '削除',
      close: '閉じる'
    },
    terminal: {
      title: 'ターミナル',
      nanokvm: 'NanoKVMターミナル',
      serial: 'シリアルポートターミナル',
      serialPort: 'シリアルポート',
      serialPortPlaceholder: 'シリアルポートを入力してください',
      baudrate: 'ボーレート',
      confirm: 'OK'
    },
    wol: {
      title: 'Wake-on-LAN',
      sending: 'コマンドを送信中...',
      sent: 'コマンドを送信しました',
      input: 'MACを入力してください',
      ok: 'OK'
    },
    power: {
      title: '電源',
      reset: 'リセット',
      power: '電源',
      powerShort: '電源（短いクリック）',
      powerLong: '電源（長いクリック）'
    },
    settings: {
      title: 'Settings',
      about: {
        title: 'NanoKVMについて',
        information: '情報',
        ip: 'IP',
        mdns: 'mDNS',
        application: 'アプリケーションバージョン',
        applicationTip: 'NanoKVM web application version',
        image: 'イメージバージョン',
        imageTip: 'NanoKVM system image version',
        firmware: 'ファームウェアバージョン',
        deviceKey: 'デバイスキー',
        community: 'コミュニティ'
      },
      appearance: {
        title: 'Appearance',
        display: 'Display',
        language: 'Language',
        menuBar: 'Menu Bar',
        menuBarDesc: 'Display icons in the menu bar'
      },
      device: {
        title: 'Device',
        oled: {
          title: 'OLED',
          description: 'OLED screen automatically sleep',
          0: 'Never',
          15: '15 sec',
          30: '30 sec',
          60: '1 min',
          180: '3 min',
          300: '5 min',
          600: '10 min',
          1800: '30 min',
          3600: '1 hour'
        },
        wifi: {
          title: 'Wi-Fi',
          description: 'Configure Wi-Fi',
          setBtn: 'Config'
        },
        disk: 'Virtual Disk',
        diskDesc: 'Mount virtual U-disk on the remote host',
        network: 'Virtual Network',
        networkDesc: 'Mount virtual network card on the remote host'
      },
      tailscale: {
        title: 'Tailscale',
        memory: {
          title: 'Memory optimization',
          tip: "When memory usage exceeds the limit, garbage collection is performed more aggressively to attempt to free up memory. it's recommended to set to 50MB if using Tailscale. A Tailscale restart is required for the change to take effect.",
          disable: 'Disable'
        },
        restart: 'Are you sure to restart Tailscale?',
        stop: 'Are you sure to stop Tailscale?',
        stopDesc: 'Log out Tailscale and disable its automatic startup on boot.',
        loading: '読み込み中...',
        notInstall: 'Tailscaleが見つかりません！インストールしてください。',
        install: 'インストール',
        installing: 'インストール中',
        failed: 'インストールに失敗しました',
        retry: 'ページをリフレッシュして再試行してください。または手動でインストールしてください',
        download: 'インストールパッケージをダウンロードして',
        package: '解凍してください',
        upTailscale: 'tailscaleをNanoKVMのディレクトリ/usr/bin/にアップロードしてください',
        upTailscaled: 'tailscaledをNanoKVMのディレクトリ/usr/sbin/にアップロードしてください',
        refresh: '現在のページをリフレッシュします',
        notLogin:
          'デバイスはまだバインドされていません。ログインしてこのデバイスをアカウントにバインドしてください。',
        urlPeriod: 'このURLは10分間有効です',
        login: 'ログイン',
        loginSuccess: 'ログイン成功',
        enable: 'Tailscaleを有効化',
        deviceName: 'デバイス名',
        deviceIP: 'デバイスIP',
        account: 'アカウント',
        logout: 'ログアウト',
        logout2: 'ログアウトしてもよろしいですか？',
        okBtn: 'Yes',
        cancelBtn: 'No'
      },
      wireguard: {
        title: 'WireGuard',
        loading: '読み込み中...',
        notInstall: 'WireGuardが見つかりません！システムを確認してください。',
        // 注意：NanoKVMにはネイティブWireGuardサポートが組み込まれています
        // 以下のインストール関連のキーは参考用に保持されていますが、使用されていません
        install: 'インストール',
        installing: 'インストール中',
        failed: 'インストールに失敗しました',
        retry: 'ページをリフレッシュして再試行してください。',
        download: 'ダウンロード',
        package: 'インストールパッケージ',
        unzip: '解凍してください',
        upWireguard: 'wireguard-goをNanoKVMのディレクトリ/usr/bin/にアップロードしてください',
        upWg: 'wgをNanoKVMのディレクトリ/usr/bin/にアップロードしてください',
        upWgQuick: 'wg-quickをNanoKVMのディレクトリ/usr/bin/にアップロードしてください',
        manualInstall1: 'RISC-V用のwireguard-go、wg、wg-quickバイナリをダウンロードしてください',
        manualInstall2: 'wireguard-go、wg、wg-quickを/usr/bin/ディレクトリにアップロードしてください',
        manualInstall3: '実行：chmod +x /usr/bin/wireguard-go /usr/bin/wg /usr/bin/wg-quick',
        refresh: '現在のページをリフレッシュします',
        start: 'WireGuardを起動してもよろしいですか？',
        restart: 'WireGuardを再起動してもよろしいですか？',
        stop: 'WireGuardを停止してもよろしいですか？',
        stopDesc: 'WireGuard VPN接続を停止します。',
        uninstall: 'アンインストール',
        uninstallConfirm: 'WireGuardをアンインストールしてもよろしいですか？',
        uninstallDesc: 'WireGuardをアンインストールしてもよろしいですか？',
        up: '起動',
        down: '停止',
        okBtn: 'はい',
        cancelBtn: 'いいえ',
        tabs: {
          status: 'ステータス',
          config: '設定'
        },
        status: {
          title: '接続状態',
          notConfigured: 'WireGuardが設定されていません。設定タブで設定してください。',
          interface: 'インターフェース',
          status: 'ステータス',
          running: '実行中',
          stopped: '停止中',
          publicKey: '公開鍵',
          listenPort: 'リスニングポート',
          peers: 'ピア',
          noPeers: 'ピアが設定されていません',
          endpoint: 'エンドポイント',
          allowedIPs: '許可されたIP',
          latestHandshake: '最新のハンドシェイク',
          transfer: '転送',
          sent: '送信',
          received: '受信',
          never: 'なし',
          enabled: '有効',
          disabled: '無効',
          enable: '有効化',
          disable: '無効化',
          connected: '接続済み',
          justNow: 'たった今',
          minutesAgo: ' 分前',
          hoursAgo: ' 時間前',
          daysAgo: ' 日前',
          address: 'アドレス',
          configure: '設定'
        },
        config: {
          title: '設定',
          description: 'WireGuard設定ファイルを編集します',
          placeholder: 'WireGuard設定をここに貼り付けてください...',
          save: '設定を保存',
          saveConfig: '保存',
          saving: '保存中...',
          saved: '設定が正常に保存されました',
          configSaved: '設定を保存しました',
          generateKeys: '鍵を生成',
          generating: '生成中...',
          generated: '鍵が正常に生成されました',
          keysGenerated: '鍵を生成しました',
          privateKey: '秘密鍵',
          publicKey: '公開鍵',
          copyPrivateKey: '秘密鍵をコピー',
          copyPublicKey: '公開鍵をコピー',
          publicKeyCopied: '公開鍵をクリップボードにコピーしました',
          copied: 'クリップボードにコピーしました',
          loadTemplate: 'テンプレートを読み込む',
          templateLoaded: 'テンプレートを読み込みました',
          interface: 'インターフェース',
          configHelp: '以下でWireGuard設定を編集してください。「テンプレートを読み込む」をクリックして初期設定を取得できます。',
          template: {
            title: '設定テンプレート',
            description: 'このテンプレートを使用してWireGuardを開始します',
            interface: '[Interface]',
            address: 'Address = 10.0.0.2/24',
            privateKeyComment: '# 秘密鍵に置き換えてください',
            privateKeyPlaceholder: 'PrivateKey = YOUR_PRIVATE_KEY_HERE',
            peer: '[Peer]',
            publicKeyComment: '# サーバーの公開鍵に置き換えてください',
            publicKeyPlaceholder: 'PublicKey = SERVER_PUBLIC_KEY_HERE',
            endpointComment: '# サーバーのアドレスとポートに置き換えてください',
            endpointPlaceholder: 'Endpoint = your-server.com:51820',
            allowedIPsComment: '# VPN経由ですべてのトラフィックをルーティング',
            allowedIPs: 'AllowedIPs = 0.0.0.0/0',
            persistentKeepalive: 'PersistentKeepalive = 25'
          },
          validation: {
            empty: '設定を空にすることはできません',
            invalid: '設定形式が無効です',
            missingInterface: '[Interface]セクションがありません',
            missingPrivateKey: '[Interface]セクションにPrivateKeyがありません',
            error: '設定エラー'
          }
        }
      },
      update: {
        title: 'アップデートの確認',
        queryFailed: 'バージョンの取得に失敗しました',
        updateFailed: '更新に失敗しました。再試行してください。',
        isLatest: '最新のバージョンを既に持っています。',
        available: 'アップデートが利用可能です。更新してもよろしいですか？',
        updating: '更新を開始しました。お待ちください...',
        confirm: '確認',
        cancel: 'キャンセル'
      },
      account: {
        title: 'Account',
        webAccount: 'Web Account Name',
        password: 'Password',
        updateBtn: 'Update',
        logoutBtn: 'Logout'
      }
    }
  }
};

export default ja;
