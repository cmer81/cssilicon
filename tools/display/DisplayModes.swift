// Pure display-mode choice for display120 (no CoreGraphics here, so it can be unit-tested: make test-display).
struct ModeInfo: Equatable {
    let id: Int32
    let width: Int, height: Int             // points ("looks like")
    let pixelWidth: Int, pixelHeight: Int   // backing pixels (5120x2880 for 2560x1440 HiDPI)
    let hz: Double
}

// The mode with the current mode's size (points and pixels, so HiDPI stays HiDPI) at `hz` (119.88 counts as 120).
func pickMode(_ modes: [ModeInfo], current: ModeInfo, hz: Double) -> ModeInfo? {
    modes.first { m in
        m.width == current.width && m.height == current.height &&
        m.pixelWidth == current.pixelWidth && m.pixelHeight == current.pixelHeight && abs(m.hz - hz) < 0.5
    }
}
