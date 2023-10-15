import QtQuick.Controls
import QtQuick
import QtAppBase

ApplicationWindow {

    visible: true

	Column {

		anchors.centerIn: parent

		Label {
			text: "secret: " + secret.secret
		}

		TextField {
            width: 240
            text: secret.secret
            onTextEdited: {
            	secret.secret = text
            }
        }

		Button {
			text: "open dialog"
			onClicked: dialog.open()
		}

		Secret {
			id: secret
			name: "test"
		}
	}

	Dialog {
		id: dialog
		title: "Title"
		parent: Overlay.overlay
		width: 300

		Label {
			text: "Window width: " + Window.contentItem + " - " + ApplicationWindow.contentItem + " - " + ApplicationWindow.window.contentItem
		}

		Component.onCompleted: {

			console.log("---------------------------");
			for (let key in ApplicationWindow) {
			  console.log(key, ApplicationWindow[key]);
			}
			console.log("-----");
			for (let key in Window) {
			  console.log(key, Window[key]);
			}
			console.log("---------------------------");
		}

		onOpened: {

			console.log("---------------------------");
			console.log("-----" + ApplicationWindow);
			for (let key in ApplicationWindow) {
			  console.log(key, ApplicationWindow[key]);
			}
			console.log("");
			console.log("----- " + Window);
			for (let key in Window) {
			  console.log(key, Window[key]);
			}
			console.log("");
			console.log("----- " + ApplicationWindow.window);
			for (let key in ApplicationWindow.window) {
			  console.log(key, ApplicationWindow.window[key]);
			}
			console.log("---------------------------");
		}
	}
}