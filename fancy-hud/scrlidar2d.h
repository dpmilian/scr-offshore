#ifndef SCRLIDAR2D_H
#define SCRLIDAR2D_H

#include "rplidar/include/rplidar.h"
#include <QString>

namespace rpl = rp::standalone::rplidar;

namespace SCR{

class Lidar2d {
public:
    Lidar2d();

    int main(QString port = "");
private:
    bool checkRPLIDARHealth(rpl::RPlidarDriver *drv);
    void releaseDriver();
    int createDriver();

    rpl::RPlidarDriver *drv;
};
}


#endif // SCRLIDAR2D_H
