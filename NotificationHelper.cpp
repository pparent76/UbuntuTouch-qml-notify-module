

#include <libnotify/notify.h>

#include "NotificationHelper.h"
#include <QDebug>
#include <QDBusInterface>
#include <QDBusReply>


NotificationHelper::NotificationHelper(QObject *parent)
: QObject(parent)
{
    notify_init("alefnode.whatsweb"); // Initialiser libnotify
}

void NotificationHelper::vibrate(int ms) {
    // Crée une interface vers le service HFD
    QDBusInterface hfd(
        "com.lomiri.hfd",            // bus name
        "/com/lomiri/hfd",           // object path
        "com.lomiri.hfd.Vibrator",   // interface
        QDBusConnection::systemBus() // ou sessionBus si le service est sur le bus session
    );

    if (!hfd.isValid()) {
        qDebug() << "Impossible de se connecter au service HFD";
        return;
    }

    // Appelle la méthode Vibrate pour 3000ms
    QDBusReply<void> reply = hfd.call("vibrate", ms);
    if (!reply.isValid()) {
        qDebug() << "Erreur lors de l'appel D-Bus:" << reply.error().message();
        return;
    }
}

void NotificationHelper::showNotificationMessage(const QString &message)
{
    const QString icon = "/opt/click.ubuntu.com/.click/users/@all/alefnode.whatsweb/icon.png";

    NotifyNotification *notification = notify_notification_new( message.toStdString().c_str(),nullptr, icon.toStdString().c_str());

    notify_notification_set_urgency(notification, NOTIFY_URGENCY_CRITICAL);

    GError *error = nullptr;
    if (!notify_notification_show(notification, &error)) {
        qWarning() << "Failed to show notification:" << error->message;
     g_error_free(error);
    }

    NotificationHelper::vibrate(2000);
    g_object_unref(G_OBJECT(notification));
}

