#include "QtApplicationBase.h"
#include <QCoreApplication>

int main(int argc, char** argv) {

  QtApplicationBase<QCoreApplication> app(argc, argv);
}
