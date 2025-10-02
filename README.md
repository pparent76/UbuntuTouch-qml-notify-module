# qml-notify-module

This QML module exposes allows to display desktop notifications with haptic feedback from qml
**It requires the app to be inconfined to work**
It works with **Qt5** and uses **GLib**, **libnotify**, and **QDBus**.

---

## Example Usage in QML

Here is a simple example demonstrating how to use the module in a QML file:

```qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import Pparent.Notifications 1.0

ApplicationWindow {
    visible: true

    NotificationHelper {
        id: helper
    }

    Button {
        text: "Show Notification"
        onClicked: helper.showNotificationMessage("Hello from QML!")
    }
}
