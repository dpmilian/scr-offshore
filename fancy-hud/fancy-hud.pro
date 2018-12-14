QT += quick charts
QT += multimedia 3dinput 3dquick 3dquickextras
CONFIG += c++11

INCLUDEPATH += /usr/local/include/opencv2
LIBS += -L/usr/local/lib


LIBS += -lopencv_core \
-lopencv_imgproc \
-lopencv_imgcodecs \
-lopencv_videoio \
-lopencv_flann \
-lopencv_highgui \
-lopencv_features2d \
-lopencv_photo \
-lopencv_video \
-lopencv_calib3d \
-lopencv_objdetect \
-lopencv_videostab \
-lopencv_shape \
-lopencv_stitching \
-lopencv_superres \
-lopencv_dnn \
-lopencv_ml

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += main.cpp \
    scrcontours.cpp \
    scrlidar2d.cpp \
    rplidar/src/arch/linux/net_serial.cpp \
    rplidar/src/arch/linux/net_socket.cpp \
    rplidar/src/arch/linux/timer.cpp \
    rplidar/src/hal/thread.cpp \
    rplidar/src/rplidar_driver.cpp \
    stabiliser.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    scrcontours.h \
    scrlidar2d.h \
    rplidar/include/rplidar.h \
    rplidar/include/rplidar_cmd.h \
    rplidar/include/rplidar_driver.h \
    rplidar/include/rplidar_protocol.h \
    rplidar/include/rptypes.h \
    rplidar/src/arch/linux/arch_linux.h \
    rplidar/src/arch/linux/net_serial.h \
    rplidar/src/arch/linux/thread.hpp \
    rplidar/src/arch/linux/timer.h \
    rplidar/src/hal/abs_rxtx.h \
    rplidar/src/hal/assert.h \
    rplidar/src/hal/byteops.h \
    rplidar/src/hal/event.h \
    rplidar/src/hal/locker.h \
    rplidar/src/hal/socket.h \
    rplidar/src/hal/thread.h \
    rplidar/src/hal/types.h \
    rplidar/src/hal/util.h \
    rplidar/src/rplidar_driver_impl.h \
    rplidar/src/rplidar_driver_serial.h \
    rplidar/src/rplidar_driver_TCP.h \
    rplidar/src/sdkcommon.h \
    stabiliser.h

