#pragma once
#include "LogMessageHandler.h"
#include "QtApplicationBaseExport.h"
#include "info.h"
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QLibraryInfo>
#include <QSettings>
#include <QStandardPaths>
#include <QString>
#include <QtGlobal>


template<class T>
class QTAPPBASE_EXPORT QtApplicationBase : public T {

 public:
	QtApplicationBase(int &argc, char **argv) : T(argc, argv) { init(); }
	void set(const QString &applicationName, const QString &applicationVersion, const QString &domain);
	// Must only be called once
	int start();

	QString getCacheLocation();
	QString getDataLocation();
	QString getConfigLocation();

 private:
	void init();
};

template<class T>
void QtApplicationBase<T>::set(const QString &applicationName, const QString &applicationVersion, const QString &domain) {

	QCoreApplication::setApplicationName(applicationName);
	QCoreApplication::setApplicationVersion(applicationVersion);
	QCoreApplication::setOrganizationDomain(domain);
	QCoreApplication::setOrganizationName("");
}

template<class T>
QString QtApplicationBase<T>::getCacheLocation() {

#ifdef QT_DEBUG
	return QCoreApplication::applicationDirPath() + "/cache";
#else
	return QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
#endif
}


template<class T>
QString QtApplicationBase<T>::getDataLocation() {

#ifdef QT_DEBUG
	return QCoreApplication::applicationDirPath() + "/data";
#else
	return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
#endif
}
template<class T>
QString QtApplicationBase<T>::getConfigLocation() {

#ifdef QT_DEBUG
	return QCoreApplication::applicationDirPath() + "/config";
#else
	return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
#endif
}

template<class T>
int QtApplicationBase<T>::start() {

	QCommandLineParser parser;
	parser.addOption({"u", "Uninstall persistent data."});
	parser.parse(QCoreApplication::arguments());

	if(parser.isSet("u")) {
		// Delete the persistence
		QDir(getDataLocation()).removeRecursively();
		QDir(getConfigLocation()).removeRecursively();
		QDir(getCacheLocation()).removeRecursively();
		return 0;
	}

	return T::exec();
}

template<class T>
void QtApplicationBase<T>::init() {

#if defined(INFO_PROJECTNAME) && defined(INFO_VERSION_MAJOR) && defined(INFO_VERSION_MINOR) && defined(INFO_VERSION_PATCH) && \
 defined(INFO_DOMAIN)
	set(INFO_PROJECTNAME, QString("%1.%2.%3").arg(INFO_VERSION_MAJOR).arg(INFO_VERSION_MINOR).arg(INFO_VERSION_PATCH), INFO_DOMAIN);
#else
	qWarning() << "missing app info defines. you should call 'set()' and provide the app infos yourself!";
#endif

#if(QT_VERSION < QT_VERSION_CHECK(6, 0, 0))
	QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
	QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif

	QDir dir;
	dir.mkpath(getDataLocation());
	dir.mkpath(getConfigLocation());
	dir.mkpath(getCacheLocation());

	QSettings::setDefaultFormat(QSettings::IniFormat);
	QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, getConfigLocation());
	QSettings::setPath(QSettings::IniFormat, QSettings::SystemScope, getConfigLocation());

	QSettings settings;
	settings.beginGroup("_informational_");
	if(settings.value("pid").isValid()) {
		qWarning() << "app crashed before";
	}
	settings.setValue("application", QCoreApplication::applicationName());
	settings.setValue("version", QCoreApplication::applicationVersion());
	settings.setValue("pid", QCoreApplication::applicationPid());
	settings.endGroup();
	settings.sync();

	LogMessageHandler logMessageHandler;
	logMessageHandler.prepare(getDataLocation());

	qInfo().noquote() << QString("Starting app \"%1\" v%2 with PID %3 using Qt %4")
	                      .arg(QCoreApplication::applicationName(), QCoreApplication::applicationVersion(),
	                           QString::number(QCoreApplication::applicationPid()), QString::fromLocal8Bit(qVersion()));
	qInfo() << "Qt" << qPrintable(QLibraryInfo::version().toString().prepend("v")) << "dbg:" << QLibraryInfo::isDebugBuild()
	        << "prefix path:" << QLibraryInfo::path(QLibraryInfo::PrefixPath);
	qInfo() << "data location:" << getDataLocation();
	qInfo() << "config location:" << getConfigLocation();
	qInfo() << "cache location:" << getCacheLocation();

	QObject::connect(qApp, &QCoreApplication::aboutToQuit, qApp, []() {
		qInfo() << "Stopping app with PID" << QCoreApplication::applicationPid();
		QSettings settings;
		settings.beginGroup("_informational_");
		settings.setValue("pid", {});
		settings.endGroup();
		settings.sync();
	});
}
