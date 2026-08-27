use std::sync::{Mutex, MutexGuard, OnceLock};

/// Serialises tests that read or write process environment variables.
///
/// Cargo runs the tests of one crate as threads in a single process, so a test
/// that clears a variable would otherwise race with a test that has just set it.
pub(crate) fn lock() -> MutexGuard<'static, ()> {
    static LOCK: OnceLock<Mutex<()>> = OnceLock::new();

    // A test that panics while holding the guard must not turn every other
    // environment test into a poison error, which would hide the real failure.
    LOCK.get_or_init(|| Mutex::new(()))
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}
