import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Extras 1.4

import QtQuick.Controls.Styles 1.4
import QtQuick.Particles 2.0

ApplicationWindow{

    id: root
    visible: true
    visibility: "FullScreen"
    width: 1000
    height: 1000
    title: qsTr("SCR Curve Detector and Fancy HUD")

    Item {
        focus: true;
        Keys.onPressed: {
            if (event.key === Qt.Key_Q){
                console.warn("Main item caught the keypress");
                event.accepted = true;
                root.close();
            }
        }
    }

//   SCRMap {
//       anchors.fill: parent
//   }

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

//    SCRcamera {}


    SCRhud {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 500
        height: 500

    }

    SCRBar {}


    SCRNavigator {
        width: parent.width * 0.65
        height: parent.height * 0.65
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        anchors.left: parent.left

        function toggle(){
            var oldhdg = hdg
            var auxhdg = (hdg + ((Math.random() - 0.5) * 10)) % 360

            if (auxhdg < 0) auxhdg = auxhdg + 360
            auxhdg = auxhdg.toFixed(0)

            changeHdg(auxhdg);
        }

        Timer {interval: 800; repeat: true; running: true; onTriggered: this.parent.toggle() }
    }

}
