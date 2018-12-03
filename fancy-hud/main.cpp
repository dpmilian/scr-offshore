#include <QApplication>
#include <QQuickView>
#include <QQmlApplicationEngine>
#include "scrlidar2d.h"

//#include "qcvdetectfilter.h"
#include "scrcontours.h"

int main(int argc, char *argv[]){

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_UseDesktopOpenGL);

    qmlRegisterType<SCR::ContourFinder>("com.SCR.classes", 1, 0,"ContourFinder");
    qRegisterMetaType<QList<QRect>>("QList<QRect>");

    SCR::Lidar2d lidar;
    lidar.main();
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return  app.exec();

}
