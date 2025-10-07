# qml-notify-module

This QML module exposes allows to display Ubuntu Touch notifications locally (without going through a remote push server)

**It requires the project to be configured properly with configuration files provided**, setup-project.sh is here to help with this task.

Local notifications are mainly useful in case where the app is not suspended in background. In order to avoid suspending your app in background use Ubuntu Tweaks app. Note that this will consume more battery, make sure your application is not too CPU-intensive.

**Note:** The Lomiri notifications may not show the notifications of your app if it is in foreground.

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

    Timer {
            id: delayTimer
            interval: 5000        // 5 secondes
            repeat: false
            running: false
            onTriggered: helper.send("Hello world")
    }

    Button {
        text: "Show Notification in 5s"
        onClicked: delayTimer.running = true;
    }
}
 
