import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    visible: true
    title: qsTr("MyTask")
    color: "#F4F5F7"

    // Color palette for column accents
    property var accents: ["#0052CC", "#FF8B00", "#00875A", "#6554C0", "#DE350B", "#00B8D9"]

    property int ringingTaskId: -1

    // Sound effect for deadline alerts and completed tasks
    SoundEffect {
        id: doneSound
        source: "qrc:/done.wav"
    }

    // Listen to C++ signals from the TaskModel
    Connections {
        target: taskModel
        function onDeadlineRing(taskId, taskTitle) {
            doneSound.play()
            root.ringingTaskId = taskId
            alarmPopup.showAlarm(taskTitle)
        }
    }

    // Notification popup for expired deadlines
    Popup {
        id: alarmPopup
        width: 350
        height: 80
        x: (root.width - width) / 2
        y: 20
        modal: false
        closePolicy: Popup.NoAutoClose
        background: Rectangle {
            radius: 8
            color: "#FFEBE6"
            border.color: "#DE350B"
            border.width: 2
        }

        property string taskName: ""

        function showAlarm(title) {
            taskName = title
            open()
            hideTimer.restart()
        }

        // Auto-hide the alarm popup after 6 seconds
        Timer {
            id: hideTimer
            interval: 6000
            onTriggered: {
                alarmPopup.close()
                root.ringingTaskId = -1
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Text {
                text: "⏰"
                font.pixelSize: 32
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: qsTr("Time's up!")
                    font.bold: true
                    color: "#DE350B"
                    font.pixelSize: 16
                }
                Text {
                    text: alarmPopup.taskName
                    color: "#172B4D"
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Top header bar
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "#1A1D27"

        Text {
            id: headerTitle
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("MyTask Board")
            color: "white"
            font.pixelSize: 18
            font.bold: true
        }

        // App language switcher
        ComboBox {
            id: langSelector
            anchors.left: headerTitle.right
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 110
            height: 30
            model: ["English", "Українська", "Русский"]
            currentIndex: 0
            onActivated: {
                if (currentIndex === 0) langManager.setLanguage("en")
                else if (currentIndex === 1) langManager.setLanguage("uk_UA")
                else if (currentIndex === 2) langManager.setLanguage("ru_RU")
            }
            background: Rectangle {
                color: "#333A4D"
                radius: 4
            }
            contentItem: Text {
                text: langSelector.currentText
                color: "white"
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // REST API motivation quote display
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Text {
                text: taskModel.motivationQuote
                color: "#A0AABF"
                font.pixelSize: 13
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
                width: 400
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }

            Rectangle {
                width: 30
                height: 30
                radius: 4
                color: apiBtnMouse.containsMouse ? "#333A4D" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "🔄"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: apiBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: taskModel.fetchMotivation()
                }
            }
        }
    }

    // Custom Date and Time picker popup
    Popup {
        id: dateTimePopup
        width: 320
        height: 430
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            radius: 10
            color: "white"
            border.color: "#C1C7D0"
            border.width: 1
        }

        property var targetField: null
        property var monthNames: [qsTr("January"), qsTr("February"), qsTr("March"), qsTr("April"), qsTr("May"), qsTr("June"), qsTr("July"), qsTr("August"), qsTr("September"), qsTr("October"), qsTr("November"), qsTr("December")]

        property int curMonth: new Date().getMonth()
        property int curYear: new Date().getFullYear()

        property int selDay: new Date().getDate()
        property int selMonth: new Date().getMonth()
        property int selYear: new Date().getFullYear()

        property int daysInMonth: new Date(curYear, curMonth + 1, 0).getDate()
        property int firstDay: {
            let d = new Date(curYear, curMonth, 1).getDay()
            return d === 0 ? 6 : d - 1
        }

        function openPicker(field) {
            targetField = field
            let d = new Date()
            curMonth = d.getMonth()
            curYear = d.getFullYear()
            selDay = d.getDate()
            selMonth = d.getMonth()
            selYear = d.getFullYear()
            hourSpin.value = d.getHours()
            minSpin.value = d.getMinutes()
            open()
        }

        function applyDate() {
            let d = selDay.toString().padStart(2, '0')
            let m = (selMonth + 1).toString().padStart(2, '0')
            let y = selYear
            let hh = hourSpin.value.toString().padStart(2, '0')
            let mm = minSpin.value.toString().padStart(2, '0')
            if (targetField) targetField.text = `${d}.${m}.${y} ${hh}:${mm}`
            close()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            Text {
                text: qsTr("Select date and time")
                font.bold: true
                font.pixelSize: 16
                color: "#172B4D"
                Layout.alignment: Qt.AlignHCenter
            }

            // Month and Year navigation
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: "<"
                    onClicked: {
                        if (dateTimePopup.curMonth === 0) {
                            dateTimePopup.curMonth = 11;
                            dateTimePopup.curYear--
                        } else {
                            dateTimePopup.curMonth--
                        }
                    }
                }
                Text {
                    text: dateTimePopup.monthNames[dateTimePopup.curMonth] + " " + dateTimePopup.curYear
                    font.bold: true
                    font.pixelSize: 14
                    color: "#172B4D"
                    Layout.preferredWidth: 120
                    horizontalAlignment: Text.AlignHCenter
                }
                Button {
                    text: ">"
                    onClicked: {
                        if (dateTimePopup.curMonth === 11) {
                            dateTimePopup.curMonth = 0;
                            dateTimePopup.curYear++
                        } else {
                            dateTimePopup.curMonth++
                        }
                    }
                }
            }

            // Days of the week header
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14
                Repeater {
                    model: [qsTr("Mon"), qsTr("Tue"), qsTr("Wed"), qsTr("Thu"), qsTr("Fri"), qsTr("Sat"), qsTr("Sun")]
                    Text {
                        text: modelData
                        font.bold: true
                        color: "#5E6C84"
                        font.pixelSize: 12
                        width: 26
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Calendar days grid
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: 42
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16

                        property int dayNum: index - dateTimePopup.firstDay + 1
                        property bool isValid: dayNum > 0 && dayNum <= dateTimePopup.daysInMonth
                        property bool isSelected: isValid && dayNum === dateTimePopup.selDay && dateTimePopup.curMonth === dateTimePopup.selMonth && dateTimePopup.curYear === dateTimePopup.selYear

                        color: isSelected ? "#0052CC" : (dayMouse.containsMouse && isValid ? "#DFE1E6" : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: isValid ? dayNum.toString() : ""
                            color: isSelected ? "white" : "#172B4D"
                            font.bold: isSelected
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: isValid
                            cursorShape: isValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (isValid) {
                                    dateTimePopup.selDay = dayNum
                                    dateTimePopup.selMonth = dateTimePopup.curMonth
                                    dateTimePopup.selYear = dateTimePopup.curYear
                                }
                            }
                        }
                    }
                }
            }

            // Time inputs
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 5
                Text { text: qsTr("Time:"); font.bold: true; color: "#172B4D" }
                SpinBox { id: hourSpin; from: 0; to: 23; Layout.preferredWidth: 90 }
                Text { text: ":" }
                SpinBox { id: minSpin; from: 0; to: 59; Layout.preferredWidth: 90 }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: qsTr("Cancel")
                    Layout.fillWidth: true
                    onClicked: dateTimePopup.close()
                }
                Button {
                    text: qsTr("Apply")
                    Layout.fillWidth: true
                    onClicked: dateTimePopup.applyDate()
                }
            }
        }
    }

    // Popup for editing an existing task
    Popup {
        id: taskPopup
        width: 400
        height: 380
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            radius: 10
            color: "white"
            border.color: "#C1C7D0"
        }

        property int currentTaskId: -1

        function openTask(id, title, deadline) {
            currentTaskId = id
            taskTitleEdit.text = title
            taskDeadlineEdit.text = deadline
            open()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                text: qsTr("Edit task")
                font.bold: true
                font.pixelSize: 18
                color: "#172B4D"
            }

            Text {
                text: qsTr("Title:")
                font.pixelSize: 14
                color: "#5E6C84"
            }
            TextArea {
                id: taskTitleEdit
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                wrapMode: Text.WordWrap
                background: Rectangle {
                    radius: 4
                    border.color: "#DFE1E6"
                    border.width: 1
                }
            }

            Text {
                text: qsTr("Deadline:")
                font.pixelSize: 14
                color: "#5E6C84"
            }

            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: taskDeadlineEdit
                    Layout.fillWidth: true
                    placeholderText: qsTr("No deadline")
                    readOnly: true
                    background: Rectangle {
                        radius: 4
                        border.color: "#DFE1E6"
                        border.width: 1
                    }
                }
                Button {
                    text: "📅"
                    Layout.preferredWidth: 40
                    onClicked: dateTimePopup.openPicker(taskDeadlineEdit)
                }
                Button {
                    text: "❌"
                    Layout.preferredWidth: 40
                    onClicked: taskDeadlineEdit.text = ""
                }
            }

            Item { Layout.fillHeight: true }

            Button {
                text: qsTr("Save")
                Layout.fillWidth: true
                onClicked: {
                    if (taskTitleEdit.text.trim() !== "") {
                        taskModel.updateTaskDetails(taskPopup.currentTaskId, taskTitleEdit.text.trim(), taskDeadlineEdit.text.trim())
                    }
                    taskPopup.close()
                }
            }
        }
    }

    // Main Kanban board area (horizontally scrollable)
    ScrollView {
        id: boardScroll
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        ScrollBar.horizontal.policy: ScrollBar.AsNeeded

        contentWidth: columnsRow.width

        // Enable horizontal scrolling with mouse wheel
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                let maxScroll = boardScroll.contentWidth - boardScroll.width
                if (maxScroll > 0) {
                    let newX = boardScroll.contentItem.contentX - wheel.angleDelta.y
                    boardScroll.contentItem.contentX = Math.max(0, Math.min(newX, maxScroll))
                }
            }
        }

        // Row containing all columns
        Row {
            id: columnsRow
            spacing: 20

            // Render each column from the model
            Repeater {
                model: taskModel.columns

                // Single column container
                Rectangle {
                    id: colRect
                    width: 320
                    height: root.height - header.height - 60
                    radius: 10
                    color: "#E2E4E9"

                    property string colName: modelData.name
                    property color accentColor: modelData.color
                    property string colDeadline: modelData.deadline
                    property bool showAddBox: false

                    HoverHandler { id: colHover }

                    // Handle drag-and-drop actions for cards
                    DropArea {
                        anchors.fill: parent
                        keys: ["taskCard"]
                        onDropped: (drop) => {
                            if (drop.source && drop.source.taskId !== undefined) {
                                taskModel.updateTaskColumn(drop.source.taskId, colRect.colName);
                            }
                        }
                    }

                    // Top colored accent line
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 5
                        radius: 10
                        color: accentColor
                    }

                    // Column header block
                    Column {
                        id: colHeaderWrapper
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: 15
                        anchors.leftMargin: 15
                        anchors.right: headerMenuBtn.left
                        spacing: 2

                        Text {
                            text: colName
                            font.pixelSize: 15
                            font.bold: true
                            color: "#172B4D"
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Rectangle {
                            visible: colRect.colDeadline !== ""
                            width: colDlText.contentWidth + 10
                            height: 18
                            radius: 4
                            color: "#DE350B"
                            Text {
                                id: colDlText
                                anchors.centerIn: parent
                                text: "⏳ " + colRect.colDeadline
                                font.pixelSize: 11
                                font.bold: true
                                color: "white"
                            }
                        }
                    }

                    // Column context menu trigger
                    Rectangle {
                        id: headerMenuBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: 32
                        height: 32
                        radius: 4
                        color: menuHover.hovered || colMenu.opened ? "#C1C7D0" : "transparent"
                        visible: colHover.hovered || colMenu.opened || colRect.colDeadline !== ""

                        Text {
                            anchors.centerIn: parent
                            text: "⋮"
                            font.pixelSize: 22
                            font.bold: true
                            color: "#5E6C84"
                            anchors.verticalCenterOffset: -2
                        }

                        HoverHandler { id: menuHover }
                        TapHandler { onTapped: colMenu.open() }

                        Menu {
                            id: colMenu
                            y: 32
                            MenuItem {
                                text: qsTr("Settings...")
                                onClicked: editPopup.open()
                            }
                            MenuItem {
                                text: qsTr("Delete column")
                                onClicked: taskModel.deleteColumn(colRect.colName)
                            }
                        }
                    }

                    // Popup for column settings
                    Popup {
                        id: editPopup
                        width: 280
                        height: 280
                        x: (colRect.width - width) / 2
                        y: 40
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        background: Rectangle {
                            radius: 8
                            color: "white"
                            border.color: "#C1C7D0"
                            border.width: 1
                        }

                        property string selectedColor: colRect.accentColor

                        onOpened: {
                            editNameInput.text = colRect.colName
                            editDeadlineInput.text = colRect.colDeadline
                            selectedColor = colRect.accentColor
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 12

                            Text {
                                text: qsTr("Column settings")
                                font.bold: true
                                color: "#172B4D"
                            }

                            TextField {
                                id: editNameInput
                                width: parent.width
                                placeholderText: qsTr("Column title")
                                background: Rectangle {
                                    radius: 4
                                    border.color: "#DFE1E6"
                                    border.width: 1
                                }
                            }

                            RowLayout {
                                width: parent.width
                                TextField {
                                    id: editDeadlineInput
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Deadline")
                                    readOnly: true
                                    background: Rectangle {
                                        radius: 4
                                        border.color: "#DFE1E6"
                                        border.width: 1
                                    }
                                }
                                Button {
                                    text: "📅"
                                    Layout.preferredWidth: 40
                                    onClicked: dateTimePopup.openPicker(editDeadlineInput)
                                }
                                Button {
                                    text: "❌"
                                    Layout.preferredWidth: 40
                                    onClicked: editDeadlineInput.text = ""
                                }
                            }

                            Row {
                                spacing: 8
                                Repeater {
                                    model: root.accents
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: modelData
                                        border.color: "#172B4D"
                                        border.width: editPopup.selectedColor === modelData ? 2 : 0
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: editPopup.selectedColor = modelData
                                        }
                                    }
                                }
                            }

                            Button {
                                text: qsTr("Save")
                                width: parent.width
                                onClicked: {
                                    if (editNameInput.text.trim() !== "") {
                                        taskModel.updateColumn(colRect.colName, editNameInput.text.trim(), editPopup.selectedColor, editDeadlineInput.text.trim())
                                        editPopup.close()
                                    }
                                }
                            }
                        }
                    }

                    // List of task cards within the column
                    ListView {
                        id: taskList
                        anchors.top: colHeaderWrapper.bottom
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 10
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        clip: true
                        model: taskModel

                        // Footer: "Add new card" section
                        footer: Column {
                            width: taskList.width
                            spacing: 5
                            topPadding: 10
                            bottomPadding: 10

                            Rectangle {
                                width: parent.width
                                height: 36
                                radius: 8
                                color: addBtnHover.hovered ? "#C1C7D0" : "transparent"
                                visible: !colRect.showAddBox

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    Text {
                                        text: "+"
                                        font.pixelSize: 18
                                        color: "#5E6C84"
                                    }
                                    Text {
                                        text: qsTr("Add card")
                                        font.pixelSize: 14
                                        color: "#5E6C84"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                HoverHandler { id: addBtnHover }
                                TapHandler { onTapped: colRect.showAddBox = true }
                            }

                            // Quick add task input box
                            Column {
                                width: parent.width
                                visible: colRect.showAddBox
                                spacing: 8

                                Rectangle {
                                    width: parent.width
                                    height: 60
                                    radius: 8
                                    color: "white"
                                    border.color: colRect.accentColor
                                    border.width: 2

                                    TextArea {
                                        id: newTaskInput
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        placeholderText: qsTr("What needs to be done?")
                                        wrapMode: Text.WordWrap
                                        background: Item {}
                                        Keys.onReturnPressed: (event) => {
                                            if (!(event.modifiers & Qt.ShiftModifier)) {
                                                if (text.trim() !== "") {
                                                    taskModel.addTask(text.trim(), colRect.colName)
                                                }
                                                text = ""
                                                colRect.showAddBox = false
                                                event.accepted = true
                                            }
                                        }
                                    }
                                }

                                Row {
                                    spacing: 8
                                    Button {
                                        text: qsTr("Add")
                                        onClicked: {
                                            if (newTaskInput.text.trim() !== "") {
                                                taskModel.addTask(newTaskInput.text.trim(), colRect.colName)
                                            }
                                            newTaskInput.text = ""
                                            colRect.showAddBox = false
                                        }
                                    }
                                    Button {
                                        text: qsTr("Cancel")
                                        onClicked: {
                                            newTaskInput.text = ""
                                            colRect.showAddBox = false
                                        }
                                    }
                                }
                            }
                        }

                        // Single task card visual representation
                        delegate: Item {
                            id: delegateRoot
                            width: ListView.view.width
                            property bool isMatch: model.columnName === colRect.colName
                            height: isMatch ? (cardVisual.implicitHeight + 10) : 0
                            visible: isMatch
                            property int taskId: model.id

                            property bool isRinging: root.ringingTaskId === model.id

                            Rectangle {
                                id: cardVisual
                                width: delegateRoot.width
                                implicitHeight: cardContent.height + 20
                                radius: 8
                                color: model.isCompleted ? "#F0F1F4" : "white"
                                border.color: cardHover.hovered ? "#8993A4" : "#C1C7D0"
                                border.width: 1

                                transform: Translate { id: shakeTransform }

                                // Setup drag-and-drop properties
                                Drag.active: dragMouseArea.drag.active
                                Drag.source: delegateRoot
                                Drag.keys: ["taskCard"]
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                states: [
                                    State {
                                        when: cardVisual.Drag.active
                                        ParentChange { target: cardVisual; parent: root.contentItem }
                                        PropertyChanges { target: cardVisual; opacity: 0.8; rotation: 3; border.color: colRect.accentColor; border.width: 2 }
                                    }
                                ]

                                // Shake animation for deadline alarm
                                SequentialAnimation {
                                    running: delegateRoot.isRinging
                                    loops: Animation.Infinite
                                    NumberAnimation { target: shakeTransform; property: "x"; to: 4; duration: 50 }
                                    NumberAnimation { target: shakeTransform; property: "x"; to: -4; duration: 50 }
                                    NumberAnimation { target: shakeTransform; property: "x"; to: 4; duration: 50 }
                                    NumberAnimation { target: shakeTransform; property: "x"; to: -4; duration: 50 }
                                    NumberAnimation { target: shakeTransform; property: "x"; to: 0; duration: 50 }
                                    PauseAnimation { duration: 800 }
                                }

                                // Red blinking border for alarm
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.color: "#DE350B"
                                    border.width: 3
                                    visible: delegateRoot.isRinging

                                    SequentialAnimation on opacity {
                                        running: delegateRoot.isRinging
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 0.2; to: 1.0; duration: 400 }
                                        NumberAnimation { from: 1.0; to: 0.2; duration: 400 }
                                    }
                                }

                                // Drag-and-drop logic for the task card
                                MouseArea {
                                    id: dragMouseArea
                                    anchors.fill: parent
                                    drag.target: cardVisual
                                    onClicked: taskPopup.openTask(model.id, model.title, model.deadline)
                                    onReleased: {
                                        if (drag.active) {
                                            cardVisual.Drag.drop()
                                            cardVisual.parent = delegateRoot
                                            cardVisual.x = 0
                                            cardVisual.y = 0
                                        }
                                    }
                                }

                                RowLayout {
                                    id: cardContent
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.topMargin: 10
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    CheckBox {
                                        Layout.alignment: Qt.AlignTop
                                        checked: model.isCompleted
                                        onToggled: {
                                            taskModel.toggleTaskCompletion(model.id, checked)
                                            if (checked) {
                                                doneSound.play()
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 5
                                        Text {
                                            Layout.fillWidth: true
                                            text: model.title
                                            font.pixelSize: 14
                                            wrapMode: Text.WordWrap
                                            color: model.isCompleted ? "#97A0AF" : "#172B4D"
                                            font.strikeout: model.isCompleted
                                        }

                                        Rectangle {
                                            visible: model.deadline !== ""
                                            Layout.preferredWidth: taskDlText.contentWidth + 10
                                            Layout.preferredHeight: 18
                                            radius: 4
                                            color: model.isCompleted ? "#DFE1E6" : (delegateRoot.isRinging ? "#DE350B" : "#FFAB00")
                                            Text {
                                                id: taskDlText
                                                anchors.centerIn: parent
                                                text: "⏳ " + model.deadline
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: model.isCompleted ? "#5E6C84" : "white"
                                            }
                                        }
                                    }

                                    // Delete card button
                                    Rectangle {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        radius: 4
                                        color: delHover.hovered ? "#FFEBE6" : "transparent"
                                        visible: cardHover.hovered

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            color: "#DE350B"
                                            font.pixelSize: 18
                                        }
                                        HoverHandler { id: delHover }
                                        TapHandler { onTapped: taskModel.deleteTask(model.id) }
                                    }
                                }
                                HoverHandler { id: cardHover }
                            }
                        }
                    }
                }
            }

            // "Add new column" block at the end of the board
            Rectangle {
                width: 320
                height: 50
                radius: 10
                color: "#00000010"
                border.color: "#00000020"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    TextField {
                        id: newColInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("New column...")
                        background: Item {}
                        Keys.onReturnPressed: (event) => {
                            if (text.trim() !== "") {
                                let nextColor = root.accents[taskModel.columns.length % root.accents.length]
                                taskModel.addColumn(text.trim(), nextColor)
                            }
                            text = ""
                            event.accepted = true
                        }
                    }
                    Button {
                        text: "+"
                        onClicked: {
                            if (newColInput.text.trim() !== "") {
                                let nextColor = root.accents[taskModel.columns.length % root.accents.length]
                                taskModel.addColumn(newColInput.text.trim(), nextColor)
                            }
                            newColInput.text = ""
                        }
                    }
                }
            }
        }
    }
}