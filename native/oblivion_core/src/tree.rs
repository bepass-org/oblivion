use std::path::{Path, PathBuf};
use std::process::{Child, Command};

pub fn own_group(command: &mut Command) {
    #[cfg(unix)]
    {
        use std::os::unix::process::CommandExt;
        command.process_group(0);
    }
    #[cfg(not(unix))]
    let _ = command;
}

pub struct Tree {
    record: Option<PathBuf>,
    #[cfg(windows)]
    job: Option<job::Job>,
}

impl Tree {
    pub fn adopt(child: &Child, record: Option<PathBuf>) -> Self {
        if let Some(path) = &record {
            let _ = std::fs::write(path, child.id().to_string());
        }
        Self {
            record,
            #[cfg(windows)]
            job: job::Job::holding(child),
        }
    }
}

impl Drop for Tree {
    fn drop(&mut self) {
        #[cfg(windows)]
        drop(self.job.take());
        if let Some(path) = &self.record {
            let _ = std::fs::remove_file(path);
        }
    }
}

pub fn end(child: &mut Child, tree: Option<Tree>) {
    #[cfg(unix)]
    unsafe {
        libc::killpg(child.id() as libc::pid_t, libc::SIGKILL);
    }
    drop(tree);
    let _ = child.kill();
    let _ = child.wait();
}

pub fn record_path(directory: &Path) -> PathBuf {
    directory.join("core.pid")
}

#[cfg(target_os = "linux")]
pub fn end_leftovers(record: &Path, binaries: &[PathBuf]) -> usize {
    let Ok(text) = std::fs::read_to_string(record) else {
        return 0;
    };
    let _ = std::fs::remove_file(record);
    let Ok(group) = text.trim().parse::<i32>() else {
        return 0;
    };
    if group <= 1 {
        return 0;
    }

    let wanted: Vec<PathBuf> = binaries
        .iter()
        .filter_map(|binary| binary.canonicalize().ok())
        .collect();
    let Ok(entries) = std::fs::read_dir("/proc") else {
        return 0;
    };

    let mut ended = 0;
    for entry in entries.flatten() {
        let Some(pid) = entry
            .file_name()
            .to_str()
            .and_then(|name| name.parse::<i32>().ok())
        else {
            continue;
        };
        let in_group = std::fs::read_to_string(entry.path().join("stat"))
            .ok()
            .and_then(|stat| group_of(&stat))
            == Some(group);
        if !in_group {
            continue;
        }
        let ours = std::fs::read_link(entry.path().join("exe"))
            .map(|exe| wanted.contains(&exe))
            .unwrap_or(false);
        if ours && unsafe { libc::kill(pid, libc::SIGKILL) } == 0 {
            ended += 1;
        }
    }
    ended
}

#[cfg(not(target_os = "linux"))]
pub fn end_leftovers(record: &Path, _binaries: &[PathBuf]) -> usize {
    let _ = std::fs::remove_file(record);
    0
}

#[cfg(target_os = "linux")]
pub fn group_of(stat: &str) -> Option<i32> {
    let close = stat.rfind(')')?;
    stat[close + 1..].split_whitespace().nth(2)?.parse().ok()
}

#[cfg(windows)]
mod job {
    use std::os::windows::io::AsRawHandle;
    use std::process::Child;
    use windows_sys::Win32::Foundation::{CloseHandle, HANDLE};
    use windows_sys::Win32::System::JobObjects::{
        AssignProcessToJobObject, CreateJobObjectW, JobObjectExtendedLimitInformation,
        SetInformationJobObject, TerminateJobObject, JOBOBJECT_EXTENDED_LIMIT_INFORMATION,
        JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE,
    };

    pub struct Job(HANDLE);

    unsafe impl Send for Job {}

    impl Job {
        pub fn holding(child: &Child) -> Option<Self> {
            unsafe {
                let handle = CreateJobObjectW(std::ptr::null(), std::ptr::null());
                if handle.is_null() {
                    return None;
                }
                let job = Self(handle);
                let mut limits: JOBOBJECT_EXTENDED_LIMIT_INFORMATION = std::mem::zeroed();
                limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
                let limited = SetInformationJobObject(
                    job.0,
                    JobObjectExtendedLimitInformation,
                    &limits as *const _ as *const core::ffi::c_void,
                    std::mem::size_of::<JOBOBJECT_EXTENDED_LIMIT_INFORMATION>() as u32,
                ) != 0;
                if !limited || AssignProcessToJobObject(job.0, child.as_raw_handle() as HANDLE) == 0
                {
                    return None;
                }
                Some(job)
            }
        }
    }

