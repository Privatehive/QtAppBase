#pragma once
#include "LogMessageHandler.h"
#include "info.h" // this file is generated by QtAppBase.cmake
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QLibraryInfo>
#include <QSettings>
#include <QStandardPaths>
#include <QString>
#include <QtGlobal>


template<class T>
class QtApplicationBase : public T {

public:
	QtApplicationBase(int &argc, char **argv) :
		T(argc, argv) {
#if defined(INFO_PROJECTNAME) && defined(INFO_VERSION_MAJOR) && defined(INFO_VERSION_MINOR) && defined(INFO_VERSION_PATCH) && \
defined(INFO_DOMAIN)
		set(INFO_PROJECTNAME, QString("%1.%2.%3").arg(INFO_VERSION_MAJOR).arg(INFO_VERSION_MINOR).arg(INFO_VERSION_PATCH), INFO_DOMAIN);
#endif
		init();
	}

	QtApplicationBase(int &argc, char **argv, const QString &applicationName) :
		T(argc, argv) {

#if defined(INFO_VERSION_MAJOR) && defined(INFO_VERSION_MINOR) && defined(INFO_VERSION_PATCH) && defined(INFO_DOMAIN)
		set(applicationName, QString("%1.%2.%3").arg(INFO_VERSION_MAJOR).arg(INFO_VERSION_MINOR).arg(INFO_VERSION_PATCH), INFO_DOMAIN);
#endif
		init();
	}

	QtApplicationBase(int &argc, char **argv, const QString &applicationName, const QString &applicationVersion) :
		T(argc, argv) {

#if defined(INFO_DOMAIN)
		set(applicationName, applicationVersion, INFO_DOMAIN);
#endif
		init();
	}

	QtApplicationBase(int &argc, char **argv, const QString &applicationName, const QString &applicationVersion,
	                  const QString &domainReversed) :
		T(argc, argv) {

		set(applicationName, applicationVersion, domainReversed);
		init();
	}

	// Must only be called once
	int start();

	QString getCacheLocation();
	QString getDataLocation();
	QString getConfigLocation();

private:
	void set(const QString &applicationName, const QString &applicationVersion, const QString &domainReversed);
	void init();
};

// provide the domain in reverse notation com.github.tereius instead of tereius.github.com
template<class T>
void QtApplicationBase<T>::set(const QString &applicationName, const QString &applicationVersion, const QString &domainReversed) {

	QCoreApplication::setApplicationName(applicationName);
	QCoreApplication::setApplicationVersion(applicationVersion);
	QCoreApplication::setOrganizationDomain(domainReversed);
	auto domainSplit = domainReversed.split(".", Qt::SkipEmptyParts);
	if(!domainSplit.isEmpty()) {
		QCoreApplication::setOrganizationName(domainSplit.last());
	}
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

	Q_ASSERT_X(!QCoreApplication::applicationName().isEmpty(), "QtApplicationBase::init",
	           "QCoreApplication::applicationName must not be empty - set it or provide the compile definition: INFO_PROJECTNAME");
	Q_ASSERT_X(!QCoreApplication::organizationDomain().isEmpty(), "QtApplicationBase::init",
	           "QCoreApplication::organizationDomain must not be empty - set it or provide the compile definition: INFO_DOMAIN");
	Q_ASSERT_X(!QCoreApplication::applicationVersion().isEmpty(), "QtApplicationBase::init",
	           "QCoreApplication::applicationVersion must not be empty - set it or provide the compile definitions: INFO_VERSION_MAJOR, "
	           "INFO_VERSION_MINOR, INFO_VERSION_PATCH");

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

	LogMessageHandler::prepare(getDataLocation());

	qInfo().noquote() << QString("Starting app \"%1\" v%2 ID %4 PID %3")
	                     .arg(QCoreApplication::applicationName(), QCoreApplication::applicationVersion(),
	                          QString::number(QCoreApplication::applicationPid())).arg(INFO_PROJECTID);
	qInfo() << "Qt" << qPrintable(QLibraryInfo::version().toString().prepend("v")) << "dbg:" << QLibraryInfo::isDebugBuild()
		<< "prefix path:" << QLibraryInfo::path(QLibraryInfo::PrefixPath);
	qInfo() << "cwd:" << QDir::currentPath();
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
