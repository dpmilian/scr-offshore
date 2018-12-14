import QtQuick 2.3
import QtGraphicalEffects 1.0

Item {
    id: compass
    property real hdg: 0
    property real tilt: 0
    property real square_dim: Math.min(compass.width, compass.height)
    rotation: 0

    function changeHdg(newhdg){
        compass.hdg = newhdg;
        animateHdg.start();
    }

    RotationAnimation {
        id: animateHdg
        target: compass_background
        properties: "rotation"
        to: -compass.hdg
        easing.type: Easing.InQuad
        duration: 500
        direction: RotationAnimation.Shortest
//        onStarted: console.warn("RUNNING STARTED TO " + (-compass.hdg) + " vs " + compass_background.rotation);
        onRunningChanged: {
            if (running === false){
//                console.warn("RUNNING FINISHED AT " + (-compass.hdg) + " vs " + compass_background.rotation);
                compass_pointer.children[0].requestPaint();
            }
        }
    }



    // -----------

    Item {
        id: compass_background
        width: square_dim
        height: square_dim
        rotation: 0
        z:1

        Glow{
            anchors.fill: compass_background_canvas
            radius: 5
            samples: 35
            color: Qt.rgba(1, 102/255, 0, .4);
            source: compass_background_canvas
            cached: true
            transparentBorder: true
        }
        transform: [
            Translate {y: -(square_dim - height)/2; x: -(square_dim-width)/2},
            Rotation {origin.x: width/2; origin.y: height/2; axis {x:1; y: 0; z:0} angle: compass.tilt}
        ]

        Canvas {
            id: compass_background_canvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative
            antialiasing: true
            smooth: true

            onPaint: {
                var ctx = getContext("2d");
                var centreX = width / 2;
                var centreY = height / 2;

                ctx.reset();
                ctx.translate(centreX, centreY);

                ctx.strokeStyle = Qt.rgba(1., 102./255., 0, .1);
                ctx.lineWidth = 20;
                ctx.arc(0, 0, width/2 - 50, 0, 2* Math.PI, false);
                ctx.stroke();

//                ctx.beginPath();
//                ctx.strokeStyle = Qt.rgba(1., 102./255., 0, .5);
//                ctx.lineWidth = 5;
//                ctx.arc(0, 0, width/2 - 115, 0, 2* Math.PI, false);
//                ctx.stroke();

//                ctx.beginPath();
//                ctx.lineWidth = 3;
//                ctx.strokeStyle = Qt.rgba(1., 102./255., 0, .8);
//                ctx.moveTo(0, -square_dim/2);
//                ctx.lineTo(0,0);
//                ctx.lineTo(square_dim/2, 0);
//                ctx.stroke();
                var astep = 10;
                var resetwidth = false;
                ctx.font = "bold 18px sans-serif";

                for (var a = 0; a < 360; a += astep){
                    ctx.moveTo(0,0);
                    if ((a % 90) == 0){
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.strokeStyle = Qt.rgba(1., 102./255., 0, .8);
                        ctx.lineWidth = 6;
                        resetwidth = true;
                        ctx.moveTo(width/2 - 60,0);
                        ctx.lineTo(width/2 - 50, 0);
                    } else {
                        ctx.moveTo(width/2 - 60, 0);
                        ctx.lineTo(width/2 - 40, 0);
                        ctx.moveTo(width/2 - 32, 0);
                        ctx.lineTo(width/2 - 34, 0)
                    }
                    if (resetwidth){
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.lineWidth = 1;
                        ctx.save();
                        ctx.translate(width/2 - 35, 0);
                        ctx.rotate(-Math.PI * a/180);
                        var b = ((a+90)%360);
                        switch(b){
                        case 0:
                            ctx.translate(-5,-10);
                            break;
                        case 90:
                            ctx.translate(2, 5);
                            break;
                        case 180:
                            ctx.translate(-15, 12);
                            break;
                        case 270:
                            ctx.translate(-36, 5);
                            break;

                        }
                        ctx.fillStyle = Qt.rgba(1., 102/255, 0, 1);
                        ctx.fillText(b.toString() + '\u00B0', 0, 0);
                        ctx.stroke();
                        ctx.restore();

                        ctx.beginPath();
                        ctx.strokeStyle = Qt.rgba(1., 102./255., 0, .4);
                        resetwidth = false;
                    }

                    ctx.rotate(Math.PI * astep/ 180);
    //                ctx.text(a.toString(), width/2-30,0);
                }
                ctx.stroke();


            }


        }
    }

    // ------------------------


    Item {
        id: compass_pointer
        width: square_dim
        height: square_dim
        z:2
        rotation: 0

        transform: [
            Translate {y: -(square_dim - height)/2; x: -(square_dim-width)/2},
            Rotation {origin.x: width/2; origin.y: height/2; axis {x:1; y: 0; z:0} angle: compass.tilt}
        ]

        Canvas {
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative
            antialiasing: true
            smooth: true

            onPaint: {
                var ctx = getContext("2d");
                var centreX = width / 2;
                var centreY = height / 2;

                ctx.reset();
                ctx.beginPath();
                ctx.strokeStyle = Qt.rgba(1., 102./255., 0, .4);
                ctx.fillStyle = Qt.rgba(1., 102./255., 0, .8);

                ctx.translate(centreX, centreY);
                ctx.lineWidth = 4;
                ctx.moveTo(0, -width/2 + 78);
                ctx.moveTo(0, -width/2 + 65);
                ctx.lineTo(8, -width/2 + 78);
                ctx.lineTo(-8, -width/2 + 78);
//                ctx.stroke();
                ctx.fill();
                ctx.font = "bold 24px sans-serif";
                ctx.textAlign = "center";
                ctx.fillText(compass.hdg.toFixed(0).toString() + '\u00B0', 0, -width/2 + 105);
            }
        }
    }


}

