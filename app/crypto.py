XOR_KEY = b"0xAA, 0x55, 0xC3, 0x3C"

def xor_decrypt(data):
    out = bytearray(len(data))
    for i in range(len(data)):
        out[i] = data[i] ^ XOR_KEY[i % len(XOR_KEY)]
    return bytes(out)