    impl Drop for Job {
        fn drop(&mut self) {
            unsafe {
                TerminateJobObject(self.0, 1);
                CloseHandle(self.0);
            }
        }
    }
}

#[cfg(all(test, target_os = "linux"))]
mod tests {
    use super::*;
    use std::process::Stdio;
    use std::time::{Duration, Instant};

    fn members(group: i32) -> Vec<i32> {
        std::fs::read_dir("/proc")
            .unwrap()
            .flatten()
            .filter_map(|entry| {
                let pid = entry.file_name().to_str()?.parse::<i32>().ok()?;
                let stat = std::fs::read_to_string(entry.path().join("stat")).ok()?;
                let state = stat[stat.rfind(')')? + 1..]
                    .split_whitespace()
                    .next()?
                    .to_string();
                (group_of(&stat) == Some(group) && state != "Z").then_some(pid)
            })
            .collect()
    }

    fn settle(group: i32) -> Vec<i32> {
        let deadline = Instant::now() + Duration::from_secs(3);
        while Instant::now() < deadline && !members(group).is_empty() {
            std::thread::sleep(Duration::from_millis(20));
        }
        members(group)
    }

    fn spawn_family() -> Child {
        let mut command = Command::new("sh");
        command
            .args(["-c", "sleep 60 & sleep 60 & wait"])
            .stdin(Stdio::null());
        own_group(&mut command);
        let child = command.spawn().unwrap();
        let group = child.id() as i32;
        let deadline = Instant::now() + Duration::from_secs(3);
        while Instant::now() < deadline && members(group).len() < 3 {
            std::thread::sleep(Duration::from_millis(20));
        }
        assert_eq!(members(group).len(), 3);
        child
    }

    #[test]
    fn the_group_is_read_after_a_name_holding_a_paren() {
        assert_eq!(group_of("42 (a) b) S 1 977 977 0 -1"), Some(977));
        assert_eq!(group_of("42 (sleep) S 1 31 31"), Some(31));
        assert_eq!(group_of("no paren here"), None);
    }

    #[test]
    fn ending_the_core_takes_what_it_started_with_it() {
        let mut child = spawn_family();
        let group = child.id() as i32;

        end(&mut child, None);

        assert!(settle(group).is_empty());
    }

    #[test]
    fn a_group_left_by_an_earlier_run_is_ended_through_its_record() {
        let directory = std::env::temp_dir().join(format!("oblivion-tree-{}", std::process::id()));
        std::fs::create_dir_all(&directory).unwrap();
        let record = record_path(&directory);

        let mut child = spawn_family();
        let group = child.id() as i32;
        let tree = Tree::adopt(&child, Some(record.clone()));
        std::mem::forget(tree);
        assert_eq!(std::fs::read_to_string(&record).unwrap(), group.to_string());

        let binaries = [PathBuf::from("/bin/sh"), PathBuf::from("/bin/sleep")];
        assert_eq!(end_leftovers(&record, &binaries), 3);
        let _ = child.wait();

        assert!(settle(group).is_empty());
        assert!(!record.exists());
        let _ = std::fs::remove_dir_all(&directory);
    }

    #[test]
    fn a_record_naming_someone_else_ends_nothing() {
        let directory =
            std::env::temp_dir().join(format!("oblivion-tree-other-{}", std::process::id()));
        std::fs::create_dir_all(&directory).unwrap();
        let record = record_path(&directory);

        let mut child = spawn_family();
        let group = child.id() as i32;
        std::fs::write(&record, group.to_string()).unwrap();

        let binaries = [PathBuf::from("/nonexistent/aether")];
        assert_eq!(end_leftovers(&record, &binaries), 0);
        assert_eq!(members(group).len(), 3);

        end(&mut child, None);
        assert!(settle(group).is_empty());
        let _ = std::fs::remove_dir_all(&directory);
    }

    #[test]
    fn dropping_the_tree_forgets_its_record() {
        let directory =
            std::env::temp_dir().join(format!("oblivion-tree-drop-{}", std::process::id()));
        std::fs::create_dir_all(&directory).unwrap();
        let record = record_path(&directory);

        let mut child = Command::new("true").spawn().unwrap();
        let tree = Tree::adopt(&child, Some(record.clone()));
        assert!(record.exists());
        end(&mut child, Some(tree));
        assert!(!record.exists());
        let _ = std::fs::remove_dir_all(&directory);
    }
}
