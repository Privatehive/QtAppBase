#pragma once
#include "QtApplicationBaseExport.h"
#include "info.h"
#include <QByteArray>
#include <QString>

class QTAPPBASE_EXPORT SecretsManager {

 public:
	// Write a secret synchronous (blocking as long as secret is written)
	virtual void writeSecretSync(const QString &alias, const QString &value);
	// Read a secret synchronous (blocking as long as secret is read)
	virtual QString readSecretSync(const QString &alias);
	// returns a constant, unique and anonymized 16 Byte long Id within the scope:
	// * the system (as long as the OS is not reinstalled, factory reset)
	// * current user (uid which is running this app)
	// * app config file
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
	static QByteArray getCreateSettingsIdEntry(const QString &settingsKey);
	static QString getNamespace();
	// Implemented in OS specific file
	static QByteArray getMachine();
	// Implemented in OS specific file
	static QByteArray getUser();
};
