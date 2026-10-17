import socket

from zeroconf import ServiceInfo, Zeroconf

from domain.config import PORT


def get_local_ip():
    """Finds the primary local IP address of this computer on the network."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def setup_zeroconf(ip):
    """
    Broadcasts an mDNS signal using the PC's hostname.
    Allows the mobile app to automatically discover this specific machine.
    """
    hostname = socket.gethostname()
    instance_name = f"{hostname}._darkremote._tcp.local."

    info = ServiceInfo(
        "_darkremote._tcp.local.",
        instance_name,
        addresses=[socket.inet_aton(ip)],
        port=PORT,
        properties={},
        server=f"{hostname}.local.",
    )
    zc = Zeroconf(interfaces=[ip])
    zc.register_service(info)
    print(f"[mDNS] Broadcasting server as '{hostname}' at {ip}:{PORT}")
    return zc, info
