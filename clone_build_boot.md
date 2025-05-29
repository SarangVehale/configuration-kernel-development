# Clone + Build + Boot the kernel in QEMU

1. **Cloning** mainline
2. **Building** the kernel
3. **Booting** it in QEMU
4. **(Optional)**: Making quick changes and testing them

---

## 🧰 Assumptions

You’re on a Linux distro (e.g. Ubuntu/Debian), and you know how to use Git and a terminal.

---

## ✅ 1. Clone Linus’s Mainline Kernel

Use HTTPS (recommended):

```bash
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
```

Or shallow clone (much faster):

```bash
git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
```
> Not recommended if you're planning to contribute upstream

---

## ✅ 2. Install Dependencies

For Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev qemu-system-x86
```

---

## ✅ 3. Configure Kernel (QEMU-Ready)

Use a small default config for x86\_64:

```bash
make defconfig
```

Optionally, enable virtualized kernel options manually:

```bash
make menuconfig
# Navigate to "Processor type and features"
# Enable "KVM for Virtualization" and any debugging options you want
```

---

## ✅ 4. Build the Kernel

This takes \~10–30 mins on a decent system:

```bash
make -j$(nproc)
```

This gives you the kernel image:
👉 `arch/x86/boot/bzImage`

---

## ✅ 5. Create a Root Filesystem

You’ll need a basic root filesystem for QEMU to boot.

Here’s a minimal way using **Buildroot** (you can use BusyBox too):

```bash
git clone https://github.com/buildroot/buildroot.git
cd buildroot
make qemu_x86_64_defconfig
make -j$(nproc)
```

After it finishes, you'll get:

* Root filesystem image: `output/images/rootfs.ext2`
* Kernel (you won’t need this if using yours): `output/images/bzImage`

---

## ✅ 6. Boot in QEMU

Go back to your kernel directory, and launch QEMU:

```bash
qemu-system-x86_64 \
  -kernel arch/x86/boot/bzImage \
  -append "root=/dev/sda console=ttyS0" \
  -hda ../buildroot/output/images/rootfs.ext2 \
  -nographic
```

Now you’ve booted a Linux kernel **you built from source**, with a basic Linux environment running in QEMU.

---

## 🛠️ 7. Make Changes & Rebuild

Want to change some kernel code? Example:

```c
// in init/main.c
printk(KERN_INFO "Hello, kernel world!\n");
```

Then just rebuild:

```bash
make -j$(nproc)
```

And re-run QEMU. Boom — modified kernel live.

---

## ✅ Optional: Faster Iteration with Scripts

You can wrap the whole thing into a shell script like:

```bash
#!/bin/bash
make -j$(nproc) &&
qemu-system-x86_64 \
  -kernel arch/x86/boot/bzImage \
  -append "root=/dev/sda console=ttyS0" \
  -hda ../buildroot/output/images/rootfs.ext2 \
  -nographic
```

---

## 🧪 Bonus: Debug With GDB

Boot QEMU with GDB stub:

```bash
qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
  -append "root=/dev/sda console=ttyS0" \
  -hda ../buildroot/output/images/rootfs.ext2 \
  -nographic -s -S
```

Then from another terminal:

```bash
gdb vmlinux
(gdb) target remote :1234
```

---
