#!/usr/bin/env python3
"""Add a Max button to the DMS battery profile row.

DMS only ships Power Saver / Balanced / Performance. This patches a
materialized shell tree (DMS_SHELL_DIR) so the battery popout and the
control-center battery detail can launch battery-plan.sh.
"""

from __future__ import annotations

import sys
from pathlib import Path

MARKER = "maxBatteryScript"

POPOUT_FUNCS = """\
    function setProfile(profile) {
        if (PowerProfileWatcher.applyProfile(profile))
            return;

        if (!PowerProfileWatcher.available)
            ToastService.showError(I18n.tr("power-profiles-daemon not available"));
        else
            ToastService.showError(I18n.tr("Failed to set power profile"));
    }
"""

POPOUT_FUNCS_NEW = """\
    function setProfile(profile) {
        if (PowerProfileWatcher.applyProfile(profile))
            return;

        if (!PowerProfileWatcher.available)
            ToastService.showError(I18n.tr("power-profiles-daemon not available"));
        else
            ToastService.showError(I18n.tr("Failed to set power profile"));
    }

    readonly property string maxBatteryScript: Quickshell.env("HOME") + "/.config/scripts/battery-plan.sh"
    property bool maxBatteryActive: false

    function profileArg(profile) {
        if (profile === PowerProfile.PowerSaver)
            return "power-saver";
        if (profile === PowerProfile.Performance)
            return "performance";
        return "balanced";
    }

    function chooseProfile(choice) {
        if (choice === "max") {
            maxBatteryProc.command = [maxBatteryScript, "max"];
            maxBatteryProc.running = true;
            maxBatteryActive = true;
            return;
        }
        if (maxBatteryActive) {
            maxBatteryActive = false;
            maxBatteryProc.command = [maxBatteryScript, profileArg(choice)];
            maxBatteryProc.running = true;
            return;
        }
        setProfile(choice);
    }

    Process {
        id: maxBatteryProc

        onExited: maxPlanState.reload()
    }

    FileView {
        id: maxPlanState

        path: Quickshell.env("HOME") + "/.local/state/battery-plan/saved"
        watchChanges: true
        onLoaded: root.maxBatteryActive = text().includes("active=1")
        onLoadFailed: root.maxBatteryActive = false
    }
"""

POPOUT_GROUP = """\
                    DankButtonGroup {
                        id: profileButtonGroup

                        property var profileModel: PowerProfileWatcher.availableProfiles
                        property int currentProfileIndex: {
                            if (typeof PowerProfiles === "undefined")
                                return 1;
                            return profileModel.findIndex(profile => root.isActiveProfile(profile));
                        }

                        scale: Math.min(1, parent.width / implicitWidth)
                        transformOrigin: Item.Center
                        anchors.horizontalCenter: parent.horizontalCenter
                        model: profileModel.map(profile => Theme.getPowerProfileLabel(profile))
                        currentIndex: currentProfileIndex
                        selectionMode: "single"
                        onSelectionChanged: (index, selected) => {
                            if (!selected)
                                return;
                            root.setProfile(profileModel[index]);
                        }
                    }
"""

POPOUT_GROUP_NEW = """\
                    DankButtonGroup {
                        id: profileButtonGroup

                        property var profileModel: ["max"].concat(PowerProfileWatcher.availableProfiles)
                        property int currentProfileIndex: {
                            if (root.maxBatteryActive)
                                return 0;
                            if (typeof PowerProfiles === "undefined")
                                return 2;
                            const idx = profileModel.findIndex(profile => profile !== "max" && root.isActiveProfile(profile));
                            return idx < 0 ? 1 : idx;
                        }

                        scale: Math.min(1, parent.width / implicitWidth)
                        transformOrigin: Item.Center
                        anchors.horizontalCenter: parent.horizontalCenter
                        model: profileModel.map(profile => profile === "max" ? "Max" : Theme.getPowerProfileLabel(profile))
                        currentIndex: currentProfileIndex
                        selectionMode: "single"
                        onSelectionChanged: (index, selected) => {
                            if (!selected)
                                return;
                            root.chooseProfile(profileModel[index]);
                        }
                    }
"""

