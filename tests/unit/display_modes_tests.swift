import Foundation
// Tests for tools/display/DisplayModes.swift (pure mode choice). Built with swiftc together with DisplayModes.swift:
//   make test-display
var failures = 0
func check(_ cond: Bool, _ name: String) {
    if cond { print("ok    \(name)") } else { print("FAIL  \(name)"); failures += 1 }
}
func m(_ id: Int32, _ w: Int, _ h: Int, _ pw: Int, _ ph: Int, _ hz: Double) -> ModeInfo {
    ModeInfo(id: id, width: w, height: h, pixelWidth: pw, pixelHeight: ph, hz: hz)
}
let cur = m(1, 2560, 1440, 5120, 2880, 160)

check(pickMode([cur, m(2, 2560, 1440, 5120, 2880, 120), m(3, 1920, 1080, 3840, 2160, 120)], current: cur, hz: 120)?.id == 2,
      "test_pick_mode_same_res_120")
check(pickMode([cur, m(2, 2560, 1440, 5120, 2880, 60)], current: cur, hz: 120) == nil,
      "test_pick_mode_none_when_missing")
check(pickMode([m(4, 2560, 1440, 2560, 1440, 120), m(5, 2560, 1440, 5120, 2880, 120)], current: cur, hz: 120)?.id == 5,
      "test_pick_mode_keeps_hidpi")
check(pickMode([m(6, 2560, 1440, 5120, 2880, 119.88)], current: cur, hz: 120)?.id == 6,
      "test_pick_mode_tolerance")

print(failures == 0 ? "all display mode tests passed" : "\(failures) display mode test(s) failed")
if failures > 0 { exit(1) }
