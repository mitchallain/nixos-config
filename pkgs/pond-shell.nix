# pkgs/pond-shell.nix - Pond OS Quickshell sidebar adapted for NixOS + Niri
# https://github.com/bflycomputer/pond-interface
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  networkmanager,
  iw,
  ddcutil,
  brightnessctl,
  fastfetch,
  swaylock,
  procps,
  coreutils,
  xkeyboard_config,
  tzdata,
}:

let
  pythonEnv = python3.withPackages (ps: [
    ps.pygobject3
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "pond-shell";
  version = "0.1.11";

  src = fetchFromGitHub {
    owner = "bflycomputer";
    repo = "pond-interface";
    rev = "b652dd48abaf965b56295dae9bd093ae8ade0ae6";
    hash = "sha256-XreRqDX/v5AvLPh2IPLLNEv9e2qF8CRqk417NbL7BwI=";
  };

  dontConfigure = true;
  dontBuild = true;

  postPatch = ''
    # Remove __pycache__ artifact committed upstream
    rm -rf shell/settings/information/__pycache__

    # 1. Decouple shell.qml from Pond.Wallpaper (we use swaybg) and disable first-run manual popup
    substituteInPlace shell/shell.qml \
      --replace-fail 'import Pond.Wallpaper as Wallpaper' "" \
      --replace-fail 'Settings.State.open("", "manual");' ""
    ${pythonEnv}/bin/python3 - <<'EOF'
    from pathlib import Path
    import re

    p = Path("shell/shell.qml")
    s = p.read_text()
    s = re.sub(r"Wallpaper\.Window\s*\{[^}]*\}\s*", "", s)
    # Only instantiate the sidebar on the leftmost monitor (so dual monitors don't have a bar in the center seam),
    # while keeping Settings.Window available on every monitor so Mod+Comma works on whichever screen is focused.
    s = s.replace(
        "model: Quickshell.screens",
        "model: { const s = Quickshell.screens.slice(); s.sort((a, b) => a.x - b.x || a.y - b.y); return s.slice(0, 1); }",
    )
    old_settings_win = "      Settings.Window { menuScreen: modelData }\n    }\n  }"
    new_settings_win = """    }
      }

      Variants {
        model: Quickshell.screens
        delegate: Settings.Window {
          required property var modelData
          menuScreen: modelData
        }
      }"""
    assert old_settings_win in s, "old_settings_win not found"
    s = s.replace(old_settings_win, new_settings_win)
    p.write_text(s)

    p = Path("shell/Sidebar.qml")
    s = p.read_text()
    s = s.replace("import Pond.Screenshot as Screenshot\n", "")
    s = re.sub(r"Screenshot\.Preview\s*\{[^}]*\}\s*", "", s)
    s = s.replace('if (outputName !== root.screen.name) return;', "")
    s = s.replace(
        'if (NiriMsg.focusedOutputName === "" || root.screen.name === NiriMsg.focusedOutputName)',
        'if (true)',
    )
    s = s.replace(
        "settingsOpen: Settings.State.opened && Settings.State.outputName === root.screen.name",
        "settingsOpen: Settings.State.opened",
    )
    s = s.replace(
        "onSettingsClicked: Settings.State.toggle(root.screen.name)",
        "onSettingsClicked: Settings.State.opened ? Settings.State.close() : Settings.State.open(root.screen.name)",
    )
    p.write_text(s)

    # Have the single sidebar's workspace minimap follow whichever monitor is currently focused
    p = Path("shell/minimap/Map.qml")
    s = p.read_text()
    s = s.replace(
        "property var screen: null",
        'property var screen: null\n  readonly property string targetOutputName: Shell.NiriMsg.focusedOutputName || (root.screen ? root.screen.name : "")',
    )
    s = s.replace("row.outputName === root.screen.name", "row.outputName === root.targetOutputName")
    s = s.replace("expandedWorkspace.model.outputName === root.screen.name", "expandedWorkspace.model.outputName === root.targetOutputName")
    s = s.replace("collapsedWorkspace.model.outputName === root.screen.name", "collapsedWorkspace.model.outputName === root.targetOutputName")
    p.write_text(s)

    p = Path("shell/BrightnessFeedback.qml")
    s = p.read_text()
    s = s.replace("if (outputName !== root.screen.name) return;", "")
    p.write_text(s)

    p = Path("shell/KeyboardFeedback.qml")
    s = p.read_text()
    s = s.replace("if (NiriMsg.focusedOutputName !== root.screen.name) return;", "")
    p.write_text(s)

    p = Path("shell/notifications/ToastWindow.qml")
    s = p.read_text()
    s = s.replace(
        'readonly property bool outputMatches: Notifications.State.transientOutputName === ""\n      || Notifications.State.transientOutputName === outputName',
        "readonly property bool outputMatches: true",
    )
    p.write_text(s)

    p = Path("shell/NiriMsg.qml")
    s = p.read_text()
    s = s.replace("import Pond.Screenshot as Screenshot\n", "")
    s = s.replace("Screenshot.State.receive(ev.ScreenshotCaptured.path, focusedOutputName);", "")
    old_ws_open = """      if (a.focused && target && !target.isFocused && !dragOrigin && !overviewOpen
              && !Object.values(_windows).some(w => w.workspaceId === a.id)) {
            _workspaceLauncherOpen = true;
            Quickshell.execDetached(["vicinae", "open"]);
          }"""
    old_ws_close = """    const focusedWorkspace = workspaces.find(w => w.isFocused);
        if (_workspaceLauncherOpen && (overviewOpen || (focusedWorkspace
            && Object.values(_windows).some(w => w.workspaceId === focusedWorkspace.id)))) {
          _workspaceLauncherOpen = false;
          Quickshell.execDetached(["vicinae", "close"]);
        }"""
    assert old_ws_open in s, "old_ws_open not found"
    assert old_ws_close in s, "old_ws_close not found"
    s = s.replace(old_ws_open, "")
    s = s.replace(old_ws_close, "")
    old_app_info = """  function _appInfo(appId) {
        if (_appInfoCache[appId])
          return _appInfoCache[appId];
        const lower = appId.toLowerCase();
        const entry = appId && (DesktopEntries.heuristicLookup(appId)
               || DesktopEntries.byId(appId)
               || DesktopEntries.byId(lower)
               || DesktopEntries.heuristicLookup(lower));
        const iconName = entry?.icon || lower;
        const info = {
          iconName: iconName,
          iconSource: entry && !Quickshell.hasThemeIcon(iconName) && _hicolorIcon(iconName)
              || Quickshell.iconPath(iconName, "application-x-executable")
        };
        if (entry)
          _appInfoCache[appId] = info;
        return info;
      }"""
    new_app_info = """  Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
          root._appInfoCache = ({});
          root._recompute();
        }
      }

      function _appInfo(appId) {
        if (_appInfoCache[appId])
          return _appInfoCache[appId];
        const lower = appId.toLowerCase();
        const entry = appId && (DesktopEntries.heuristicLookup(appId)
               || DesktopEntries.byId(appId)
               || DesktopEntries.byId(lower)
               || DesktopEntries.heuristicLookup(lower));
        const iconName = entry?.icon || appId || lower;
        let iconSource = "";
        if (iconName.startsWith("file://")) {
          iconSource = iconName;
        } else if (iconName.startsWith("/")) {
          iconSource = "file://" + iconName;
        } else {
          iconSource = Quickshell.iconPath(iconName, true)
              || Quickshell.iconPath(lower, true)
              || Quickshell.iconPath(lower.replace(/_/g, "-"), true)
              || (entry && _hicolorIcon(iconName))
              || "";
        }
        const info = { iconName: iconName, iconSource: iconSource };
        if (entry && iconSource)
          _appInfoCache[appId] = info;
        return info;
      }"""
    assert old_app_info in s, "old_app_info not found"
    s = s.replace(old_app_info, new_app_info)
    s = s.replace(
        'for (const size of ["scalable", "512x512", "256x256", "128x128", "64x64", "48x48"]) {',
        'for (const size of ["512x512", "256x256", "128x128", "64x64", "48x48"]) {',
    )
    old_focus_app = """  function appMatches(appId, appName, desktopEntry) {
        function normalize(value) {
          return String(value || "").toLowerCase().replace(/\\.desktop$/, "").replace(/[^a-z0-9]+/g, "");
        }
        const wanted = desktopEntry || appName;
        if (!appId || !wanted) return false;
        const entry = DesktopEntries.heuristicLookup(appId);
        const target = DesktopEntries.heuristicLookup(wanted);
        if (entry && target) return entry.id === target.id;
        return [appId, entry?.id, entry?.name].some(value => normalize(value) === normalize(wanted));
      }

      function focusApp(appName, desktopEntry) {
        const window = Object.values(_windows).find(w => appMatches(w.appId, appName, desktopEntry));
        if (window) focusWindow(window.id);
        return !!window;
      }"""
    new_focus_app = """  function appMatches(appId, appName, desktopEntry) {
        function normalize(value) {
          return String(value || "").toLowerCase().replace(/\\.desktop$/, "").replace(/[^a-z0-9]+/g, "");
        }
        if (!appId) return false;
        const entry = DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
        for (const wanted of [desktopEntry, appName]) {
          if (!wanted) continue;
          const target = DesktopEntries.byId(wanted) || DesktopEntries.heuristicLookup(wanted);
          if (entry && target && entry.id === target.id) return true;
          if ([appId, entry?.id, entry?.name].some(value => normalize(value) === normalize(wanted)))
            return true;
        }
        return false;
      }

      function focusApp(appName, desktopEntry) {
        const window = Object.values(_windows).find(w => appMatches(w.appId, appName, desktopEntry));
        if (window) {
          focusWindow(window.id);
          return true;
        }
        for (const wanted of [desktopEntry, appName]) {
          if (!wanted) continue;
          const lower = String(wanted).toLowerCase();
          const entry = DesktopEntries.byId(wanted)
              || DesktopEntries.byId(lower)
              || DesktopEntries.heuristicLookup(wanted)
              || DesktopEntries.heuristicLookup(lower);
          if (entry) {
            entry.execute();
            return true;
          }
        }
        return false;
      }"""
    assert old_focus_app in s, "old_focus_app not found"
    s = s.replace(old_focus_app, new_focus_app)
    p.write_text(s)

    # Fix QML alias chain in settings/Modal.qml (Quickshell 0.3.0 requires single-dot alias target)
    p = Path("shell/settings/Modal.qml")
    s = p.read_text()
    s = s.replace(
        "default property alias content: body.contentItem.data",
        "default property alias content: bodyContent.data",
    )
    s = s.replace(
        "Shell.ScrollWheel { view: body }",
        "Shell.ScrollWheel { view: body }\n    Item { id: bodyContent; width: body.width; height: root.contentHeight }",
    )
    p.write_text(s)

    # Disable Arch package-manager polling in updates/State.qml
    p = Path("shell/updates/State.qml")
    s = p.read_text()
    s = s.replace('command: ["pm", "-a"]', 'command: ["true"]')
    p.write_text(s)

    # Fix notification icon resolution to avoid Adwaita missing "application-x-executable" warning
    p = Path("shell/notifications/State.qml")
    s = p.read_text()
    old_notif_icon = """  function iconSource(notification) {
        const rawIcon = String(notification.appIcon || "");
        if (rawIcon.startsWith("file:") || rawIcon.startsWith("image:")
            || rawIcon.startsWith("qrc:"))
          return rawIcon;
        if (rawIcon.startsWith("/"))
          return "file://" + rawIcon;
        if (rawIcon !== "")
          return Quickshell.iconPath(rawIcon, "application-x-executable");

        const candidates = [notification.desktopEntry, notification.appName];
        for (const candidate of candidates) {
          if (!candidate)
            continue;
          try {
            const lower = String(candidate).toLowerCase();
            const entry = DesktopEntries.byId(candidate)
                || DesktopEntries.byId(lower)
                || DesktopEntries.heuristicLookup(candidate)
                || DesktopEntries.heuristicLookup(lower);
            if (entry && entry.icon)
              return Quickshell.iconPath(entry.icon, "application-x-executable");
          } catch (error) {}
        }

        const fallback = String(notification.appName || "application-x-executable")
            .toLowerCase().replace(/\\s+/g, "-");
        return Quickshell.iconPath(fallback, "application-x-executable");
      }"""
    new_notif_icon = """  function _resolveIcon(name) {
        if (!name) return "";
        if (name.startsWith("file:") || name.startsWith("image:") || name.startsWith("qrc:"))
          return name;
        if (name.startsWith("/"))
          return "file://" + name;
        const lower = name.toLowerCase();
        return Quickshell.iconPath(name, true)
            || Quickshell.iconPath(lower, true)
            || Quickshell.iconPath(lower.replace(/\\s+/g, "-"), true)
            || Shell.NiriMsg._hicolorIcon(name)
            || Shell.NiriMsg._hicolorIcon(lower)
            || "";
      }

      function iconSource(notification) {
        const resolvedRaw = _resolveIcon(String(notification.appIcon || ""));
        if (resolvedRaw !== "")
          return resolvedRaw;

        const candidates = [notification.desktopEntry, notification.appName];
        for (const candidate of candidates) {
          if (!candidate)
            continue;
          try {
            const lower = String(candidate).toLowerCase();
            const entry = DesktopEntries.byId(candidate)
                || DesktopEntries.byId(lower)
                || DesktopEntries.heuristicLookup(candidate)
                || DesktopEntries.heuristicLookup(lower);
            if (entry && entry.icon) {
              const resolvedEntry = _resolveIcon(entry.icon);
              if (resolvedEntry !== "")
                return resolvedEntry;
            }
          } catch (error) {}
        }

        return _resolveIcon(String(notification.appName || "")) || Qt.resolvedUrl("../assets/bell.svg");
      }"""
    assert old_notif_icon in s, "old_notif_icon not found"
    s = s.replace(old_notif_icon, new_notif_icon)
    s = s.replace(
        "    if (action) action.invoke();\n    else Shell.NiriMsg.focusApp(notification.appName, notification.desktopEntry);",
        "    if (action) action.invoke();\n    Shell.NiriMsg.focusApp(notification.appName, notification.desktopEntry);",
    )
    p.write_text(s)

    # Fix opacity binding loop on inlineClose in notifications/SidebarCard.qml
    p = Path("shell/notifications/SidebarCard.qml")
    s = p.read_text()
    old_inline_close = """  Notifications.CloseButton {
        id: inlineClose
        compact: true
        x: root.width - width / 2
        y: 60
        z: 3
        opacity: preview.hovered && root.inlineAmount > 0.7 ? 1 : 0
        visible: opacity > 0.001
        enabled: opacity > 0.5
        onClicked: Notifications.State.remove(root.notification)
      }"""
    new_inline_close = """  Notifications.CloseButton {
        id: inlineClose
        compact: true
        x: root.width - width / 2
        y: 60
        z: 3
        opacity: preview.hovered && root.inlineAmount > 0.7 ? 1 : 0
        visible: opacity > 0.001
        enabled: opacity > 0.5
        Behavior on opacity { Shell.HoverAnimation {} }
        onClicked: Notifications.State.remove(root.notification)
      }"""
    assert old_inline_close in s, "old_inline_close not found"
    s = s.replace(old_inline_close, new_inline_close)
    p.write_text(s)
    EOF

    # 2. Default Theme.qml to "unthemed" (#1D1D1D crisp dark cards; can still switch to "daylight" in Settings)
    #    and use Advent Pro for large display numerals instead of proprietary Pond Gramercy
    substituteInPlace shell/Theme.qml \
      --replace-fail 'property string name: "daylight"' 'property string name: "unthemed"' \
      --replace-fail 'readonly property string titleFontFamily: "Pond Gramercy"' 'readonly property string titleFontFamily: "Advent Pro"'

    # 3. Replace hardcoded FHS paths with Nix store paths
    substituteInPlace shell/wifi/State.qml \
      --replace-fail '"/usr/bin/nmcli"' '"${networkmanager}/bin/nmcli"' \
      --replace-fail '"/usr/bin/iw"' '"${iw}/bin/iw"'

    substituteInPlace shell/settings/information/State.qml \
      --replace-fail '"fastfetch"' '"${fastfetch}/bin/fastfetch"'

    substituteInPlace shell/settings/appearance/control.py \
      --replace-fail '"ddcutil"' '"${ddcutil}/bin/ddcutil"' \
      --replace-fail '"brightnessctl"' '"${brightnessctl}/bin/brightnessctl"'

    # Replace PyQt6 timezone lookup in settings/system/control.py with stdlib zoneinfo (avoids pulling in PyQt6/QtWebEngine)
    ${pythonEnv}/bin/python3 - <<'EOF'
    from pathlib import Path
    p = Path("shell/settings/system/control.py")
    s = p.read_text()
    s = s.replace(
        "from PyQt6.QtCore import QDateTime, QLocale, QTimeZone",
        "from datetime import datetime, timezone as dt_tz\nfrom zoneinfo import ZoneInfo",
    )
    s = s.replace("ENGLISH = QLocale('en_US')", "")
    old_tz = """def zone(identifier, now):
        tz = QTimeZone(identifier.encode())
        offset = tz.offsetFromUtc(now)
        label = tz.displayName(now, QTimeZone.NameType.LongName, ENGLISH)
        return {'id': identifier, 'label': label, 'minutes': offset // 60,
                'offset': f'GMT{"-" if offset < 0 else "+"}{abs(offset) // 3600:02}:{abs(offset) // 60 % 60:02}',
                'search': label + ' ' + tz.abbreviation(now)}


    def timezones(current):
        with open('/usr/share/zoneinfo/zone.tab') as table:
            identifiers = sorted(line.split('\\t')[2].strip() for line in table if not line.startswith('#'))
        now = QDateTime.currentDateTimeUtc()
        groups = {}
        for i in [current, 'UTC', *identifiers]:
            z = zone(i, now)
            groups.setdefault((z['label'], z['minutes'], QTimeZone(i.encode()).offsetFromUtc(now.addMonths(6))), z)
        labels = [z['label'] for z in groups.values()]
        for z in groups.values():
            if labels.count(z['label']) > 1: z['label'] += ' – ' + z['id'].rpartition('/')[2].replace('_', ' ')
        return sorted(groups.values(), key=lambda z: (z['minutes'], z['label']))"""
    new_tz = """def zone(identifier, now):
        try:
            tz = ZoneInfo(identifier)
            dt = now.astimezone(tz)
            offset = int(dt.utcoffset().total_seconds())
            abbr = dt.tzname() or identifier
        except Exception:
            offset = 0
            abbr = identifier
        label = identifier.replace('_', ' ')
        return {'id': identifier, 'label': label, 'minutes': offset // 60,
                'offset': f'GMT{"-" if offset < 0 else "+"}{abs(offset) // 3600:02}:{abs(offset) // 60 % 60:02}',
                'search': label + ' ' + abbr}


    def timezones(current):
        with open('/usr/share/zoneinfo/zone.tab') as table:
            identifiers = sorted(line.split('\\t')[2].strip() for line in table if not line.startswith('#'))
        now = datetime.now(dt_tz.utc)
        return sorted((zone(i, now) for i in dict.fromkeys([current, 'UTC', *identifiers])), key=lambda z: (z['minutes'], z['label']))"""
    assert old_tz in s, "old_tz block not found"
    s = s.replace(old_tz, new_tz)
    s = s.replace(
        "timezone = bytes(QTimeZone.systemTimeZoneId()).decode()\n    return {'selectedLanguages': [ids.get(name, name) for name in names], 'languageNames': names,\n            'timezone': timezone, 'timezoneLabel': zone(timezone, QDateTime.currentDateTimeUtc())['label'],",
        "timezone = os.path.realpath('/etc/localtime').partition('zoneinfo/')[2] or 'UTC'\n    return {'selectedLanguages': [ids.get(name, name) for name in names], 'languageNames': names,\n            'timezone': timezone, 'timezoneLabel': zone(timezone, datetime.now(dt_tz.utc))['label'],",
    )
    old_mouse = """def mouse():
        values = get_properties(INPUT.read_text(), ('input', 'mouse'))
        return {'speed': (values.get('accel-speed', 0) + 1) / 2, 'scroll': values.get('scroll-factor', 1),
                'acceleration': values.get('accel-profile') != 'flat'}"""
    new_mouse = """def mouse():
        cfg = INPUT if INPUT.exists() else INPUT.parents[1] / 'config.kdl'
        values = get_properties(cfg.read_text(), ('input', 'mouse')) if cfg.exists() else {}
        return {'speed': (values.get('accel-speed', 0) + 1) / 2, 'scroll': values.get('scroll-factor', 1),
                'acceleration': values.get('accel-profile') != 'flat'}"""
    assert old_mouse in s, "old_mouse not found"
    s = s.replace(old_mouse, new_mouse)
    p.write_text(s)
    EOF

    substituteInPlace shell/settings/system/control.py \
      --replace-fail "/usr/share/X11/xkb/rules/" "${xkeyboard_config}/share/X11/xkb/rules/" \
      --replace-fail "/usr/share/zoneinfo/zone.tab" "${tzdata}/share/zoneinfo/zone.tab" \
      --replace-fail "/usr/bin/timedatectl" "timedatectl"

    for f in \
      shell/Shortcuts.qml \
      shell/bluetooth/State.qml \
      shell/settings/State.qml \
      shell/settings/appearance/State.qml \
      shell/settings/display/State.qml \
      shell/settings/system/State.qml
    do
      substituteInPlace "$f" \
        --replace-quiet '"python3"' '"${pythonEnv}/bin/python3"'
    done

    # 4. Patch lockscreen for NixOS (pure QML WifiStatus, local Daylight shader import, PAM service, fonts)
    mkdir -p lockscreen/frontend/daylight
    cp wallpaper/daylight/Sky.qml wallpaper/daylight/SkyState.js wallpaper/daylight/sky.frag wallpaper/daylight/sky.frag.qsb lockscreen/frontend/daylight/

    substituteInPlace lockscreen/frontend/Layout.qml \
      --replace-fail 'import Pond.Daylight as Daylight' 'import "daylight" as Daylight'

    substituteInPlace lockscreen/frontend/Theme.qml \
      --replace-fail 'readonly property string displayFont: "Pond Gramercy"' 'readonly property string displayFont: "Advent Pro"'

    for f in \
      lockscreen/frontend/Layout.qml \
      lockscreen/frontend/PowerMenu.qml \
      lockscreen/frontend/UserHeader.qml \
      lockscreen/frontend/form/Form.qml \
      shell/settings/information/Panel.qml \
      shell/settings/information/Footer.qml \
      shell/battery/ProfileSelector.qml
    do
      substituteInPlace "$f" \
        --replace-quiet 'font.styleName: "Book"' 'font.styleName: "Regular"' \
        --replace-quiet 'font.styleName:"Book"' 'font.styleName:"Regular"'
    done

    # Remove pre-release watermark text and avoid NaN layoutScale before initial geometry in lockscreen/frontend/Layout.qml
    ${pythonEnv}/bin/python3 - <<'EOF'
    from pathlib import Path
    import re

    p = Path("lockscreen/frontend/Layout.qml")
    s = p.read_text()
    s = re.sub(r"\s*SoftLightText\s*\{[^}]*Pre-release version[^}]*\}", "", s)
    s = re.sub(r"\s*SoftLightText\s*\{[^}]*Some features may not work[^}]*\}", "", s)
    s = s.replace(
        "readonly property real layoutScale: Math.min(height / canvasHeight, width / 960)",
        "readonly property real layoutScale: Math.max(0.001, Math.min(height / canvasHeight, width / 960))",
    )
    p.write_text(s)

    p = Path("lockscreen/session/Shell.qml")
    s = p.read_text()
    s = s.replace("import Pond.WifiStatus\n", "")
    s = s.replace(
        "NetworkStatus { id: network }",
        """QtObject {
        id: network
        property bool wifiConnected: false
    }
    Process {
        id: wifiCheck
        command: ["${networkmanager}/bin/nmcli", "-t", "-f", "TYPE,STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: network.wifiConnected = text.split("\\n").some(line => line.trim() === "wifi:connected")
        }
    }
    Connections {
        target: locker
        function onActiveChanged() {
            if (locker.active) wifiCheck.running = true;
        }
    }""",
    )
    s = s.replace('"/usr/bin/systemctl"', '"systemctl"')
    p.write_text(s)

    p = Path("lockscreen/session/Authentication.qml")
    s = p.read_text()
    s = s.replace('Quickshell.env("POND_PAM_SERVICE") || "login"', 'Quickshell.env("POND_PAM_SERVICE") || "swaylock"')
    s = s.replace(
        "if [ -f /etc/pam.d/login ]; then printf '%s\\\\n' login;",
        "if [ -f /etc/pam.d/swaylock ]; then printf '%s\\\\n' swaylock; elif [ -f /etc/pam.d/login ]; then printf '%s\\\\n' login;",
    )
    p.write_text(s)
    EOF

    substituteInPlace lockscreen/session/SessionInfo.qml \
      --replace-fail '"/usr/bin/id"' '"${coreutils}/bin/id"' \
      --replace-fail '"/usr/bin/getent"' '"getent"'

    # Wire shell/settings/session.py to use pond-lockscreen and wait until lock surface is secure
    cat > shell/settings/session.py <<'EOF'
    #!${pythonEnv}/bin/python3
    import subprocess
    import sys
    import time

    def ipc(method):
        return subprocess.run(
            ["qs", "-c", "pond-lockscreen", "ipc", "call", "lockscreen", method],
            capture_output=True,
            text=True,
        )

    def wait_secure(timeout=3.0):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            res = ipc("isSecure")
            if res.returncode == 0 and res.stdout.strip() == "true":
                return True
            time.sleep(0.05)
        return False

    def run(action):
        if action in ("reboot", "shutdown"):
            subprocess.run(["systemctl", "reboot" if action == "reboot" else "poweroff"], check=True)
            return
        if action not in ("lock", "suspend"):
            raise ValueError(f"Unsupported session action: {action}")
        method = "lock" if action == "lock" else "lockAndSuspend"
        if ipc(method).returncode != 0:
            subprocess.run(["qs", "-d", "-c", "pond-lockscreen"], check=True)
            for _ in range(30):
                if ipc(method).returncode == 0:
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError("Pond lockscreen did not start")
        if not wait_secure() and action == "suspend":
            raise RuntimeError("Pond lockscreen did not become secure; refusing to suspend")

    if __name__ == "__main__":
        run(sys.argv[1])
    EOF
    chmod +x shell/settings/session.py

    # 5. Make Clock.qml always expose the bottom strip so the 1-click System & Power popout works on desktops too
    substituteInPlace shell/calendar/Clock.qml \
      --replace-fail 'readonly property bool battery: Battery.State.present' 'readonly property bool battery: true' \
      --replace-fail 'width: 132 * Battery.State.percentage / 100' 'width: Battery.State.present ? 132 * Battery.State.percentage / 100 : 132' \
      --replace-fail 'text: Battery.State.level + "%"' 'text: Battery.State.present ? Battery.State.level + "%" : "System"' \
      --replace-fail 'percentage: Battery.State.percentage' 'percentage: Battery.State.present ? Battery.State.percentage : 100'

    # 6. Upgrade shell/battery/Card.qml into a 1-click System Metrics + Power Profile + Caffeine popout
    cat > shell/battery/Card.qml <<'EOF'
    pragma ComponentBehavior: Bound
    import QtQuick
    import Quickshell
    import Quickshell.Io
    import Quickshell.Services.UPower
    import "." as Battery
    import ".." as Shell

    Shell.PanelBackground {
      id: root
      property string hoveredProfile: ""
      readonly property UPowerDevice device: Battery.State.device
      readonly property bool hasBattery: Battery.State.present
      readonly property bool charging: device.state === UPowerDeviceState.Charging
      readonly property string selectedProfile:
          Battery.State.profiles.find(profile => profile.profile === PowerProfiles.profile)?.name ?? ""

      property int cpuPercent: 0
      property real prevIdle: 0
      property real prevTotal: 0
      property real memUsedGiB: 0
      property real memTotalGiB: 1
      property real memPercent: 0
      property bool caffeineActive: false

      implicitWidth: 280
      implicitHeight: hasBattery ? 372 : 186
      Accessible.role: Accessible.Pane
      Accessible.name: "System & Power"

      function duration(seconds) {
        const minutes = Math.round(seconds / 60);
        const hours = Math.floor(minutes / 60);
        return hours > 0 ? hours + "h " + minutes % 60 + "m" : minutes + "m";
      }

      function pollMetrics() {
        procStat.reload();
        procMem.reload();
        if (!caffeineCheck.running) caffeineCheck.running = true;
      }

      onVisibleChanged: if (visible) pollMetrics()
      Component.onCompleted: pollMetrics()

      Timer {
        interval: 2000
        repeat: true
        running: root.visible
        onTriggered: root.pollMetrics()
      }

      FileView {
        id: procStat
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
          const line = text().split("\n")[0] || "";
          const parts = line.trim().split(/\s+/).slice(1).map(Number);
          if (parts.length < 4) return;
          const idle = parts[3] + (parts[4] || 0);
          const total = parts.reduce((a, b) => a + b, 0);
          const diffTotal = total - root.prevTotal;
          const diffIdle = idle - root.prevIdle;
          if (root.prevTotal > 0 && diffTotal > 0) {
            root.cpuPercent = Math.round(100 * (diffTotal - diffIdle) / diffTotal);
          }
          root.prevTotal = total;
          root.prevIdle = idle;
        }
      }

      FileView {
        id: procMem
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
          let totalKb = 0;
          let availKb = 0;
          for (const line of text().split("\n")) {
            if (line.startsWith("MemTotal:")) totalKb = parseInt(line.split(/\s+/)[1], 10) || 0;
            else if (line.startsWith("MemAvailable:")) availKb = parseInt(line.split(/\s+/)[1], 10) || 0;
          }
          if (totalKb > 0) {
            const usedKb = Math.max(0, totalKb - availKb);
            root.memTotalGiB = totalKb / (1024 * 1024);
            root.memUsedGiB = usedKb / (1024 * 1024);
            root.memPercent = Math.min(100, Math.round(100 * usedKb / totalKb));
          }
        }
      }

      Process {
        id: caffeineCheck
        command: ["sh", "-c", "if ${procps}/bin/ps -C swayidle -o state= | grep -q T; then echo on; else ${coreutils}/bin/rm -f /tmp/caffeine-on; echo off; fi"]
        stdout: StdioCollector {
          onStreamFinished: root.caffeineActive = text.trim() === "on"
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      }

      // ── Battery & Power Profile Section (shown when battery is present) ──
      Item {
        id: batterySection
        width: parent.width
        height: root.hasBattery ? 210 : 0
        visible: root.hasBattery

        Label { x: 20; capTop: 20; text: "Battery"; opacity: 0.7 }

        Image {
          x: status.x - 13
          y: 18
          width: 6
          height: 12
          visible: status.visible
          source: Qt.resolvedUrl("../assets/battery/bolt.svg")
          sourceSize: Qt.size(12, 24)
        }
        Label {
          id: status
          x: 260 - width
          capTop: 20
          visible: Battery.State.charging
          text: root.charging ? "Charging" : "Charged"
          color: "#CBE25B"
        }

        Label {
          x: 20
          capTop: 53
          text: Battery.State.level + "%"
          font.family: Shell.Theme.titleFontFamily
          font.styleName: "Regular"
          font.pixelSize: 39
          font.letterSpacing: -1.17
        }

        Item {
          x: 254 - width
          width: Math.max(rate.x + rate.width, remaining.width)
          visible: root.charging || !Battery.State.charging

          Image {
            y: 53
            width: 9
            height: 9
            visible: root.charging && rate.visible
            source: Qt.resolvedUrl("../assets/battery/plus.svg")
            sourceSize: Qt.size(18, 18)
          }
          Label {
            id: rate
            x: root.charging ? 11 : 0
            capTop: 53
            visible: root.device.changeRate !== 0
            text: Math.round(Math.abs(root.device.changeRate)) + "W"
            color: root.charging ? "#CBE25B" : Shell.Theme.sidebarV3Foreground
            opacity: root.charging ? 1 : 0.4
          }
          Label {
            id: remaining
            x: parent.width - width
            capTop: 71
            opacity: 0.7
            text: root.charging
                ? (root.device.timeToFull > 0 ? root.duration(root.device.timeToFull) + " to full" : "")
                : (root.device.timeToEmpty > 0 ? root.duration(root.device.timeToEmpty) + " left" : "")
          }
        }

        Rectangle {
          x: 20
          y: 96
          width: 240
          height: 20
          radius: 6
          color: Qt.rgba(1, 1, 1, 0.1)

          Rectangle {
            width: parent.width * Battery.State.percentage / 100
            height: parent.height
            radius: 6
            color: Shell.Theme.sidebarV3Foreground
            gradient: Battery.State.charging ? chargeGradient : null
          }
        }

        Gradient {
          id: chargeGradient
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: Qt.rgba(111 / 255, 124 / 255, 50 / 255, 0) }
          GradientStop { position: 0.48134; color: "#CBE25B" }
        }

        Label { x: 20; capTop: 136; text: "Power profile"; opacity: 0.7 }
        Label {
          x: 260 - width
          capTop: 136
          text: root.hoveredProfile || root.selectedProfile
          color: "white"
        }

        Repeater {
          model: Battery.State.profiles

          delegate: Battery.PowerProfileButton {
            id: button
            required property int index

            x: 20 + index * 82
            y: 157
            width: 76
            height: 40
            iconSource: Qt.resolvedUrl("../assets/battery/" + modelData.icon + (selected ? "-active" : "") + ".svg")
            glyphOpacity: !available ? 0.2 : selected || highlighted ? 1 : 0.6

            onHighlightedChanged: {
              if (highlighted) root.hoveredProfile = modelData.name;
              else if (root.hoveredProfile === modelData.name) root.hoveredProfile = "";
            }

            Rectangle {
              anchors.fill: parent
              z: -1
              radius: 8
              color: button.selected ? Qt.alpha(button.modelData.accent, 0.1)
                  : button.highlighted ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)
            }
          }
        }

        Rectangle {
          x: 20
          y: 208
          width: 240
          height: 1
          color: Qt.rgba(1, 1, 1, 0.08)
        }
      }

      // ── System Metrics + Caffeine Section ──
      Item {
        y: root.hasBattery ? 210 : 0
        width: parent.width
        height: 162

        Label { x: 20; capTop: 18; text: "CPU"; opacity: 0.7 }
        Label {
          x: 260 - width
          capTop: 18
          text: root.cpuPercent + "%"
          color: root.cpuPercent >= 85 ? "#FD6164" : root.cpuPercent >= 60 ? "#FFDC67" : "white"
        }
        Rectangle {
          x: 20
          y: 38
          width: 240
          height: 10
          radius: 4
          color: Qt.rgba(1, 1, 1, 0.1)
          Rectangle {
            width: parent.width * Math.min(100, root.cpuPercent) / 100
            height: parent.height
            radius: 4
            color: root.cpuPercent >= 85 ? "#FD6164" : "#CBA6F7"
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
          }
        }

        Label { x: 20; capTop: 62; text: "Memory"; opacity: 0.7 }
        Label {
          x: 260 - width
          capTop: 62
          text: root.memUsedGiB.toFixed(1) + " / " + root.memTotalGiB.toFixed(0) + " GiB"
          color: "white"
        }
        Rectangle {
          x: 20
          y: 82
          width: 240
          height: 10
          radius: 4
          color: Qt.rgba(1, 1, 1, 0.1)
          Rectangle {
            width: parent.width * Math.min(100, root.memPercent) / 100
            height: parent.height
            radius: 4
            color: root.memPercent >= 85 ? "#FD6164" : "#CBE25B"
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
          }
        }

        Rectangle {
          id: caffeineBtn
          x: 20
          y: 106
          width: 240
          height: 36
          radius: 8
          color: root.caffeineActive ? Qt.alpha("#CBE25B", 0.14)
              : caffeineMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)

          Label {
            x: 12
            capTop: 12
            text: "Keep Awake (Caffeine)"
            opacity: 0.85
          }
          Label {
            x: 228 - width
            capTop: 12
            text: root.caffeineActive ? "Active" : "Off"
            color: root.caffeineActive ? "#CBE25B" : Qt.rgba(1, 1, 1, 0.5)
          }

          MouseArea {
            id: caffeineMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.caffeineActive) {
                Quickshell.execDetached(["sh", "-c", "${coreutils}/bin/rm -f /tmp/caffeine-on; ${procps}/bin/pkill -CONT swayidle"]);
                root.caffeineActive = false;
              } else {
                Quickshell.execDetached(["sh", "-c", "${coreutils}/bin/touch /tmp/caffeine-on; ${procps}/bin/pkill -STOP swayidle"]);
                root.caffeineActive = true;
              }
            }
          }
        }
      }

      component Label: Text {
        id: label
        property real capTop
        y: capTop + labelMetrics.capitalHeight - baselineOffset
        color: Shell.Theme.sidebarV3Foreground
        font.family: Shell.Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
        FontMetrics { id: labelMetrics; font: label.font }
      }
    }
    EOF
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/pond-interface $out/bin
    cp -r shell $out/share/pond-interface/shell
    cp -r lockscreen $out/share/pond-interface/lockscreen
    chmod +x $out/share/pond-interface/shell/bluetooth/actions.py
    chmod +x $out/share/pond-interface/shell/settings/*.py
    chmod +x $out/share/pond-interface/shell/settings/*/*.py

    cat > $out/bin/pond-lock <<EOF
    #!/bin/sh
    exec $out/share/pond-interface/shell/settings/session.py "\''${1:-lock}"
    EOF
    chmod +x $out/bin/pond-lock
    runHook postInstall
  '';

  meta = with lib; {
    description = "Pond OS desktop shell for Niri (Quickshell sidebar + popout cards)";
    homepage = "https://github.com/bflycomputer/pond-interface";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
