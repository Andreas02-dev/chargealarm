## Installation using Nix

### Getting started

-   Install Nix and enable Nix Flakes
-   Install direnv
-   Run `direnv allow` in this directory
-   Create the avd using `create-avd`
-   Start the avd once using `start-avd`
-   Perform the modifications as shown in `Emulator` below

Make sure you have installed the prerequisites for your OS: https://tauri.app/start/prerequisites/, then run:
  cd chargealarm
  yarn
  yarn tauri android init

For Desktop development, run:
  yarn tauri dev

For Android development, run:
  yarn tauri android dev

#### Emulator

Modify
`../.android/avd/phone.avd/config.ini`
and
`../.android/avd/phone.avd/hardware-qemu.ini`

```
hw.gpu.enabled = true
hw.gpu.mode = host
hw.keyboard = true
hw.audioInput = no
hw.audioOutput = no
```