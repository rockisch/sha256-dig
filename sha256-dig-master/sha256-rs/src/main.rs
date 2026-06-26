mod sha256;

use sha2::{Digest, Sha256};
use sha256::Sha256 as MySha256;

use std::{env, process::ExitCode};

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();
    if args.len() > 2 {
        println!("Usage: sha256-rs <VALUE>");
        return ExitCode::from(1);
    }
    let data = &args[1];

    let a: [u8; 32] = Sha256::digest(&data).into();
    let b: [u8; 32] = MySha256::digest(&data);
    if a != b {
        eprintln!(
            "Custom SHA-256 implementation didn't match official one: {} {}",
            hex(&a),
            hex(&b)
        );
        return ExitCode::from(1);
    }

    println!("{}", hex(&a));
    return ExitCode::from(0);
}

const HEX_LOOKUP: [char; 16] = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
];

pub fn hex(bytes: &[u8]) -> String {
    bytes
        .iter()
        .flat_map(|&b| [HEX_LOOKUP[b as usize >> 4], HEX_LOOKUP[b as usize & 0xf]])
        .collect()
}
