# SHA-256 VHDL Project

My final project for Sistemas Digitais course is going to be the development of a SHA-256 algorithm using VHDL.

## Group Members

- João Carneiro Haas (25204064) (02208A)

## Background

### SHA-2

[SHA-2](https://en.wikipedia.org/wiki/SHA-2) is a family of cryptographic hash functions designed by the NSA in 2001. It includes SHA-224, SHA-256, SHA-384, and SHA-512 (named for their output bit lengths). These algorithms take input data of any size and produce a fixed-size byte representation (hash) that uniquely represents that data. SHA-2 is widely used for digital signatures, password storage, and data integrity verification.

### SHA-256

Out of the different ciphers in the family, SHA-256 in general ends having the most widespread usage. Although it has less bits than the other commonly used variant SHA-512, which technically makes collisions more likely, so far no collisions have been found, and thus it ends up being choosen over the 'more secure' variant due to it's speed. It is used in SSL/TLS hahdshakes, 'shasum' verification of binary files, password hashing, and so on.

## Project

The idea of the project will be to implement one of the SHA-2 algorithms, SHA-256, using VHDL. Aside from a few control and clock signals, the project will have 2 64-bit inputs to determine the location and size of a variable-sized input byte array, and 1 256-bit output containing the resulting SHA-256 hash.

As mentioned above, SHA-256 was choosen among the SHA-2 family due to it being the one with most widespread usage. While it wouldn't be too hard to implement all SHA-2 variants and letting the user select which one to use through a separate input signal, internally the bump to SHA-512 has a few changes that will either require extensive usage of generics/macros or duplication of a lot of the logic, both of which would make reviewing and developing the project a lot harder. Depending on my availability at the end of the semester I might set as a personal goal to implement all variants, but I'm constraining the initial scope of the project to just SHA-256.

## Structure

The project is split into 2 parts:
- `sha256-rs`: A reference Rust implementation so I can more easily check what the algorithm is supposed to use. To run it, `cd` into the folder and run `cargo run -- <target_string>`
- `sha256-vhdl`: The VHDL implementation
