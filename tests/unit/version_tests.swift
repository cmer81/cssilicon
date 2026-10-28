import Foundation
// Tests for tools/launcher/Version.swift (release tag comparison used by the updater): make test-launcher
var failures = 0
func check(_ cond: Bool, _ name: String) {
    if cond { print("ok    \(name)") } else { print("FAIL  \(name)"); failures += 1 }
}
check(versionParts("v0.3.0") == [0, 3, 0], "test_version_parts_tag")
check(versionParts("v0.2.0-4-gabc123") == [0, 2, 0], "test_version_parts_describe")
check(isNewer("v0.2.0", than: "v0.1.9"), "test_newer_minor")
check(isNewer("v0.10.0", than: "v0.9.0"), "test_newer_numeric_not_lexical")
check(!isNewer("v0.1.0", than: "v0.1.0"), "test_same_not_newer")
check(!isNewer("v0.1.0", than: "v0.1.0-3-gdeadbee"), "test_dev_build_of_same_tag_not_older")
check(isNewer("v0.1.0", than: "abc1234"), "test_untagged_build_gets_any_release")
print(failures == 0 ? "all version tests passed" : "\(failures) version test(s) failed")
if failures > 0 { exit(1) }
