import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

Item {
    id: root

    readonly property string binPath: (Quickshell.env("HOME") || "") + "/.local/bin/sysupdate"
    property bool busy: false
    property string status: "Loading…"
    property string logText: ""

    ListModel { id: tasks }

    Component.onCompleted: loadList()

    function loadList() {
        if (!binPath || binPath.charAt(0) !== "/") {
            status = "Cannot find sysupdate"
            logText = "Expected ~/.local/bin/sysupdate"
            return
        }
        busy = true
        status = "Loading…"
        Proc.runCommand("sysupdate.list", [binPath, "list", "--json"], (stdout, exitCode) => {
            busy = false
            if (exitCode !== 0) {
                status = "Could not list updates"
                logText = stdout || (binPath + " failed")
                return
            }
            applyTasks(stdout, "Ready")
        }, 0, 15000)
    }

    function check() {
        busy = true
        status = "Checking…"
        logText = ""
        Proc.runCommand("sysupdate.check", [binPath, "check", "--json"], (stdout, exitCode) => {
            busy = false
            if (exitCode !== 0) {
                status = "Check failed"
                logText = stdout || "sysupdate check failed"
                return
            }
            applyTasks(stdout, "Checked")
        }, 0, 180000)
    }

    function applyTasks(stdout, nextStatus) {
        try {
            const data = JSON.parse(stdout)
            tasks.clear()
            const rows = data.tasks || []
            for (let i = 0; i < rows.length; i++) {
                const row = rows[i]
                tasks.append({
                    taskId: row.id || "",
                    taskName: row.name || "",
                    taskDetail: row.detail || "",
                    taskSummary: row.summary || ""
                })
            }
            status = nextStatus
            logText = rows.length + " updaters"
        } catch (e) {
            status = "Bad report"
            logText = stdout || String(e)
        }
    }

    function openRun(id) {
        status = id === "all" ? "Opening Update all…" : "Opening…"
        Proc.runCommand("sysupdate.open." + id, [binPath, "open", id], (stdout, exitCode) => {
            if (exitCode !== 0) {
                status = "Could not open a terminal"
                logText = stdout || "wezterm did not start"
                return
            }
            status = "Opened in WezTerm"
            logText = id === "all" ? "Update all is running in a terminal." : "Running in a terminal."
        }, 0, 8000)
    }

    DankFlickable {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingL
        anchors.rightMargin: Theme.spacingL
        clip: true
        contentWidth: width
        contentHeight: page.implicitHeight + Theme.spacingXL

        Column {
            id: page
            width: Math.min(620, parent.width)
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: Theme.spacingM
            spacing: Theme.spacingM

            StyledText {
                width: parent.width
                text: "Updates"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
            }

            StyledText {
                width: parent.width
                text: "Replaces the built-in system updater. A run opens WezTerm, so yay and the others can ask before they change anything."
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: Theme.spacingS

                Rectangle {
                    width: 88
                    height: 32
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHighest
                    border.color: Theme.outlineMedium
                    border.width: Theme.layerOutlineWidth
                    StyledText {
                        anchors.centerIn: parent
                        text: "Check"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.check()
                    }
                }

                Rectangle {
                    width: 110
                    height: 32
                    radius: Theme.cornerRadius
                    color: Theme.primary
                    StyledText {
                        anchors.centerIn: parent
                        text: "Update all"
                        color: Theme.primaryText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openRun("all")
                    }
                }
            }

            StyledText {
                width: parent.width
                text: root.status
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }

            StyledText {
                width: parent.width
                visible: root.logText !== ""
                text: root.logText
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: tasks

                Rectangle {
                    required property string taskId
                    required property string taskName
                    required property string taskDetail
                    required property string taskSummary

                    width: page.width
                    implicitHeight: row.implicitHeight + Theme.spacingS * 2
                    height: implicitHeight
                    radius: Theme.cornerRadius
                    color: Theme.floatingWindowNestedSurface
                    border.color: Theme.outlineMedium
                    border.width: Theme.layerOutlineWidth

                    Row {
                        id: row
                        width: parent.width - Theme.spacingM * 2
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        Column {
                            width: parent.width - 88
                            spacing: 2
                            StyledText {
                                width: parent.width
                                text: taskName
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }
                            StyledText {
                                width: parent.width
                                text: taskSummary
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                            StyledText {
                                width: parent.width
                                text: taskDetail
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            width: 72
                            height: 32
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHighest
                            border.color: Theme.outlineMedium
                            border.width: Theme.layerOutlineWidth
                            anchors.verticalCenter: parent.verticalCenter
                            StyledText {
                                anchors.centerIn: parent
                                text: "Run"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.busy
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openRun(taskId)
                            }
                        }
                    }
                }
            }
        }
    }
}
