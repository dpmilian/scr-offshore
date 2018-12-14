#include <QDebug>
#include <QTextStream>
#include <QtConcurrent/QtConcurrentRun>
#include "scrlidar2d.h"

namespace rpl = rp::standalone::rplidar;

#ifndef _countof
#define _countof(_Array) (int)(sizeof(_Array) / sizeof(_Array[0]))
#endif

//-----------------------------
SCR::Lidar2d::Lidar2d() {
    drv = nullptr;
    endscanflag = false;
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
void SCR::Lidar2d::shutdown(){

    qWarning()<<"Told to shut down...";
    this->scandata.lock();
    this->endscanflag = true;
    this->scandata.unlock();

//    if (drv != nullptr){
//        drv->stop();
//        drv->stopMotor();
//        this->releaseDriver();
//    }
}

//-----------------------------
void SCR::Lidar2d::finishShutdown(){

    qWarning()<<"And finish shutting down";
    if (drv != nullptr){
        drv->stop();
        drv->stopMotor();
        this->releaseDriver();
    }
}

//-----------------------------
int SCR::Lidar2d::setupAndConnect(QString port){

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

    qWarning()<<"Started Lidar driver, motor spinning";
    return 0;
}

//-----------------------------
void SCR::Lidar2d::scan(){
    // fetch result and print it out...
    u_result     op_result;

    if (drv == nullptr){
        qWarning()<<"NULLPTR Concurrent run decided it's time to end scan...";
        return;
    }
    drv->startScan(false, true);

    bool endscan = false;
    int ixscan = 0;
    while (true) {
        ixscan++;
//        qWarning()<<"Lidar2d scanning..."<<ixscan;
        rplidar_response_measurement_node_hq_t nodes[8192];
        size_t   count = _countof(nodes);

        if (drv == nullptr){
            qWarning()<<"NULLPTR Concurrent run decided it's time to end scan...";
            this->finishShutdown();
            return;
        }

//        op_result = drv->grabScanData(nodes, count);
        op_result = drv->grabScanDataHq(nodes, count);
//        float freq;
//        drv->getFrequency(false, count, &freq);
//        qWarning()<<"Lidar2d full scan complete"<<ixscan;

        if (IS_OK(op_result) || op_result == RESULT_OPERATION_TIMEOUT) {
            drv->ascendScanData(nodes, count);
            QList<qreal> cdists, cangles, cqs;

            for (int pos = 0; pos < (int)count ; ++pos) {

                rplidar_response_measurement_node_hq_t node = nodes[pos];
                float distance_meters = node.dist_mm_q2 / 1000.0f / (1<<2);
                if (distance_meters == 0) continue;
                float angle_degrees = node.angle_z_q14 * 90.f / (1<<14);

//                qWarning()<<distance_meters;
                float quality = node.quality / 255.0f;
                cdists.append(distance_meters);
                cangles.append(angle_degrees);
                cqs.append(quality);
            }
//            qWarning()<<"Parsed all scan data"<<ixscan;

            this->scandata.lock();

            this->scandata.dists<<cdists;
            this->scandata.angles<<cangles;
            this->scandata.qs<<cqs;
            endscan = this->endscanflag;

            this->scandata.unlock();

            if (endscan){
//                qWarning()<<"Concurrent run decided it's time to end scan...";
                this->finishShutdown();
                return;
            }
            emit hasData();
        } else {
            qWarning()<<"scan op_result is not ok!";
        }
    }
}


//-----------------------------
int SCR::Lidar2d::runLidar(){
    // start concurrent scan thread...
    connect (this, &SCR::Lidar2d::concurrentFinished, this, &SCR::Lidar2d::finishShutdown);
    QtConcurrent::run(this, &SCR::Lidar2d::scan);

    return 0;
}


//-----------------------------
QList<qreal> SCR::Lidar2d::getData(char what){

    this->scandata.lock();

    QList<qreal> retval;
    switch(what){
    case 0:{
        retval = this->scandata.dists;
        this->scandata.dists.clear();
        break;
    }
    case 1:{
        retval = this->scandata.angles;
        this->scandata.angles.clear();
        break;
    }
    case 2:{
        retval = this->scandata.qs;
        this->scandata.qs.clear();
        break;
    }
    }

    this->scandata.unlock();

    return retval;
}

