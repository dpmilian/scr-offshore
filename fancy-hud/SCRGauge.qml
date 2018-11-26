import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4

import QtQuick 2.0

Item {

    CircularGauge {
        anchors.fill: parent
        anchors.top: parent.top
        anchors.left: parent.left

//            transform: Rotation {origin.x: 0; origin.y: 0; axis {x:1; y: 1; z:0} angle: 20}
        style: CircularGaugeStyle {

            needle: Rectangle {
                y: outerRadius * 0.15
                implicitWidth: outerRadius * 0.03
                implicitHeight: outerRadius * 0.9
                antialiasing: true
                color: Qt.rgba(0.66, 0.3, 0, 1)
            }
            tickmarkLabel:  Text {
                font.pixelSize: Math.max(6, outerRadius * 0.1)
                text: styleData.value
                color: styleData.value >= 80 ? "#e34c22" : "#e5e5e5"
                antialiasing: true
            }
            tickmark: Rectangle {
                visible: styleData.value < 80 || styleData.value % 10 == 0
                implicitWidth: outerRadius * 0.02
                antialiasing: true
                implicitHeight: outerRadius * 0.06
                color: styleData.value >= 80 ? "#e34c22" : "#e5e5e5"
            }
        }
    }
}
