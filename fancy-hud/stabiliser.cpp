#include "stabiliser.h"

Stabiliser::Stabiliser(){

}

void Stabiliser::main(cv::Mat input){
    cv::cvtColor(prev, prev_grey, cv::COLOR_BGR2GRAY);

    // Step 1 - Get previous to current frame transformation (dx, dy, da) for all frames
    std::vector <TransformParam> prev_to_cur_transform; // previous to current
    // Accumulated frame to frame transform
    double a = 0;
    double x = 0;
    double y = 0;
    // Step 2 - Accumulate the transformations to get the image trajectory
    std::vector <Trajectory> trajectory; // trajectory at all frames
    //
    // Step 3 - Smooth out the trajectory using an averaging window
    std::vector <Trajectory> smoothed_trajectory; // trajectory at all frames
    Trajectory X;//posteriori state estimate
    Trajectory	X_;//priori estimate
    Trajectory P;// posteriori estimate error covariance
    Trajectory P_;// priori estimate error covariance
    Trajectory K;//gain
    Trajectory	z;//actual measurement
    double pstd = 4e-3;//can be changed
    double cstd = 0.25;//can be changed
    Trajectory Q(pstd,pstd,pstd);// process noise covariance
    Trajectory R(cstd,cstd,cstd);// measurement noise covariance
    // Step 4 - Generate new set of previous to current transform, such that the trajectory ends up being the same as the smoothed trajectory
    std::vector <TransformParam> new_prev_to_cur_transform;
    //
    // Step 5 - Apply the new transformation to the video
    //cap.set(CV_CAP_PROP_POS_FRAMES, 0);
    cv::Mat T(2,3,CV_64F);

    int vert_border = HORIZONTAL_BORDER_CROP * prev.rows / prev.cols; // get the aspect ratio correct

    //
    int k=1;
    cv::Mat last_T;
    cv::Mat prev_grey_,cur_grey_;

    while(true) {

        if(cur.data == nullptr) {
            break;
        }

        cv::cvtColor(cur, cur_grey, cv::COLOR_BGR2GRAY);

        // vector from prev to cur
        std::vector <cv::Point2f> prev_corner, cur_corner;
        std::vector <cv::Point2f> prev_corner2, cur_corner2;
        std::vector <uchar> status;
        std::vector <float> err;

        cv::goodFeaturesToTrack(prev_grey, prev_corner, 200, 0.01, 30);
        cv::calcOpticalFlowPyrLK(prev_grey, cur_grey, prev_corner, cur_corner, status, err);

        // weed out bad matches
        for(size_t i=0; i < status.size(); i++) {
            if(status[i]) {
                prev_corner2.push_back(prev_corner[i]);
                cur_corner2.push_back(cur_corner[i]);
            }
        }

        // translation + rotation only
        cv::Mat T = cv::estimateRigidTransform(prev_corner2, cur_corner2, false); // false = rigid transform, no scaling/shearing

        // in rare cases no transform is found. We'll just use the last known good transform.
        if(T.data == nullptr) {
            last_T.copyTo(T);
        }

        T.copyTo(last_T);

        // decompose T
        double dx = T.at<double>(0,2);
        double dy = T.at<double>(1,2);
        double da = atan2(T.at<double>(1,0), T.at<double>(0,0));
        //
        //prev_to_cur_transform.push_back(TransformParam(dx, dy, da));

//        out_transform << k << " " << dx << " " << dy << " " << da << std::endl;
        //
        // Accumulated frame to frame transform
        x += dx;
        y += dy;
        a += da;
        //trajectory.push_back(Trajectory(x,y,a));
        //
//        out_trajectory << k << " " << x << " " << y << " " << a << endl;
        //
        z = Trajectory(x,y,a);
        //
        if(k==1){
            // intial guesses
            X = Trajectory(0,0,0); //Initial estimate,  set 0
            P =Trajectory(1,1,1); //set error variance,set 1
        }
        else
        {
            //time update（prediction）
            X_ = X; //X_(k) = X(k-1);
            P_ = P+Q; //P_(k) = P(k-1)+Q;
            // measurement update（correction）
            K = P_/( P_+R ); //gain;K(k) = P_(k)/( P_(k)+R );
            X = X_+K*(z-X_); //z-X_ is residual,X(k) = X_(k)+K(k)*(z(k)-X_(k));
            P = (Trajectory(1,1,1)-K)*P_; //P(k) = (1-K(k))*P_(k);
        }
        //smoothed_trajectory.push_back(X);
//        out_smoothed_trajectory << k << " " << X.x << " " << X.y << " " << X.a << endl;
        //-
        // target - current
        double diff_x = X.x - x;//
        double diff_y = X.y - y;
        double diff_a = X.a - a;

        dx = dx + diff_x;
        dy = dy + diff_y;
        da = da + diff_a;

        //new_prev_to_cur_transform.push_back(TransformParam(dx, dy, da));
        //
//        out_new_transform << k << " " << dx << " " << dy << " " << da << endl;
        //
        T.at<double>(0,0) = cos(da);
        T.at<double>(0,1) = -sin(da);
        T.at<double>(1,0) = sin(da);
        T.at<double>(1,1) = cos(da);

        T.at<double>(0,2) = dx;
        T.at<double>(1,2) = dy;

        cv::Mat cur2;

        warpAffine(prev, cur2, T, cur.size());

        cur2 = cur2(cv::Range(vert_border, cur2.rows-vert_border), cv::Range(HORIZONTAL_BORDER_CROP, cur2.cols-HORIZONTAL_BORDER_CROP));

        // Resize cur2 back to cur size, for better side by side comparison
        resize(cur2, cur2, cur.size());

        // Now draw the original and stablised side by side for coolness
        cv::Mat canvas = cv::Mat::zeros(cur.rows, cur.cols*2+10, cur.type());

        prev.copyTo(canvas(cv::Range::all(), cv::Range(0, cur2.cols)));
        cur2.copyTo(canvas(cv::Range::all(), cv::Range(cur2.cols+10, cur2.cols*2+10)));

        // If too big to fit on the screen, then scale it down by 2, hopefully it'll fit :)
        if(canvas.cols > 1920) {
            cv::resize(canvas, canvas, cv::Size(canvas.cols/2, canvas.rows/2));
        }
        //outputVideo<<canvas;
        imshow("before and after", canvas);

        cv::waitKey(10);
        //
        prev = cur.clone();//cur.copyTo(prev);
        cur_grey.copyTo(prev_grey);

//        std::cout<< "Frame: " << k << "/" << max_frames << " - good optical flow: " << prev_corner2.size() << endl;
        k++;

    }
}
