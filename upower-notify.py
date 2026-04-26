import subprocess
import asyncio
from dbus_fast.aio import MessageBus
from dbus_fast import BusType

UPOWER_BUS = 'org.freedesktop.UPower'
UPOWER_PATH = '/org/freedesktop/UPower/devices/battery_BAT0'
PROPERTIES = 'org.freedesktop.DBus.Properties'
LOW_BATTERY_THRESHOLD = 15
CRITICAL_BATTERY_THRESHOLD = 5
last_percentage = None

def on_properties_changed(interface_name, changed_properties, invalidated_properties):
    global last_percentage

    for prop, variant in changed_properties.items():
        if prop != 'Percentage':
            continue

        percentage = variant.value

        # Notify when the charge crosses below the threshold, rather than
        # waiting for an exact floating-point value that may never occur.
        if (
            percentage <= CRITICAL_BATTERY_THRESHOLD
            and (last_percentage is None or last_percentage > CRITICAL_BATTERY_THRESHOLD)
        ):
            subprocess.run([
                'notify-send',
                '--urgency',
                'critical',
                '--app-name',
                'upower-notify',
                f'Very Low Battery: {percentage:.0f}%',
            ])
        elif (
            percentage <= LOW_BATTERY_THRESHOLD
            and (last_percentage is None or last_percentage > LOW_BATTERY_THRESHOLD)
        ):
            subprocess.run([
                'notify-send',
                '--urgency',
                'normal',
                '--app-name',
                'upower-notify',
                f'Low Battery: {percentage:.0f}%',
            ])

        last_percentage = percentage

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
