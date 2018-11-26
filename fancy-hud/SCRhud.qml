import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Extras 2.0
import QtQuick.Scene3D 2.0
import QtQuick.Extras 1.4
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4

import QtQuick 2.0 as QQ2

Scene3D {
    id: hud
    anchors.fill: parent
    anchors.margins: 10
    focus: true
    aspects: ["input", "logic"]
    cameraAspectRatioMode: Scene3D.AutomaticAspectRatio



    Entity {
        id: sceneRoot

        Camera {
            id: camera
            projectionType: CameraLens.PerspectiveProjection
            fieldOfView: 65
            nearPlane : 0.1
            farPlane : 1000.0
            position: Qt.vector3d( 10.0, 0.0, 40.0 )
            upVector: Qt.vector3d( 0.0, 1.0, 0.0 )
            viewCenter: Qt.vector3d( 0.0, 0.0, 0.0 )
        }

        FirstPersonCameraController { camera: camera }

        components: [
            RenderSettings {
                activeFrameGraph: ForwardRenderer {
                    camera: camera
                    clearColor: "transparent"
                }
            },
            InputSettings { }
        ]

        PhongMaterial {
            id: material
        }

        TorusMesh {
            id: torusMesh
            radius: 5
            minorRadius: .3
            rings: 100
            slices: 20
        }



        Transform {
            id: torusTransform
            scale3D: Qt.vector3d(1.5, 2, 1)
            rotation: fromAxisAndAngle(Qt.vector3d(1, 1, 0), 55)
        }

        Entity {
            id: torusEntity
            components: [ torusMesh, material, torusTransform ]
        }

    }
}
