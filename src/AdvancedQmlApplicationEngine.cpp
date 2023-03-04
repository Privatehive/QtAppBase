#include "AdvancedQmlApplicationEngine.h"
#include "info.h"
#include <QDir>
#include <QFileSystemWatcher>
#include <QIcon>
#include <QMetaObject>
#include <QQmlContext>
#include <QStandardPaths>
#include <QString>
#include <QThread>
#include <QTimer>


AdvancedQmlApplicationEngine::AdvancedQmlApplicationEngine(QObject *parent) :
 QQmlApplicationEngine(parent), mHotReloading(false), mpWatcher(new QFileSystemWatcher(this)), mpTimer(new QTimer(this)) {

	mpTimer->setTimerType(Qt::VeryCoarseTimer);
	mpTimer->setInterval(500);
	mpTimer->setSingleShot(true);
	connect(mpTimer, &QTimer::timeout, this, [this]() { reload(); });
	init();
}

void AdvancedQmlApplicationEngine::init() {

	// Q_IMPORT_PLUGIN(QuickFutureQmlPlugin);
	// setImportPathList({QLatin1String("/home/bjoern/.conan/data/qt/6.4.2/_/_/package/98e9915d107b9d8446edaf435ac655e84843eb36/res/archdatadir/qml")}/*QStringList(QLatin1String("qrc:/"))+engine.importPathList()+QString::fromLocal8Bit(QML_IMPORT_PATHS).split(QLatin1String(","))*/);
	// setPluginPathList({QLatin1String("qrc:/"), QLatin1String("qrc:/qt-project.org/imports"),
	// QLatin1String("/home/bjoern/.conan/data/qt/6.4.2/_/_/package/98e9915d107b9d8446edaf435ac655e84843eb36/res/archdatadir/plugins")}/*QStringList(QLatin1String("qrc:/"))+engine.pluginPathList()+QString::fromLocal8Bit(QML_PLUGIN_PATHS).split(QLatin1String(","))*/);
	qInfo() << "--- starting AdvancedQmlApplicationEngine ---";
	qInfo() << "qml import paths:" << importPathList();
	qInfo() << "qml plugin paths:" << pluginPathList();
	if(qEnvironmentVariableIsSet("QML_DISK_CACHE_PATH")) {
		qInfo() << "qml cache location (overwritten)" << qgetenv("QML_DISK_CACHE_PATH");
	} else {
		qInfo() << "qml cache location (default)" << QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
	}
	qInfo() << "icon search path" << QIcon::themeSearchPaths();
}

void AdvancedQmlApplicationEngine::setHotReload(bool enable) {

	mHotReloading = enable;
	if(hasRootItem()) {
		connectWatcher();
	}
}

void AdvancedQmlApplicationEngine::loadRootItem(const QString &rootItem) {

	if(rootItem.startsWith("qrc:"))
		loadRootItem(QUrl(rootItem));
	else
		loadRootItem(QUrl::fromLocalFile(rootItem));
}

void AdvancedQmlApplicationEngine::loadRootItem(const QUrl &rootItem) {

	mRootUrl = rootItem;
	load(rootItem);
	if(rootObjects().isEmpty()) {
		const auto errorMsg = QString("Couldn't create GUI: %1").arg(rootItem.toDisplayString());
		qFatal(qPrintable(errorMsg));
	}
	if(mHotReloading) connectWatcher();
}

bool AdvancedQmlApplicationEngine::hasRootItem() const {

	return !rootObjects().isEmpty();
}

void AdvancedQmlApplicationEngine::connectWatcher() {

	disconnectWatcher();
	auto objects = rootObjects();
	if(!objects.isEmpty() && objects.first()) {
		auto ctx = contextForObject(objects.first());
		if(ctx && ctx->baseUrl().isLocalFile()) {
			QFileInfo fi(ctx->baseUrl().toLocalFile());
			QDir dir(fi.absoluteDir());
			connect(mpWatcher, &QFileSystemWatcher::directoryChanged, this, [this]() {
				if(mpTimer) mpTimer->start();
			});
			connect(mpWatcher, &QFileSystemWatcher::fileChanged, this, [this]() {
				if(mpTimer) mpTimer->start();
			});
			auto filesDirsToWatch = findQmlFilesRecursive(dir);
			for(const auto &qmlFile : filesDirsToWatch) {
				qInfo() << "Enabled hot reloading for following file:" << qmlFile;
				mpWatcher->addPath(qmlFile);
			}
		} else {
			qWarning() << "Can't install filesystem watcher. Root item it not a local file.";
		}
	} else {
		qWarning() << "Can't install filesystem watcher. Missing root item.";
	}
}

void AdvancedQmlApplicationEngine::disconnectWatcher() {

	disconnect(mpWatcher, nullptr, this, nullptr);
	mpWatcher->removePaths(mpWatcher->directories());
	mpWatcher->removePaths(mpWatcher->files());
}

QList<QString> AdvancedQmlApplicationEngine::findQmlFilesRecursive(const QDir &dir) const {

	QList<QString> ret;
	auto qmlFiles = dir.entryList({"*.qml"}, QDir::Files);
	ret.push_back(dir.absolutePath());
	for(const auto &qmlFile : qmlFiles) {
		ret.push_back(dir.absoluteFilePath(qmlFile));
	}
	auto subDirs = dir.entryList({"*"}, QDir::Dirs | QDir::NoDotAndDotDot);
	for(const auto &subDir : subDirs) {
		ret.append(findQmlFilesRecursive(QDir(dir.absoluteFilePath(subDir))));
	}
	return ret;
}

void AdvancedQmlApplicationEngine::reload() {

	for(auto rootObject : rootObjects()) {
		if(rootObject) {
			QMetaObject::invokeMethod(rootObject, "close", Qt::DirectConnection);
		}
	}
	clearComponentCache();
	QThread::msleep(50);
	load(mRootUrl);
}
