// display120 (main.swift: top-level code must live here when several files are compiled): switch the main display to 120 Hz for a game session and put the previous mode back afterwards.
//   display120 set <statefile> [<w> <h>]  remember the current mode in <statefile>, switch to 120 Hz: same size, or
//                                    <w>x<h> at 1x pixels when the game runs fullscreen at another size
//   display120 restore <statefile>   switch back to the remembered mode and delete <statefile> (no file: nothing to do)
// The switch is made for the login session only (.forSession): a logout or reboot also brings the old mode back.
// Without a 120 Hz mode of the same size nothing is changed (and no state file is written).
import CoreGraphics
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

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("display120: \(message)\n".utf8)); exit(1)
}

let args = CommandLine.arguments
guard (args.count == 3 || (args.count == 5 && args[1] == "set")), ["set", "restore"].contains(args[1]) else {
    print("usage: display120 set <statefile> [<w> <h>] | restore <statefile>"); exit(2)
}
let size: (Int, Int)? = args.count == 5 ? Int(args[3]).flatMap { w in Int(args[4]).map { (w, $0) } } : nil
let stateFile = args[2]
let display = CGMainDisplayID()
guard let current = CGDisplayCopyDisplayMode(display) else { fail("cannot read the current display mode") }
let modes = allModes(display)

if args[1] == "set" {
    var count: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &count)
    if count > 1 { FileHandle.standardError.write(Data("display120: several displays active, switching main only\n".utf8)) }
    let cur = info(current)
    let sameSize = size.map { $0.0 == cur.width && $0.1 == cur.height } ?? true
    if abs(cur.hz - 120) < 0.5 && sameSize { print("already at 120 Hz (\(cur.width)x\(cur.height))"); exit(0) }
    guard let want = pickMode(modes.map(info), current: cur, hz: 120, size: size),
          let mode = modes.first(where: { $0.ioDisplayModeID == want.id }) else {
        let (w, h) = size ?? (cur.width, cur.height)
        print("no 120 Hz mode for \(w)x\(h), unchanged"); exit(0)
    }
    do { try "\(cur.id)\n".write(toFile: stateFile, atomically: true, encoding: .utf8) }
    catch { fail("cannot write \(stateFile)") }
    guard apply(mode, display) else { try? FileManager.default.removeItem(atPath: stateFile); fail("switch to 120 Hz failed") }
    print("switched \(cur.width)x\(cur.height)@\(Int(cur.hz.rounded())) Hz to \(want.width)x\(want.height)@120 Hz")
} else {
    guard let saved = try? String(contentsOfFile: stateFile, encoding: .utf8) else { exit(0) }
    guard let id = Int32(saved.trimmingCharacters(in: .whitespacesAndNewlines)),
          let mode = modes.first(where: { $0.ioDisplayModeID == id }) else {
        try? FileManager.default.removeItem(atPath: stateFile); fail("saved mode \(saved) no longer exists")
    }
    if mode.ioDisplayModeID != current.ioDisplayModeID && !apply(mode, display) { fail("restore failed") }
    try? FileManager.default.removeItem(atPath: stateFile)
    print("restored \(mode.width)x\(mode.height) at \(Int(mode.refreshRate.rounded())) Hz")
}
