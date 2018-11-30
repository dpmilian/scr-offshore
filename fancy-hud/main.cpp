#include <QApplication>
#include <QQuickView>
#include <QQmlApplicationEngine>

//#include "qcvdetectfilter.h"
#include "scrcontours.h"

int main(int argc, char *argv[]){

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_UseDesktopOpenGL);

//    qmlRegisterType<QCvDetectFilter>("com.amin.classes", 1, 0, "CvDetectFilter");
    qmlRegisterType<SCR::ContourFinder>("com.SCR.classes", 1, 0,"ContourFinder");
    qRegisterMetaType<QList<QRect>>("QList<QRect>");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
