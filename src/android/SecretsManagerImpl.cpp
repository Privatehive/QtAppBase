#include "SecretsManager.h"
#include <QFile>
#include <QJniObject>


QByteArray SecretsManager::getMachine() {

	auto machineId = QJniObject::getStaticObjectField<jstring>("android/provider/Settings$Secure", "ANDROID_ID");
	return machineId.toString().toLatin1();
}

QByteArray SecretsManager::getUser() {

	jint id = QJniObject::callStaticMethod<jint>("android/os/Process", "myUid");
	return QByteArray::number(id);
}
