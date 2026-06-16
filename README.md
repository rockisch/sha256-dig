# SHA-256 VHDL Project

My final project for Sistemas Digitais course is going to be the development of a SHA-256 hashing algorithm using VHDL.

## Group Members

- João Carneiro Haas (25204064) (02208A)

## Background

### SHA-2

[SHA-2](https://en.wikipedia.org/wiki/SHA-2) is a family of cryptographic hash functions designed by the NSA in 2001. It includes SHA-224, SHA-256, SHA-384, and SHA-512 (named for their output bit lengths). These algorithms take input data of any size and produce a fixed-size byte representation (hash) that uniquely represents that data. SHA-2 is widely used for digital signatures, password storage, and data integrity verification.

### SHA-256

Out of the different ciphers in the family, SHA-256 in general ends having the most widespread usage. Although it has less bits than the other commonly used variant SHA-512, which technically makes collisions more likely, so far no collisions have been found, and thus it ends up being choosen over the 'more secure' variant due to it's speed. It is used in SSL/TLS hahdshakes, 'shasum' verification of binary files, password hashing, and so on.

## Project

The idea of the project will be to implement the SHA256 algorithm using VHDL for messages of 55 bytes or less. Aside from a few control and clock signals, the system will have 1 440-bit (55 bytes) input for the message, and 1 256-bit output as the hash.

The reason behind this input size limitation is that it'll allow us to optimize the SHA256 implementation. SHA256 usually pre-processes the input by adding at minimum 65 bits of data and then splitting the input into 512-bit chunks, but by constraining our input to 440 bits (55 bytes), we can skip the chunk part and just treat the input directly as a chunk. This will allow the project to be simpler and faster.

## Structure

The project is split into 2 parts:
- `sha256-rs`: A reference Rust implementation so I can more easily check what the algorithm is supposed to use. To run it, `cd` into the folder and run `cargo run -- <target_string>`
- `sha256-vhdl`: The VHDL implementation
