import QtQuick
import QtQuick.Controls.Basic
import Qt5Compat.GraphicalEffects
import IslandBackend

Button {
    id: control
    implicitWidth: 32
    implicitHeight: 32

    // Reference to the theme
    property QtObject theme

    // Active state of sidebar to change indicators
    property bool sidebarActive: false

    background: Rectangle {
        implicitWidth: 32
        implicitHeight: 32
        radius: width / 2
        
        // Exact same background as other top bar components
        color: StyleTokens.black
        border.color: control.hovered || control.sidebarActive ? control.theme.primary : StyleTokens.overviewInnerBorder
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Subtle shadow matching macOS
        layer.enabled: control.hovered
        layer.effect: Component {
            DropShadow {
                radius: 6
                samples: 12
                color: "#30000000"
                horizontalOffset: 0
                verticalOffset: 1.5
            }
        }
    }

    contentItem: Item {
        anchors.fill: parent

        Image {
            id: logo
            anchors.centerIn: parent
            width: 16
            height: 16
            source: "assets/arch_logo.svg"
            sourceSize.width: 16
            sourceSize.height: 16
            fillMode: Image.PreserveAspectFit
            
            // Apply Matugen primary accent color to the Arch logo
            layer.enabled: true
            layer.effect: Component {
                ColorOverlay {
                    color: control.theme.primary
                }
            }
        }

        // Small indicator dot below the pill
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            width: 4
            height: 4
            radius: 2
            color: control.theme.primary
            visible: control.sidebarActive

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
