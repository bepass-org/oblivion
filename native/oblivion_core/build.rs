use std::env;
use std::path::{Path, PathBuf};

fn hev_root() -> Option<PathBuf> {
    if let Ok(value) = env::var("OBLIVION_HEV_ROOT") {
        let path = PathBuf::from(value);
        if path.join("include/hev-socks5-tunnel.h").exists() {
            return Some(path);
        }
        return None;
    }

    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let candidate = manifest
        .join("../../../hev-socks5-tunnel")
        .canonicalize()
        .ok()?;
    if candidate.join("include/hev-socks5-tunnel.h").exists() {
        Some(candidate)
    } else {
        None
    }
}

fn archive(dir: &Path, name: &str) -> bool {
    dir.join(format!("lib{name}.a")).exists()
}

fn main() {
    println!("cargo::rustc-check-cfg=cfg(oblivion_hev)");
    println!("cargo:rerun-if-env-changed=OBLIVION_HEV_ROOT");

    let root = match hev_root() {
        Some(value) => value,
        None => return,
    };

    let tunnel_bin = root.join("bin");
    let yaml_bin = root.join("third-part/yaml/bin");
    let lwip_bin = root.join("third-part/lwip/bin");
    let task_bin = root.join("third-part/hev-task-system/bin");

    let ready = archive(&tunnel_bin, "hev-socks5-tunnel")
        && archive(&yaml_bin, "yaml")
        && archive(&lwip_bin, "lwip")
        && archive(&task_bin, "hev-task-system");

    if !ready {
        println!(
            "cargo:warning=hev-socks5-tunnel archives are missing, \
             tunnel mode will be unavailable"
        );
        return;
    }

    for dir in [&tunnel_bin, &yaml_bin, &lwip_bin, &task_bin] {
        println!("cargo:rustc-link-search=native={}", dir.display());
        println!("cargo:rerun-if-changed={}", dir.display());
    }

    println!("cargo:rustc-link-lib=static=hev-socks5-tunnel");
    println!("cargo:rustc-link-lib=static=lwip");
    println!("cargo:rustc-link-lib=static=hev-task-system");
    println!("cargo:rustc-link-lib=static=yaml");

    let target = env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    if target != "windows" {
        println!("cargo:rustc-link-lib=dylib=pthread");
    }

    println!("cargo:rustc-cfg=oblivion_hev");
}
