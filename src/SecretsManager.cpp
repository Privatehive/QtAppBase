#include "SecretsManager.h"
#include "QtApplicationBase.h"
#include "qt6keychain/keychain.h"
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QEventLoop>
#include <QMessageAuthenticationCode>
#include <QSettings>
#include <QUuid>
#include <memory>


Q_LOGGING_CATEGORY(secretsmanager, "secretsmanager")

#define SECRETS_SETTINGS_GROUP "_secrets_"
#define SECRETSMANAGER_SETTINGS_GROUP "_secretsmanager_"


void SecretsManager::setFallbackSettings(std::unique_ptr<QSettings> settings) {

	fallbackSettings = std::move(settings);
}

void SecretsManager::setNamespace(const QString &ns) {

	overwriteNamespace = ns;
}

void SecretsManager::writeSecret(const QString &alias, const QString &value, std::function<void()> callback,
                                 QObject *watcher /*= nullptr*/) {

	if(!alias.isEmpty()) {
		auto job = new QKeychain::WritePasswordJob(SecretsManager::getNamespace(), watcher ? watcher : qApp);
		job->setKey(alias);
		job->setTextData(value);
		job->setInsecureFallback(false);
		job->setAutoDelete(true);
		QObject::connect(job, &QKeychain::Job::finished, watcher ? watcher : qApp, [alias, value, callback](QKeychain::Job *job) {
			if(job->error()) {
				qWarning(secretsmanager) << "Could not write secret to OS secrets manager:" << qPrintable(job->errorString());
				qInfo(secretsmanager) << "Fallback to settings file secret obfuscation";
				SecretsManager::fallbackWriteSecret(alias, value);
			}
			qDebug(secretsmanager) << "Wrote secret:" << alias;
			callback();
		});
		job->start();
	} else {
		callback();
	}
}

void SecretsManager::readSecret(const QString &alias, std::function<void(QString)> callback, QObject *watcher /*= nullptr*/) {

	if(!alias.isEmpty()) {
		auto job = new QKeychain::ReadPasswordJob(SecretsManager::getNamespace(), watcher ? watcher : qApp);
		job->setKey(alias);
		job->setInsecureFallback(false);
		job->setAutoDelete(true);
		QObject::connect(job, &QKeychain::Job::finished, watcher ? watcher : qApp, [alias, callback](QKeychain::Job *job) {
			if(job->error()) {
				qWarning(secretsmanager) << "Could not read secret:" << qPrintable(job->errorString());
				qInfo(secretsmanager) << "Fallback to settings file secret";
				callback(SecretsManager::fallbackReadSecret(alias));
			} else {
				auto readJob = qobject_cast<QKeychain::ReadPasswordJob *>(job);
				callback(readJob->textData());
			}
			qDebug(secretsmanager) << "Read secret:" << alias;
		});
		job->start();
	} else {
		callback({});
	}
}

void SecretsManager::deleteSecret(const QString &alias, std::function<void()> callback, QObject *watcher /*= nullptr*/) {

	if(!alias.isEmpty()) {
		auto job = new QKeychain::DeletePasswordJob(SecretsManager::getNamespace(), watcher ? watcher : qApp);
		job->setKey(alias);
		job->setInsecureFallback(false);
		job->setAutoDelete(true);
		QObject::connect(job, &QKeychain::Job::finished, watcher ? watcher : qApp, [alias, callback](QKeychain::Job *job) {
			// job->error() not reported
			Q_UNUSED(job)
			SecretsManager::fallbackDeleteSecret(alias);
			qDebug(secretsmanager) << "Deleted secret:" << alias;
			callback();
		});
		job->start();
	} else {
		callback();
	}
}

