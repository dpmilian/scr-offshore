import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Extras 1.4

import QtQuick.Controls.Styles 1.4
import QtQuick.Particles 2.0
import QtCharts 2.0


ApplicationWindow{

    id: root
    visible: true
    visibility: "FullScreen"
    width: 1000
    height: 1000
    title: qsTr("SCR Curve Detector and HUD")

    Item {
        focus: true;
        Keys.onPressed: {
            if (event.key === Qt.Key_Q){
                Qt.quit();
    //            event.accepted = true;
            }
        }
    }

    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 100
        z: 1
        color: Qt.rgba(1., 102./255., 0, .5);
        font.pixelSize: 20
        font.bold: true
        text: "santa compaña robotics || Lat: 42.344433  Lon: 31.341278 || Altitude: 2.45m || Depth: 2500m"
    }

    SCRcamera {}

//    SCRhud{}

    Item {
        id: rightBar
        width: 0.2 * parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.right: parent.right

        Rectangle {

            color: "transparent"
            opacity: 0.1
            width: parent.width
            height: parent.height
            anchors.top: parent.top
            anchors.right: parent.right
        }
        //        transform: Rotation {origin.x: 100; origin.y: 100; axis {x:0; y: 0; z:1} angle: 30}


        ChartView {
            id: chart
            title: "Line"
            width: parent.width
            height: 400
            anchors.top: parent.top
            margins.top: parent.height * 0.2
            antialiasing: true
            backgroundColor: "transparent"

            LineSeries {
                name: "LineSeries"
                XYPoint { x: 0; y: 0 }
                XYPoint { x: 1.1; y: 2.1 }
                XYPoint { x: 1.9; y: 3.3 }
                XYPoint { x: 2.1; y: 2.1 }
                XYPoint { x: 2.9; y: 4.9 }
                XYPoint { x: 3.4; y: 3.0 }
                XYPoint { x: 4.1; y: 3.3 }
            }
        }
    }


    SCRNavigator {
        width: parent.width * 0.65
        height: parent.height * 0.65
//        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        anchors.left: parent.left
//        anchors.leftMargin: 0
//        anchors.bottom: parent.bottom
//        anchors.bottomMargin: 0

        function toggle(){
            var oldhdg = hdg
            var auxhdg = (hdg + ((Math.random() - 0.5) * 10)) % 360

            if (auxhdg < 0) auxhdg = auxhdg + 360
            auxhdg = auxhdg.toFixed(0)

//            console.warn("Toggle: move from " + oldhdg + " to " + auxhdg)
            changeHdg(auxhdg);
        }

        Timer {interval: 800; repeat: true; running: true; onTriggered: this.parent.toggle() }
    }

/*
    Rectangle{
        width: 600
        height: 600
        color: "transparent"

        ParticleSystem {
            id: candidate_particles
            anchors.fill: parent

            ImageParticle{
                source: "qrc:/logoscr.png"
                colorVariation: .1
            }

            Emitter {
                anchors.bottom: parent.bottom
                height: 10
                width: 5
                anchors.fill: parent

                anchors.horizontalCenter: parent.horizontalCenter
                velocity: AngleDirection {
                              angle: 270
                              angleVariation: 30
                              magnitude: 200
                          }
                lifeSpan: 8000
                sizeVariation: 20
            }

            Gravity{
                anchors.fill: parent
                angle: 90
                magnitude: 150
            }
        }
    }
    */

    Item{
        width: 400
        height: 200
        anchors.right: root.right

        anchors.bottom: parent.bottom
//        transform: Rotation {origin.x: 0; origin.y: 0; axis {x:0; y: 1; z:0} angle: 10}


    }
}