DETAIL_FUNCS = """\
    function setProfile(profile) {
        if (PowerProfileWatcher.applyProfile(profile))
            return;

        if (!PowerProfileWatcher.available)
            ToastService.showError(I18n.tr("power-profiles-daemon not available"));
        else
            ToastService.showError(I18n.tr("Failed to set power profile"));
    }
"""

DETAIL_FUNCS_NEW = POPOUT_FUNCS_NEW

DETAIL_GROUP = """\
        DankButtonGroup {
            property var profileModel: PowerProfileWatcher.availableProfiles
            property int currentProfileIndex: {
                if (typeof PowerProfiles === "undefined")
                    return 1;
                return profileModel.findIndex(profile => isActiveProfile(profile));
            }

            model: profileModel.map(profile => Theme.getPowerProfileLabel(profile))
            currentIndex: currentProfileIndex
            selectionMode: "single"
            anchors.horizontalCenter: parent.horizontalCenter
            onSelectionChanged: (index, selected) => {
                if (!selected)
                    return;
                setProfile(profileModel[index]);
            }
        }
"""

DETAIL_GROUP_NEW = """\
        Item {
            width: parent.width
            height: profileButtonGroup.height * profileButtonGroup.scale

            DankButtonGroup {
                id: profileButtonGroup

                property var profileModel: ["max"].concat(PowerProfileWatcher.availableProfiles)
                property int currentProfileIndex: {
                    if (root.maxBatteryActive)
                        return 0;
                    if (typeof PowerProfiles === "undefined")
                        return 2;
                    const idx = profileModel.findIndex(profile => profile !== "max" && root.isActiveProfile(profile));
                    return idx < 0 ? 1 : idx;
                }

                scale: Math.min(1, parent.width / implicitWidth)
                transformOrigin: Item.Center
                anchors.horizontalCenter: parent.horizontalCenter
                model: profileModel.map(profile => profile === "max" ? "Max" : Theme.getPowerProfileLabel(profile))
                currentIndex: currentProfileIndex
                selectionMode: "single"
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    root.chooseProfile(profileModel[index]);
                }
            }
        }
"""


def patch(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text()
    if old not in text:
        if MARKER in text and new.strip()[:40] in text or MARKER in text:
            print(f"already patched: {label}")
            return
        raise SystemExit(f"pattern not found in {path} ({label})")
    path.write_text(text.replace(old, new, 1))
    print(f"patched: {label}")


def ensure_import(path: Path, line: str) -> None:
    text = path.read_text()
    lines = text.splitlines()
    if line in lines:
        return
    try:
        anchor = lines.index("import QtQuick")
    except ValueError:
        raise SystemExit(f"no import anchor in {path}") from None
    lines.insert(anchor + 1, line)
    path.write_text("\n".join(lines) + ("\n" if text.endswith("\n") else ""))


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {sys.argv[0]} SHELL_DIR")
    root = Path(sys.argv[1])
    popout = root / "Modules/DankBar/Popouts/BatteryPopout.qml"
    detail = root / "Modules/ControlCenter/Details/BatteryDetail.qml"
    if not popout.is_file() or not detail.is_file():
        raise SystemExit(f"not a DMS shell tree: {root}")

    ensure_import(popout, "import Quickshell.Io")
    ensure_import(detail, "import Quickshell")
    ensure_import(detail, "import Quickshell.Io")

    popout_text = popout.read_text()
    if "popupWidth: 400" in popout_text:
        popout.write_text(popout_text.replace("popupWidth: 400", "popupWidth: 470", 1))

    patch(popout, POPOUT_FUNCS, POPOUT_FUNCS_NEW, "popout functions")
    patch(popout, POPOUT_GROUP, POPOUT_GROUP_NEW, "popout buttons")
    patch(detail, DETAIL_FUNCS, DETAIL_FUNCS_NEW, "detail functions")
    patch(detail, DETAIL_GROUP, DETAIL_GROUP_NEW, "detail buttons")


if __name__ == "__main__":
    main()
