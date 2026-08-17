use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

const HEV_CFLAGS: &str = "-fPIC -Wno-error";

const ARCHIVES: [(&str, &str); 4] = [
    ("bin", "hev-socks5-tunnel"),
    ("third-part/yaml/bin", "yaml"),
    ("third-part/lwip/bin", "lwip"),
    ("third-part/hev-task-system/bin", "hev-task-system"),
];

fn candidate_roots(manifest: &Path) -> Vec<PathBuf> {
    if let Ok(value) = env::var("OBLIVION_HEV_ROOT") {
        return vec![PathBuf::from(value)];
    }

    vec![
        manifest.join("../../android/aether-vpn/src/main/jni/hev-socks5-tunnel"),
        manifest.join("../../../hev-socks5-tunnel"),
    ]
}

fn hev_root(manifest: &Path) -> Option<PathBuf> {
    for candidate in candidate_roots(manifest) {
        let Ok(resolved) = candidate.canonicalize() else {
            continue;
        };
        if resolved.join("include/hev-socks5-tunnel.h").exists() {
            return Some(resolved);
        }
    }
    None
}

fn archives_present(root: &Path) -> bool {
    ARCHIVES
        .iter()
        .all(|(dir, name)| root.join(dir).join(format!("lib{name}.a")).exists())
}

fn stamp_path(root: &Path) -> PathBuf {
    root.join("bin/.oblivion-build-flags")
}

fn stamp_matches(root: &Path) -> bool {
    fs::read_to_string(stamp_path(root))
        .map(|value| value.trim() == HEV_CFLAGS)
        .unwrap_or(false)
}

fn run_make(root: &Path, make: &str, target_os: &str, goal: &str) -> Result<(), String> {
    let jobs = env::var("NUM_JOBS").unwrap_or_else(|_| "1".to_string());

    let mut command = Command::new(make);
    command
        .current_dir(root)
        .arg(goal)
        .arg(format!("-j{jobs}"))
        .arg(format!("CFLAGS={HEV_CFLAGS}"));

    if target_os == "macos" {
        command.arg("CC=clang");
    }

    let output = command
        .output()
        .map_err(|error| format!("could not run {make}: {error}"))?;

    if output.status.success() {
        return Ok(());
    }

    let detail = String::from_utf8_lossy(&output.stderr);
    let tail: Vec<String> = detail
        .trim()
        .lines()
        .rev()
        .take(6)
        .map(|line| line.trim().to_string())
        .collect();
    Err(tail.into_iter().rev().collect::<Vec<_>>().join("; "))
}

fn build_archives(root: &Path, target_os: &str) -> Result<(), String> {
    let make = env::var("OBLIVION_HEV_MAKE").unwrap_or_else(|_| "make".to_string());

    if !stamp_matches(root) {
        let _ = run_make(root, &make, target_os, "clean");
    }

    run_make(root, &make, target_os, "static")?;

    let _ = fs::write(stamp_path(root), HEV_CFLAGS);
    Ok(())
}

fn required() -> bool {
    env::var("OBLIVION_REQUIRE_HEV")
        .map(|value| value == "1" || value.eq_ignore_ascii_case("true"))
        .unwrap_or(false)
}

fn give_up(reason: &str) {
    if required() {
        panic!(
            "tunnel mode is required for this build but {reason}. \
             Unset OBLIVION_REQUIRE_HEV to build a proxy only binary."
        );
    }
    println!("cargo:warning={reason}, tunnel mode stays off");
}

fn main() {
    println!("cargo::rustc-check-cfg=cfg(oblivion_hev)");
    println!("cargo:rerun-if-env-changed=OBLIVION_HEV_ROOT");
    println!("cargo:rerun-if-env-changed=OBLIVION_HEV_MAKE");
    println!("cargo:rerun-if-env-changed=OBLIVION_REQUIRE_HEV");

    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();

    let root = match hev_root(&manifest) {
        Some(value) => value,
        None => {
            give_up(
                "the hev-socks5-tunnel sources are missing, \
                 run git submodule update --init --recursive",
            );
            return;
        }
    };

    println!("cargo:rerun-if-changed={}", root.join("src").display());
    println!("cargo:rerun-if-changed={}", root.join("Makefile").display());

    if target_os == "windows" {
        println!(
            "cargo:warning=on windows the tunnel device runs as the bundled \
             hev-socks5-tunnel.exe helper rather than being linked in"
        );
        return;
    }

    if !archives_present(&root) || !stamp_matches(&root) {
        if let Err(error) = build_archives(&root, &target_os) {
            give_up(&format!("hev-socks5-tunnel did not build: {error}"));
            return;
        }
    }

    if !archives_present(&root) {
        give_up("hev-socks5-tunnel reported success but left no archives behind");
        return;
    }

    for (dir, _) in ARCHIVES {
        println!(
            "cargo:rustc-link-search=native={}",
            root.join(dir).display()
        );
    }

    println!("cargo:rustc-link-lib=static=hev-socks5-tunnel");
    println!("cargo:rustc-link-lib=static=lwip");
    println!("cargo:rustc-link-lib=static=hev-task-system");
    println!("cargo:rustc-link-lib=static=yaml");
    println!("cargo:rustc-link-lib=dylib=pthread");
    println!("cargo:rustc-cfg=oblivion_hev");
}
