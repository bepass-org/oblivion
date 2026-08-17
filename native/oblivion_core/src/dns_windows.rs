pub struct DnsOverride {
    active: bool,
}

impl DnsOverride {
    pub const fn new() -> Self {
        Self { active: false }
    }

    pub fn is_active(&self) -> bool {
        self.active
    }

    pub fn apply(&mut self, _servers: &[String]) -> Result<String, String> {
        Err("the tunnel adapter carries the resolver on windows".to_string())
    }

    pub fn restore(&mut self) {
        self.active = false;
    }
}

impl Default for DnsOverride {
    fn default() -> Self {
        Self::new()
    }
}

pub fn recover_stale_override() -> bool {
    false
}
