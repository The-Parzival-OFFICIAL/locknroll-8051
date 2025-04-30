<<<<<<< HEAD
# mpmc_project
this is a mpmc_project where we use a 8051 micro controller to create a smart lock
=======
# 🔐 Password-Protected Door Lock System – 8051 Assembly

Welcome to the source code of a **password-protected door lock system** built using the **8051 microcontroller**. This embedded system uses a **4x4 keypad** and **16x2 LCD** for user input and feedback, supports password reset through **external interrupt (INT0)**, and includes a lockout mechanism with **buzzer alerts** and **servo control** to simulate door access.

---

## 📦 Features

- 🔑 4-digit password input using a keypad
- 🔐 XOR-based password encryption
- 📺 LCD feedback (Access Granted, Denied, Locked Out, etc.)
- 🚨 Lockout mode after 5 failed attempts
- 🛠️ Password reset via INT0 (push button)
- 🔄 Servo control to simulate door locking/unlocking
- 🔊 Buzzer alert in lockout mode
- 🧠 Written entirely in **8051 Assembly Language**

---

## 🧰 Hardware Used

| Component         | Description                          |
|------------------|--------------------------------------|
| AT89S52 (8051 MCU)| The heart of the system             |
| 16x2 LCD          | Displays messages                   |
| 4x4 Keypad        | For password input                  |
| L293D + DC Motor  | Simulates door lock (servo optional)|
| Push Button       | Triggers password reset (INT0)      |
| Buzzer            | Alerts during lockout               |

---

## 📌 Pin Configuration

| Peripheral        | Port & Pins         |
|------------------|---------------------|
| LCD Data         | Port 1              |
| LCD Control      | RS: P3.5, RW: P3.6, EN: P3.7 |
| Keypad (4x4)     | Port 2              |
| Push Button (INT0) | P3.2               |
| Buzzer           | P3.3                |
| Servo Motor      | P3.4                |

---

## 🔄 How It Works

1. On startup, a default encrypted password is loaded.
2. User is prompted to enter a 4-digit password.
3. If correct → access granted, servo opens the door.
4. If incorrect → system denies access and decrements attempt count.
5. After 5 wrong tries → system locks out and sounds the buzzer.
6. Press the reset button (INT0) to set a new password.

---

## 📃 License

MIT License. Fork it, build it, improve it 
>>>>>>> 5040cbf7b89d5e013ce4fcde82e0324c0b71ac69
