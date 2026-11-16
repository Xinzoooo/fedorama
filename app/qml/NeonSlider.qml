import QtQuick
import QtQuick.Controls

Item {
    id: s
    property string text
    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0
    property int decimals: 2
    property string suffix: ""
    property var format: null
    signal moved(real value)
    implicitHeight: 52
    implicitWidth: 300
    Text { id: lbl; text: s.text; color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
    Text {
        anchors.right: parent.right
        text: s.format ? s.format(sl.value) : sl.value.toFixed(s.decimals) + s.suffix
        color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
    }
    Binding { target: sl; property: "value"; value: s.value; when: !sl.pressed }
    Slider {
        id: sl
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        from: s.from; to: s.to; stepSize: s.stepSize
        onMoved: s.moved(value)
        background: Rectangle {
            x: sl.leftPadding; y: sl.topPadding + sl.availableHeight / 2 - height / 2
            width: sl.availableWidth; height: 4; radius: 2
            color: Theme.glassHover
            Rectangle {
                width: sl.visualPosition * parent.width; height: parent.height; radius: 2
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
            }
        }
        handle: Rectangle {
            x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
            y: sl.topPadding + sl.availableHeight / 2 - height / 2
            width: 18; height: 18; radius: 9
            color: "#ffffff"
            border.width: 3; border.color: Theme.accent
            scale: sl.pressed ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
    }
}
