import QtQuick 2.0
import QtCharts 2.0

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
        //margins.top: parent.height * 0.2
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
