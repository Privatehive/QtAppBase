#include "Result.h"
#include <QFuture>
#include <QObject>
#include <QTextDocumentFragment>

Result::Result() : mStatusCode(Result::OK.mStatusCode), mLabel(Result::OK.mLabel), mDetails() {}

Result::Result(const Result &rType, const QString &rDetails) : mStatusCode(rType.mStatusCode), mLabel(rType.mLabel), mDetails(rDetails) {}

Result::Result(StatusCode value, const QString &rLabel) : mStatusCode(value), mLabel(rLabel), mDetails() {}

QString Result::toString() const {

	auto ret = QString(mLabel);
	if(!mDetails.isNull()) {
		ret.append(QString(" %1").arg(mDetails));
	}
	return ret;
}

void Result::setLabel(const QString &rLabel) {

	mLabel = rLabel;
}

void Result::setDetails(const QString &rDetails) {

	mDetails = rDetails;
}

QDebug operator<<(QDebug debug, const Result &rRestult) {
	QDebugStateSaver saver(debug);
	debug.nospace() << rRestult.getLabel() << ": " << rRestult.getDetails();
	return debug;
}

const Result Result::OK(RESULT_OK, "");
const Result Result::CANCELLED(RESULT_CANCELLED, QObject::tr("The operation was cancelled"));
const Result Result::UNKNOWN(RESULT_UNKNOWN, QObject::tr("Unknown error"));
const Result Result::INVALID_ARGUMENT(RESULT_INVALID_ARGUMENT, QObject::tr("The client specified an invalid argument"));
const Result Result::DEADLINE_EXCEEDED(RESULT_DEADLINE_EXCEEDED, QObject::tr("The deadline expired before the operation could complete"));
const Result Result::NOT_FOUND(RESULT_NOT_FOUND, QObject::tr("Some requested entity was not found"));
const Result Result::ALREADY_EXISTS(RESULT_ALREADY_EXISTS, QObject::tr("The entity that a client attempted to create already exists"));
const Result Result::PERMISSION_DENIED(RESULT_PERMISSION_DENIED,
                                       QObject::tr("The caller does not have permission to execute the specified operation"));
const Result Result::RESOURCE_EXHAUSTED(RESULT_RESOURCE_EXHAUSTED, QObject::tr("Some resource has been exhausted"));
const Result Result::FAILED_PRECONDITION(
 RESULT_FAILED_PRECONDITION,
 QObject::tr("The operation was rejected because the system is not in a state required for the operation’s execution"));
const Result Result::ABORTED(
 RESULT_ABORTED,
 QObject::tr("The operation was aborted, typically due to a concurrency issue such as a sequencer check failure or transaction abort"));
const Result Result::OUT_OF_RANGE(RESULT_OUT_OF_RANGE, QObject::tr("The operation was attempted past the valid range"));
const Result Result::UNIMPLEMENTED(RESULT_UNIMPLEMENTED,
                                   QObject::tr("The operation is not implemented or is not supported/enabled in this service"));
const Result Result::INTERNAL(RESULT_INTERNAL, QObject::tr("Internal errors"));
const Result Result::UNAVAILABLE(RESULT_UNAVAILABLE, QObject::tr("The service is currently unavailable"));
const Result Result::DATA_LOSS(RESULT_DATA_LOSS, QObject::tr("Unrecoverable data loss or corruption"));
const Result Result::UNAUTHENTICATED(RESULT_UNAUTHENTICATED,
                                     QObject::tr("The request does not have valid authentication credentials for the operation"));
const Result Result::QML_ERROR(RESULT_QML_ERROR, QObject::tr("The QML component contains error(s)"));


Q_DECLARE_METATYPE(Result)
Q_DECLARE_METATYPE(QFuture<Result>)
