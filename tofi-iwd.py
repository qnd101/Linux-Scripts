#!/usr/bin/env python3
# Script for getting network info (ssid, strength)
# Directly accesses D-Bus of iwd, instead of relying on iwctl
# Primarily for tofi-iwd.sh script

import asyncio
import subprocess
from dbus_fast.aio import MessageBus
from dbus_fast import BusType

IWD_BUS_NAME = 'net.connman.iwd'
STATION_INTERFACE_NAME = 'net.connman.iwd.Station'
NETWORK_INTERFACE_NAME = 'net.connman.iwd.Network'

HARDWARE_OPTIMUM = -45
HARDWARE_MIN = -90
def dbm_to_percent(dbm):
    strength = 100 - (
        ((HARDWARE_OPTIMUM - dbm) / (HARDWARE_OPTIMUM - HARDWARE_MIN)) * 100
    )
    return max(0, min(100, int(strength)))

async def get_station_path(iobjs):
    station_path = None
    for path, interfaces in iobjs.items():
        if STATION_INTERFACE_NAME in interfaces:
            station_path = path
            break
    return station_path

async def get_wifi_with_strength(bus, iobjs, station_path):
    # 2. Call GetOrderedNetworks on the Station interface
    introspection = await bus.introspect(IWD_BUS_NAME, station_path)
    station_obj = bus.get_proxy_object(IWD_BUS_NAME, station_path, introspection)
    station_iface = station_obj.get_interface(STATION_INTERFACE_NAME)
    
    # Returns a list of [ObjectPath, uint16 strength]
    ordered_networks = await station_iface.call_get_ordered_networks()
    result = []
    for net_path, strength in ordered_networks:
        # Get the properties of the specific network object
        net_props = iobjs[net_path][NETWORK_INTERFACE_NAME]
        result.append({
            "net_path": net_path,
            "ssid": net_props['Name'].value, 
            "known": 'KnownNetwork' in net_props,
            "strength_pct": dbm_to_percent(strength/100)
            })
    return result

# async def connect_wifi(bus, network_path):
#     introspection = await bus.introspect(IWD_BUS_NAME, network_path)
#     network_obj = bus.get_proxy_object(IWD_BUS_NAME, network_path, introspection)
#     network_iface = network_obj.get_interface(NETWORK_INTERFACE_NAME)
#     await network_iface.call_connect()

def connect_wifi(station, ssid, query_pwd):
    args =['iwctl', "station", station, "connect", ssid]

    if query_pwd:
        passphrase = subprocess.run(
                ['tofi', '--hide-input=true', '--prompt-text', 'Passphrase: ', '--require-match=false'],
                input="\n",
                capture_output=True,
                text=True
                ).stdout.strip('\n')
        args.insert(1, f'--passphrase={passphrase}')

    # Execute `iwctl connect`
    # Note: in failure, iwctl gives out misleading error: Argument format is invalid
    result = subprocess.run(args)
    print(result.returncode)

    # Send notification 
    if result.returncode == 0:
        subprocess.run(['notify-send', 'Connected!','--app-name', 'iwd(tofi)'])
    else:
        subprocess.run(['notify-send', 'Connection Failure', '--app-name', 'iwd(tofi)'])

async def main():
    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()

    introspection_root = await bus.introspect(IWD_BUS_NAME, '/')
    obj = bus.get_proxy_object(IWD_BUS_NAME, '/', introspection_root)
    manager = obj.get_interface('org.freedesktop.DBus.ObjectManager')
    iobjs = await manager.call_get_managed_objects()

    station_path = await get_station_path(iobjs)
    if not station_path:
        return

    # Execute scanning
    station_name = iobjs[station_path]["net.connman.iwd.Device"]["Name"].value

    net_info = await get_wifi_with_strength(bus, iobjs, station_path)

    tofi_input = ""
    for obj in net_info:
        tofi_input += f"{obj['ssid']:<40} {obj['strength_pct']:>4}% {'✓' if obj['known'] else '?'}\n"

    result = subprocess.run(
            ['tofi', '--prompt-text', 'Connect to: ', '--width', '800'], 
        input=tofi_input, 
        capture_output=True, 
        text=True
    )
    if not result.stdout:
        return

    ssid_sel = result.stdout.split()[0]
    obj_sel = next((obj for obj in net_info if obj['ssid']==ssid_sel), None)

    if obj_sel['known']:
        # Ask for passphrase reinput
        reply = subprocess.run(
                ['tofi', '--prompt-text', 'Known Network. Retype passphrase? '], 
                input="No\nYes", 
                capture_output=True, 
                text=True
                ).stdout.strip('\n')
        if reply == 'No':
            connect_wifi(station_name, ssid_sel, False) 
        if reply != 'Yes':
            return
    connect_wifi(station_name, ssid_sel, True) 
    # Do a rescan
    subprocess.run(['iwctl', 'station', station_name, 'scan'])

asyncio.run(main())
