import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root

  property string dateKey: ""
  property date today: new Date()
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool expanded: false
  property string language: "en"
  property int defaultDurationMinutes: 60

  signal submitted(string title, string time, string endTime, bool allDay,
    string calendar, string location, string clipboardText)
  signal dismissed()

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property var parsedTime: Model.parseTime(timeField.text)
  readonly property var parsedEndTime: Model.parseTime(endTimeField.text)
  readonly property bool valid: titleField.text.replace(/^\s+|\s+$/g, "") !== ""
    && (allDayToggle.checked || (parsedTime !== null && parsedEndTime !== null))

  implicitHeight: expanded ? column.implicitHeight : 0
  clip: true

  Behavior on implicitHeight {
    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
  }

  function reset() {
    titleField.text = ""
    allDayToggle.checked = false
    timeField.text = Model.nextSlot(root.today).text
    var start = Model.nextSlot(root.today)
    var end = new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate(),
      start.hour, start.minute + root.defaultDurationMinutes)
    endTimeField.text = Model.formatTime(end, "24-hour")
    calendarField.text = ""
    locationField.text = ""
  }

  function label(english, swedish) {
    return root.language === "sv" ? swedish : english
  }

  function focusTitle() {
    titleField.forceActiveFocus()
    titleField.selectAll()
  }

  function submit() {
    if (!valid) return
    var title = titleField.text.replace(/^\s+|\s+$/g, "")
    var startText = allDayToggle.checked ? "" : parsedTime.text
    var endText = allDayToggle.checked ? "" : parsedEndTime.text
    var details = [title]
    if (root.dateKey) details.push(root.dateKey)
    if (allDayToggle.checked) details.push(Model.text("allDay", root.language))
    else details.push(startText + "–" + endText)
    if (calendarField.text) details.push(Model.text("calendar", root.language) + ": " + calendarField.text)
    if (locationField.text) details.push(Model.text("location", root.language) + ": " + locationField.text)
    root.submitted(title, startText, endText, allDayToggle.checked,
      calendarField.text, locationField.text, details.join("\n"))
    reset()
  }

  function handleKey(event) {
    if (event.key === Qt.Key_Escape) {
      root.dismissed()
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.submit()
      event.accepted = true
    }
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(6)

    Row {
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: titleField
        width: parent.width - timeField.width - endTimeField.width - allDayToggle.width
          - submitButton.width - Style.space(24)
        placeholderText: root.label("New event", "Nytt event")
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onPressed: function (event) { root.handleKey(event) }
      }

      TextField {
        id: timeField
        width: Style.space(64)
        enabled: !allDayToggle.checked
        opacity: enabled ? 1.0 : 0.45
        placeholderText: "09:00"
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onPressed: function (event) { root.handleKey(event) }
      }

      TextField {
        id: endTimeField
        width: Style.space(64)
        enabled: !allDayToggle.checked
        opacity: enabled ? 1.0 : 0.45
        placeholderText: "10:00"
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onPressed: function (event) { root.handleKey(event) }
      }

      Button {
        id: allDayToggle
        property bool checked: false
        anchors.verticalCenter: parent.verticalCenter
        text: Model.text("allDay", root.language)
        selected: checked
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: checked = !checked
      }

      Button {
        id: submitButton
        anchors.verticalCenter: parent.verticalCenter
        text: Model.text("openProton", root.language)
        iconText: "󰏋"
        bordered: true
        enabled: root.valid
        opacity: enabled ? 1.0 : 0.45
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.submit()
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: calendarField
        width: (parent.width - Style.space(6)) / 2
        placeholderText: Model.text("calendar", root.language)
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onPressed: function (event) { root.handleKey(event) }
      }

      TextField {
        id: locationField
        width: (parent.width - Style.space(6)) / 2
        placeholderText: Model.text("location", root.language)
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onPressed: function (event) { root.handleKey(event) }
      }
    }

    Text {
      width: parent.width
      text: {
        var when = root.dateKey === "" ? Model.text("selectedDay", root.language)
          : Model.formatDate(Model.parseStamp(root.dateKey), "ddd d MMM", root.language)
        if (!root.valid && titleField.text === "")
          return root.label("Proton has no write API — the details are copied and the web app opens on the day.",
            "Proton saknar skriv-API — detaljerna kopieras och webbappen öppnas på rätt dag.")
        if (!root.valid) return root.label("That is not a valid time. Try 9, 930, or 9:30.",
          "Tiden är inte giltig. Prova 9, 930 eller 9:30.")
        return root.label("Copies the details and opens Proton Calendar on ",
          "Kopierar detaljerna och öppnar Proton Calendar på ") + when + "."
      }
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }

  onExpandedChanged: {
    if (expanded) {
      reset()
      Qt.callLater(focusTitle)
    }
  }
}
