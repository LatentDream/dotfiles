pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.latent.typo"

  readonly property var typoService: bar && bar.shell
    && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dimForeground: Qt.darker(foreground, 1.5)
  property bool popupOpen: false
  property int expandedIndex: -1

  function close() { popupOpen = false }
  function toggleHistory() { popupOpen = !popupOpen }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: root.typoService && root.typoService.busy ? spinnerComponent : normalIconComponent
    active: root.popupOpen
    tooltipText: root.typoService && root.typoService.busy
      ? (root.typoService.statusText || "Correcting clipboard...")
      : root.typoService && root.typoService.lastError
        ? root.typoService.lastError
        : "Left-click: correct clipboard  Right-click: history"

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.toggleHistory()
      else if (buttonCode === Qt.LeftButton && root.typoService)
        root.typoService.correctClipboard()
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.typoService && root.typoService.busy
      ? "Correcting clipboard" : "Correct clipboard text"
    Accessible.description: "Left-click corrects clipboard text. Right-click opens correction history."
    Accessible.onPressAction: if (root.typoService) root.typoService.correctClipboard()

  }

  Component {
    id: normalIconComponent

    OpticalGlyph {
      anchors.fill: parent
      anchors.topMargin: Style.space(2)
      text: "󰓆"
      fontFamily: button.fontFamily
      fontSize: button.fontSize
      color: button.active && button.useActiveColor ? button.activeColor : button.foreground
    }
  }

  Component {
    id: spinnerComponent

    Item {
      Item {
        id: spinner
        anchors.centerIn: parent
        width: Math.max(9, Math.min(parent.width, parent.height) * 0.64)
        height: width

        Canvas {
          anchors.fill: parent
          onPaint: {
            var context = getContext("2d")
            var stroke = Math.max(1.5, width * 0.14)
            context.reset()
            context.beginPath()
            context.lineWidth = stroke
            context.lineCap = "round"
            context.strokeStyle = "black"
            context.arc(width / 2, height / 2, (width - stroke) / 2,
              -Math.PI / 2, Math.PI)
            context.stroke()
          }
        }

        RotationAnimation on rotation {
          from: 0
          to: 360
          duration: 750
          loops: Animation.Infinite
          running: true
        }
      }
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(440))
    contentHeight: popup.fittedContentHeight(content.implicitHeight, Style.space(580))

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(8)

        Column {
          width: parent.width - clearButton.width - parent.spacing
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: "Typo history"
            color: root.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            width: parent.width
            text: root.typoService && root.typoService.lastError
              ? root.typoService.lastError
              : root.typoService && root.typoService.busy
                ? (root.typoService.statusText || "Correcting clipboard...")
                : "Click a result to copy it again"
            color: root.typoService && root.typoService.lastError
              ? (root.bar ? root.bar.urgent : Color.urgent) : root.dimForeground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        Button {
          id: clearButton
          visible: root.typoService && root.typoService.history.length > 0
          text: "Clear"
          foreground: root.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          onClicked: {
            root.expandedIndex = -1
            root.typoService.clearHistory()
          }
        }
      }

      PanelSeparator {
        width: parent.width
        foreground: root.foreground
      }

      Item {
        width: parent.width
          implicitHeight: Math.max(Style.space(80), Math.min(historyColumn.implicitHeight, Style.space(480)))

        Text {
          anchors.centerIn: parent
          visible: !root.typoService || root.typoService.history.length === 0
          text: "No corrections yet"
          color: root.dimForeground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
        }

        Flickable {
          anchors.fill: parent
          visible: root.typoService && root.typoService.history.length > 0
          contentWidth: width
          contentHeight: historyColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          Column {
            id: historyColumn
            width: parent.width
            spacing: Style.space(6)

            Repeater {
              model: root.typoService ? root.typoService.history : []

              BorderSurface {
                id: row
                required property var modelData
                required property int index
                width: historyColumn.width
                implicitHeight: rowContent.implicitHeight + Style.space(16)
                radius: Style.cornerRadius
                color: root.expandedIndex === index
                  ? Style.selectedFillFor(root.foreground, Color.accent) : "transparent"
                borderSpec: root.expandedIndex === index
                  ? Border.controlSpec("normal", root.foreground, Color.accent) : Border.none()

                Column {
                  id: rowContent
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  spacing: Style.space(5)

                  Row {
                    width: parent.width
                    spacing: Style.space(8)

                    Text {
                      width: parent.width - deleteButton.width - parent.spacing
                      text: String(row.modelData.output || "")
                      color: root.foreground
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.body
                      maximumLineCount: root.expandedIndex === row.index ? 8 : 2
                      wrapMode: Text.Wrap
                      elide: Text.ElideRight
                    }

                    Button {
                      id: deleteButton
                      iconText: "󰆴"
                      tooltipText: "Delete entry"
                      foreground: root.foreground
                      horizontalPadding: Style.space(5)
                      verticalPadding: Style.space(3)
                      onClicked: {
                        root.expandedIndex = -1
                        root.typoService.removeHistory(row.index)
                      }
                    }
                  }

                  Text {
                    visible: root.expandedIndex === row.index
                    width: parent.width
                    text: "Original\n" + String(row.modelData.input || "")
                    color: root.dimForeground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.caption
                    maximumLineCount: 8
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: String(row.modelData.createdAt || "") + "  " + String(row.modelData.model || "")
                    color: root.dimForeground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  anchors.rightMargin: deleteButton.width + Style.space(14)
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton)
                      root.expandedIndex = root.expandedIndex === row.index ? -1 : row.index
                    else
                      root.typoService.copyOutput(row.index)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
