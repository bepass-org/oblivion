#[cfg(unix)]
mod dns;
#[cfg(not(unix))]
#[path = "dns_windows.rs"]
mod dns;
mod net;
mod probe;
mod settings;
mod supervisor;
mod sysproxy;
mod tunnel;

use std::ffi::{c_char, CStr, CString};
use std::path::PathBuf;
use std::sync::{Arc, OnceLock};

use settings::ConnectRequest;
use supervisor::Supervisor;

fn supervisor() -> &'static Arc<Supervisor> {
    static INSTANCE: OnceLock<Arc<Supervisor>> = OnceLock::new();
    INSTANCE.get_or_init(|| {
        let instance = Arc::new(Supervisor::new());
        instance.recover_previous_session();
        instance
    })
}

unsafe fn read_string(pointer: *const c_char) -> Option<String> {
    if pointer.is_null() {
        return None;
    }
    CStr::from_ptr(pointer).to_str().ok().map(str::to_string)
}

fn into_c_string(value: String) -> *mut c_char {
    CString::new(value)
        .unwrap_or_else(|_| CString::new("").unwrap())
        .into_raw()
}

#[no_mangle]
pub unsafe extern "C" fn oblivion_set_core_path(path: *const c_char) -> i32 {
    match read_string(path) {
        Some(value) => {
            supervisor().set_core_binary(PathBuf::from(value));
            0
        }
        None => -1,
    }
}

#[no_mangle]
pub unsafe extern "C" fn oblivion_connect(payload: *const c_char) -> i32 {
    let raw = match read_string(payload) {
        Some(value) => value,
        None => return -1,
    };

    let request: ConnectRequest = match serde_json::from_str(&raw) {
        Ok(value) => value,
        Err(_) => return -2,
    };

    supervisor().connect(request.settings, request.arguments);
    0
}

#[no_mangle]
pub extern "C" fn oblivion_disconnect() -> i32 {
    supervisor().disconnect();
    0
}

#[no_mangle]
pub unsafe extern "C" fn oblivion_submit_line(line: *const c_char) -> i32 {
    let value = match read_string(line) {
        Some(value) => value,
        None => return -1,
    };

    if supervisor().submit_line(&value) {
        0
    } else {
        -2
    }
}

#[no_mangle]
pub extern "C" fn oblivion_status_json() -> *mut c_char {
    into_c_string(supervisor().snapshot_json())
}

#[no_mangle]
pub extern "C" fn oblivion_drain_logs() -> *mut c_char {
    into_c_string(supervisor().drain_logs())
}

#[no_mangle]
pub extern "C" fn oblivion_read_logs() -> *mut c_char {
    into_c_string(supervisor().read_logs())
}

#[no_mangle]
pub extern "C" fn oblivion_clear_logs() -> i32 {
    supervisor().clear_logs();
    0
}

#[no_mangle]
pub extern "C" fn oblivion_core_version() -> *mut c_char {
    into_c_string(supervisor().core_version())
}

#[no_mangle]
pub extern "C" fn oblivion_tunnel_available() -> i32 {
    if supervisor().tunnel_device_available() {
        1
    } else {
        0
    }
}

#[no_mangle]
pub extern "C" fn oblivion_is_privileged() -> i32 {
    if net::is_privileged() {
        1
    } else {
        0
    }
}

#[no_mangle]
pub unsafe extern "C" fn oblivion_string_free(pointer: *mut c_char) {
    if pointer.is_null() {
        return;
    }
    drop(CString::from_raw(pointer));
}
