#include <QDebug>
#include "scrcontours.h"


// *********************************
QVideoFilterRunnable* SCR::ContourFinder::createFilterRunnable(){
//    qWarning()<<"WTFFFFFF";
    return new ContourFinderRunnable(this);
}

// *********************************
QVideoFrame SCR::ContourFinderRunnable::run(QVideoFrame *input, const QVideoSurfaceFormat &surfaceFormat, RunFlags flags){
    Q_UNUSED(flags);

    input->map(QAbstractVideoBuffer::ReadOnly);
    if (surfaceFormat.handleType() == QAbstractVideoBuffer::NoHandle){
        QImage image(input->bits(), input->width(), input->height(),
                     QVideoFrame::imageFormatFromPixelFormat(input->pixelFormat()));
        image = image.convertToFormat(QImage::Format_RGB888);
//        cv::Mat mat(image.height(), image.width(), CV_8UC3, image.bits(), image.bytesPerLine());
//        cv::flip(mat, mat, 0);
    }

//    emit filter->objectDetected(100, 200, 200, 200);

    return *input;
}

