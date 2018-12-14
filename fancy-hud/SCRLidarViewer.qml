import SCR 1.0
import QtQuick 2.3
import QtQuick.Controls 1.4
import QtGraphicalEffects 1.0

Item {
    id: lidarview
    property real default_range: 3  // default to 3 meters, can be zoomed in/ out

    Lidar2d {
        id: driver;

        onHasData: {
            var dists = getData(0);
            var angles = getData(1);
            var qs = getData(2);
//            rightBar.log("Obtained " + (dists.length) + " scan points");
            pose.addPoints(dists, angles, qs);
//            rightBar.log("Added points");
            data.length = 0;
        }
    }


    Slider {
        value: default_range
        orientation: Qt.Vertical
        minimumValue: 1.0
        maximumValue: 10.0
        stepSize: 1.0
        tickmarksEnabled: true
        height: lidarview.height * .8
        width: 50
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        onValueChanged: {
            pose.range = value
            slider_label.text = "Range:\n" + value + "m"
        }
    }

    Label {
        id: slider_label
        text: "Range:\n" + default_range + "m"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 50
        anchors.bottomMargin: 50

    }

    Component.onCompleted: {
        var ok = driver.setupAndConnect();
        rightBar.log("Lidar setup ok: " + ok);
        driver.runLidar();
    }

    Component.onDestruction: {
        driver.shutdown();
        rightBar.log("QML Shut down");
    }


    Item {
        id: pose
        // points has 1D array of trio: theta/distance/quality
        property var dists: []
        property var thetas: []
        property var qs: []
        property real range: default_range
        property real xpose: 0
        property real ypose: 0
        property real phipose: 0

        anchors.fill: parent

        function addPoints(adists, aangles, aqs){
            thetas = aangles;
            dists = adists;
            qs = aqs;

            pose_canvas.requestPaint();
        }

        function mean(vals){
            var l = vals.length;
            if (l === 0) return NaN;

            var sum = 0;
            for (var ix = 0; ix < l; ix++){
                sum += vals[ix];
            }
            return (sum/l);
        }


        Canvas {
            id: pose_canvas
            anchors.fill:parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative
            smooth: true
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");

                ctx.reset();

                var cx = lidarview.width/2;
                var cy = lidarview.height/2;
                var radius = Math.min(cx, cy) - 50-10;

//                console.warn("MAX: " + distmax + ", radius: " + radius + ", ratio: " + ratio);

                ctx.translate(cx, cy);

                ctx.strokeStyle = Qt.rgba(0, 102./255., 1., 1);
                ctx.lineWidth = 5;
                ctx.moveTo(10, 0);
                ctx.arc(0, 0, 10, 0, 2* Math.PI, false);
                ctx.stroke();

                ctx.beginPath();
                ctx.lineWidth = 1;
                ctx.strokeStyle = Qt.rgba(30/255,123/255, 133/255, .5);
                ctx.fillStyle = Qt.rgba(0,1,0, .1);
                ctx.moveTo(radius, 0);
                ctx.arc(0,0, radius, 0, 2* Math.PI, false);
                ctx.fill();

                ctx.beginPath();
                ctx.moveTo(radius, 0);
                ctx.arc(0,0, radius, 0, 2* Math.PI, false);
                ctx.moveTo(2*radius/3,0);
                ctx.arc(0,0, 2*radius/3, 0, 2* Math.PI, false);
                ctx.moveTo(1*radius/3,0);
                ctx.arc(0,0, 1*radius/3, 0, 2* Math.PI, false);
                ctx.stroke();

                ctx.save();

                var l = parent.dists.length;
                if (l < 1) return;

                ctx.beginPath();
                ctx.strokeStyle = Qt.rgba(1, 102./255., .0, .8);
                ctx.lineWidth = 2;

//                var distmax = Math.max.apply(Math, parent.dists);
//                var dmean = parent.mean(parent.dists);

////                console.warn("distmax " +distmax + " vs mean " + dmean);
//                if (distmax > 1.85 * dmean) distmax = 1.85 * dmean;

                var ratio = radius / parent.range;

                parent.dists.map(function(d) {
                    if (d > parent.range) d = parent.range;
                    d = d * ratio;
                });

                var ptheta = parent.thetas[0];
                var pdist = parent.dists[0];

                for (var ix = 0; ix < l; ix++){
                    var ctheta = parent.thetas[ix];
                    var cdist = parent.dists[ix] * ratio;

                    ctx.rotate((ctheta - ptheta) /180 *Math.PI);
                    ctx.moveTo(1, -cdist);
                    ctx.lineTo(-1, -cdist);
//                    ctx.moveTo(2, -ratio * parent.range);
//                    ctx.lineTo(-2, -ratio * parent.range);
//                    console.warn("Rotate to " + ((ctheta -ptheta) / 180 * Math.PI)+ ", move to " + cdist);

                    ptheta = ctheta;
                    pdist = ctheta;
                }
                ctx.stroke();

                parent.thetas.length = 0;
                parent.dists.length = 0;
                parent.qs.length = 0;

            }
        }
    }

}
