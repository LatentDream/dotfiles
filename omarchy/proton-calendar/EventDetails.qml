import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Rectangle {
  id: root

  property var event: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property string language: "en"
  property string timeFormat: "24-hour"

  signal closeRequested()
  signal openRequested(var event)
  signal joinRequested(string url)
  signal copyRequested(string value)
  signal snoozeRequested(var event, int minutes)

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color accentColor: event && event.color !== "" ? event.color : Color.accent

  visible: event !== null
  width: parent ? parent.width : implicitWidth
  implicitHeight: visible ? content.implicitHeight + Style.space(18) : 0
  radius: Style.cornerRadius
  color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.045)
  border.width: Style.spacing.hairline
  border.color: Style.normalBorderFor(foreground, Color.accent)

  function whenText() {
    if (!root.event) return ""
    if (root.event.allDay) {
      var start = Model.formatDate(root.event.start, "ddd d MMM", root.language)
      return root.event.multiDay ? start + " – " + Model.formatDate(root.event.lastDate, "ddd d MMM", root.language) : start
    }
    return Model.formatDate(root.event.start, "ddd d MMM", root.language) + " · "
      + Model.formatTime(root.event.start, root.timeFormat) + "–"
      + Model.formatTime(root.event.end, root.timeFormat)
  }

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(9)
    spacing: Style.space(7)

    Row {
      width: parent.width
      spacing: Style.space(8)

      Rectangle {
        width: Style.space(4)
        height: titleBlock.implicitHeight
        radius: width / 2
        color: root.accentColor
      }

      Column {
        id: titleBlock
        width: parent.width - Style.space(42)
        spacing: Style.space(2)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.event ? root.event.title : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.whenText()
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      PanelActionButton {
        iconText: "󰅖"
        tooltipText: Model.text("dismiss", root.language)
        foreground: root.dim
        fontFamily: root.fontFamily
        onClicked: root.closeRequested()
      }
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      visible: root.event && root.event.calendar !== ""
      text: Model.text("calendar", root.language) + ": " + (root.event ? root.event.calendar : "")
        + (root.event && root.event.recurring ? " · " + Model.text("recurring", root.language) : "")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      visible: root.event && root.event.location !== ""
      text: Model.text("location", root.language) + ": " + (root.event ? root.event.location : "")
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      visible: root.event && root.event.description !== ""
      text: root.event ? root.event.description : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      maximumLineCount: 8
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      visible: root.event && root.event.organizer !== ""
      text: Model.text("organizer", root.language) + ": " + (root.event ? root.event.organizer : "")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      visible: root.event && root.event.attendees && root.event.attendees.length > 0
      text: Model.text("participants", root.language) + ": "
        + (root.event && root.event.attendees ? root.event.attendees.join(", ") : "")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      maximumLineCount: 3
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      visible: root.event && !root.event.allDay && (root.event.sourceTimezone !== ""
        || root.event.secondaryTimezone !== "")
      text: {
        if (!root.event) return ""
        var values = []
        if (root.event.sourceTimezone)
          values.push(root.event.sourceTimezone + " " + Model.formatTime(root.event.sourceStart, root.timeFormat))
        if (root.event.secondaryTimezone && root.event.secondaryStart)
          values.push(root.event.secondaryTimezone + " " + Model.formatTime(root.event.secondaryStart, root.timeFormat))
        return values.join(" · ")
      }
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Row {
      width: parent.width
      spacing: Style.space(5)

      Button {
        visible: root.event && root.event.meetingLink !== ""
        text: Model.text("join", root.language)
        iconText: "󰍉"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.joinRequested(root.event.meetingLink)
      }

      Button {
        visible: root.event && root.event.location !== ""
        text: Model.text("copyLocation", root.language)
        iconText: "󰆏"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.copyRequested(root.event.location)
      }

      Button {
        text: Model.text("openProton", root.language)
        iconText: "󰏋"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.openRequested(root.event)
      }

      Button {
        text: Model.text("snooze5", root.language)
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.snoozeRequested(root.event, 5)
      }

      Button {
        text: Model.text("snooze15", root.language)
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.snoozeRequested(root.event, 15)
      }
    }
  }
}
