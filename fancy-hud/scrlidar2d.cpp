#include "scrlidar2d.h"
#include <QtDebug>

namespace rpl = rp::standalone::rplidar;

#ifndef _countof
#define _countof(_Array) (int)(sizeof(_Array) / sizeof(_Array[0]))
#endif

//-----------------------------
SCR::Lidar2d::Lidar2d() {
    drv = nullptr;
}

//-----------------------------
bool SCR::Lidar2d::checkRPLIDARHealth(rpl::RPlidarDriver * drv){
    u_result     op_result;
    rplidar_response_device_health_t healthinfo;


    op_result = drv->getHealth(healthinfo);
    if (IS_OK(op_result)) { // the macro IS_OK is the preperred way to judge whether the operation is succeed.
        qWarning()<<"RPLidar health status :"<<healthinfo.status;
        if (healthinfo.status == RPLIDAR_STATUS_ERROR) {
            qCritical()<<"Error, rplidar internal error detected. Please reboot the device to retry.";
            // enable the following code if you want rplidar to be reboot by software
            // drv->reset();
            return false;
        } else {
            return true;
        }

    } else {
        qCritical()<<"Error, cannot retrieve the lidar health code:"<< op_result;
        return false;
    }
}

//-----------------------------
int SCR::Lidar2d::createDriver(){
    // create the driver instance
    this->drv = rpl::RPlidarDriver::CreateDriver(rpl::DRIVER_TYPE_SERIALPORT);

    if (!drv) {
        qCritical()<<"insufficient memory, exit!";
        return (-2);
    }
    else return (0);
}

//-----------------------------
void SCR::Lidar2d::releaseDriver(){

    if (drv != nullptr){
        rpl::RPlidarDriver::DisposeDriver(drv);
        drv = nullptr;
    }
}

//-----------------------------
int SCR::Lidar2d::main(QString port){

    const char * opt_com_path = nullptr;
    _u32         baudrateArray[2] = {115200, 256000};
    _u32         opt_com_baudrate = 0;
    u_result     op_result;

    qWarning()<<"Ultra simple LIDAR data grabber for RPLIDAR.\n"<<"Version: "<<RPLIDAR_SDK_VERSION;

    // read serial port from the command line...
    if (! port.isEmpty()) opt_com_path = port.toLatin1().constData(); // or set to a fixed value: e.g. "com3"
    else opt_com_path = "/dev/ttyUSB0";

    opt_com_baudrate = baudrateArray[1];

    int created = this->createDriver();
    if (created != 0) return created;

    // make connection...
    bool connectSuccess = false;
    rplidar_response_device_info_t devinfo;

    if (IS_OK(drv->connect(opt_com_path, opt_com_baudrate))) {
        op_result = drv->getDeviceInfo(devinfo);

        if (IS_OK(op_result)) {
            connectSuccess = true;
        }
        else {
            delete drv;
            drv = nullptr;
        }
    }

    if (!connectSuccess) {
        qCritical()<<"Error, cannot bind to the specified serial port"<<port<<".";
        this->releaseDriver();
        return (-9);
    }


    // print out the device serial number, firmware and hardware version number..

        QString serial = "";

        for (int pos = 0; pos < 16 ;++pos) {
            serial.append(QString::number(devinfo.serialnum[pos], 16));
        }
        qWarning()<<"RPLIDAR S/N:"<<serial;

        qWarning()<<
                "Firmware Ver:"<<(devinfo.firmware_version>>8)<<(devinfo.firmware_version & 0xFF)<<
                "Hardware Rev:"<<((int) devinfo.hardware_version);

        // check health...
        if (!checkRPLIDARHealth(drv)) {
            this->releaseDriver();
            return (-8);
        }

        drv->startMotor();
        // start scan...
        drv->startScan(0,1);

        // fetech result and print it out...
        for (int ix = 0; ix < 10; ++ix) {
            rplidar_response_measurement_node_t nodes[8192];
            size_t   count = _countof(nodes);
            op_result = drv->grabScanData(nodes, count);

            if (IS_OK(op_result)) {
                drv->ascendScanData(nodes, count);
                for (int pos = 0; pos < (int)count ; ++pos) {
                    QString syncbit = (nodes[pos].sync_quality & RPLIDAR_RESP_MEASUREMENT_SYNCBIT) ?"S ":"  ";

                    qWarning()<<syncbit<<
                              "theta:"<<(nodes[pos].angle_q6_checkbit >> RPLIDAR_RESP_MEASUREMENT_ANGLE_SHIFT)/64.0f<<
                              "Dist:"<<nodes[pos].distance_q2/4.0f<<
                              "Q:"<<(nodes[pos].sync_quality >> RPLIDAR_RESP_MEASUREMENT_QUALITY_SHIFT);
                }
            }
        }

        drv->stop();
        drv->stopMotor();

        // done!
        releaseDriver();
        qWarning()<<"ALL DONE!";
        return 0;



}
