import QtQuick 2.0
import QtLocation 5.3


Item {
    Plugin{
            id: osmplugin
            name: "osm"
        }

    Map {
        id: map
        anchors.fill: parent
        plugin: osmplugin
        zoomLevel: maximumZoomLevel
        center {
            // Charca de Navia
            latitude: 42.210987
            longitude: -8.755854
        }
    }
}
