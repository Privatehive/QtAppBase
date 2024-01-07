#pragma once
#include "QtApplicationBaseExport.h"
#include "info.h"
#include <QByteArray>
#include <QString>

class QTAPPBASE_EXPORT SecretsManager {

 public:
	// Write a secret asynchronous
	static void writeSecret(const QString &alias, const QString &value, std::function<void()> callback, QObject *watcher = nullptr);
	// Read a secret asynchronous
	static void readSecret(const QString &alias, std::function<void(QString)> callback, QObject *watcher = nullptr);
	// Delete a secret asynchronous
	static void deleteSecret(const QString &alias, std::function<void()> callback, QObject *watcher = nullptr);
	// Write a secret synchronous (blocking as long as secret is written)
	static void writeSecretSync(const QString &alias, const QString &value);
	// Read a secret synchronous (blocking as long as secret is read)
	static QString readSecretSync(const QString &alias);
	// Delete a secret (blocking as long as secret is deleted)
	static void deleteSecretSync(const QString &alias);
	// returns a constant, unique and anonymized 16 Byte long Id within the scope:
	// * the system (as long as the OS is not reinstalled, factory reset)
	// * current user (uid which is running this app)
	// * app config file (as long as the config file is not deleted)
	static QByteArray getUniqueId();
	// returns a constant, unique and anonymized 16 Byte long Id within the scope:
	// * the system (as long as the OS is not reinstalled, factory reset)
	static QByteArray getMachineId();
	// returns a constant, unique quint64 identifying this app
	static quint64 getAppId() {
#if defined(INFO_PROJECTID)
		return INFO_PROJECTID;
#else
		return qHash(QCoreApplication::applicationName());
#endif
	}

 private:
	static void fallbackWriteSecret(const QString &alias, const QString &value);
	static QString fallbackReadSecret(const QString &alias);
	static void fallbackDeleteSecret(const QString &alias);
	static QByteArray otp(QByteArray key, QByteArray secret);
	static QByteArray getCreateSettingsIdEntry(const QString &settingsKey);
	static QString getNamespace();
	// Implemented in OS specific file
	static QByteArray getMachine();
	// Implemented in OS specific file
	static QByteArray getUser();
};
