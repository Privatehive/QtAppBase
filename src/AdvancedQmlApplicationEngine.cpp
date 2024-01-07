#include "AdvancedQmlApplicationEngine.h"
#include "info.h"
#include <QDir>
#include <QFileSystemWatcher>
#include <QIcon>
#include <QLoggingCategory>
#include <QMetaObject>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickView>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QString>
#include <QThread>
#include <QTimer>


Q_LOGGING_CATEGORY(qmlengine, "qmlengine")

AdvancedQmlApplicationEngine::AdvancedQmlApplicationEngine(QObject *parent) :
 QQmlApplicationEngine(parent), mHotReloading(false), mpWatcher(new QFileSystemWatcher(this)), mpTimer(new QTimer(this)), mpView(nullptr) {

	mpTimer->setTimerType(Qt::VeryCoarseTimer);
	mpTimer->setInterval(500);
	mpTimer->setSingleShot(true);
	connect(mpTimer, &QTimer::timeout, this, [this]() { handleReload(); });
	init();
}

void AdvancedQmlApplicationEngine::init() {

	// Q_IMPORT_PLUGIN(QuickFutureQmlPlugin);
	// setImportPathList({QLatin1String("/home/bjoern/.conan/data/qt/6.4.2/_/_/package/98e9915d107b9d8446edaf435ac655e84843eb36/res/archdatadir/qml")}/*QStringList(QLatin1String("qrc:/"))+engine.importPathList()+QString::fromLocal8Bit(QML_IMPORT_PATHS).split(QLatin1String(","))*/);
	// setPluginPathList({QLatin1String("qrc:/"), QLatin1String("qrc:/qt-project.org/imports"),
	// QLatin1String("/home/bjoern/.conan/data/qt/6.4.2/_/_/package/98e9915d107b9d8446edaf435ac655e84843eb36/res/archdatadir/plugins")}/*QStringList(QLatin1String("qrc:/"))+engine.pluginPathList()+QString::fromLocal8Bit(QML_PLUGIN_PATHS).split(QLatin1String(","))*/);
	qInfo(qmlengine) << "Starting AdvancedQmlApplicationEngine";
	QQuickWindow::setTextRenderType(QQuickWindow::QtTextRendering); // Use Qt rendering for constant quality beyond all platforms
}

void AdvancedQmlApplicationEngine::setHotReload(bool enable) {

	mHotReloading = enable;
	if(hasRootItem()) {
		connectWatcher();
	}
}

// If "useQuickView==false" you have to use ApplicationWindow as you root qml object.
void AdvancedQmlApplicationEngine::loadRootItem(const QString &rootItem, bool useQuickView /*= true*/) {

#ifdef Q_OS_ANDROID
	addImportPath("qrc:/qt/qml"); // Workaround for Bug https://bugreports.qt.io/browse/QTBUG-120445
#endif
	qInfo(qmlengine) << "loading qml root item";
	qInfo(qmlengine) << "qml import paths:" << importPathList();
	qInfo(qmlengine) << "qml plugin paths:" << pluginPathList();
	if(qEnvironmentVariableIsSet("QML_DISK_CACHE_PATH")) {
		qInfo(qmlengine) << "qml cache location (overwritten)" << qgetenv("QML_DISK_CACHE_PATH");
	} else {
		qInfo(qmlengine) << "qml cache location (default)" << QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
	}
	qInfo(qmlengine) << "icon search path" << QIcon::themeSearchPaths();

	if(rootItem.startsWith("qrc:"))
		loadRootItem(QUrl(rootItem), useQuickView);
	else
		loadRootItem(QUrl::fromLocalFile(rootItem), useQuickView);
}

void AdvancedQmlApplicationEngine::loadRootItem(const QUrl &rootItem, bool useQuickView) {

	mRootUrl = rootItem;

	if(useQuickView) {
		// QWindow window;
		mpView = new QQuickView(this, nullptr);
		mpView->setResizeMode(QQuickView::SizeRootObjectToView);
		mpView->setSource(rootItem);
		if(!mpView->rootObject()) {
			QString errorMsg;
			for(const auto &error : mpView->errors()) {
				errorMsg += QString("Couldn't create GUI: %1").arg(error.toString());
			}
			qFatal(qmlengine) << errorMsg;
		} else {
			for(const auto &error : mpView->errors()) {
				qFatal(qmlengine) << error;
			}
			mpView->show();
		}
	} else {
		load(rootItem);
		if(rootObjects().isEmpty()) {
			const auto errorMsg = QString("Couldn't create GUI: %1").arg(rootItem.toDisplayString());
			qFatal(qmlengine) << errorMsg;
		}
	}
	if(mHotReloading) connectWatcher();
}

bool AdvancedQmlApplicationEngine::hasRootItem() const {

	return getRootObject();
}

void AdvancedQmlApplicationEngine::connectWatcher() {

	disconnectWatcher();
	if(const auto rootObject = getRootObject()) {
		auto ctx = contextForObject(rootObject);
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
				qInfo(qmlengine) << "Enabled hot reloading for following file:" << qmlFile;
				mpWatcher->addPath(qmlFile);
			}
		} else {
			qWarning(qmlengine) << "Can't install filesystem watcher. Root item it not a local file.";
		}
	} else {
		qWarning(qmlengine) << "Can't install filesystem watcher. Missing root item.";
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

	if(mpTimer) mpTimer->start();
}

void AdvancedQmlApplicationEngine::handleReload() {

	if(mpView) {
		mpView->setSource({});
	} else {
		for(auto rootObject : rootObjects()) {
			if(rootObject) {
				QMetaObject::invokeMethod(rootObject, "close", Qt::DirectConnection);
			}
		}
	}
	clearComponentCache();
	QThread::msleep(50);
	if(mpView) {
		mpView->setSource(mRootUrl);
		mpView->requestActivate();
	} else {
		load(mRootUrl);
	}
	emit reloadFinished();
}

QObject *AdvancedQmlApplicationEngine::getRootObject() const {

	if(mpView) {
		return reinterpret_cast<QObject *>(mpView->rootObject());
	} else {
		return rootObjects().isEmpty() ? nullptr : rootObjects().first();
	}
}