void SecretsManager::writeSecretSync(const QString &alias, const QString &value) {

	if(!alias.isEmpty()) {
		QEventLoop eventLoop;
		auto job = new QKeychain::WritePasswordJob(SecretsManager::getNamespace(), &eventLoop);
		job->setKey(alias);
		job->setTextData(value);
		job->setInsecureFallback(false);
		job->setAutoDelete(true);
		QObject::connect(
		 job, &QKeychain::Job::finished, &eventLoop,
		 [alias, value, &eventLoop](QKeychain::Job *job) {
			 if(job->error()) {
				 qWarning(secretsmanager) << "Could not write secret to OS secrets manager:" << qPrintable(job->errorString());
				 qInfo(secretsmanager) << "Fallback to settings file secret obfuscation";
				 SecretsManager::fallbackWriteSecret(alias, value);
			 }
			 qDebug(secretsmanager) << "Wrote secret:" << alias;
			 eventLoop.exit(0);
		 },
		 Qt::QueuedConnection);
		job->start();
		eventLoop.exec();
	}
}

QString SecretsManager::readSecretSync(const QString &alias) {

	if(!alias.isEmpty()) {
		QString secret;
		QEventLoop eventLoop;
		auto job = new QKeychain::ReadPasswordJob(SecretsManager::getNamespace(), &eventLoop);
		job->setKey(alias);
		job->setInsecureFallback(false);
		job->setAutoDelete(true);
		QObject::connect(
		 job, &QKeychain::Job::finished, &eventLoop,
		 [alias, &secret, &eventLoop](QKeychain::Job *job) {
			 if(job->error()) {
				 qWarning(secretsmanager) << "Could not read secret:" << qPrintable(job->errorString());
				 qInfo(secretsmanager) << "Fallback to settings file secret";
				 secret = SecretsManager::fallbackReadSecret(alias);
			 } else {
				 auto readJob = qobject_cast<QKeychain::ReadPasswordJob *>(job);
				 secret = readJob->textData();
			 }
			 qDebug(secretsmanager) << "Read secret:" << alias;
			 eventLoop.exit(0);
		 },
		 Qt::QueuedConnection);
		job->start();
		eventLoop.exec();
		return secret;
	} else {
		return {};
	}
}

void SecretsManager::deleteSecretSync(const QString &alias) {

	if(!alias.isEmpty()) {
		QString secret;
		QEventLoop eventLoop;
		auto job = new QKeychain::DeletePasswordJob(SecretsManager::getNamespace(), &eventLoop);
		job->setKey(alias);
		job->setInsecureFallback(false);
		job->setAutoDelete(true);
		QObject::connect(
		 job, &QKeychain::Job::finished, &eventLoop,
		 [alias, &secret, &eventLoop](QKeychain::Job *job) {
			 // job->error not reported
			 SecretsManager::fallbackDeleteSecret(alias);
			 qDebug(secretsmanager) << "Deleted secret:" << alias;
			 eventLoop.exit(0);
		 },
		 Qt::QueuedConnection);
		job->start();
		eventLoop.exec();
	}
}

QByteArray SecretsManager::getUniqueId() {

	QMessageAuthenticationCode code(QCryptographicHash::Sha1, QByteArray::number(SecretsManager::getAppId()));
	auto machineId = getMachine();
	if(machineId.isEmpty()) {
		qWarning(secretsmanager) << "Missing a valid machineId - using a random one";
		machineId = getCreateSettingsIdEntry("machineId");
	}
	auto userId = getUser();
	if(userId.isEmpty()) {
		qWarning(secretsmanager) << "Missing a valid userId - using a random one";
		machineId = getCreateSettingsIdEntry("userId");
	}
	auto salt = getCreateSettingsIdEntry("salt");
	code.addData(machineId);
	code.addData(userId);
	code.addData(salt);
	return code.result();
}

QByteArray SecretsManager::getMachineId() {

	QMessageAuthenticationCode code(QCryptographicHash::Sha1, QByteArray::number(SecretsManager::getAppId()));
	auto machineId = getMachine();
	if(machineId.isEmpty()) {
		qWarning(secretsmanager) << "Missing a valid machineId - using a random one";
		machineId = getCreateSettingsIdEntry("machineId");
	}
	code.addData(machineId);
	return code.result();
}

std::unique_ptr<QSettings> SecretsManager::fallbackSettings = std::unique_ptr<QSettings>(nullptr);

