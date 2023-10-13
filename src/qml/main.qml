import QtQuick.Controls
import QtQuick

ApplicationWindow {

    visible: true

	Column {

		anchors.centerIn: parent

		Label {
			text: "test"
		}

		Button {
			text: "open dialog " + Window.contentItem
			onClicked: dialog.open()
		}
	}

	Component.onCompleted: {

		console.warn("----- " + Window.contentItem)
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