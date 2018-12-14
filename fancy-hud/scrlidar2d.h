#ifndef SCRLIDAR2D_H
#define SCRLIDAR2D_H

#include "rplidar/include/rplidar.h"
#include <QObject>
#include "stabiliser.h"
//#include <QString>
#include <QList>
#include <QMutex>

namespace rpl = rp::standalone::rplidar;

namespace SCR{

class Lidar2d : public QObject {
    Q_OBJECT

public:
    Lidar2d();
    Q_INVOKABLE int setupAndConnect(QString port = "");

signals:
    void hasData();
    void concurrentFinished();

public slots:
    int runLidar();
    QList<qreal> getData(char what);
    void shutdown();
    void finishShutdown();

private:
    bool checkRPLIDARHealth(rpl::RPlidarDriver *drv);
    void releaseDriver();
    int createDriver();

    rpl::RPlidarDriver *drv;
    void scan();
    struct {
        QMutex _lock;
        QList<qreal> dists, angles, qs;
        void lock(){ _lock.lock();}
        void unlock(){_lock.unlock();}
    } scandata;

    bool endscanflag;
};
}


#endif // SCRLIDAR2D_H
