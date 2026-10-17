import pyautogui


pyautogui.PAUSE = 0
pyautogui.FAILSAFE = False


def execute_action(data):
    action = data.get("action")

    if action == "move":
        dx = data.get("dx", 0)
        dy = data.get("dy", 0)
        pyautogui.moveRel(dx, dy)
    elif action == "click":
        pyautogui.click()
    elif action == "right_click":
        pyautogui.rightClick()
    elif action == "scroll_up":
        pyautogui.scroll(100)
    elif action == "scroll_down":
        pyautogui.scroll(-100)
    elif action == "up":
        pyautogui.press("up")
    elif action == "down":
        pyautogui.press("down")
    elif action == "left":
        pyautogui.press("left")
    elif action == "right":
        pyautogui.press("right")
    elif action == "volume_up":
        pyautogui.press("volumeup")
    elif action == "volume_down":
        pyautogui.press("volumedown")
    elif action == "mute":
        pyautogui.press("volumemute")
    elif action == "space":
        pyautogui.press("space")
    elif action == "backspace":
        pyautogui.press("backspace")
    elif action == "enter":
        pyautogui.press("enter")
    elif action == "shut_down":
        pyautogui.hold("alt")
        pyautogui.press("f4")
        pyautogui.release("alt")
    elif action == "text":
        text = data.get("text", "")
        if text:
            pyautogui.write(text, interval=0)


def is_known_action(data):
    return data.get("action") in {
        "move", "click", "right_click", "scroll_up", "scroll_down",
        "up", "down", "left", "right", "volume_up", "volume_down",
        "mute", "space", "backspace", "enter", "text",
    }
