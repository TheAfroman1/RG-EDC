# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC
#
# A small stand-in for bluetoothd on the session bus, enough to drive
# rgedc-phone end to end off the device: an adapter, advertising and GATT
# managers, and an "iPhone" that serves ANCS and the Current Time Service.

import asyncio
import struct

import dbussy as dbus
from dbussy import DBUS

ANCS = "7905f431-b5ce-4e99-a40f-4b1e122d00d0"
NS = "9fbf120d-6301-42d9-8c58-25e699a21dbd"
CP = "69d1d8f3-45e1-49a8-9821-9bbdfdaad9d9"
DS = "22eac6e9-24d6-4bb5-be44-b36ace7c7bfb"
AMS = "89d3502b-0f36-433a-8ef4-c502ad55f8dc"
CTS = "00001805-0000-1000-8000-00805f9b34fb"
CTS_CUR = "00002a2b-0000-1000-8000-00805f9b34fb"
CTS_LTI = "00002a0f-0000-1000-8000-00805f9b34fb"

SIGS = {"Address": "s", "Alias": "s", "Name": "s", "Powered": "b", "Connected": "b",
        "Paired": "b", "Trusted": "b", "ServicesResolved": "b", "UUIDs": "as",
        "UUID": "s", "Primary": "b", "Device": "o", "Service": "o", "Flags": "as",
        "Value": "ay", "Notifying": "b", "AddressType": "s"}

HCI = "/org/bluez/hci0"
PHONE = HCI + "/dev_AA_BB_CC_DD_EE_FF"


def variant(k, v):
    return (SIGS.get(k, "s"), v)


