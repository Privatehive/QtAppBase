#include "SecretsManager.h"
#include <QFile>
extern "C" {
#include <unistd.h>
}


QByteArray SecretsManager::getMachine() {

	QByteArray ret;
	QFile file("/etc/machine-id");
	if(file.open(QIODevice::ReadOnly | QIODevice::Text)) {
		ret = file.readAll().trimmed();
		file.close();
	}
	return ret;
}

QByteArray SecretsManager::getUser() {

	if(auto uid = getuid()) {
		return QByteArray::number(uid);
	}
	return {};
}
