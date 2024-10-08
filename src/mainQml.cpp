#include "AdvancedQmlApplicationEngine.h"
#include "QtApplicationBase.h"
#include "SecretsManager.h"
#include "info.h"
#include <QGuiApplication>
#include <QQuickView>

int main(int argc, char **argv) {

	QtApplicationBase<QGuiApplication> app(argc, argv);
	AdvancedQmlApplicationEngine qmlEngine;

	SecretsManager::writeSecretSync("sadfasdf", "23423424");
	SecretsManager::deleteSecretSync("sadfasdf");
	SecretsManager::writeSecretSync("test", "23423424");
	SecretsManager::deleteSecret("test", []() {});

#ifdef QT_DEBUG
	auto qmlMainFile = QString("QtAppBaseTestApp/QtAppBaseTest/main.qml");
	if(QFile::exists(qmlMainFile)) {
		qInfo() << "QML hot reloading enabled";
		qmlEngine.setHotReload(true);
		qmlEngine.loadRootItem("QtAppBaseTestApp/QtAppBaseTest/main.qml", false);
	} else {
		qmlEngine.setHotReload(false);
		qmlEngine.loadRootItem("qrc:/qt/qml/QtAppBaseTest/QtAppBaseTest/main.qml", false);
	}
#else
	qmlEngine.setHotReload(false);
	qmlEngine.loadRootItem("qrc:/qt/qml/QtAppBaseTest/QtAppBaseTest/main.qml", false);
#endif

	return app.start();
}