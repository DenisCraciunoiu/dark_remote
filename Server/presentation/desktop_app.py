import asyncio
import threading

import customtkinter as ctk
import pystray
from PIL import Image

from application.server import run_server
from domain.config import PORT
from infrastructure.discovery import get_local_ip
from infrastructure.resources import get_resource_path


class MouseServerApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("PC Remote Server")
        self.geometry("320x320")

        self.server_thread = None
        self.loop = None
        self.is_running = False
        self.tray_icon = None

        self.iconbitmap(get_resource_path("Desktop_icon.ico"))
        self.icon_on = self.load_icon_image("icon_on.png")
        self.icon_off = self.load_icon_image("icon_off.png")

        self.status_label = ctk.CTkLabel(
            self, text="Status: Stopped", text_color="gray", font=("Helvetica", 14)
        )
        self.status_label.pack(pady=15)

        self.ip_label = ctk.CTkLabel(self, text=f"IP: {get_local_ip()}:{PORT}")
        self.ip_label.pack(pady=10)

        self.start_btn = ctk.CTkButton(self, text="Start Server", command=self.start_server)
        self.start_btn.pack(pady=10)

        self.stop_btn = ctk.CTkButton(
            self, text="Stop Server", command=self.stop_server, state="disabled"
        )
        self.stop_btn.pack(pady=10)
        self.protocol("WM_DELETE_WINDOW", self.hide_window)

    def load_icon_image(self, file_name):
        """Loads and resizes an icon image safely."""
        icon_path = get_resource_path(file_name)
        try:
            image = Image.open(icon_path)
            return image.resize((64, 64))
        except FileNotFoundError:
            print(f"[Warning] {file_name} not found at {icon_path}. Fallback generated.")
            return Image.new("RGB", (64, 64), color=(128, 128, 128))

    def update_tray_icon(self):
        if self.tray_icon is not None:
            self.tray_icon.icon = self.icon_on if self.is_running else self.icon_off

    def start_server(self):
        if self.is_running:
            return

        self.is_running = True
        self.start_btn.configure(state="disabled")
        self.stop_btn.configure(state="normal")
        self.status_label.configure(text="Status: Listening", text_color="green")
        self.update_tray_icon()

        self.server_thread = threading.Thread(target=self.start_async_loop, daemon=True)
        self.server_thread.start()

    def stop_server(self):
        if not self.is_running or not self.loop:
            return

        self.is_running = False
        self.start_btn.configure(state="normal")
        self.stop_btn.configure(state="disabled")
        self.status_label.configure(text="Status: Stopped", text_color="gray")
        self.update_tray_icon()
        self.loop.call_soon_threadsafe(self.loop.stop)

    def start_async_loop(self):
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

        server_task = self.loop.create_task(run_server(get_local_ip(), PORT))

        def _on_done(t):
            if not t.cancelled() and t.exception():
                print(f"[Server] CRASHED: {t.exception()!r}")

        server_task.add_done_callback(_on_done)

        try:
            self.loop.run_forever()
        finally:
            server_task.cancel()
            self.loop.close()

    def hide_window(self):
        self.withdraw()

        current_icon_image = self.icon_on if self.is_running else self.icon_off
        menu = pystray.Menu(
            pystray.MenuItem("Open Remote Server", self.show_window, default=True),
            pystray.MenuItem("Quit App", self.quit_window),
        )
        self.tray_icon = pystray.Icon(
            "MouseServerTray", current_icon_image, "PC Remote Server", menu
        )
        threading.Thread(target=self.tray_icon.run, daemon=True).start()

    def show_window(self, icon=None, item=None):
        self.after(0, self._show_window)

    def _show_window(self):
        if self.tray_icon:
            self.tray_icon.stop()
            self.tray_icon = None
        self.deiconify()

    def quit_window(self, icon=None, item=None):
        self.after(0, self._quit_window)

    def _quit_window(self):
        if self.tray_icon:
            self.tray_icon.stop()
        self.stop_server()
        self.destroy()
