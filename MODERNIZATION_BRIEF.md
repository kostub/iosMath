Goal: modernize iosMath.

Requirements:
1. Use current Apple toolchain.
2. Target iOS 18+ only.
3. Primary consumer experience must be Swift.
4. Remove CocoaPods support if it exists.
5. Prefer Swift Package Manager as the only distribution method.
6. Keep changes as small and practical as possible; do not rewrite the rendering engine in Swift unless necessary.
7. Add/update examples so a Swift app can import the package and render LaTeX.
8. Add CI for current Xcode.
9. Update README and migration notes.

Constraints:
- Keep public API changes modest where possible.
- Prefer deleting legacy install paths over preserving them.
- Validate changes with xcodebuild/swift build/tests where possible.
