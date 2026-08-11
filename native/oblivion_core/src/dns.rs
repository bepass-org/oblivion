use std::fs;
use std::path::{Path, PathBuf};

const RESOLV_CONF: &str = "/etc/resolv.conf";
const BACKUP_DIR: &str = "/run/oblivion";
const BACKUP_FILE: &str = "/run/oblivion/resolv.conf.backup";
const SYMLINK_MARKER: &str = "/run/oblivion/resolv.conf.symlink";
const BANNER: &str = "# written by oblivion while the tunnel is active";

#[derive(Debug)]
pub enum Previous {
    Symlink(PathBuf),
    Contents(String),
    Missing,
}

pub struct DnsOverride {
    previous: Option<Previous>,
}

impl DnsOverride {
    pub const fn new() -> Self {
        Self { previous: None }
    }

    pub fn is_active(&self) -> bool {
        self.previous.is_some()
    }

    pub fn apply(&mut self, servers: &[String]) -> Result<String, String> {
        if self.previous.is_some() {
            return Err("the resolver is already redirected".to_string());
        }
        if servers.is_empty() {
            return Err("no resolver address was supplied".to_string());
        }

        let path = Path::new(RESOLV_CONF);
        let previous = if let Ok(target) = fs::read_link(path) {
            Previous::Symlink(target)
        } else if path.exists() {
            match fs::read_to_string(path) {
                Ok(contents) if contents.contains(BANNER) => {
                    return Err("a stale oblivion resolver file is in place".to_string())
                }
                Ok(contents) => Previous::Contents(contents),
                Err(error) => return Err(error.to_string()),
            }
        } else {
            Previous::Missing
        };

        persist_backup(&previous);

        let mut body = String::from(BANNER);
        body.push('\n');
        for server in servers {
            body.push_str(&format!("nameserver {server}\n"));
        }
        body.push_str("options edns0 trust-ad\n");

        if matches!(previous, Previous::Symlink(_)) {
            fs::remove_file(path).map_err(|error| error.to_string())?;
        }
        fs::write(path, body).map_err(|error| error.to_string())?;

        self.previous = Some(previous);
        Ok(servers.join(", "))
    }

    pub fn restore(&mut self) {
        let previous = match self.previous.take() {
            Some(value) => value,
            None => return,
        };
        restore_previous(&previous);
        clear_backup();
    }
}

impl Default for DnsOverride {
    fn default() -> Self {
        Self::new()
    }
}

fn persist_backup(previous: &Previous) {
    let _ = fs::create_dir_all(BACKUP_DIR);
    match previous {
        Previous::Symlink(target) => {
            let _ = fs::write(SYMLINK_MARKER, target.to_string_lossy().as_bytes());
            let _ = fs::remove_file(BACKUP_FILE);
        }
        Previous::Contents(contents) => {
            let _ = fs::write(BACKUP_FILE, contents);
            let _ = fs::remove_file(SYMLINK_MARKER);
        }
        Previous::Missing => {
            let _ = fs::remove_file(BACKUP_FILE);
            let _ = fs::remove_file(SYMLINK_MARKER);
        }
    }
}

fn clear_backup() {
    let _ = fs::remove_file(BACKUP_FILE);
    let _ = fs::remove_file(SYMLINK_MARKER);
}

fn restore_previous(previous: &Previous) {
    let path = Path::new(RESOLV_CONF);
    match previous {
        Previous::Symlink(target) => {
            let _ = fs::remove_file(path);
            let _ = std::os::unix::fs::symlink(target, path);
        }
        Previous::Contents(contents) => {
            let _ = fs::write(path, contents);
        }
        Previous::Missing => {
            let _ = fs::remove_file(path);
        }
    }
}

pub fn recover_stale_override() -> bool {
    let path = Path::new(RESOLV_CONF);
    let looks_stale = fs::read_to_string(path)
        .map(|contents| contents.contains(BANNER))
        .unwrap_or(false);
    if !looks_stale {
        clear_backup();
        return false;
    }

    if let Ok(target) = fs::read_to_string(SYMLINK_MARKER) {
        restore_previous(&Previous::Symlink(PathBuf::from(target.trim())));
    } else if let Ok(contents) = fs::read_to_string(BACKUP_FILE) {
        restore_previous(&Previous::Contents(contents));
    } else {
        return false;
    }

    clear_backup();
    true
}
