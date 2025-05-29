# Linux Kernel Development Starter Guide

This repository provides a minimal setup and workflow for:

* Cloning Linus Torvalds’s mainline Linux kernel
* Building the kernel and booting it with QEMU
* Automating patch creation and submission
* Navigating kernel subsystems effectively

---

## Table of Contents

* [Prerequisites](#prerequisites)
* [Clone the Kernel](#clone-the-kernel)
* [Build the Kernel](#build-the-kernel)
* [Boot with QEMU](#boot-with-qemu)
* [Automate Patches](#automate-patches)
* [Submit Patches](#submit-patches)
* [Navigate Subsystems](#navigate-subsystems)
* [Helpful Resources](#helpful-resources)

---

## Prerequisites

Install necessary packages on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev qemu-system-x86 git
```

---

## Clone the Kernel

Clone Linus’s mainline kernel via HTTPS:

```bash
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
```

(Optional) Shallow clone to speed up:

```bash
git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
```

---

## Build the Kernel

Generate a default config for x86\_64 and build:

```bash
make defconfig
make -j$(nproc)
```

The compiled kernel image will be at:
`arch/x86/boot/bzImage`

---

## Boot with QEMU

You need a root filesystem (e.g., from [Buildroot](https://buildroot.org/)).

Boot the kernel with QEMU:

```bash
qemu-system-x86_64 \
  -kernel arch/x86/boot/bzImage \
  -append "root=/dev/sda console=ttyS0" \
  -hda /path/to/rootfs.ext2 \
  -nographic
```

---

## Automate Patches

Save the following script as `auto_patch_send.sh` and make it executable:

```bash
#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 \"commit message\""
  exit 1
fi

# Stage all changes
git add .

# Commit with Signed-off-by
git commit -s -m "$1"

# Generate patch for last commit
git format-patch -1 HEAD

# Find maintainers for changed files
MAINTAINERS=$(git diff --name-only HEAD~1 HEAD | xargs ./scripts/get_maintainer.pl | grep -E "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" | sort -u | paste -sd "," -)

if [ -z "$MAINTAINERS" ]; then
  echo "No maintainers found, please specify --to manually."
  exit 1
fi

echo "Sending patch to: $MAINTAINERS"

# Send patch email (configure your SMTP in git config)
git send-email --to="$MAINTAINERS" *.patch
```

### Usage:

```bash
./auto_patch_send.sh "Your concise commit message here"
```

> **Note:** You must configure your SMTP server for `git send-email`:

```bash
git config --global sendemail.smtpserver smtp.example.com
git config --global sendemail.smtpuser your-email@example.com
git config --global sendemail.smtpencryption tls
git config --global user.name "Your Name"
git config --global user.email your-email@example.com
```

---

## Submit Patches

* Identify the correct mailing list using:

```bash
./scripts/get_maintainer.pl path/to/changed/file.c
```

* Subscribe and send patches using the automated script or manually with:

```bash
git send-email --to=mailinglist@example.com 0001-your-patch.patch
```

* Respond to feedback and revise patches as needed.

---

## Navigate Subsystems

* The Linux kernel is divided into subsystems like:

| Subsystem      | Directory  | Mailing List                    |
| -------------- | ---------- | ------------------------------- |
| Networking     | `net/`     | `netdev@vger.kernel.org`        |
| Filesystems    | `fs/`      | `linux-fsdevel@vger.kernel.org` |
| Memory Mgmt    | `mm/`      | `linux-mm@vger.kernel.org`      |
| Device Drivers | `drivers/` | Varies by driver type           |

* Use `scripts/get_maintainer.pl` to find maintainers for your code areas.
* Use tools like `ctags` or `cscope` to browse source code efficiently.
* Use `git log`, `git blame`, and `git grep` for history and search.

---

## Helpful Resources

* [Linux Kernel Newbies](https://kernelnewbies.org/)
* [Kernel Maintainers](https://kernel.org/doc/html/latest/process/maintainer.html#subsystem-maintainers)
* [Submitting Patches](https://kernel.org/doc/html/latest/process/submitting-patches.html)
* [Kernel Mailing Lists](https://lists.kernelnewbies.org/mailman/listinfo)
* [Kernel Documentation](https://kernel.org/doc/html/latest/)

---

Feel free to open issues or pull requests if you want to improve this guide!
