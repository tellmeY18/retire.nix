import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // Which widget set shows where: ws 2 = work, ws 3 = media, any other = home.
    readonly property int ws: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int workWs: 2
    readonly property int mediaWs: 3

    // Live palette from ~/.local/state/theme/qs.json (written by `theme`).
    QtObject {
        id: pal
        property color bg: "#ffffff"
        property color fg: "#161616"
        property color rule: "#cccccc"
        property color mute: "#555555"
        property color tint: "#f5f5f5"
    }
    FileView {
        path: root.home + "/.local/state/theme/qs.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var t = JSON.parse(text());
                pal.bg = t.bg; pal.fg = t.fg; pal.rule = t.rule; pal.mute = t.mute; pal.tint = t.tint;
            } catch (e) {}
        }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // ── todo list (shared: the home card and the "next task" line) ───────
    property var todoItems: []
    FileView {
        id: todoFile
        path: root.home + "/.local/share/ink/todo.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.todoItems = text().split("\n").filter(function (l) { return l.trim() !== ""; })
    }
    function saveTodo(list) {
        root.todoItems = list;
        todoFile.setText(list.length ? list.join("\n") + "\n" : "");
    }

    // ── fast state (3 s): meters, network, top processes ─────────────────
    QtObject {
        id: sys
        property int cpu: 0
        property int mem: 0
        property int disk: 0
        property int temp: 0
        property int bat: 0
        property string status: ""
        property int ac: 0
        property string ssid: ""
        property int vol: 0
        property int muted: 0
        property int bright: 0
        property real rx: 0
        property real tx: 0
        property string uptime: ""
        property string kernel: ""
        property var top: []
    }

    // ── slow state (10 s): repo, units, pools, cluster, clipboard, ... ───
    QtObject {
        id: slow
        property string repoChange: ""
        property int repoFiles: 0
        property int failed: 0
        property int userFailed: 0
        property int dnd: 0
        property int night: 0
        property var zfs: []
        property var k8s: []
        property var clip: []
        property var shot: []
        property var bt: []
        property var tz: []
        property var cd: []
    }

    function apply(target, text, arrayKeys) {
        var arrs = {};
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var p = lines[i].indexOf("=");
            if (p < 1) continue;
            var k = lines[i].substring(0, p), v = lines[i].substring(p + 1);
            if (arrayKeys.indexOf(k) >= 0) {
                (arrs[k] = arrs[k] || []).push(v);
            } else if (k in target) {
                if (typeof target[k] === "string") target[k] = v;
                else target[k] = parseFloat(v) || 0;
            }
        }
        for (var j = 0; j < arrayKeys.length; j++) target[arrayKeys[j]] = arrs[arrayKeys[j]] || [];
    }

    // Download rate history for the sparkline.
    property var netHist: []
    property real netDown: 0
    property real netUp: 0
    property real lastRx: -1
    property real lastTx: 0
    property real lastT: 0
    function netSample() {
        var now = Date.now();
        if (lastRx >= 0 && now > lastT) {
            var dt = (now - lastT) / 1000;
            netDown = Math.max(0, (sys.rx - lastRx) / dt);
            netUp = Math.max(0, (sys.tx - lastTx) / dt);
            var h = netHist.concat([netDown]);
            if (h.length > 40) h = h.slice(h.length - 40);
            netHist = h;
        }
        lastRx = sys.rx; lastTx = sys.tx; lastT = now;
    }
    function rate(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s";
        if (b >= 1024) return Math.round(b / 1024) + " KB/s";
        return Math.round(b) + " B/s";
    }

    Process {
        id: statsProc
        command: [Quickshell.env("INK_STATS")]
        stdout: StdioCollector {
            onStreamFinished: { root.apply(sys, text, ["top"]); root.netSample(); }
        }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: if (!statsProc.running) statsProc.running = true
    }
    Process {
        id: slowProc
        command: [Quickshell.env("INK_SLOW")]
        stdout: StdioCollector {
            onStreamFinished: root.apply(slow, text, ["zfs", "k8s", "clip", "shot", "bt", "tz", "cd"])
        }
    }
    Timer {
        id: slowTimer
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: if (!slowProc.running) slowProc.running = true
    }
    Timer {
        id: slowSoon
        interval: 1200
        onTriggered: if (!slowProc.running) slowProc.running = true
    }

    // ── building blocks ──────────────────────────────────────────────────
    component Lbl: Text {
        color: pal.fg
        font.family: "sans-serif"
        font.pixelSize: 13
    }

    component Card: Rectangle {
        id: card
        default property alias content: col.data
        property string title: ""
        color: pal.bg
        border.color: pal.rule
        border.width: 1
        radius: 3
        implicitWidth: 300
        implicitHeight: col.implicitHeight + 24
        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 12 }
            spacing: 8
            Lbl {
                visible: card.title !== ""
                text: card.title
                color: pal.mute
                font.pixelSize: 11
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }
        }
    }

    component Meter: RowLayout {
        property string label
        property real value: 0
        property string suffix: "%"
        property int labelWidth: 38
        Layout.fillWidth: true
        spacing: 8
        Lbl { text: parent.label; color: pal.mute; Layout.preferredWidth: parent.labelWidth; elide: Text.ElideRight }
        Rectangle {
            Layout.fillWidth: true
            height: 6; radius: 3
            color: pal.tint
            border.color: pal.rule; border.width: 1
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, parent.parent.value / 100))
                height: parent.height; radius: 3
                color: pal.fg
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
        Lbl { text: parent.value + parent.suffix; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
    }

    component Slide: RowLayout {
        id: sl
        property string label
        property real value: 0
        signal picked(real v)
        Layout.fillWidth: true
        spacing: 8
        Lbl { text: sl.label; color: pal.mute; Layout.preferredWidth: 38 }
        Rectangle {
            Layout.fillWidth: true
            height: 14; radius: 3
            color: pal.tint
            border.color: pal.rule; border.width: 1
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, sl.value / 100))
                height: parent.height; radius: 3; color: pal.fg
            }
            MouseArea {
                anchors.fill: parent
                onPressed: (m) => sl.picked(Math.max(0, Math.min(1, m.x / width)))
                onPositionChanged: (m) => { if (pressed) sl.picked(Math.max(0, Math.min(1, m.x / width))) }
            }
        }
        Lbl { text: Math.round(sl.value) + "%"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
    }

    component Btn: Rectangle {
        id: b
        property string label
        property bool on: false
        signal clicked()
        implicitHeight: 26
        implicitWidth: t.implicitWidth + 20
        radius: 3
        color: (ma.containsMouse || on) ? pal.fg : pal.bg
        border.color: pal.rule; border.width: 1
        Lbl { id: t; anchors.centerIn: parent; text: b.label; color: (ma.containsMouse || b.on) ? pal.bg : pal.fg }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }
    }

    // A widget set: fades in/out with the workspace.
    component Panel: PanelWindow {
        id: panel
        property bool shown: true
        property bool atRight: false
        default property alias content: body.data
        anchors { top: true; left: !atRight; right: atRight }
        margins { top: 48; left: 16; right: 16 }
        implicitWidth: body.implicitWidth
        implicitHeight: body.implicitHeight
        visible: shown || body.opacity > 0.01
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "ink-widgets"
        RowLayout {
            id: body
            spacing: 12
            opacity: panel.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }
    }

    // ── shared media player pick (ignores the playerctld proxy) ──────────
    readonly property var player: {
        var ps = Mpris.players.values.filter(function (p) { return p.dbusName.indexOf("playerctld") < 0; });
        for (var i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i];
        return ps.length ? ps[0] : null;
    }

    // ════════════════════════ HOME (any other workspace) ══════════════════
    Panel {
        shown: root.ws !== root.workWs && root.ws !== root.mediaWs

        // column 1: clock, calendar, todo, world clocks
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Card {
                Lbl {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: 56
                    font.weight: Font.Medium
                }
                Lbl {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                    color: pal.mute
                    font.pixelSize: 14
                }
                Lbl {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: pal.mute
                    text: root.todoItems.length ? "next · " + root.todoItems[0] : "nothing on the list"
                }
            }

            Card {
                title: Qt.formatDateTime(clock.date, "MMMM yyyy")
                Grid {
                    id: cal
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 2
                    Layout.alignment: Qt.AlignHCenter
                    readonly property var cells: {
                        var d = clock.date;
                        var first = new Date(d.getFullYear(), d.getMonth(), 1);
                        var off = (first.getDay() + 6) % 7;
                        var n = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
                        var out = ["M", "T", "W", "T", "F", "S", "S"];
                        for (var i = 0; i < off; i++) out.push("");
                        for (var j = 1; j <= n; j++) out.push(j);
                        return out;
                    }
                    Repeater {
                        model: cal.cells
                        Rectangle {
                            required property var modelData
                            required property int index
                            width: 38; height: 24; radius: 3
                            color: modelData === clock.date.getDate() && index >= 7 ? pal.fg : "transparent"
                            Lbl {
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: parent.index < 7 ? pal.mute
                                    : (parent.modelData === clock.date.getDate() ? pal.bg : pal.fg)
                                font.pixelSize: parent.index < 7 ? 11 : 13
                            }
                        }
                    }
                }
            }

            Card {
                title: "todo"
                Repeater {
                    model: root.todoItems
                    RowLayout {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        Lbl { text: "–"; color: pal.mute }
                        Lbl { text: parent.modelData; Layout.fillWidth: true; elide: Text.ElideRight }
                        Lbl {
                            text: "×"; color: pal.mute
                            MouseArea {
                                anchors { fill: parent; margins: -4 }
                                onClicked: {
                                    var l = root.todoItems.slice();
                                    l.splice(parent.parent.index, 1);
                                    root.saveTodo(l);
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 28; radius: 3
                    color: pal.tint
                    border.color: pal.rule; border.width: 1
                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: pal.fg
                        font.family: "sans-serif"; font.pixelSize: 13
                        clip: true
                        onAccepted: {
                            if (text.trim() === "") return;
                            root.saveTodo(root.todoItems.concat([text.trim()]));
                            text = "";
                        }
                    }
                    Lbl {
                        visible: input.text === ""
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        text: "add a task, press enter"
                        color: pal.mute
                    }
                }
            }

            Card {
                visible: slow.tz.length > 0 || slow.cd.length > 0
                title: "world"
                Repeater {
                    model: slow.tz
                    RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Lbl { text: parent.modelData.split("|")[0]; color: pal.mute; Layout.fillWidth: true }
                        Lbl { text: parent.modelData.split("|")[1] }
                    }
                }
                Repeater {
                    model: slow.cd
                    RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Lbl { text: parent.modelData.split("|")[0]; color: pal.mute; Layout.fillWidth: true }
                        Lbl { text: parent.modelData.split("|")[1] + " days" }
                    }
                }
            }
        }

        // column 2: system, battery, network + sound, media, launchers
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Card {
                title: "system"
                Meter { label: "cpu"; value: sys.cpu }
                Meter { label: "mem"; value: sys.mem }
                Meter { label: "disk"; value: sys.disk }
                Meter { label: "temp"; value: sys.temp; suffix: "°" }
                Lbl { text: "up " + sys.uptime.replace(/^up /, "") + " · " + sys.kernel; color: pal.mute; font.pixelSize: 11 }
            }

            Card {
                title: "battery"
                Meter { label: sys.status === "" ? "bat" : sys.status; value: sys.bat; labelWidth: 84 }
                Lbl {
                    text: sys.ac === 1 ? "charger connected" : "on battery"
                    color: pal.mute
                }
            }

            Card {
                title: "network + sound"
                Lbl { text: sys.ssid !== "" ? "wifi · " + sys.ssid : "offline" }
                Slide {
                    label: sys.muted === 1 ? "muted" : "vol"
                    value: sys.vol
                    onPicked: (v) => {
                        sys.vol = Math.round(v * 100);
                        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]);
                    }
                }
                Slide {
                    label: "light"
                    value: sys.bright
                    onPicked: (v) => {
                        var p = Math.max(1, Math.round(v * 100));
                        sys.bright = p;
                        Quickshell.execDetached(["brightnessctl", "set", p + "%"]);
                    }
                }
            }

            Card {
                title: "now playing"
                Lbl {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackTitle || "unknown") : "nothing playing"
                }
                Lbl {
                    visible: root.player !== null
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: pal.mute
                    text: root.player ? root.player.trackArtist : ""
                }
                RowLayout {
                    visible: root.player !== null
                    spacing: 6
                    Btn { label: "prev"; onClicked: root.player.previous() }
                    Btn { label: root.player && root.player.isPlaying ? "pause" : "play"; onClicked: root.player.togglePlaying() }
                    Btn { label: "next"; onClicked: root.player.next() }
                }
            }

            Card {
                title: "launch"
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Btn { label: "firefox"; onClicked: Quickshell.execDetached(["firefox"]) }
                    Btn { label: "terminal"; onClicked: Quickshell.execDetached(["kitty"]) }
                    Btn { label: "files"; onClicked: Quickshell.execDetached(["thunar"]) }
                    Btn { label: "signal"; onClicked: Quickshell.execDetached(["flare"]) }
                    Btn { label: "lock"; onClicked: Quickshell.execDetached(["loginctl", "lock-session"]) }
                    Btn { label: "power"; onClicked: Quickshell.execDetached(["power-menu"]) }
                }
            }
        }
    }

    // ════════════════════════ WORK (workspace 2) ═════════════════════════
    Panel {
        shown: root.ws === root.workWs

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Card {
                title: "nix-config · jj"
                Lbl {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: slow.repoChange !== "" ? slow.repoChange : "no repo"
                }
                Lbl {
                    color: pal.mute
                    text: slow.repoFiles === 0 ? "working copy clean" : slow.repoFiles + " changed files"
                }
            }

            Card {
                title: "health"
                RowLayout {
                    Layout.fillWidth: true
                    Lbl { text: "failed units"; color: pal.mute; Layout.fillWidth: true }
                    Lbl { text: slow.failed + " system · " + slow.userFailed + " user" }
                }
                Repeater {
                    model: slow.zfs
                    RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Lbl { text: "zfs " + parent.modelData.split(" ")[0]; color: pal.mute; Layout.fillWidth: true }
                        Lbl { text: parent.modelData.split(" ")[1].toLowerCase() }
                    }
                }
            }

            Card {
                title: "k3s nodes"
                Lbl { visible: slow.k8s.length === 0; text: "no cluster reachable"; color: pal.mute }
                Repeater {
                    model: slow.k8s
                    RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Lbl { text: parent.modelData.split(" ")[0]; Layout.fillWidth: true }
                        Lbl {
                            text: parent.modelData.split(" ")[1]
                            color: parent.modelData.split(" ")[1] === "Ready" ? pal.mute : pal.fg
                            font.weight: parent.modelData.split(" ")[1] === "Ready" ? Font.Normal : Font.Bold
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Card {
                id: pomo
                title: "pomodoro"
                implicitWidth: 340
                property bool onBreak: false
                property bool running: false
                property int remaining: 25 * 60
                readonly property int total: onBreak ? 5 * 60 : 25 * 60
                Lbl {
                    text: Math.floor(pomo.remaining / 60).toString().padStart(2, "0") + ":" + (pomo.remaining % 60).toString().padStart(2, "0")
                    font.pixelSize: 48
                    font.weight: Font.Medium
                }
                Meter { label: pomo.onBreak ? "break" : "focus"; value: 100 * (pomo.total - pomo.remaining) / pomo.total }
                RowLayout {
                    spacing: 6
                    Btn { label: pomo.running ? "pause" : "start"; onClicked: pomo.running = !pomo.running }
                    Btn { label: "reset"; onClicked: { pomo.running = false; pomo.remaining = pomo.total; } }
                    Btn { label: pomo.onBreak ? "to focus" : "to break"; onClicked: { pomo.running = false; pomo.onBreak = !pomo.onBreak; pomo.remaining = pomo.total; } }
                }
                Timer {
                    interval: 1000; repeat: true; running: pomo.running
                    onTriggered: {
                        pomo.remaining -= 1;
                        if (pomo.remaining <= 0) {
                            Quickshell.execDetached(["notify-send", "-a", "pomodoro", pomo.onBreak ? "break over" : "time for a break", pomo.onBreak ? "back to focus" : "25 minutes done"]);
                            pomo.onBreak = !pomo.onBreak;
                            pomo.remaining = pomo.total;
                        }
                    }
                }
            }

            Card {
                title: "notes"
                implicitWidth: 340
                FileView {
                    id: notesFile
                    path: root.home + "/.local/share/ink/notes.txt"
                    printErrors: false
                    onLoaded: if (!notes.activeFocus) notes.text = text()
                }
                Timer { id: notesSave; interval: 800; onTriggered: notesFile.setText(notes.text) }
                Rectangle {
                    Layout.fillWidth: true
                    height: 220; radius: 3
                    color: pal.tint
                    border.color: pal.rule; border.width: 1
                    TextEdit {
                        id: notes
                        anchors { fill: parent; margins: 8 }
                        color: pal.fg
                        font.family: "sans-serif"; font.pixelSize: 13
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        clip: true
                        onTextChanged: if (activeFocus) notesSave.restart()
                    }
                    Lbl {
                        visible: notes.text === ""
                        anchors { left: parent.left; top: parent.top; margins: 8 }
                        text: "scratch notes, saved automatically"
                        color: pal.mute
                    }
                }
            }
        }
    }

    // ════════════════════════ MEDIA (workspace 3) ════════════════════════
    Panel {
        shown: root.ws === root.mediaWs

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Card {
                id: np
                title: "now playing"
                implicitWidth: 420
                RowLayout {
                    spacing: 12
                    Rectangle {
                        width: 120; height: 120; radius: 3
                        color: pal.tint
                        border.color: pal.rule; border.width: 1
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: root.player ? root.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Lbl {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: 18
                            font.weight: Font.Medium
                            text: root.player ? (root.player.trackTitle || "unknown") : "nothing playing"
                        }
                        Lbl {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: pal.mute
                            text: root.player ? root.player.trackArtist : ""
                        }
                        Lbl {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: pal.mute
                            font.pixelSize: 11
                            text: root.player ? root.player.trackAlbum : ""
                        }
                        RowLayout {
                            visible: root.player !== null
                            spacing: 6
                            Btn { label: "prev"; onClicked: root.player.previous() }
                            Btn { label: root.player && root.player.isPlaying ? "pause" : "play"; onClicked: root.player.togglePlaying() }
                            Btn { label: "next"; onClicked: root.player.next() }
                        }
                    }
                }
                Rectangle {
                    visible: root.player !== null && root.player.lengthSupported
                    Layout.fillWidth: true
                    height: 8; radius: 4
                    color: pal.tint
                    border.color: pal.rule; border.width: 1
                    Rectangle {
                        height: parent.height; radius: 4; color: pal.fg
                        width: root.player && root.player.length > 0
                            ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: (m) => {
                            if (root.player && root.player.canSeek)
                                root.player.position = (m.x / width) * root.player.length;
                        }
                    }
                }
                Timer {
                    interval: 1000; repeat: true
                    running: root.player !== null && root.player.isPlaying && np.visible
                    onTriggered: root.player.positionChanged()
                }
            }

            Card {
                id: viz
                title: "visualiser"
                implicitWidth: 420
                property var bars: []
                Process {
                    command: [Quickshell.env("INK_CAVA"), "-p", Quickshell.env("INK_CAVA_CONF")]
                    running: root.ws === root.mediaWs && root.player !== null && root.player.isPlaying
                    stdout: SplitParser {
                        onRead: (line) => {
                            var v = line.split(";").filter(function (s) { return s !== ""; }).map(Number);
                            if (v.length) viz.bars = v;
                        }
                    }
                }
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 80
                    spacing: 3
                    Repeater {
                        model: viz.bars.length > 0 ? viz.bars : new Array(32).fill(0)
                        Item {
                            required property var modelData
                            width: 9; height: 80
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                radius: 2
                                color: pal.fg
                                height: Math.max(2, parent.height * parent.modelData / 100)
                                Behavior on height { NumberAnimation { duration: 80 } }
                            }
                        }
                    }
                }
            }

            Card {
                title: "sound"
                implicitWidth: 420
                PwObjectTracker { objects: Pipewire.nodes.values }
                Slide {
                    label: sys.muted === 1 ? "muted" : "vol"
                    value: sys.vol
                    onPicked: (v) => {
                        sys.vol = Math.round(v * 100);
                        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]);
                    }
                }
                Lbl { text: "output"; color: pal.mute; font.pixelSize: 11 }
                Repeater {
                    model: Pipewire.nodes.values.filter(function (n) { return n.isSink && !n.isStream && n.audio; })
                    Btn {
                        required property var modelData
                        Layout.fillWidth: true
                        label: modelData.nickname || modelData.description || modelData.name
                        on: Pipewire.defaultAudioSink === modelData
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }
        }
    }

    // ═══════════════ UTILITY (right side, every workspace) ═══════════════
    Panel {
        atRight: true

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Card {
                title: "toggles"
                RowLayout {
                    spacing: 6
                    Btn {
                        label: "night light"; on: slow.night === 1
                        onClicked: { Quickshell.execDetached(["nightlight"]); slowSoon.restart(); }
                    }
                    Btn {
                        label: "do not disturb"; on: slow.dnd === 1
                        onClicked: { Quickshell.execDetached(["dunstctl", "set-paused", "toggle"]); slowSoon.restart(); }
                    }
                }
            }

            Card {
                title: "network"
                RowLayout {
                    Layout.fillWidth: true
                    Lbl { text: "↓ " + root.rate(root.netDown); Layout.fillWidth: true }
                    Lbl { text: "↑ " + root.rate(root.netUp); color: pal.mute }
                }
                Canvas {
                    id: spark
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    Connections { target: root; function onNetHistChanged() { spark.requestPaint(); } }
                    onPaint: {
                        var c = getContext("2d");
                        c.clearRect(0, 0, width, height);
                        var h = root.netHist;
                        if (h.length < 2) return;
                        var max = Math.max.apply(null, h.concat([10240]));
                        c.strokeStyle = pal.fg;
                        c.lineWidth = 1.5;
                        c.beginPath();
                        for (var i = 0; i < h.length; i++) {
                            var x = i * width / 39;
                            var y = height - 2 - (height - 4) * h[i] / max;
                            if (i === 0) c.moveTo(x, y); else c.lineTo(x, y);
                        }
                        c.stroke();
                    }
                }
            }

            Card {
                title: "top processes"
                Repeater {
                    model: sys.top
                    RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Lbl { text: parent.modelData.substring(0, parent.modelData.lastIndexOf(" ")); Layout.fillWidth: true; elide: Text.ElideRight }
                        Lbl { text: parent.modelData.substring(parent.modelData.lastIndexOf(" ") + 1); color: pal.mute }
                    }
                }
            }

            Card {
                title: "bluetooth"
                Lbl { visible: slow.bt.length === 0; text: "no paired devices"; color: pal.mute }
                Repeater {
                    model: slow.bt
                    RowLayout {
                        required property string modelData
                        readonly property var f: modelData.split("|")
                        Layout.fillWidth: true
                        Lbl { text: parent.f[1]; Layout.fillWidth: true; elide: Text.ElideRight }
                        Btn {
                            label: parent.f[2] === "1" ? "disconnect" : "connect"
                            on: parent.f[2] === "1"
                            onClicked: {
                                Quickshell.execDetached(["bluetoothctl", parent.f[2] === "1" ? "disconnect" : "connect", parent.f[0]]);
                                slowSoon.restart();
                            }
                        }
                    }
                }
            }

            Card {
                title: "clipboard"
                Lbl { visible: slow.clip.length === 0; text: "empty"; color: pal.mute }
                Repeater {
                    model: slow.clip
                    Lbl {
                        required property string modelData
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: modelData.substring(modelData.indexOf("\t") + 1)
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.execDetached(["sh", "-c", "cliphist decode '" + parent.modelData.split("\t")[0] + "' | wl-copy"])
                        }
                    }
                }
            }

            Card {
                title: "recent screenshots"
                visible: slow.shot.length > 0
                Row {
                    spacing: 6
                    Repeater {
                        model: slow.shot
                        Rectangle {
                            required property string modelData
                            width: 88; height: 56; radius: 3
                            color: pal.tint
                            border.color: pal.rule; border.width: 1
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: "file://" + parent.modelData
                                sourceSize: Qt.size(176, 112)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xdg-open", parent.modelData]) }
                        }
                    }
                }
            }
        }
    }
}
