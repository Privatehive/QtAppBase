#pragma once
#include "QtApplicationBaseQmlExport.h"
#include <QObject>
#include <QtQmlIntegration>


class QTAPPBASEQML_EXPORT Secret : public QObject {

	Q_OBJECT
	QML_NAMED_ELEMENT(Secret)
	Q_PROPERTY(QString alias READ getAlias WRITE setAlias NOTIFY aliasChanged)
	Q_PROPERTY(QString value READ getValue WRITE setValue NOTIFY valueChanged)
	// Indicates if the secret was read/written from the obfuscated settings file
	Q_PROPERTY(bool fallback READ isFallback NOTIFY fallbackChanged)

 public:
	explicit Secret(QObject *parent = nullptr);
	QString getAlias() const;
	void setAlias(const QString &alias);
	QString getValue() const;
	void setValue(const QString &secret);
	bool isFallback() const;
	Q_INVOKABLE void deleteSecret(const QString &alias);

 signals:
	void aliasChanged();
	void valueChanged();
	void secretWritten();
	void fallbackChanged();
	void secretRead(const QString &secret);
	void secretDeleted(const QString &alias);

 private:
	Q_DISABLE_COPY(Secret);

	QString mAlias;
	QString mSecretValue;
	bool mFallback;
};
