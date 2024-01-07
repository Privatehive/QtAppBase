#include "Secret.h"
#include "SecretsManager.h"


Secret::Secret(QObject *parent) : QObject(parent), mAlias(), mSecretValue() {}

QString Secret::getAlias() const {

	return mAlias;
}

void Secret::setAlias(const QString &alias) {

	mAlias = alias;
	SecretsManager::readSecret(
	 getAlias(),
	 [this](QString secret) {
		 mSecretValue = secret;
		 emit valueChanged();
		 emit secretRead(secret);
	 },
	 this);
	emit aliasChanged();
}

QString Secret::getValue() const {

	return mSecretValue;
}

void Secret::setValue(const QString &secret) {

	SecretsManager::writeSecret(getAlias(), secret, [this]() { emit secretWritten(); }, this);
	mSecretValue = secret;
	emit valueChanged();
}

void Secret::deleteSecret(const QString &alias) {

	SecretsManager::deleteSecret(alias, [this, alias]() { emit secretDeleted(alias); }, this);
}
