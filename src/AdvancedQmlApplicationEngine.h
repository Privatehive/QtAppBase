#pragma once
#include "QtApplicationBaseExport.h"
#include <QDir>
#include <QFileSystemWatcher>
#include <QList>
#include <QQmlApplicationEngine>
#include <QString>
#include <QUrl>
#include <QUuid>

class QFileSystemWatcher;
class QTimer;
class QQuickView;


class QTAPPBASE_EXPORT AdvancedQmlApplicationEngine : public QQmlApplicationEngine {

	Q_OBJECT

 public:
	explicit AdvancedQmlApplicationEngine(QObject *parent = nullptr);
	void setHotReload(bool enable);
	void loadRootItem(const QString &rootItem, bool useQuickView = true);
	bool hasRootItem() const;

 public slots:
	void reload();

 private slots:
	void handleReload();

 signals:
	void reloadFinished();

 private:
	Q_DISABLE_COPY(AdvancedQmlApplicationEngine)

	void loadRootItem(const QUrl &rootItem, bool useQuickView);
	void init();
	void connectWatcher();
	void disconnectWatcher();
	QList<QString> findQmlFilesRecursive(const QDir &dir) const;
	QObject *getRootObject() const;

	QUrl mRootUrl;
	bool mHotReloading;
	QFileSystemWatcher *mpWatcher;
	QTimer *mpTimer;
	QQuickView *mpView;
};
