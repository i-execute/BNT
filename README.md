<p align="center">
  <a href="https://t.me/I_execute"><img src="https://img.shields.io/badge/Telegram-@I__execute-26A5E4?style=flat&logo=telegram&logoColor=white" alt="Telegram" /></a>
</p>

### BNT - Bot Net Tool in Telegram wich let you using self-made modules!

This tool is for personal use only. Keep your sessions secure. The author is not responsible for misuse and deleted/limited/frozen accounts.

### Quick Start

Prepare your Bot token and API cerds from [my.telegram.org](https://my.telegram.org) and run that script:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/i-execute/BNT/main/Storage/Installation/QuickStart.sh)
```

### Service Management

```bash
systemctl --user status BNT
systemctl --user restart BNT
systemctl --user stop BNT
journalctl --user -u BNT -f
```

### File Structure

```
BNT/
├── CHANGELOG.md
├── README.md
├── LICENSE
├── Storage/
│   ├── installation/
│   │   ├── QuickStart.sh
│   │   └── Setuper.sh
│   ├── Photo/
│   └── Video/
└── BNT/
    ├── protection.py
    ├── functions.py
    ├── commands.py
    ├── updater.py
    ├── strings.py
    ├── core.py
    ├── tl.py
    └── Modules/
        ├── OnlineKeeper.py
        └── Watcher.py
```

### License

GNU GPL v3 - see [LICENSE](LICENSE)