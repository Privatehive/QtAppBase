#pragma once
#include <QObject>
#include <QtQmlIntegration>


class Secret : public QObject {

	Q_OBJECT
	QML_ELEMENT
	Q_PROPERTY(QString name READ getName WRITE setName NOTIFY nameChanged)
	Q_PROPERTY(QString secret READ getSecret WRITE setSecret NOTIFY secretChanged)

 public:
	explicit Secret(QObject *parent = nullptr);
	QString getName() const;
	void setName(const QString &name);
	QString getSecret() const;
	void setSecret(const QString &secret);

 signals:
	void nameChanged();
	void secretChanged();

 private:
	QString mName;
};
