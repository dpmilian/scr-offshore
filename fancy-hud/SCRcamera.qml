import com.SCR.classes 1.0
import QtMultimedia 5.8
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import QtQuick 2.0

Item {
    anchors.fill: parent
    // *******************+
    ContourFinder{
        id: finder
        Component.onCompleted: {
//            console.warn("COMPLETED!!!");
        }
        onObjectDetected: {
            var r = video.mapNormalizedRectToItem(Qt.rect(x,y,w,h));
//            console.warn("DETECTED - x: " + x + ", y: " + y);
/*
//            logo.x = x;
//            logo.y = y;
//            logo.width = w;
//            logo.height = h;
//            logo.visible = true;
*/
        }
    }

    // *********************
    Camera {
        id: camera
    }

    // *********************
    ShaderEffect{
        id: videoShader
        property variant src: video
        property variant source: video
    }

    // *********************
    GroupBox{
        anchors.fill: parent
        visible: true
        padding: 0

        ColumnLayout{
            anchors.fill: parent

            VideoOutput{
                id: video
                Layout.fillHeight: true
                Layout.fillWidth: true
                source: camera
                autoOrientation: false
                fillMode: VideoOutput.Stretch

                filters: [finder]

                Image{
                    id: logo
                    source: "qrc:/img/logo-small-notext.svg"
                    visible: true
                    width: 75
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    anchors.right: parent.right
                }
            }

            RowLayout{
                Layout.alignment: Qt.AlignHCenter
                visible: false
                Layout.fillWidth: true
                Label {
                    text: "Camera"
                }
                ComboBox{
                    Layout.fillWidth: true
                    model: QtMultimedia.availableCameras
                    textRole: "displayName"
                    onActivated:{
                        camera.stop()
                        camera.deviceId = model[currentIndex].deviceId
                        cameraStartTimer.start()
                    }

                    Timer {
                        id: cameraStartTimer;
                        interval: 500;
                        running: false;
                        repeat: false;
                        onTriggered: camera.start();
                    }

                    onAccepted:{
                        console.warn("aaa")
                    }
                }
            }
        }



    }

}
