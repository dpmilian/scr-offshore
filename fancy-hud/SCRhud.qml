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
import QtCharts 2.0

Item{

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

                property real rotationAngle: 60

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
                    translation: Qt.vector3d( 0.0, 0.0, 0.0)
                    scale3D: Qt.vector3d(5, 5, .2)
                    rotation: fromAxisAndAngle(Qt.vector3d(0,1,1), cube.rotationAngle)
                }

                CuboidMesh {
                    id: cubeMesh
                }

                PhongMaterial {
                    id: cubeMaterial
                    ambient: Qt.rgba( 244/255,
                                      12/255,
                                      99/255, 1.0 )
                    diffuse: Qt.rgba( 0.1, 0.1, 0.1, 0.5 )
                    shininess: .8
                }
//                TextureMaterial {
//                    id: cubeMaterial
//                    texture: offscreenTexture
//                }

                ObjectPicker {
                    id: cubePicker
                    hoverEnabled: true
                    dragEnabled: true

                    // Explicitly require a middle click to have the Scene2D grab the mouse
                    // events from the picker
                    onPressed: {
                        if (pick.button === PickEvent.RightButton) {
                            qmlTexture.mouseEnabled = !qmlTexture.mouseEnabled
                        }
                    }
                }

                Scene2D {
                    id: qmlTexture
                    Component.onDestruction: {
                        console.warn("destroying");

                        qmlTexture.output.texture.destroy();
                    }

//                     renderPolicy: QtQuick.QScene2D.Continuous
                    output: RenderTargetOutput {
                        attachmentPoint: RenderTargetOutput.Color0

                        texture: Texture2D {
                            id: offscreenTexture
                            width: 1024
                            height: 1024
                            format: Texture.RGBA8_UNorm
                            generateMipMaps: false
                            magnificationFilter: Texture.Linear
                            minificationFilter: Texture.LinearMipMapLinear
                            wrapMode {
                                x: WrapMode.ClampToEdge
                                y: WrapMode.ClampToEdge
                            }
                        }
                    }

                    entities: [ cube ]
                    mouseEnabled: true


                    ChartView {
                        id: chart
                        title: "Line"
                        width: offscreenTexture.width
                        height: offscreenTexture.height

                        //margins.top: parent.height * 0.2
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

            }
        }


    }
}
