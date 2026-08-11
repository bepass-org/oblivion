use std::io::{Read, Write};
use std::net::{Shutdown, SocketAddr, TcpStream};
use std::time::Duration;

const CONNECT_TIMEOUT: Duration = Duration::from_secs(4);
const IO_TIMEOUT: Duration = Duration::from_secs(4);

const PROBE_HOST: &str = "connectivity.cloudflareclient.com";
const PROBE_PORT: u16 = 80;
const PROBE_PATH: &str = "/cdn-cgi/trace";

pub fn socks_reachable(socks_port: u16) -> bool {
    perform(socks_port).unwrap_or(false)
}

fn perform(socks_port: u16) -> std::io::Result<bool> {
    let address: SocketAddr = format!("127.0.0.1:{socks_port}")
        .parse()
        .map_err(|_| std::io::Error::other("invalid socks address"))?;

    let mut stream = TcpStream::connect_timeout(&address, CONNECT_TIMEOUT)?;
    stream.set_read_timeout(Some(IO_TIMEOUT))?;
    stream.set_write_timeout(Some(IO_TIMEOUT))?;
    stream.set_nodelay(true)?;

    stream.write_all(&[0x05, 0x01, 0x00])?;
    stream.flush()?;

    let mut greeting = [0u8; 2];
    stream.read_exact(&mut greeting)?;
    if greeting[0] != 0x05 || greeting[1] != 0x00 {
        return Ok(false);
    }

    let host = PROBE_HOST.as_bytes();
    let mut request = Vec::with_capacity(7 + host.len());
    request.extend_from_slice(&[0x05, 0x01, 0x00, 0x03, host.len() as u8]);
    request.extend_from_slice(host);
    request.extend_from_slice(&PROBE_PORT.to_be_bytes());
    stream.write_all(&request)?;
    stream.flush()?;

    let mut head = [0u8; 4];
    stream.read_exact(&mut head)?;
    if head[1] != 0x00 {
        return Ok(false);
    }

    let trailing = match head[3] {
        0x01 => 4 + 2,
        0x04 => 16 + 2,
        0x03 => {
            let mut length = [0u8; 1];
            stream.read_exact(&mut length)?;
            length[0] as usize + 2
        }
        _ => return Ok(false),
    };
    let mut discard = vec![0u8; trailing];
    stream.read_exact(&mut discard)?;

    let http = format!(
        "GET {PROBE_PATH} HTTP/1.1\r\nHost: {PROBE_HOST}\r\nUser-Agent: Oblivion\r\nConnection: close\r\n\r\n"
    );
    stream.write_all(http.as_bytes())?;
    stream.flush()?;

    let mut response = [0u8; 64];
    let read = stream.read(&mut response)?;
    let _ = stream.shutdown(Shutdown::Both);
    if read == 0 {
        return Ok(false);
    }

    let status = String::from_utf8_lossy(&response[..read]);
    Ok(status.contains(" 200"))
}
