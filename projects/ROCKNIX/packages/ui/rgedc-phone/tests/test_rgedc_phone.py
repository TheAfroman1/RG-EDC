# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC
#
# Tests for rgedc-phone. The protocol tests need nothing; the end-to-end test
# needs dbussy and a session bus:
#   dbus-run-session -- python3 -m unittest -v test_rgedc_phone

import asyncio
import importlib.machinery
import importlib.util
import json
import os
import struct
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = tempfile.mkdtemp(prefix="rgedc-phone-test-")
os.environ.update(RGEDC_PHONE_SOCK=os.path.join(TMP, "sock"), RGEDC_PHONE_STATE=TMP,
                  RGEDC_PHONE_CACHE=TMP, RGEDC_PHONE_LOG=os.path.join(TMP, "log"),
                  RGEDC_PHONE_BUS="session", RGEDC_PHONE_SET_CLOCK="0")

_loader = importlib.machinery.SourceFileLoader("rgedc_phone", os.path.join(HERE, "..", "sources", "rgedc-phone"))
_spec = importlib.util.spec_from_loader("rgedc_phone", _loader)
ph = importlib.util.module_from_spec(_spec)
_loader.exec_module(ph)


class Ancs(unittest.TestCase):
    def test_ns(self):
        ev = ph.ancs_parse_ns(struct.pack("<BBBBI", 0, 0x0c, 4, 2, 77))
        self.assertEqual(ev, {"event": 0, "flags": 0x0c, "category": 4, "count": 2, "uid": 77})
        self.assertIsNone(ph.ancs_parse_ns(b"\0\0"))

    def test_command(self):
        cmd = ph.ancs_cmd_notif_attrs(0x01020304)
        self.assertEqual(cmd[:5], b"\x00\x04\x03\x02\x01")
        # app id, title(64), subtitle(64), message(400), date, pos, neg
        self.assertEqual(cmd[5:], bytes([0, 1, 64, 0, 2, 64, 0, 3, 0x90, 1, 5, 6, 7]))
        self.assertEqual(ph.ancs_cmd_action(5, False), b"\x02\x05\x00\x00\x00\x01")
        self.assertEqual(ph.ancs_cmd_app_attrs("com.x"), b"\x01com.x\x00\x00")

    def test_reassembly(self):
        r = ph.AncsResponse(0, [0, 1, 3])
        data = b"\x00" + struct.pack("<I", 9)
        for aid, v in ((0, b"com.apple.MobileSMS"), (1, "Zoë".encode()), (3, b"See you at 6")):
            data += struct.pack("<BH", aid, len(v)) + v
        for i in range(0, len(data) - 7, 7):
            self.assertFalse(r.feed(data[i:i + 7]))
        self.assertTrue(r.feed(data[(len(data) - 7) // 7 * 7:]) or r.feed(b""))
        self.assertEqual(r.uid, 9)
        self.assertEqual(r.attrs, {0: "com.apple.MobileSMS", 1: "Zoë", 3: "See you at 6"})

    def test_app_reassembly(self):
        r = ph.AncsResponse(1, [0])
        self.assertFalse(r.feed(b"\x01com.apple.Mob"))
        self.assertTrue(r.feed(b"ileSMS\x00\x00\x08\x00Messages"))
        self.assertEqual((r.app_id, r.attrs), ("com.apple.MobileSMS", {0: "Messages"}))

    def test_cts(self):
        cur = struct.pack("<HBBBBBBBB", 2026, 11, 20, 15, 4, 5, 5, 0, 0)
        # UTC-5 (-20 quarters), no DST
        self.assertEqual(ph.cts_to_utc(cur, struct.pack("<bB", -20, 0)),
                         ph.calendar.timegm((2026, 11, 20, 20, 4, 5, 0, 0, 0)))
        self.assertEqual(ph.cts_to_utc(cur, struct.pack("<bB", 4, 4)),
                         ph.calendar.timegm((2026, 11, 20, 13, 4, 5, 0, 0, 0)))
        self.assertIsNone(ph.cts_to_utc(b"\0" * 10))


class Gadgetbridge(unittest.TestCase):
    def test_espruino_json(self):
        s = r'{"t":"notify","id":1700,"src":"WhatsApp","title":"Ana","body":"caf\xe9 ☺ at 5\n","x":[1,-2.5,true,null]}'
        self.assertEqual(ph.parse_espruino_json(s),
                         {"t": "notify", "id": 1700, "src": "WhatsApp", "title": "Ana",
                          "body": "café ☺ at 5\n", "x": [1, -2.5, True, None]})
        self.assertEqual(ph.parse_espruino_json(r'"a\0b\x01\20"'), "a\0b\x01\x10")
        self.assertEqual(ph.parse_espruino_json('{"b":atob("aGVsbG8=")}'), {"b": "hello"})

    def test_line(self):
        line = "\x10setTime(1795723445);E.setTimeZone(-5.0);(s=>s&&(s.timezone=-5.0,require('Storage').write('setting.json',s)))(require('Storage').readJSON('setting.json',1))"
        self.assertEqual(ph.gb_parse_line(line), [("time", 1795723445.0), ("tz", -5.0)])
        out = ph.gb_parse_line('\x10GB({"t":"notify-","id":12})')
        self.assertEqual(out, [("gb", {"t": "notify-", "id": 12})])
        self.assertEqual(ph.gb_parse_line("\x10g.dump()"), [])

    def test_surrogates(self):
        self.assertEqual(ph.latin1_to_text("😀 hi"), "\U0001F600 hi")
        self.assertEqual(ph.gb_line({"t": "status", "bat": 80}), b'{"t":"status","bat":80}\r\n')


class Store(unittest.TestCase):
    def test_order_and_cap(self):
        st = ph.Store(os.path.join(TMP, "store-test.json"))
        posted = []
        st.listeners.append(posted.append)
        for i in range(60):
            st.put({"id": "x:%d" % i, "time": i}, announce=i == 59)
        self.assertEqual(len(st.items), ph.MAX_ITEMS)
        self.assertEqual(st.items[0]["id"], "x:59")
        self.assertEqual(posted[-1]["id"], "x:59")
        st2 = ph.Store(st.path)
        self.assertEqual(len(st2.items), ph.MAX_ITEMS)


class EndToEnd(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("DBUS_SESSION_BUS_ADDRESS"), "needs a session bus")
    def test_iphone_and_gadgetbridge(self):
        asyncio.run(self.run_e2e())

    async def run_e2e(self):
        sys.path.insert(0, HERE)
        from fake_bluez import FakeBluez, PHONE
        loop = asyncio.get_running_loop()
        clock = []
        ph.set_clock = lambda utc, src: clock.append((utc, src))

        if os.environ.get("RGEDC_PHONE_TEST_LOG"):
            ph.setup_logging()
        fake = FakeBluez(loop)
        await fake.start()
        store = ph.Store(os.path.join(TMP, "notifications.json"))
        link = ph.Link(store, loop)
        hub = ph.Hub(store, link, loop)
        await hub.start()
        await link.start()
        await asyncio.sleep(0.3)

        # Adapter set up: name, GATT app, advertisement asking for ANCS.
        self.assertEqual(fake.objects["/org/bluez/hci0"]["org.bluez.Adapter1"]["Alias"], "RG EDC")
        self.assertIn("/rgedc/phone", fake.apps)
        ad = fake.ads["/rgedc/phone/adv0"]
        self.assertEqual(ad["LocalName"], "RG EDC")
        self.assertEqual(ad["SolicitUUIDs"], [ph.ANCS_SERVICE])

        # The shell connects.
        reader, writer = await asyncio.open_unix_connection(os.environ["RGEDC_PHONE_SOCK"])
        msgs = []

        async def pump():
            while True:
                line = await reader.readline()
                if not line:
                    return
                msgs.append(json.loads(line))
        pumper = loop.create_task(pump())
        await asyncio.sleep(0.1)
        self.assertEqual(msgs[0]["t"], "state")
        self.assertFalse(msgs[0]["phone"]["connected"])

        # Pre-existing notifications on the phone, then the phone connects.
        fake.notifs[100] = {"app": "com.apple.MobileSMS", "title": "Mum", "message": "Old one",
                            "date": "20261120T090000", "neg": "Clear"}
        fake.connect_iphone()
        await asyncio.sleep(0.6)
        dev = fake.objects[PHONE]["org.bluez.Device1"]
        self.assertTrue(dev["Paired"] and dev["Trusted"])
        self.assertTrue(link.phone_connected())
        self.assertEqual(clock[-1], (ph.calendar.timegm((2026, 11, 20, 20, 4, 5, 0, 0, 0)), "iPhone"))
        self.assertNotIn("/rgedc/phone/adv0", fake.ads)     # stops advertising once connected

        fake.post(100, flags=ph.FL_PREEXISTING | ph.FL_NEGATIVE)
        await asyncio.sleep(1.6)
        fake.post(101, flags=ph.FL_NEGATIVE | ph.FL_POSITIVE, app="com.apple.MobileSMS",
                  title="Ana", message="Lunch? 🍜", pos="Reply", neg="Clear")
        await asyncio.sleep(0.6)
        posted = [m for m in msgs if m["t"] == "posted"]
        self.assertEqual(len(posted), 1)
        item = posted[0]["item"]
        self.assertEqual((item["app"], item["title"], item["body"]), ("Messages", "Ana", "Lunch? 🍜"))
        lists = [m for m in msgs if m["t"] == "list"]
        self.assertEqual([i["id"] for i in lists[-1]["items"]], ["ios:101", "ios:100"])
        self.assertEqual(lists[-1]["items"][1]["title"], "Mum")
        self.assertTrue(lists[-1]["items"][1]["read"])
        states = [m for m in msgs if m["t"] == "state"]
        self.assertEqual(states[-1]["phone"], {"connected": True, "kind": "ios", "name": "Joe's iPhone"})
        with open(os.path.join(TMP, "phone.json")) as f:
            self.assertEqual(json.load(f)["phones"][0]["kind"], "ios")

        # Dismiss on the device clears it on the phone (negative action).
        writer.write(b'{"t":"dismiss","id":"ios:101"}\n')
        await writer.drain()
        await asyncio.sleep(0.3)
        self.assertEqual(fake.actions, [(101, 1)])
        self.assertEqual([i["id"] for i in store.items], ["ios:100"])

        # Removed on the phone -> gone here.
        fake.post(100, event=ph.EV_REMOVED)
        await asyncio.sleep(0.2)
        self.assertEqual(store.items, [])

        # Incoming call
        fake.post(102, flags=ph.FL_POSITIVE | ph.FL_NEGATIVE, category=1, app="com.apple.mobilephone",
                  title="Dad", subtitle="mobile", pos="Answer", neg="Decline")
        await asyncio.sleep(0.5)
        calls = [m for m in msgs if m["t"] == "call"]
        self.assertEqual(calls[-1]["call"]["name"], "Dad")
        writer.write(b'{"t":"action","id":"call","positive":false}\n')
        await writer.drain()
        await asyncio.sleep(0.3)
        self.assertEqual(fake.actions[-1], (102, 1))

        # Phone leaves: advertising again.
        fake.disconnect_iphone()
        await asyncio.sleep(0.3)
        self.assertFalse(link.phone_connected())
        self.assertIn("/rgedc/phone/adv0", fake.ads)

        # Android pairing mode changes the advertised name.
        writer.write(b'{"t":"pair","kind":"android"}\n')
        await writer.drain()
        await asyncio.sleep(0.3)
        self.assertEqual(fake.ads["/rgedc/phone/adv0"]["LocalName"], "Espruino RG EDC")
        self.assertEqual(fake.ads["/rgedc/phone/adv0"]["SolicitUUIDs"], [])

        # Gadgetbridge connects and talks.
        await fake.gb_write("\x10setTime(1795723445);E.setTimeZone(-5.0);(s=>s&&(s.timezone=-5.0))(1)\n")
        await fake.gb_write('\x10GB({"t":"notify","id":1700,"src":"WhatsApp","title":"Ana","body":"caf\\xe9 \\ud83d\\ude00","sender":"Ana"})\n')
        await asyncio.sleep(1.3)
        self.assertEqual(clock[-1], (1795723445.0, "Gadgetbridge"))
        self.assertEqual(link.pairing, "")
        self.assertEqual(store.items[0]["body"], "café \U0001F600")
        self.assertEqual(store.items[0]["app"], "WhatsApp")
        self.assertIn(b'"t":"ver"', fake.tx)
        writer.write(b'{"t":"dismiss","id":"gb:1700"}\n')
        await writer.drain()
        await asyncio.sleep(0.3)
        self.assertIn(b'{"t":"notify","id":1700,"n":"DISMISS"}\r\n', fake.tx)
        await fake.gb_write('\x10GB({"t":"call","cmd":"incoming","name":"Bob","number":"555"})\n')
        await asyncio.sleep(0.2)
        writer.write(b'{"t":"action","id":"call","positive":true}\n')
        await writer.drain()
        await asyncio.sleep(0.3)
        self.assertIn(b'{"t":"call","n":"ACCEPT"}\r\n', fake.tx)
        states = [m for m in msgs if m["t"] == "state"]
        self.assertEqual(states[-1]["phone"]["kind"], "android")

        # Forget unpairs both phones.
        writer.write(b'{"t":"forget"}\n')
        await writer.drain()
        await asyncio.sleep(0.3)
        self.assertNotIn(PHONE, fake.objects)
        self.assertEqual(link.known, [])
        pumper.cancel()
        writer.close()
        fake.conn.close()


if __name__ == "__main__":
    unittest.main()
