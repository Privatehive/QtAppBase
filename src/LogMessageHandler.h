#pragma once
#include "QtApplicationBaseExport.h"
#include <QDateTime>
#include <QDir>
#include <QLoggingCategory>

/*!
 *
 * \brief Writes qDebug, qInfo, ... log messages to file and std::out
 *
 */
class QTAPPBASE_EXPORT LogMessageHandler {

 public:
	static void prepare(const QString &dataPath);

	//! Sorted oldest to newest
	static QList<QDateTime> getLogHistory();
	static QString getLogTail(int lines, QDateTime logTime = {});

 private:
	static QString getLogfilePath(const QDateTime &logTime);
	//! A logger that writes to std::out and a file.A qFatal message will lead to
	//! application termination
	static void dbug_msg_handler(QtMsgType type, const QMessageLogContext &rContext, const QString &rMessage);
};
