# qml-notify-module

This QML module exposes allows to display desktop notifications with haptic feedback from qml
**It requires the app to configured properly with configuration files provided to work**
It works with **Qt5** and uses **QDBus**.

---

## Configure project to use the notifications

./setup-project.sh [PROJECT-PATH]

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
        push_app_id:example.orgname_example
    }

    Button {
        text: "Show Notification"
        onClicked: helper.showNotificationMessage("Hello Title","Hello world from QML!")
    }
}
 
