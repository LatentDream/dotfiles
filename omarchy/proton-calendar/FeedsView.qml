import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root

  property var feeds: []
  property bool configured: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property string language: "en"
  property string draft: ""
  property bool busy: false

  signal addRequested(string url)
  signal removeRequested(string id)
  signal updateRequested(string id, var values)

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property bool draftValid: /^(https|webcal):\/\//i.test(draft.trim())

  implicitHeight: column.implicitHeight

  function clearDraft() {
    field.text = ""
  }

  function label(english, swedish) {
    return root.language === "sv" ? swedish : english
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(8)

    PanelSectionHeader {
      width: parent.width
      text: root.configured ? Model.text("calendars", root.language).toUpperCase()
        : root.label("ADD YOUR PROTON CALENDAR", "LÄGG TILL DIN PROTON-KALENDER")
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Text {
      width: parent.width
      visible: !root.configured
      wrapMode: Text.WordWrap
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      text: root.label(
        "In Proton Calendar: Settings → Calendars → your calendar → Share → Share with anyone, then copy the link and paste it here. The link is stored in Secret Service when available and never shown again.",
        "I Proton Calendar: Inställningar → Kalendrar → din kalender → Dela → Dela med vem som helst. Kopiera länken och klistra in den här. Länken lagras i Secret Service när det är möjligt och visas aldrig igen.")
    }

    Column {
      width: parent.width
      spacing: Style.space(3)
      visible: root.feeds.length > 0

      Repeater {
        model: root.feeds

        Rectangle {
          id: feedRow
          required property var modelData
          required property int index
          property bool editorOpen: false

          width: column.width
          height: Style.space(46) + (editorOpen ? editor.implicitHeight + Style.space(7) : 0)
          radius: Style.cornerRadius
          color: rowMouse.containsMouse || editorOpen
            ? Style.hoverFillFor(root.foreground, Color.accent)
            : "transparent"

          Rectangle {
            id: swatch
            x: Style.space(6)
            y: Style.space(14)
            width: Style.space(9)
            height: Style.space(9)
            radius: width / 2
            antialiasing: true
            color: feedRow.modelData.color || Color.accent
            opacity: feedRow.modelData.enabled === false ? 0.35 : 1.0
          }

          Column {
            id: feedText
            anchors.left: swatch.right
            anchors.leftMargin: Style.space(9)
            anchors.right: actionRow.left
            anchors.rightMargin: Style.space(6)
            y: Style.space(7)
            spacing: Style.space(1)

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: feedRow.modelData.name || Model.text("calendar", root.language)
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: {
                var data = feedRow.modelData
                if (data.error) return data.error
                if (data.skipped) return root.label("Hidden · sync paused", "Dold · synk pausad")
                var count = data.count === undefined ? 0 : data.count
                var status = Model.eventCountLabel(count, root.language)
                if (data.lastUpdatedAt) {
                  var updated = new Date(data.lastUpdatedAt)
                  status += " · " + Model.formatTime(updated, "24-hour")
                }
                return status + (data.secretStored
                  ? root.label(" · keyring", " · nyckelring")
                  : root.label(" · private file", " · privat fil"))
              }
              color: feedRow.modelData.error ? Color.urgent : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }

          Row {
            id: actionRow
            anchors.right: parent.right
            anchors.rightMargin: Style.space(4)
            y: Style.space(5)
            spacing: Style.space(2)

            PanelActionButton {
              iconText: "󰁝"
              tooltipText: root.label("Move up", "Flytta upp")
              enabled: feedRow.index > 0
              opacity: enabled ? 1.0 : 0.3
              foreground: root.dim
              fontFamily: root.fontFamily
              onClicked: root.updateRequested(feedRow.modelData.id, { move: -1 })
            }

            PanelActionButton {
              iconText: "󰁅"
              tooltipText: root.label("Move down", "Flytta ned")
              enabled: feedRow.index < root.feeds.length - 1
              opacity: enabled ? 1.0 : 0.3
              foreground: root.dim
              fontFamily: root.fontFamily
              onClicked: root.updateRequested(feedRow.modelData.id, { move: 1 })
            }

            PanelActionButton {
              iconText: feedRow.modelData.enabled === false ? "󰈈" : "󰈉"
              tooltipText: feedRow.modelData.enabled === false
                ? root.label("Show and sync", "Visa och synka")
                : root.label("Hide and pause sync", "Dölj och pausa synk")
              foreground: root.dim
              fontFamily: root.fontFamily
              onClicked: root.updateRequested(feedRow.modelData.id,
                { enabled: feedRow.modelData.enabled === false })
            }

            PanelActionButton {
              iconText: feedRow.modelData.notificationsEnabled === false ? "󰂛" : "󰂞"
              tooltipText: feedRow.modelData.notificationsEnabled === false
                ? root.label("Enable alerts", "Aktivera notiser")
                : root.label("Disable alerts", "Inaktivera notiser")
              foreground: root.dim
              fontFamily: root.fontFamily
              onClicked: root.updateRequested(feedRow.modelData.id,
                { notificationsEnabled: feedRow.modelData.notificationsEnabled === false })
            }

            PanelActionButton {
              iconText: "󰏫"
              tooltipText: root.label("Calendar preferences", "Kalenderinställningar")
              bordered: feedRow.editorOpen
              foreground: root.dim
              fontFamily: root.fontFamily
              onClicked: feedRow.editorOpen = !feedRow.editorOpen
            }

            PanelActionButton {
              iconText: "󰅖"
              tooltipText: root.label("Remove this calendar", "Ta bort kalendern")
              hoverColor: Color.urgent
              foreground: root.dim
              fontFamily: root.fontFamily
              onClicked: root.removeRequested(feedRow.modelData.id)
            }
          }

          Row {
            id: editor
            anchors.left: feedText.left
            anchors.right: parent.right
            anchors.rightMargin: Style.space(5)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.space(4)
            visible: feedRow.editorOpen
            spacing: Style.space(5)

            TextField {
              id: nameField
              width: parent.width - colorField.width - reminderField.width - saveButton.width
                - defaultButton.width - Style.space(20)
              placeholderText: feedRow.modelData.name || root.label("Calendar name", "Kalendernamn")
              foreground: root.foreground
              font.family: root.fontFamily
            }

            TextField {
              id: colorField
              width: Style.space(82)
              placeholderText: feedRow.modelData.color || "#8b7ff5"
              foreground: root.foreground
              font.family: root.fontFamily
            }

            TextField {
              id: reminderField
              width: Style.space(74)
              placeholderText: feedRow.modelData.reminderMinutes === null
                || feedRow.modelData.reminderMinutes === undefined
                ? root.label("default", "standard") : String(feedRow.modelData.reminderMinutes)
              inputMethodHints: Qt.ImhDigitsOnly
              foreground: root.foreground
              font.family: root.fontFamily
            }

            Button {
              id: defaultButton
              text: root.label("Default alerts", "Standardnotiser")
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              onClicked: root.updateRequested(feedRow.modelData.id, { reminderMinutes: null })
            }

            Button {
              id: saveButton
              text: root.label("Save", "Spara")
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              onClicked: {
                var values = {}
                if (nameField.text !== "") values.name = nameField.text
                if (colorField.text !== "") values.color = colorField.text
                if (reminderField.text !== "") values.reminderMinutes = parseInt(reminderField.text, 10)
                root.updateRequested(feedRow.modelData.id, values)
                feedRow.editorOpen = false
              }
            }
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
          }
        }
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: field
        width: parent.width - addButton.width - Style.space(6)
        enabled: !root.busy
        echoMode: TextInput.Password
        placeholderText: root.configured
          ? root.label("Paste another private share link…", "Klistra in ytterligare en privat delningslänk…")
          : "https://calendar.proton.me/api/calendar/v1/url/…"
        foreground: root.foreground
        font.family: root.fontFamily
        onTextChanged: root.draft = text
        Keys.onReturnPressed: addButton.clicked()
        Keys.onEnterPressed: addButton.clicked()
      }

      Button {
        id: addButton
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("Add", "Lägg till")
        bordered: true
        enabled: root.draftValid && !root.busy
        opacity: enabled ? 1.0 : 0.45
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: {
          if (!enabled) return
          root.addRequested(root.draft)
          root.clearDraft()
        }
      }
    }
  }
}
