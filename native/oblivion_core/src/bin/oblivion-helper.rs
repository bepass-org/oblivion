use std::process::exit;

fn main() {
    let mut arguments = std::env::args().skip(1);
    let root = match arguments.next() {
        Some(value) => value,
        None => {
            eprintln!("usage: oblivion-helper <state directory>");
            exit(2);
        }
    };

    exit(oblivion_core::helper::run(&root));
}
