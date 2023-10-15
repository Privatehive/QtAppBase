#include "SecretsManager.h"
#include "QtApplicationBase.h"
#include "qt6keychain/keychain.h"
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QEventLoop>
#include <QMessageAuthenticationCode>
#include <QSettings>
#include <QUuid>


void SecretsManager::writeSecretSync(const QString &alias, const QString &value) {

	QEventLoop eventLoop;
	auto job = new QKeychain::WritePasswordJob(SecretsManager::getNamespace(), &eventLoop);
	job->setKey(alias);
	job->setTextData(value);
	QObject::connect(job, &QKeychain::Job::finished, &eventLoop, [alias, &eventLoop](QKeychain::Job *job) {
		if(job->error()) {
			qWarning() << "Could not write secret:" << qPrintable(job->errorString());
		} else {
			qDebug() << "Wrote secret:" << alias;
		}
		eventLoop.exit(0);
	});
	job->setAutoDelete(true);
	job->start();
	eventLoop.exec();
}

QString SecretsManager::readSecretSync(const QString &alias) {

	QString secret;
	QEventLoop eventLoop;
	auto job = new QKeychain::ReadPasswordJob(SecretsManager::getNamespace(), &eventLoop);
	job->setKey(alias);
	QObject::connect(job, &QKeychain::Job::finished, &eventLoop, [alias, &eventLoop, &secret](QKeychain::Job *job) {
		if(job->error()) {
			qWarning() << "Could not write secret:" << qPrintable(job->errorString());
		} else {
			auto readJob = qobject_cast<QKeychain::ReadPasswordJob *>(job);
			secret = readJob->textData();
			qDebug() << "Wrote secret:" << alias;
		}
		eventLoop.exit(0);
	});
	job->setAutoDelete(true);
	job->start();
	eventLoop.exec();
	return secret;
}

QByteArray SecretsManager::getUniqueId() {

	QMessageAuthenticationCode code(QCryptographicHash::Sha1, QByteArray::number(SecretsManager::getAppId()));
	auto machineId = getMachine();
	if(machineId.isEmpty()) {
		qWarning() << "Missing a valid machineId - using a random one";
		machineId = getCreateSettingsIdEntry("machineId");
	}
	auto userId = getUser();
	if(userId.isEmpty()) {
		qWarning() << "Missing a valid userId - using a random one";
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
		qWarning() << "Missing a valid machineId - using a random one";
		machineId = getCreateSettingsIdEntry("machineId");
	}
	code.addData(machineId);
	return code.result();
}

QByteArray SecretsManager::getCreateSettingsIdEntry(const QString &settingsKey) {

	QSettings settings;
	settings.beginGroup("_informational_");
	if(!settings.value(settingsKey).isValid()) {
		settings.setValue(settingsKey, QUuid::createUuid().toByteArray(QUuid::WithoutBraces));
	}
	auto id = settings.value(settingsKey).toByteArray();
	settings.endGroup();
	settings.sync();
	return id;
}

QString SecretsManager::getNamespace() {

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
