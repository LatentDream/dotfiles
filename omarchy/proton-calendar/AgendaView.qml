import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root

  property var events: []
  property date now: new Date()
  property string todayKey: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property int defaultReminderMinutes: 60
  property var reminderOverrides: ({})
  property string timeFormat: "24-hour"
  property string language: "en"
  signal eventActivated(var event)
  signal reminderChanged(var event, var value)

  readonly property var groups: Model.groupByMonth(Model.upcoming(events, now))
  readonly property int total: {
    var n = 0
    for (var i = 0; i < groups.length; i++) n += groups[i].events.length
    return n
  }

  readonly property color dim: Qt.darker(foreground, 1.55)

  implicitHeight: total === 0 ? empty.implicitHeight : column.implicitHeight

  Text {
    id: empty
    width: parent.width
    visible: root.total === 0
    text: root.language === "sv" ? "Inget kommande under de närmaste tolv månaderna."
      : "Nothing coming up in the next twelve months."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Column {
    id: column
    width: parent.width
    visible: root.total > 0
    spacing: Style.space(8)

    Repeater {
      model: root.groups

      Column {
        required property var modelData
        width: column.width
        spacing: Style.space(2)

        Item {
          width: parent.width
          height: Style.space(18)

          PanelSectionHeader {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: {
              var when = new Date(modelData.year, modelData.month, 1)
              var pattern = modelData.year === root.now.getFullYear() ? "MMMM" : "MMMM yyyy"
              return Model.formatDate(when, pattern, root.language).toUpperCase()
            }
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.events.length
            color: Qt.darker(root.foreground, 2.1)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Repeater {
          model: modelData.events

          EventRow {
            required property var modelData
            width: parent.width
            event: modelData
            showDate: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            timeFormat: root.timeFormat
            language: root.language
            reminderValues: Model.reminderMinutesList(modelData, root.reminderOverrides,
              [root.defaultReminderMinutes], null)
            reminderMinutes: Model.reminderMinutes(modelData, root.reminderOverrides, root.defaultReminderMinutes) < 0
              ? root.defaultReminderMinutes
              : Model.reminderMinutes(modelData, root.reminderOverrides, root.defaultReminderMinutes)
            reminderInherited: root.reminderOverrides[Model.reminderKey(modelData)] === undefined
            reminderOff: Model.reminderMinutes(modelData, root.reminderOverrides, root.defaultReminderMinutes) < 0
            onActivated: root.eventActivated(modelData)
            onReminderChanged: function (event, value) { root.reminderChanged(event, value) }
          }
        }
      }
    }
  }
}
