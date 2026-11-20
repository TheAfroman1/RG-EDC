# rgedc-phone

Phone notifications for RG EDC over Bluetooth LE.

- **iPhone**: RG EDC advertises as `RG EDC` and solicits the Apple Notification
  Center Service. Pair from iOS Settings › Bluetooth; notifications are read over
  ANCS and the clock is set from the phone's Current Time Service.
- **Android**: install [Gadgetbridge](https://gadgetbridge.org). Settings › Phone ›
  Pair an Android phone advertises as `Espruino RG EDC` for 3 minutes, which
  Gadgetbridge adds as a Bangle.js. It speaks Gadgetbridge's Bangle.js protocol over the
  Nordic UART service: notifications, dismiss, calls, music and time.

The shell connects to `/run/rgedc-phone.sock` (JSON lines, see `Hub` in the
script). State: `/storage/.config/rgedc/phone.json` (paired phones),
`/storage/.cache/rgedc/` (notifications, iOS app names). Log:
`/var/log/rgedc-phone.log`.

## Trying it on a running device

The service is plain Python. A copy at `/storage/.config/rgedc/rgedc-phone`
replaces the built-in one, so you can test without a new image:

    cp rgedc-phone /storage/.config/rgedc/
    systemctl stop rgedc-phone 2>/dev/null
    RGEDC_PHONE_DEBUG=1 python /storage/.config/rgedc/rgedc-phone

Check first that the controller can advertise: `btmgmt info` should list `le`
and `advertising` among the supported settings.

## Tests

    cd tests && dbus-run-session -- python3 -m unittest -v test_rgedc_phone

They need `dbussy` and run against a fake bluetoothd (`fake_bluez.py`).
