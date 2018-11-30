import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Extras 2.0

import QtQuick 2.0
import QtQuick.Scene2D 2.9
import QtQuick.Scene3D 2.0

import QtQuick.Extras 1.4
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4

import QtQuick 2.0 as QQ2

Item{

    Rectangle {
        color: "steelblue" //Qt.rgba(200, 20, 34, .7)
        anchors.fill: parent
    }

    Scene3D{
        anchors.fill: parent


        Entity {
            id: hudRoot
            Camera {
                id: hudcam
                projectionType: CameraLens.PerspectiveProjection
                position: Qt.vector3d(.0, .0, 20)
            }

            components: [
                RenderSettings {
                    activeFrameGraph: ForwardRenderer {
                        camera: hudcam
                        clearColor: "white"
                    }
                },
                InputSettings{}
            ]

            Entity {
                id: cube
                components: [cubeTransform, cubeMaterial, cubeMesh, cubePicker]

                property real rotationAngle: 0

                Behavior on rotationAngle {
                    RotationAnimation {
                        direction: RotationAnimation.Shortest
                        duration: 450
                    }
                }

                RotationAnimation on rotationAngle {
                    running: false
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: 4000
                    onStopped: cube.rotationAngle = 0
                }

                Transform {
                    id: cubeTransform
                    translation: Qt.vector3d( 0.0, 0.0, 2.0)
                    scale3D: Qt.vector3d(4, 2, .2)
                    rotation: fromAxisAndAngle(Qt.vector3d(0,1,0), cube.rotationAngle)
                }

                CuboidMesh {
                    id: cubeMesh
                }

                TextureMaterial {
                    id: cubeMaterial
                    texture: offscreenTexture
                }

                ObjectPicker {
                    id: cubePicker
                    hoverEnabled: true
                    dragEnabled: true

                    // Explicitly require a middle click to have the Scene2D grab the mouse
                    // events from the picker
                    onPressed: {
                        if (pick.button === PickEvent.MiddleButton) {
                            qmlTexture.mouseEnabled = !qmlTexture.mouseEnabled
                        }
                    }
                }

                Scene2D {
                    id: qmlTexture
                    output: RenderTargetOutput {
                        attachmentPoint: RenderTargetOutput.Color0
                        texture: Texture2D {
                            id: offscreenTexture
                            width: 1024
                            height: 1024
                            format: Texture.RGBA8_UNorm
                            generateMipMaps: true
                            magnificationFilter: Texture.Linear
                            minificationFilter: Texture.LinearMipMapLinear
                            wrapMode {
                                x: WrapMode.ClampToEdge
                                y: WrapMode.ClampToEdge
                            }
                        }
                    }

                    entities: [ cube ]
                    mouseEnabled: false

                    Rectangle {
                        z: 1
                        color: "red" //Qt.rgba(200, 20, 34, .7)
                        width: offscreenTexture.width/2
                        height: offscreenTexture.height
                    }


                }
            }
        }


    }
}