QString SecretsManager::overwriteNamespace = {};

QSettings *SecretsManager::getFallbackSettings() {

	if(!fallbackSettings) {
		fallbackSettings = std::make_unique<QSettings>();
	}
	return fallbackSettings.get();
}

void SecretsManager::fallbackWriteSecret(const QString &alias, const QString &value) {

	const auto hashVal = qHash(value);
	const auto hash = QByteArray(sizeof(size_t), 0);
	memcpy((void *)hash.data(), &hashVal, sizeof(size_t));
	auto valueWithHash = value + QString::fromLatin1(hash);
	const auto settings = getFallbackSettings();
	settings->sync();
	settings->beginGroup(SECRETS_SETTINGS_GROUP);
	settings->setValue(alias, QString::fromLatin1(SecretsManager::otp(SecretsManager::getUniqueId(), valueWithHash.toUtf8()).toBase64()));
	settings->endGroup();
	settings->sync();
}

QString SecretsManager::fallbackReadSecret(const QString &alias) {

	const auto settings = getFallbackSettings();
	settings->sync();
	settings->beginGroup(SECRETS_SETTINGS_GROUP);
	auto secret = QString::fromUtf8(
	 SecretsManager::otp(SecretsManager::getUniqueId(), QByteArray::fromBase64(settings->value(alias).toString().toLatin1())));
	settings->endGroup();
	auto extractedSecret = QString();
	auto extractedSecretSize = secret.length() - sizeof(size_t);
	if(extractedSecretSize < secret.length() && extractedSecretSize >= 0) {
		extractedSecret = secret.first(extractedSecretSize);
		const auto extractedHash = secret.last(secret.length() - extractedSecret.length());
		const auto hashVal = qHash(extractedSecret);
		const auto hash = QByteArray(sizeof(size_t), 0);
		memcpy((void *)hash.data(), &hashVal, sizeof(size_t));
		if(QString::fromLatin1(hash).compare(extractedHash) == 0) {
			return extractedSecret;
		} else {
			qCritical(secretsmanager) << "The hash of the secret does not match - returning empty secret";
			return {};
		}
	} else {
		qCritical(secretsmanager) << "The secret is missing a hash - returning empty secret";
		return {};
	}
}

void SecretsManager::fallbackDeleteSecret(const QString &alias) {

	const auto settings = getFallbackSettings();
	settings->sync();
	settings->beginGroup(SECRETS_SETTINGS_GROUP);
	settings->remove(alias);
	settings->endGroup();
	settings->sync();
}

QByteArray SecretsManager::otp(QByteArray key, QByteArray secret) {

	QByteArray cyper(secret);
	if(key.length() > 0) {
		for(int i = 0; i < cyper.length(); ++i) {
			cyper[i] = (char)(cyper[i] ^ key[i % key.length()]);
		}
	} else {
		qCritical(secretsmanager) << "OTP key equals zero - encryption was skipped";
	}
	return cyper;
}

QByteArray SecretsManager::getCreateSettingsIdEntry(const QString &settingsKey) {

	const auto settings = getFallbackSettings();
	settings->sync();
	settings->beginGroup(SECRETSMANAGER_SETTINGS_GROUP);
	if(!settings->value(settingsKey).isValid()) {
		settings->setValue(settingsKey, QString::fromLatin1(QUuid::createUuid().toRfc4122().toBase64()));
	}
	auto id = QByteArray::fromBase64(settings->value(settingsKey).toString().toLatin1());
	settings->endGroup();
	settings->sync();
	return id;
}

QString SecretsManager::getNamespace() {

	if(!overwriteNamespace.isEmpty()) {
		return overwriteNamespace;
	} else {
		auto org = QCoreApplication::organizationDomain();
		if(org.isEmpty()) {
			org = "unknown";
		}
		auto app = QCoreApplication::applicationName();
		if(app.isEmpty()) {
			app = "unknown";
		}
		return QString("%1.%2").arg(org, app);
	}
}
