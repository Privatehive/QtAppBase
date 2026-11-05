#pragma once
#include "QtApplicationBaseExport.h"
#include <QObject>

class QTAPPBASE_EXPORT Result {

	Q_GADGET

 public:
	enum StatusCode {
		RESULT_OK = 0,
		RESULT_CANCELLED = 1,
		RESULT_UNKNOWN = 2,
		RESULT_INVALID_ARGUMENT = 3,
		RESULT_DEADLINE_EXCEEDED = 4,
		RESULT_NOT_FOUND = 5,
		RESULT_ALREADY_EXISTS = 6,
		RESULT_PERMISSION_DENIED = 7,
		RESULT_RESOURCE_EXHAUSTED = 8,
		RESULT_FAILED_PRECONDITION = 9,
		RESULT_ABORTED = 10,
		RESULT_OUT_OF_RANGE = 11,
		RESULT_UNIMPLEMENTED = 12,
		RESULT_INTERNAL = 13,
		RESULT_UNAVAILABLE = 14,
		RESULT_DATA_LOSS = 15,
		RESULT_UNAUTHENTICATED = 16,
		RESULT_QML_ERROR = 17,
	};
	Q_ENUM(StatusCode)

	Result();
	Result(const Result &rType, const QString &rDetails);
	~Result() = default;
	Q_INVOKABLE inline bool isSuccess() const { return !isFault(); }
	Q_INVOKABLE inline bool isFault() const { return mStatusCode != RESULT_OK; }
	inline bool operator==(const Result &rOther) const { return mStatusCode == rOther.mStatusCode; }
	inline bool operator!=(const Result &rOther) const { return mStatusCode != rOther.mStatusCode; }
	Q_INVOKABLE inline StatusCode getStatusCode() const { return mStatusCode; }
	inline void setStatusCode(StatusCode code) { mStatusCode = code; }
	Q_INVOKABLE inline QString getLabel() const { return mLabel; }
	Q_INVOKABLE inline QString getDetails() const { return mDetails; }
	QString toString() const;
	void setLabel(const QString &rLabel);
	void setDetails(const QString &rDetails);
	//! Safe bool
	explicit operator bool() const { return isSuccess(); }

	const static Result OK;
	const static Result CANCELLED;
	const static Result UNKNOWN;
	const static Result INVALID_ARGUMENT;
	const static Result DEADLINE_EXCEEDED;
	const static Result NOT_FOUND;
	const static Result ALREADY_EXISTS;
	const static Result PERMISSION_DENIED;
	const static Result RESOURCE_EXHAUSTED;
	const static Result FAILED_PRECONDITION;
	const static Result ABORTED;
	const static Result OUT_OF_RANGE;
	const static Result UNIMPLEMENTED;
	const static Result INTERNAL;
	const static Result UNAVAILABLE;
	const static Result DATA_LOSS;
	const static Result UNAUTHENTICATED;
	const static Result QML_ERROR;

 private:
	Result(StatusCode value, const QString &rLabel);

	StatusCode mStatusCode;
	QString mLabel;
	QString mDetails;
};
