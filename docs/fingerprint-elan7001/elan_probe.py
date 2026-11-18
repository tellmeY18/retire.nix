import os, fcntl, struct, ctypes, time, sys

SPI = "/dev/spidev1.0"
HID = "/dev/hidraw0"

def ioc_w(nr, size, typ=ord('k')):
    return (1 << 30) | (size << 16) | (typ << 8) | nr

def hidiocsfeature(n):
    return (3 << 30) | (n << 16) | (ord('H') << 8) | 0x06

fd = os.open(SPI, os.O_RDWR)
fcntl.ioctl(fd, ioc_w(1, 1), struct.pack("B", 0))            # SPI_IOC_WR_MODE = 0
fcntl.ioctl(fd, ioc_w(3, 1), struct.pack("B", 8))            # bits per word
fcntl.ioctl(fd, ioc_w(4, 4), struct.pack("I", 12_000_000))   # max speed

def xfer(wr, rdlen=0, speed=12_000_000):
    wbuf = ctypes.create_string_buffer(bytes(wr), len(wr))
    msgs, keep = [], [wbuf]
    msgs.append(struct.pack("QQIIHBBBBBx", ctypes.addressof(wbuf), 0, len(wr), speed, 0, 8, 0, 0, 0, 0))
    rbuf = None
    if rdlen:
        rbuf = ctypes.create_string_buffer(rdlen)
        msgs.append(struct.pack("QQIIHBBBBBx", 0, ctypes.addressof(rbuf), rdlen, speed, 0, 8, 0, 0, 0, 0))
    arg = b"".join(msgs)
    fcntl.ioctl(fd, ioc_w(0, 32 * len(msgs)), arg)
    return rbuf.raw if rbuf else b""

def single_read(cmd):
    return xfer([cmd, 0xFF], 1)[0]

def read_reg(r):
    return xfer([r | 0x40], 1)[0]

def hwreset():
    h = os.open(HID, os.O_RDWR)
    try:
        fcntl.ioctl(h, hidiocsfeature(5), bytes([0x0e, 0, 0, 0, 0]))
    finally:
        os.close(h)

print("status (pre-reset): 0x%02x" % single_read(0x03))
if "--noreset" not in sys.argv:
    hwreset(); print("hid hw reset sent")
    xfer([0x31]); print("sw reset sent")
    time.sleep(0.05)
h = single_read(0x08); w = single_read(0x09); v = single_read(0x0a); r17 = read_reg(0x17)
print("status: 0x%02x" % single_read(0x03))
print("raw height=%d width=%d (frame %dx%d)" % (h, w, h + 1, w + 1))
print("raw version=0x%02x reg17=0x%02x" % (v, r17))
