#ifndef SCRCONTOURS_H
#define SCRCONTOURS_H

#include <QAbstractVideoFilter>
//#include "opencv2/opencv.hpp"

namespace SCR{

class ContourFinder: public QAbstractVideoFilter{
    Q_OBJECT

public:
    QVideoFilterRunnable *createFilterRunnable();

signals:
    void objectDetected(float x, float y, float w, float h);

public slots:

};

class ContourFinderRunnable: public QVideoFilterRunnable{

public:
    ContourFinderRunnable(ContourFinder *creator){filter = creator;}
    QVideoFrame run(QVideoFrame *input, const QVideoSurfaceFormat &surfaceFormat, RunFlags flags);

private:
//    void dft(cv::InputArray input, cv::OutputArray output);
    ContourFinder *filter;
};

}

#endif // SCRCONTOURS_H
