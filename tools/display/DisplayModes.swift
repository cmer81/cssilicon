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
