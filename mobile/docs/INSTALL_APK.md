# Installing the NutriGuide APK (pilot)

This build talks to the NutriGuide server running on the project PC, over the
local Wi-Fi. There is no hosted server yet.

## 1. Before you start (on the PC)

1. Start the database and the API in WSL:

   ```bash
   cd ~/NutriGuideAI
   docker compose up -d db
   cd backend
   uv run uvicorn app.api.main:app --host 0.0.0.0 --port 8000
   ```

2. Make the API reachable from the Wi-Fi. WSL uses its own network, so Windows
   has to forward port 8000 to it. In an **administrator** PowerShell:

   ```powershell
   $wsl = (wsl hostname -I).Trim().Split(' ')[0]
   netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8000 connectaddress=$wsl connectport=8000
   ```

   The WSL address changes after a restart; run `netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=8000` and the two lines above again.
   Windows Firewall may also ask to allow inbound port 8000 on private
   networks; allow it only on your home Wi-Fi.

3. Check from the phone's browser: `http://<PC Wi-Fi IP>:8000/api/v1/health`
   must show `"status": "ok"`. Find the PC address with `ipconfig` (Wi-Fi
   adapter, IPv4 Address).

## 2. Install on an Android phone

1. Copy `nutriguide-<version>.apk` to the phone (USB, Drive, or a chat app).
2. Open it. Android asks to allow installs from that app ("Install unknown
   apps"); allow it for this install only.
3. The phone must be on the **same Wi-Fi** as the PC while you use the app.
4. Reminders: when you first turn one on, allow notifications.

## 3. Rebuilding with another server address

The server address is fixed at build time. From `mobile/` on Windows:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://<PC Wi-Fi IP>:8000
```

- A new Wi-Fi address also needs to be added to
  `android/app/src/main/res/xml/network_security_config.xml` (plain HTTP is
  allowed only for the listed local addresses).
- When the server is hosted with HTTPS, build with
  `--dart-define=API_BASE_URL=https://<domain>` and remove the local
  addresses from that file.

## 4. Signing

Release builds are signed with the keystore described in
`android/key.properties` (not in the repository; it points to a keystore kept
outside it). Without that file the release build falls back to the debug key,
so other clones and CI still build. Keep the keystore and its passwords
safe: the same key is needed to install updates over an existing install.
