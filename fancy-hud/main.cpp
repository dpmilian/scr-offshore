#include <QApplication>
#include <QQuickView>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "scrlidar2d.h"
#include "scrcontours.h"

int main(int argc, char *argv[]){

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_UseDesktopOpenGL);

    qmlRegisterType<SCR::ContourFinder>("SCR", 1, 0,"ContourFinder");
    qRegisterMetaType<QList<double>>("QList<double>");

    qmlRegisterType<SCR::Lidar2d>("SCR", 1, 0, "Lidar2d");
//    SCR::Lidar2d lidar;
//    lidar.main();

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/SCRHud.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return  app.exec();

}
