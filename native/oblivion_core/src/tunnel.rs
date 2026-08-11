use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::thread::{self, JoinHandle};
use std::time::Duration;

#[derive(Debug, Clone, Copy, Default)]
pub struct Counters {
    pub tx_packets: u64,
    pub tx_bytes: u64,
    pub rx_packets: u64,
    pub rx_bytes: u64,
}

#[cfg(oblivion_hev)]
mod bindings {
    use std::ffi::c_int;
    use std::os::raw::c_uchar;

    unsafe extern "C" {
        pub fn hev_socks5_tunnel_main_from_str(
            config_str: *const c_uchar,
            config_len: u32,
            tun_fd: c_int,
        ) -> c_int;

        pub fn hev_socks5_tunnel_quit();

        pub fn hev_socks5_tunnel_stats(
            tx_packets: *mut usize,
            tx_bytes: *mut usize,
            rx_packets: *mut usize,
            rx_bytes: *mut usize,
        );
    }
}

pub struct TunnelDevice {
    running: AtomicBool,
    worker: Mutex<Option<JoinHandle<i32>>>,
}

impl TunnelDevice {
    pub const fn new() -> Self {
        Self {
            running: AtomicBool::new(false),
            worker: Mutex::new(None),
        }
    }

    pub fn available() -> bool {
        cfg!(oblivion_hev)
    }

    pub fn is_running(&self) -> bool {
        self.running.load(Ordering::SeqCst)
    }

    #[cfg(oblivion_hev)]
    pub fn start(&self, config: String) -> Result<(), String> {
        if self.running.swap(true, Ordering::SeqCst) {
            return Err("the tunnel device is already running".to_string());
        }

        let bytes = config.into_bytes();
        let handle = thread::Builder::new()
            .name("oblivion-tun".to_string())
            .stack_size(1 << 20)
            .spawn(move || unsafe {
                bindings::hev_socks5_tunnel_main_from_str(
                    bytes.as_ptr(),
                    bytes.len() as u32,
                    -1,
                )
            })
            .map_err(|error| {
                self.running.store(false, Ordering::SeqCst);
                error.to_string()
            })?;

        *self.worker.lock().unwrap() = Some(handle);
        Ok(())
    }

    #[cfg(not(oblivion_hev))]
    pub fn start(&self, _config: String) -> Result<(), String> {
        Err("this build does not embed the tunnel device".to_string())
    }

    #[cfg(oblivion_hev)]
    pub fn stop(&self) {
        if !self.running.swap(false, Ordering::SeqCst) {
            return;
        }

        unsafe { bindings::hev_socks5_tunnel_quit() };

        if let Some(handle) = self.worker.lock().unwrap().take() {
            for _ in 0..50 {
                if handle.is_finished() {
                    break;
                }
                thread::sleep(Duration::from_millis(100));
            }
            let _ = handle.join();
        }
    }

    #[cfg(not(oblivion_hev))]
    pub fn stop(&self) {
        self.running.store(false, Ordering::SeqCst);
        let _ = Duration::from_millis(0);
        let _: Option<JoinHandle<i32>> = self.worker.lock().unwrap().take();
    }

    #[cfg(oblivion_hev)]
    pub fn counters(&self) -> Counters {
        if !self.is_running() {
            return Counters::default();
        }

        let mut tx_packets: usize = 0;
        let mut tx_bytes: usize = 0;
        let mut rx_packets: usize = 0;
        let mut rx_bytes: usize = 0;

        unsafe {
            bindings::hev_socks5_tunnel_stats(
                &mut tx_packets,
                &mut tx_bytes,
                &mut rx_packets,
                &mut rx_bytes,
            );
        }

        Counters {
            tx_packets: tx_packets as u64,
            tx_bytes: tx_bytes as u64,
            rx_packets: rx_packets as u64,
            rx_bytes: rx_bytes as u64,
        }
    }

    #[cfg(not(oblivion_hev))]
    pub fn counters(&self) -> Counters {
        Counters::default()
    }
}

impl Default for TunnelDevice {
    fn default() -> Self {
        Self::new()
    }
}
