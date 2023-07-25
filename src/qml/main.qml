import QtQuick.Controls
import QtQuick
import QtMultimedia

Page {

    visible: true

	MediaDevices {
		id: mediaDevices
	}

	Column {

		anchors.centerIn: parent

		Label {
			id: zoom
			text: "test"
		}

		Repeater {
			model: mediaDevices. videoInputs

			Row {
				Camera {
					id: cam
				}
				Label {
					text: modelData.id + ": " + modelData.description
				}
				Label {
					text: " minZoom: " + cam.minimumZoomFactor
				}
				Label {
					text: " maxZoom: " + cam.maximumZoomFactor
				}
				Item {
					implicitHeight: 10
				}
			}
		}
	}
}