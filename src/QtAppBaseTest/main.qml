import QtQuick.Controls
import QtQuick
import QtAppBase

ApplicationWindow {

    visible: true

    Column {

        anchors.centerIn: parent

        Label {
            text: "secret " + (secret.fallback ? "(fallback): " : ": ") + secret.value
        }

        TextField {
            width: 240
            text: secret.value
            onTextEdited: {
                secret.value = text
            }
        }

        Secret {
            id: secret
            alias: "test"
        }
    }
}