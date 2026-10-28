// displaymode (main.swift: top-level code must live here when several files are compiled): the main display's mode
// for a game session.
//   displaymode current                              print "<width> <height> <hz>" (points, rounded Hz)
//   displaymode set <statefile> <hz|current> [<w> <h>]  remember the current mode in <statefile>, then switch to <hz>:
//                                                    same size, or <w>x<h> at 1x pixels (the mode Source's fullscreen
//                                                    sets itself at another size than the desktop)
//   displaymode restore <statefile>                  switch back to the remembered mode, delete <statefile>
// The switch is made for the login session only (.forSession): a logout or reboot also brings the old mode back.
// Without a matching mode nothing is changed (and no state file is written).
import CoreGraphics
import ColorSync   // CGDisplayCreateUUIDFromDisplayID
import Foundation

func info(_ m: CGDisplayMode) -> ModeInfo {
    ModeInfo(id: m.ioDisplayModeID, width: m.width, height: m.height,
             pixelWidth: m.pixelWidth, pixelHeight: m.pixelHeight, hz: m.refreshRate)
}

func allModes(_ display: CGDirectDisplayID) -> [CGDisplayMode] {
    let opts = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
    return (CGDisplayCopyAllDisplayModes(display, opts) as? [CGDisplayMode]) ?? []
}

func apply(_ mode: CGDisplayMode, _ display: CGDirectDisplayID) -> Bool {
    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success else { return false }
    CGConfigureDisplayWithDisplayMode(config, display, mode, nil)
    return CGCompleteDisplayConfiguration(config, .forSession) == .success
}

func uuid(_ display: CGDirectDisplayID) -> String {
    guard let u = CGDisplayCreateUUIDFromDisplayID(display)?.takeRetainedValue() else { return "unknown" }
    return CFUUIDCreateString(nil, u) as String
}

func onlineDisplays() -> [CGDirectDisplayID] {
    var ids = [CGDirectDisplayID](repeating: 0, count: 16), n: UInt32 = 0
    guard CGGetOnlineDisplayList(16, &ids, &n) == .success else { return [] }
    return Array(ids.prefix(Int(n)))
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("displaymode: \(message)\n".utf8)); exit(1)
}

let args = CommandLine.arguments
let display = CGMainDisplayID()
guard let current = CGDisplayCopyDisplayMode(display) else { fail("cannot read the current display mode") }
if args.count == 2 && args[1] == "current" {
    print("\(current.width) \(current.height) \(Int(current.refreshRate.rounded()))"); exit(0)
}
guard (args.count == 3 && args[1] == "restore") || ((args.count == 4 || args.count == 6) && args[1] == "set") else {
    print("usage: displaymode current | set <statefile> <hz|current> [<w> <h>] | restore <statefile>"); exit(2)
}
let stateFile = args[2]
let size: (Int, Int)? = args.count == 6 ? Int(args[4]).flatMap { w in Int(args[5]).map { (w, $0) } } : nil
let modes = allModes(display)

if args[1] == "set" {
    var count: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &count)
    if count > 1 { FileHandle.standardError.write(Data("displaymode: several displays active, switching main only\n".utf8)) }
    let cur = info(current)
    guard let hz = args[3] == "current" ? cur.hz : Double(args[3]) else { fail("bad refresh rate \(args[3])") }
    let sameSize = size.map { $0.0 == cur.width && $0.1 == cur.height } ?? true
    if abs(cur.hz - hz) < 0.5 && sameSize { print("already \(cur.width)x\(cur.height)@\(Int(cur.hz.rounded())) Hz"); exit(0) }
    guard let want = pickMode(modes.map(info), current: cur, hz: hz, size: size),
          let mode = modes.first(where: { $0.ioDisplayModeID == want.id }) else {
        let (w, h) = size ?? (cur.width, cur.height)
        print("no \(Int(hz.rounded())) Hz mode for \(w)x\(h), unchanged"); exit(0)
    }
    do { try savedLine(display: uuid(display), mode: cur).write(toFile: stateFile, atomically: true, encoding: .utf8) }
    catch { fail("cannot write \(stateFile)") }
    guard apply(mode, display) else { try? FileManager.default.removeItem(atPath: stateFile); fail("switch failed") }
    print("switched \(cur.width)x\(cur.height)@\(Int(cur.hz.rounded())) Hz to \(want.width)x\(want.height)@\(Int(want.hz.rounded())) Hz")
} else {
    // put the mode back on the display it was taken from, found by UUID (mode ids are per display, and that display
    // may have been unplugged since); a mode or display that is gone leaves things as they are
    guard let text = try? String(contentsOfFile: stateFile, encoding: .utf8) else { exit(0) }
    try? FileManager.default.removeItem(atPath: stateFile)
    guard let saved = parseSaved(text) else { print("unreadable saved mode, nothing restored"); exit(0) }
    guard let target = onlineDisplays().first(where: { uuid($0) == saved.display }) else {
        print("display \(saved.display) not connected, nothing restored"); exit(0)
    }
    let targetModes = allModes(target)
    guard let want = restoreMode(targetModes.map(info), saved: saved.mode),
          let mode = targetModes.first(where: { $0.ioDisplayModeID == want.id }) else {
        print("saved mode \(saved.mode.width)x\(saved.mode.height)@\(Int(saved.mode.hz.rounded())) Hz no longer offered, nothing restored"); exit(0)
    }
    let now = CGDisplayCopyDisplayMode(target)
    if now?.ioDisplayModeID != mode.ioDisplayModeID && !apply(mode, target) { fail("restore failed") }
    print("restored \(mode.width)x\(mode.height) at \(Int(mode.refreshRate.rounded())) Hz")
}
