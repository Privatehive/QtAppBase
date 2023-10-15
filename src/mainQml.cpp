#include "AdvancedQmlApplicationEngine.h"
#include "QtApplicationBase.h"
#include "SecretsManager.h"
#include "info.h"
#include <QGuiApplication>
#include <QQuickView>

int main(int argc, char **argv) {

	QtApplicationBase<QGuiApplication> app(argc, argv);
	AdvancedQmlApplicationEngine qmlEngine;

	SecretsManager secrets;
	auto machineId = secrets.getUniqueId();
	secrets.writeSecretSync("test", "bjoern");
	auto result = secrets.readSecretSync("test");

#ifdef QT_DEBUG
	auto qmlMainFile = QString("QtAppBase/QtAppBase/main.qml");
	if(QFile::exists(qmlMainFile)) {
		qInfo() << "QML hot reloading enabled";
		qmlEngine.setHotReload(true);
		qmlEngine.loadRootItem("QtAppBase/QtAppBase/main.qml", false);
	} else {
		qmlEngine.setHotReload(false);
		qmlEngine.loadRootItem("qrc:/qt/qml/QtAppBase/QtAppBase/main.qml", false);
	}
#else
	qmlEngine.setHotReload(false);
	qmlEngine.loadRootItem("qrc:/qt/qml/QtAppBase/QtAppBase/main.qml", false);
#endif

	return app.start();
}