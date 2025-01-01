#include "Secret.h"
#include "SecretsManager.h"


Secret::Secret(QObject *parent) : QObject(parent), mAlias(), mSecretValue(), mFallback(false) {}

QString Secret::getAlias() const {

	return mAlias;
}

void Secret::setAlias(const QString &alias) {

	mAlias = alias;
	SecretsManager::readSecret(
	 getAlias(),
	 [this](QString secret, bool fallback) {
		 mSecretValue = secret;
		 emit valueChanged();
		 emit secretRead(secret);
		 if(fallback != mFallback) {
			 mFallback = fallback;
			 emit fallbackChanged();
		 }
	 },
	 this);
	emit aliasChanged();
}

QString Secret::getValue() const {

	return mSecretValue;
}

void Secret::setValue(const QString &secret) {

	SecretsManager::writeSecret(
	 getAlias(), secret,
	 [this](bool fallback) {
		 emit secretWritten();
		 if(fallback != mFallback) {
			 mFallback = fallback;
			 emit fallbackChanged();
		 }
	 },
	 this);
	mSecretValue = secret;
	emit valueChanged();
}

bool Secret::isFallback() const {

	return mFallback;
}

void Secret::deleteSecret(const QString &alias) {

	SecretsManager::deleteSecret(alias, [this, alias]() { emit secretDeleted(alias); }, this);
}
