#include "AdvancedQmlApplicationEngine.h"
#include "QtApplicationBase.h"
#include "info.h"
#include <QGuiApplication>
#include <QQuickView>

int main(int argc, char **argv) {

	QtApplicationBase<QGuiApplication> app(argc, argv);
	AdvancedQmlApplicationEngine qmlEngine;

#ifdef QT_DEBUG
	auto qmlMainFile = QString("src/qml/main.qml");
	if(QFile::exists(qmlMainFile)) {
		qInfo() << "QML hot reloading enabled";
		qmlEngine.setHotReload(true);
		qmlEngine.loadRootItem("src/qml/main.qml", true);
	} else {
		qmlEngine.setHotReload(false);
		qmlEngine.loadRootItem("qrc:/Application/qml/main.qml", true);
	}
#else
	qmlEngine.setHotReload(false);
	qmlEngine.loadRootItem("qrc:/Application/qml/main.qml");
#endif

	return app.start();
}