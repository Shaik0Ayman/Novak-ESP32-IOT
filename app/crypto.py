# XOR key must match ESP32 crypto.h: {0xAA, 0x55, 0xC3, 0x3C}
XOR_KEY = bytes([0xAA, 0x55, 0xC3, 0x3C])

def xor_decrypt(data):
    """Decrypt XOR-encrypted data using the same key as ESP32"""
    out = bytearray(len(data))
    for i in range(len(data)):
        out[i] = data[i] ^ XOR_KEY[i % len(XOR_KEY)]
    return bytes(out)