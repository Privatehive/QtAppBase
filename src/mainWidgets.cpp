#include "QtApplicationBase.h"
#include "info.h"
#include <QApplication>
#include <QGridLayout>
#include <QLabel>
#include <QWidget>

int main(int argc, char **argv) {

	QtApplicationBase<QApplication> app(argc, argv);
	app.set(INFO_PROJECTNAME, QString("%1.%2.%3").arg(INFO_VERSION_MAJOR).arg(INFO_VERSION_MINOR).arg(INFO_VERSION_PATCH), INFO_DOMAIN);
	QWidget window;
	window.show();
	return app.start();
}
