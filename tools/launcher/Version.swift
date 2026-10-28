// Release tag comparison for the updater (CSSLauncher.swift). Tested by make test-launcher.

/// "v0.3.0", "0.3.0", "v0.2.0-4-gabc123" (git describe) -> [0, 3, 0]; an untagged build ("abc1234") -> [0]
func versionParts(_ v: String) -> [Int] {
    var core = v.hasPrefix("v") ? String(v.dropFirst()) : v
    if let dash = core.firstIndex(of: "-") { core = String(core[..<dash]) }
    return core.split(separator: ".").map { Int($0) ?? 0 }
}

func isNewer(_ a: String, than b: String) -> Bool {
    let x = versionParts(a), y = versionParts(b)
    for i in 0..<max(x.count, y.count) {
        let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
        if l != r { return l > r }
    }
    return false
}
