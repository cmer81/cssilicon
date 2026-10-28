# tools/wine-patches/winemac_warp_nodiscard.sh must patch the runtime under CSS_HOME
test_mouse_patch_uses_css_home() {
  tmp_home; so="$CSS_HOME/wine/lib/wine/x86_64-unix/winemac.so"; mkdir -p "$(dirname "$so")"
  # 40 KB of zeros with the original bytes at both patch offsets
  head -c 40000 /dev/zero > "$so"
  printf 'f2410f118728010000' | xxd -r -p | dd of="$so" bs=1 seek=33689 conv=notrunc 2>/dev/null
  printf 'ba00180000' | xxd -r -p | dd of="$so" bs=1 seek=33931 conv=notrunc 2>/dev/null
  assert_eq original "$(bash tools/wine-patches/winemac_warp_nodiscard.sh status | cut -d" " -f1)" "status reads CSS_HOME's winemac.so"
}
