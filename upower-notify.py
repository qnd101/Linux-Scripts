import subprocess
import asyncio
from dbus_fast.aio import MessageBus
from dbus_fast import BusType

UPOWER_BUS = 'org.freedesktop.UPower'
UPOWER_PATH = '/org/freedesktop/UPower/devices/battery_BAT0'
PROPERTIES = 'org.freedesktop.DBus.Properties'

def on_properties_changed(interface_name, changed_properties, invalidated_properties):
    for prop, variant in changed_properties.items():
        if prop != 'Percentage':
            continue
        # Notify for 15%
        if variant.value == 15:
            subprocess.run(['notify-send', '--urgencey', 'normal', '--app-name', 'upower-notify', 'Low Battery: 15%'])
        # Notify for 5%
        elif variant.value == 5:
            subprocess.run(['notify-send', '--urgencey', 'critical', '--app-name', 'upower-notify', 'Very Low Battery: 5%'])

async def main():
    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
    introspection = await bus.introspect(UPOWER_BUS, UPOWER_PATH)
    obj = bus.get_proxy_object(UPOWER_BUS, UPOWER_PATH, introspection)

    # Get the standard Properties interface
    properties = obj.get_interface(PROPERTIES)

    properties.on_properties_changed(on_properties_changed)
    # Keep the script running
    await asyncio.Event().wait()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
