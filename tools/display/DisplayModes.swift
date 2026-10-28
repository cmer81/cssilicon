// Pure display-mode choice for display120 (no CoreGraphics here, so it can be unit-tested: make test-display).
struct ModeInfo: Equatable {
    let id: Int32
    let width: Int, height: Int             // points ("looks like")
    let pixelWidth: Int, pixelHeight: Int   // backing pixels (5120x2880 for 2560x1440 HiDPI)
    let hz: Double
}

// The mode to switch to for `hz`. Without `size` (or with the current size): the current mode's size, points and
// pixels, so HiDPI stays HiDPI. With another size (the game's -w/-h): that size at 1x pixels, the mode Source's
// fullscreen sets itself, so the game finds the display already there and its window isn't misplaced.
// 119.88 counts as 120.
func pickMode(_ modes: [ModeInfo], current: ModeInfo, hz: Double, size: (Int, Int)? = nil) -> ModeInfo? {
    let near = { (m: ModeInfo) in abs(m.hz - hz) < 0.5 }
    if let (w, h) = size, w != current.width || h != current.height {
        return modes.first { $0.width == w && $0.height == h && $0.pixelWidth == w && $0.pixelHeight == h && near($0) }
    }
    return modes.first { m in
        m.width == current.width && m.height == current.height &&
        m.pixelWidth == current.pixelWidth && m.pixelHeight == current.pixelHeight && near(m)
    }
}

// The mode to go back to: the saved one, found by its values (mode ids are per display and can change).
func restoreMode(_ modes: [ModeInfo], saved: ModeInfo) -> ModeInfo? {
    modes.first { m in
        m.width == saved.width && m.height == saved.height && m.pixelWidth == saved.pixelWidth &&
        m.pixelHeight == saved.pixelHeight && abs(m.hz - saved.hz) < 0.5
    }
}

// State file: "<display uuid> <id> <width> <height> <pixelWidth> <pixelHeight> <hz>", so a mode is only ever put back
// on the display it was taken from (a laptop may have unplugged its external screen since).
func savedLine(display: String, mode m: ModeInfo) -> String {
    "\(display) \(m.id) \(m.width) \(m.height) \(m.pixelWidth) \(m.pixelHeight) \(m.hz)\n"
}
func parseSaved(_ s: String) -> (display: String, mode: ModeInfo)? {
    let f = s.split(whereSeparator: \.isWhitespace).map(String.init)
    guard f.count == 7, let id = Int32(f[1]), let w = Int(f[2]), let h = Int(f[3]), let pw = Int(f[4]), let ph = Int(f[5]),
          let hz = Double(f[6]) else { return nil }
    return (f[0], ModeInfo(id: id, width: w, height: h, pixelWidth: pw, pixelHeight: ph, hz: hz))
}
