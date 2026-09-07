import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root

  property bool notificationsEnabled: true
  property bool notificationSoundEnabled: true
  property string notificationSound: "Alarm"
  property int reminderMinutes: 60
  property int weekStart: 0
  property string languageSetting: "System"
  property string resolvedLanguage: "en"
  property string timeFormat: "System"
  property string secondaryTimeZone: ""
  property bool showWeekNumbers: true
  property string barMode: "Countdown"
  property var reminderValues: [reminderMinutes]
  property bool allDayNotificationsEnabled: false
  property int allDayReminderDays: 1
  property int allDayReminderHour: 9
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal settingsRequested(bool enabled, bool soundEnabled, string sound, int minutes)
  signal weekStartRequested(int day)
  signal soundPreviewRequested(string sound)
  signal testRequested()
  signal preferencesRequested(var values)

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property real labelWidth: Style.space(118)
  readonly property real controlHeight: Style.space(34)

  implicitHeight: column.implicitHeight

  function save(enabled, soundEnabled, sound, minutes) {
    root.settingsRequested(enabled, soundEnabled, sound,
      Math.max(1, Math.min(10080, minutes)))
  }

  function label(english, swedish) {
    return root.resolvedLanguage === "sv" ? swedish : english
  }

  function applyMinutes(value) {
    var values = Model.normalizeMinuteList(String(value).split(","), [])
    if (values.length) {
      root.preferencesRequested({ reminderMinutesList: values, reminderMinutes: values[0] })
      save(root.notificationsEnabled, root.notificationSoundEnabled,
        root.notificationSound, values[0])
    }
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(9)

    PanelSectionHeader {
      width: parent.width
      text: root.label("CALENDAR LAYOUT", "KALENDERLAYOUT")
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("WEEK STARTS", "VECKAN BÖRJAR")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        id: weekStartGroup
        options: [Model.text("sunday", root.resolvedLanguage), Model.text("monday", root.resolvedLanguage)]
        value: root.weekStart === 1 ? Model.text("monday", root.resolvedLanguage)
          : Model.text("sunday", root.resolvedLanguage)
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          root.weekStartRequested(value === Model.text("monday", root.resolvedLanguage) ? 1 : 0)
        }
      }

      Button {
        text: root.showWeekNumbers ? root.label("Week numbers on", "Veckonummer på")
          : root.label("Week numbers off", "Veckonummer av")
        selected: root.showWeekNumbers
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.preferencesRequested({ showWeekNumbers: !root.showWeekNumbers })
      }
    }

    PanelSectionHeader {
      width: parent.width
      text: root.label("REGIONAL", "REGIONALT")
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("LANGUAGE", "SPRÅK")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - Style.space(6)
        options: [Model.languageSettingLabel("System", root.resolvedLanguage),
          Model.languageSettingLabel("English", root.resolvedLanguage),
          Model.languageSettingLabel("Swedish", root.resolvedLanguage)]
        value: Model.languageSettingLabel(root.languageSetting, root.resolvedLanguage)
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          root.preferencesRequested({ language: Model.languageSettingFromLabel(value) })
        }
      }
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("CLOCK", "KLOCKA")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - Style.space(6)
        options: [Model.timeFormatLabel("System", root.resolvedLanguage),
          Model.timeFormatLabel("24-hour", root.resolvedLanguage),
          Model.timeFormatLabel("12-hour", root.resolvedLanguage)]
        value: Model.timeFormatLabel(root.timeFormat, root.resolvedLanguage)
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          root.preferencesRequested({ timeFormat: Model.timeFormatFromLabel(value) })
        }
      }
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("SECOND TIME ZONE", "ANDRA TIDSZON")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      TextField {
        id: timezoneField
        width: parent.width - root.labelWidth - setTimezoneButton.width
          - clearTimezoneButton.width - Style.space(18)
        placeholderText: root.secondaryTimeZone || root.label("Europe/London or UTC", "Europe/London eller UTC")
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onReturnPressed: root.preferencesRequested({ secondaryTimeZone: text })
        Keys.onEnterPressed: root.preferencesRequested({ secondaryTimeZone: text })
      }

      Button {
        id: setTimezoneButton
        text: root.label("Set", "Sätt")
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.preferencesRequested({ secondaryTimeZone: timezoneField.text })
      }

      Button {
        id: clearTimezoneButton
        text: root.label("Off", "Av")
        selected: root.secondaryTimeZone === ""
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.preferencesRequested({ secondaryTimeZone: "" })
      }

    }

    PanelSectionHeader {
      width: parent.width
      text: root.label("BAR", "MENYRAD")
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("DISPLAY", "VISNING")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - Style.space(6)
        options: [Model.barModeLabel("Off", root.resolvedLanguage),
          Model.barModeLabel("Next event", root.resolvedLanguage),
          Model.barModeLabel("Countdown", root.resolvedLanguage),
          Model.barModeLabel("Today count", root.resolvedLanguage),
          Model.barModeLabel("Current event", root.resolvedLanguage),
          Model.barModeLabel("Privacy", root.resolvedLanguage)]
        value: Model.barModeLabel(root.barMode, root.resolvedLanguage)
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          root.preferencesRequested({ barMode: Model.barModeFromLabel(value) })
        }
      }
    }

    PanelSectionHeader {
      width: parent.width
      text: root.label("NOTIFICATIONS", "NOTISER")
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Button {
        width: (parent.width - Style.space(6)) / 2
        height: root.controlHeight
        text: root.notificationsEnabled ? root.label("Notifications on", "Notiser på")
          : root.label("Notifications off", "Notiser av")
        iconText: root.notificationsEnabled ? "󰂞" : "󰂛"
        selected: root.notificationsEnabled
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.save(!root.notificationsEnabled,
          root.notificationSoundEnabled, root.notificationSound, root.reminderMinutes)
      }

      Button {
        width: (parent.width - Style.space(6)) / 2
        height: root.controlHeight
        text: root.notificationSoundEnabled ? root.label("Alarm sound on", "Notisljud på")
          : root.label("Alarm sound off", "Notisljud av")
        iconText: root.notificationSoundEnabled ? "󰕾" : "󰝟"
        selected: root.notificationSoundEnabled
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.save(root.notificationsEnabled,
          !root.notificationSoundEnabled, root.notificationSound, root.reminderMinutes)
      }
    }

    Text {
      width: parent.width
      text: root.label("TIMED EVENTS", "TIDSSATTA EVENT")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("REMIND BEFORE", "PÅMINN FÖRE")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - Style.space(6)
        options: [Model.reminderPresetLabel(15, root.resolvedLanguage),
          Model.reminderPresetLabel(30, root.resolvedLanguage),
          Model.reminderPresetLabel(60, root.resolvedLanguage),
          Model.reminderPresetLabel(120, root.resolvedLanguage)]
        value: Model.reminderPresetLabel(root.reminderMinutes, root.resolvedLanguage)
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          var minutes = Model.reminderPresetFromLabel(value)
          if (minutes) {
            root.preferencesRequested({ reminderMinutesList: [minutes] })
            root.save(root.notificationsEnabled,
              root.notificationSoundEnabled, root.notificationSound, minutes)
          }
        }
      }
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("CUSTOM", "ANPASSAD")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      TextField {
        id: minutesField
        width: Style.space(90)
        height: root.controlHeight
        placeholderText: root.reminderValues.join(",")
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onReturnPressed: root.applyMinutes(text)
        Keys.onEnterPressed: root.applyMinutes(text)
      }

      Button {
        id: allDayToggle
        height: root.controlHeight
        text: root.label("Set list", "Sätt lista")
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.applyMinutes(minutesField.text)
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.reminderValues.join(", ") + root.label(" min before", " min före")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Text {
      width: parent.width
      text: root.label("ALL-DAY EVENTS", "HELDAGSEVENT")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("STATUS", "STATUS")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Button {
        height: root.controlHeight
        text: root.allDayNotificationsEnabled ? root.label("All-day on", "Heldag på")
          : root.label("All-day off", "Heldag av")
        selected: root.allDayNotificationsEnabled
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.preferencesRequested({
          allDayNotificationsEnabled: !root.allDayNotificationsEnabled
        })
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - root.labelWidth - allDayToggle.width - Style.space(12)
        text: root.label("Notify ", "Påminn ") + root.allDayReminderDays
          + root.label(" day before at ", " dag före kl. ")
          + (root.allDayReminderHour < 10 ? "0" : "") + root.allDayReminderHour + ":00"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("WHEN", "NÄR")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        options: [root.label("Previous day 09:00", "Dagen före 09:00"),
          root.label("Same day 09:00", "Samma dag 09:00")]
        value: root.allDayReminderDays === 0
          ? root.label("Same day 09:00", "Samma dag 09:00")
          : root.label("Previous day 09:00", "Dagen före 09:00")
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          var sameDay = value === root.label("Same day 09:00", "Samma dag 09:00")
          root.preferencesRequested({ allDayReminderDays: sameDay ? 0 : 1,
            allDayReminderHour: 9 })
        }
      }
    }

    Text {
      width: parent.width
      text: root.label("SOUND", "LJUD")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label("ALARM SOUND", "NOTISLJUD")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - Style.space(6)
        options: [Model.soundLabel("Gentle", root.resolvedLanguage),
          Model.soundLabel("Bell", root.resolvedLanguage),
          Model.soundLabel("Chime", root.resolvedLanguage),
          Model.soundLabel("Alarm", root.resolvedLanguage)]
        value: Model.soundLabel(root.notificationSound, root.resolvedLanguage)
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          var sound = Model.soundFromLabel(value)
          root.save(root.notificationsEnabled, root.notificationSoundEnabled,
            sound, root.reminderMinutes)
          root.soundPreviewRequested(sound)
        }
      }

    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Item {
        width: root.labelWidth
        height: parent.height
      }

      Button {
        height: root.controlHeight
        text: root.label("Send test reminder in 1 minute", "Skicka testnotis om 1 minut")
        iconText: "󰂞"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.testRequested()
      }
    }

    Text {
      width: parent.width
      text: root.label(
        "Use comma-separated lead times such as 60,15 for multiple alerts. Each calendar and event can override the default. Notification actions support open, snooze, and dismiss.",
        "Ange flera påminnelser med kommatecken, exempelvis 60,15. Varje kalender och event kan ha egna värden. Notiser kan öppnas, skjutas upp och stängas.")
      wrapMode: Text.WordWrap
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
