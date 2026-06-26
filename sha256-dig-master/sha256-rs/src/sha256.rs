pub struct Sha256 {
    pub state: [u32; 8],
    schedule: [u32; 64],
}

impl Default for Sha256 {
    fn default() -> Self {
        Sha256 {
            state: STATE_256,
            schedule: [0; _],
        }
    }
}

impl Sha256 {
    fn process_data(&mut self, data: &[u8]) {
        let (chunks, remainder) = data.as_chunks::<64>();
        let mut i = 1;
        for chunk in chunks.iter() {
            self.process_chunk(i, chunk);
            i += 1;
        }
        let mut final_chunk = [0u8; 64];
        final_chunk[..remainder.len()].copy_from_slice(remainder);
        final_chunk[remainder.len()] = 128;
        if remainder.len() >= 56 {
            self.process_chunk(i, &final_chunk);
            final_chunk.fill(0);
            i += 1;
        }
        final_chunk[56..64].copy_from_slice(&(data.len() * 8).to_be_bytes());
        self.process_chunk(i, &final_chunk);
    }

    fn process_chunk(&mut self, _i: usize, chunk: &[u8; 64]) {
        let (subchunks, _) = chunk.as_chunks::<4>();
        for (t, &subchunk) in subchunks.iter().enumerate() {
            let value: u32 = u32::from_be_bytes(subchunk);
            self.schedule[t] = value;
        }
        for t in 16..64 {
            self.schedule[t] = (ssig1_256(self.schedule[t - 2]) as u64
                + self.schedule[t - 7] as u64
                + ssig0_256(self.schedule[t - 15]) as u64
                + self.schedule[t - 16] as u64) as u32
        }
        // println!("SCHEDULE {:?}", self.schedule);
        let mut a = self.state[0];
        let mut b = self.state[1];
        let mut c = self.state[2];
        let mut d = self.state[3];
        let mut e = self.state[4];
        let mut f = self.state[5];
        let mut g = self.state[6];
        let mut h = self.state[7];
        // println!("VALUES {} {} {} {} {} {} {} {}", a, b, c, d, e, f, g, h);
        for t in 0..64 {
            let t1 = (h as u64
                + bsig1_256(e) as u64
                + ch_256(e, f, g) as u64
                + K_256[t] as u64
                + self.schedule[t] as u64) as u32;
            let t2 = (bsig0_256(a) as u64 + maj_256(a, b, c) as u64) as u32;
            h = g;
            g = f;
            f = e;
            e = (d as u64 + t1 as u64) as u32;
            d = c;
            c = b;
            b = a;
            a = (t1 as u64 + t2 as u64) as u32;
            // if t == 0 || t == 62 || t == 63 {
            //     println!("VALUES {} {} {} {} {} {} {} {}", a, b, c, d, e, f, g, h);
            // }
        }
        self.state[0] = (self.state[0] as u64 + a as u64) as u32;
        self.state[1] = (self.state[1] as u64 + b as u64) as u32;
        self.state[2] = (self.state[2] as u64 + c as u64) as u32;
        self.state[3] = (self.state[3] as u64 + d as u64) as u32;
        self.state[4] = (self.state[4] as u64 + e as u64) as u32;
        self.state[5] = (self.state[5] as u64 + f as u64) as u32;
        self.state[6] = (self.state[6] as u64 + g as u64) as u32;
        self.state[7] = (self.state[7] as u64 + h as u64) as u32;
        // println!("STATE {:?}", self.state);
    }

    pub fn digest(data: &str) -> [u8; 32] {
        let mut sha = Self::default();
        sha.process_data(data.as_bytes());
        let mut result: [u8; 32] = [0; 32];
        for (i, byte) in sha.state.iter().flat_map(|v| v.to_be_bytes()).enumerate() {
            result[i] = byte;
        }
        result
    }
}

const STATE_256: [u32; 8] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

const K_256: [u32; 64] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

fn ch_256(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ (!x & z)
}

fn maj_256(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ (x & z) ^ (y & z)
}

fn bsig0_256(x: u32) -> u32 {
    x.rotate_right(2) ^ x.rotate_right(13) ^ x.rotate_right(22)
}

fn bsig1_256(x: u32) -> u32 {
    x.rotate_right(6) ^ x.rotate_right(11) ^ x.rotate_right(25)
}

fn ssig0_256(x: u32) -> u32 {
    x.rotate_right(7) ^ x.rotate_right(18) ^ (x >> 3)
}

fn ssig1_256(x: u32) -> u32 {
    x.rotate_right(17) ^ x.rotate_right(19) ^ (x >> 10)
}
