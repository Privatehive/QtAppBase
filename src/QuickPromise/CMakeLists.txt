find_package(Qt6 REQUIRED COMPONENTS Core Qml)

qt_add_qml_module(
        QuickPromise

        VERSION 1.0

        NO_PLUGIN

        URI
        QuickPromise

        QML_FILES
        Promise.js
        Promise.qml
        PromiseTimer.qml
)

install_qml_module(QuickPromise)