class FakeBluez:
    def __init__(self, loop):
        self.loop = loop
        self.objects = {}
        self.ads = {}
        self.apps = {}
        self.cp_writes = []
        self.actions = []
        self.notifs = {}       # uid -> attrs for the fake iPhone
        self.apps_names = {"com.apple.MobileSMS": "Messages"}
        self.client = None     # unique name of rgedc-phone

    async def start(self):
        self.conn = await dbus.Connection.bus_get_async(DBUS.BUS_SESSION, private=True, loop=self.loop)
        self.conn.bus_request_name("org.bluez", DBUS.NAME_FLAG_DO_NOT_QUEUE)
        self.conn.add_filter(self.filter, None)
        self.conn.bus_add_match("type='signal',path_namespace='/rgedc'")
        self.tx = b""
        self.objects[HCI] = {
            "org.bluez.Adapter1": {"Address": "11:22:33:44:55:66", "Alias": "ROCKNIX", "Powered": True},
            "org.bluez.LEAdvertisingManager1": {},
            "org.bluez.GattManager1": {},
        }

    # ----- helpers

    def signal(self, path, iface, name, sig, *args):
        msg = dbus.Message.new_signal(path, iface, name)
        msg.append_objects(sig, *args)
        self.conn.send(msg)

    def set_props(self, path, iface, **props):
        self.objects[path][iface].update(props)
        self.signal(path, DBUS.INTERFACE_PROPERTIES, "PropertiesChanged", "sa{sv}as",
                    iface, {k: variant(k, v) for k, v in props.items()}, [])

    def add_object(self, path, ifaces):
        self.objects[path] = ifaces
        self.signal("/", "org.freedesktop.DBus.ObjectManager", "InterfacesAdded", "oa{sa{sv}}",
                    path, {i: {k: variant(k, v) for k, v in p.items()} for i, p in ifaces.items()})

    def remove_object(self, path):
        ifaces = self.objects.pop(path)
        self.signal("/", "org.freedesktop.DBus.ObjectManager", "InterfacesRemoved", "oas",
                    path, list(ifaces))

    async def call(self, dest, path, iface, method, sig="", *args):
        msg = dbus.Message.new_method_call(dest, path, iface, method)
        if sig:
            msg.append_objects(sig, *args)
        reply = await self.conn.send_await_reply(msg, 5000)
        return reply.expect_return_objects(reply.signature)

    # ----- the phone

    def connect_iphone(self):
        self.add_object(PHONE, {"org.bluez.Device1": {
            "Address": "AA:BB:CC:DD:EE:FF", "Alias": "Joe's iPhone", "Name": "Joe's iPhone",
            "Connected": True, "Paired": False, "Trusted": False, "ServicesResolved": False,
            "UUIDs": [AMS], "AddressType": "random"}})

        def svc(n, uuid):
            p = "%s/service%04x" % (PHONE, n)
            self.add_object(p, {"org.bluez.GattService1": {"UUID": uuid, "Primary": True, "Device": PHONE}})
            return p

        def ch(svcp, n, uuid, flags):
            p = "%s/char%04x" % (svcp, n)
            self.add_object(p, {"org.bluez.GattCharacteristic1": {"UUID": uuid, "Service": svcp,
                                                                   "Flags": flags, "Notifying": False}})
            return p

        s = svc(0x20, ANCS)
        self.ns = ch(s, 0x21, NS, ["notify"])
        self.cp = ch(s, 0x24, CP, ["write"])
        self.ds = ch(s, 0x26, DS, ["notify"])
        c = svc(0x30, CTS)
        self.cts_cur = ch(c, 0x31, CTS_CUR, ["read", "notify"])
        self.cts_lti = ch(c, 0x33, CTS_LTI, ["read"])
        self.set_props(PHONE, "org.bluez.Device1", ServicesResolved=True)

    def disconnect_iphone(self):
        self.set_props(PHONE, "org.bluez.Device1", Connected=False, ServicesResolved=False)

    def post(self, uid, flags=0, category=4, event=0, **attrs):
        if attrs:
            self.notifs[uid] = attrs
        self.set_props(self.ns, "org.bluez.GattCharacteristic1",
                       Value=list(struct.pack("<BBBBI", event, flags, category, 1, uid)))

    def ds_send(self, data):
        # Split in two to exercise reassembly.
        half = max(1, len(data) // 2)
        for chunk in (data[:half], data[half:]):
            if chunk:
                self.set_props(self.ds, "org.bluez.GattCharacteristic1", Value=list(chunk))

    def answer_cp(self, data):
        data = bytes(data)
        self.cp_writes.append(data)
        if data[0] == 0:
            uid = struct.unpack("<I", data[1:5])[0]
            attrs = self.notifs.get(uid, {})
            out = bytearray(data[:5])
            pos = 5
            ids = {0: "app", 1: "title", 2: "subtitle", 3: "message", 5: "date", 6: "pos", 7: "neg"}
            while pos < len(data):
                aid = data[pos]
                pos += 1
                if aid in (1, 2, 3):
                    maxlen = struct.unpack("<H", data[pos:pos + 2])[0]
                    pos += 2
                else:
                    maxlen = 1000
                v = str(attrs.get(ids.get(aid, ""), "")).encode()[:maxlen]
                out += struct.pack("<BH", aid, len(v)) + v
            self.loop.call_later(0.05, self.ds_send, bytes(out))
        elif data[0] == 1:
            end = data.index(b"\0", 1)
            app = data[1:end].decode()
            v = self.apps_names.get(app, "").encode()
            self.loop.call_later(0.05, self.ds_send, data[:end + 1] + struct.pack("<BH", 0, len(v)) + v)
        elif data[0] == 2:
            uid, act = struct.unpack("<IB", data[1:6])
            self.actions.append((uid, act))

    # ----- D-Bus dispatch

    def filter(self, conn, msg, _):
        if msg.type == DBUS.MESSAGE_TYPE_SIGNAL and (msg.path or "").startswith("/rgedc"):
            args = msg.all_objects
            if msg.member == "PropertiesChanged" and "Value" in args[1]:
                self.tx += bytes(args[1]["Value"][1])
            return DBUS.HANDLER_RESULT_NOT_YET_HANDLED
        if msg.type != DBUS.MESSAGE_TYPE_METHOD_CALL or msg.destination not in ("org.bluez", conn.bus_unique_name):
            return DBUS.HANDLER_RESULT_NOT_YET_HANDLED
        res = self.handle(msg)
        if asyncio.iscoroutine(res):
            async def later():
                try:
                    out = await res
                    self.reply(msg, out)
                except Exception as e:
                    self.reply_error(msg, str(e))
            self.loop.create_task(later())
        else:
            try:
                self.reply(msg, res)
            except Exception as e:
                self.reply_error(msg, str(e))
        return DBUS.HANDLER_RESULT_HANDLED

    def reply(self, msg, res):
        if isinstance(res, Exception):
            return self.reply_error(msg, str(res))
        r = msg.new_method_return()
        if res:
            r.append_objects(*res)
        self.conn.send(r)

    def reply_error(self, msg, text):
        self.conn.send(msg.new_error("org.bluez.Error.Failed", text))

    def handle(self, msg):
        path, iface, member = msg.path, msg.interface, msg.member
        args = msg.all_objects
        self.client = msg.sender
        if iface == "org.freedesktop.DBus.ObjectManager" and member == "GetManagedObjects":
            return ("a{oa{sa{sv}}}", {p: {i: {k: variant(k, v) for k, v in pr.items()} for i, pr in ifs.items()}
                                      for p, ifs in self.objects.items()})
        if iface == DBUS.INTERFACE_PROPERTIES:
            if member == "Set":
                i, k, v = args
                self.set_props(path, i, **{k: v[1]})
                return None
            if member == "GetAll":
                return ("a{sv}", {k: variant(k, v) for k, v in self.objects[path][args[0]].items()})
        if iface == "org.bluez.LEAdvertisingManager1":
            if member == "RegisterAdvertisement":
                return self.register_ad(msg.sender, args[0])
            if member == "UnregisterAdvertisement":
                self.ads.pop(args[0], None)
                return None
        if iface == "org.bluez.GattManager1" and member == "RegisterApplication":
            return self.register_app(msg.sender, args[0])
        if iface == "org.bluez.Device1" and member == "Pair":
            self.set_props(path, "org.bluez.Device1", Paired=True)
            return None
        if iface == "org.bluez.Adapter1" and member == "RemoveDevice":
            if args[0] in self.objects:
                self.remove_object(args[0])
            return None
        if iface == "org.bluez.GattCharacteristic1":
            if member in ("StartNotify", "StopNotify"):
                self.set_props(path, iface, Notifying=member == "StartNotify")
                return None
            if member == "WriteValue" and path == getattr(self, "cp", None):
                self.answer_cp(args[0])
                return None
            if member == "ReadValue":
                if path == getattr(self, "cts_cur", None):
                    # 2026-11-20 15:04:05 local, UTC-5
                    return ("ay", list(struct.pack("<HBBBBBBBB", 2026, 11, 20, 15, 4, 5, 5, 0, 0)))
                if path == getattr(self, "cts_lti", None):
                    return ("ay", list(struct.pack("<bB", -20, 0)))
        return RuntimeError("fake bluez: no %s.%s on %s" % (iface, member, path))

    async def register_ad(self, sender, path):
        props = await self.call(sender, path, DBUS.INTERFACE_PROPERTIES, "GetAll", "s",
                                "org.bluez.LEAdvertisement1")
        self.ads[path] = {k: v[1] for k, v in props[0].items()}
        return None

    async def register_app(self, sender, path):
        objs = await self.call(sender, path, "org.freedesktop.DBus.ObjectManager", "GetManagedObjects")
        self.apps[path] = objs[0]
        self.gb_sender = sender
        return None

    # ----- acting as a Gadgetbridge phone

    def gb_char(self, uuid):
        for app in self.apps.values():
            for p, ifs in app.items():
                c = ifs.get("org.bluez.GattCharacteristic1")
                if c and c["UUID"][1] == uuid:
                    return str(p)
        raise KeyError(uuid)

    async def gb_write(self, text, device=HCI + "/dev_11_11_11_11_11_11"):
        if device not in self.objects:
            self.add_object(device, {"org.bluez.Device1": {
                "Address": "11:11:11:11:11:11", "Alias": "Pixel 9", "Connected": True,
                "Paired": False, "UUIDs": [], "AddressType": "random"}})
        rx = self.gb_char("6e400002-b5a3-f393-e0a9-e50e24dcca9e")
        data = text.encode("latin-1")
        for i in range(0, len(data), 20):
            await self.call(self.gb_sender, rx, "org.bluez.GattCharacteristic1", "WriteValue", "aya{sv}",
                            list(data[i:i + 20]), {"device": ("o", device), "type": ("s", "command")})
