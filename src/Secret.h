#pragma once
#include "QtApplicationBaseExport.h"
#include <QObject>
#include <QtQmlIntegration>


class QTAPPBASE_EXPORT Secret : public QObject {

	Q_OBJECT
	QML_ELEMENT
	Q_PROPERTY(QString alias READ getAlias WRITE setAlias NOTIFY aliasChanged)
	Q_PROPERTY(QString value READ getValue WRITE setValue NOTIFY valueChanged)

 public:
	explicit Secret(QObject *parent = nullptr);
	QString getAlias() const;
	void setAlias(const QString &alias);
	QString getValue() const;
	void setValue(const QString &secret);
	Q_INVOKABLE void deleteSecret(const QString &alias);

 signals:
	void aliasChanged();
	void valueChanged();
	void secretWritten();
	void secretRead(const QString &secret);
	void secretDeleted(const QString &alias);

 private:
	Q_DISABLE_COPY(Secret);
	QString mAlias;
	QString mSecretValue;
};
