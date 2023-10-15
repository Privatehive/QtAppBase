#include "Secret.h"
#include "SecretsManager.h"


Secret::Secret(QObject *parent) : QObject(parent), mName() {}

QString Secret::getName() const {

	return mName;
}

void Secret::setName(const QString &name) {

	mName = name;
	emit nameChanged();
	emit secretChanged();
}

QString Secret::getSecret() const {

	SecretsManager m;
	auto secret = m.readSecretSync(getName());
	return secret;
}

void Secret::setSecret(const QString &secret) {

	SecretsManager m;
	m.writeSecretSync(getName(), secret);
	emit secretChanged();
}
