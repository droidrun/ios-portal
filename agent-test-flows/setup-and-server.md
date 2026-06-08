# Setup And Server

Use this to start the portal and verify that the host can reach it.

## Optional Build Check

```bash
xcodebuild -project droidrun-ios-portal.xcodeproj \
  -scheme droidrun-ios-portal \
  -configuration Debug \
  -sdk iphoneos \
  -derivedDataPath /tmp/ios-portal-derived-data \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Simulator

Start the portal:

```bash
./simulator.sh "<simulator-name>"
```

Check that the server answers:

```bash
curl -fsS http://127.0.0.1:6643/device/date
```

## Physical iPhone

Start the portal:

```bash
./device.sh <device-udid>
```

Forward the port from another terminal:

```bash
iproxy -u <device-udid> -s 127.0.0.1 6643:6643
```

Check that the server answers:

```bash
curl -fsS http://127.0.0.1:6643/device/date
```

## Cleanup

- Stop the portal test run when checks are finished.
- Stop `iproxy` after physical iPhone checks.
- If port `6643` is already in use, stop the old portal process before retrying.
