/// Hints to the VM to prefer inlining the annotated standalone function.
///
/// Use on small, hot-path functions where call overhead matters. Do not apply
/// to extension type members — the VM manages their inlining automatically.
const inline = pragma('vm:prefer-inline');

/// Hints to the VM to never inline the annotated standalone function.
///
/// Use on large functions or error-path helpers that should remain visible in
/// stack traces. Do not apply to extension type members.
const noinline = pragma('vm:never-inline');
