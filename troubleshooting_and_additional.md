# Secure Linux Kernel Build and Configuration Guide

---

## 1. System Prerequisites

### 1.1 Environment Requirements

Ensure you're using a modern Linux distribution (e.g., Ubuntu 25.04 or later).

```bash
sudo apt update
sudo apt install -y build-essential libncurses-dev flex bison libssl-dev \
  libelf-dev python3-dev pahole bc cpio git fakeroot rsync openssl gnupg kmod \
  mokutil efitools libdw-dev
```

---

## 2. Kernel Source Preparation

### 2.1 Clone Official Kernel Repository

```bash
mkdir -p ~/kernel-work && cd ~/kernel-work
# Optionally pick a stable branch
git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux-secure
cd linux-secure
make mrproper
```

### 2.2 Use Existing Distro Config (Optional)

```bash
cp /boot/config-$(uname -r) .config
make olddefconfig
```

---

## 3. Cryptographic Key Management

### 3.1 Generate Developer Key for Module Signing

```bash
cd certs/
openssl req -new -x509 -newkey rsa:2048 -keyout devkey.key -out devkey.crt \
  -days 3650 -nodes -subj "/CN=My Secure Kernel/"
cat devkey.key devkey.crt > my-signing-key.pem
cd ..
```

### 3.2 Protect and Backup Keys

* Restrict permissions: `chmod 600 certs/devkey.key`
* Store keys in secure hardware (TPM, USB HSM) for production
* Never publish keys used in trusted builds

---

## 4. Kernel Configuration: Secure Settings

Use `scripts/config` for automated configuration:

```bash
# Secure Boot and Signature Verification
scripts/config --enable CONFIG_MODULE_SIG
scripts/config --enable CONFIG_MODULE_SIG_FORCE
scripts/config --set-str CONFIG_MODULE_SIG_HASH "sha256"
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS "certs/my-signing-key.pem"
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""

# Lockdown and Security Modules
scripts/config --enable CONFIG_SECURITY_LOCKDOWN_LSM_EARLY
scripts/config --enable CONFIG_LOCK_DOWN_KERNEL
scripts/config --enable CONFIG_SECURITY
scripts/config --enable CONFIG_SECURITYFS
scripts/config --enable CONFIG_KEYS
scripts/config --enable CONFIG_KEY_DH_OPERATIONS

# IMA/EVM
scripts/config --enable CONFIG_INTEGRITY
scripts/config --enable CONFIG_INTEGRITY_SIGNATURE
scripts/config --enable CONFIG_IMA
scripts/config --set-val CONFIG_IMA_MEASURE_PCR_IDX 10
scripts/config --enable CONFIG_IMA_APPRAISE
scripts/config --enable CONFIG_IMA_APPRAISE_BOOTPARAM
scripts/config --enable CONFIG_IMA_APPRAISE_SIGNED_INIT
scripts/config --enable CONFIG_IMA_WRITE_POLICY
scripts/config --enable CONFIG_IMA_READ_POLICY
scripts/config --enable CONFIG_IMA_KEYRINGS_PERMIT_SIGNED_BY_BUILTIN_OR_SECONDARY
scripts/config --enable CONFIG_EVM
scripts/config --enable CONFIG_EVM_ATTR_FSUUID

make olddefconfig
```

---

## 5. Build and Install

### 5.1 Kernel Compilation

```bash
make -j$(nproc)
```

### 5.2 Install Modules and Kernel

```bash
sudo make modules_install install
```

### 5.3 Sign External Modules (if building out-of-tree)

```bash
./scripts/sign-file sha256 certs/devkey.key certs/devkey.crt path/to/module.ko
```

---

## 6. Secure Boot Integration

### 6.1 Enroll MOK Key

```bash
sudo mokutil --import certs/devkey.crt
# Reboot and enroll via MOK Manager interface
```

### 6.2 GRUB Configuration

```bash
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="ima_policy=measure lockdown=integrity"/' /etc/default/grub
sudo update-grub
```

---

## 7. Reboot and Verification

### 7.1 Post-Boot Checks

```bash
uname -r

# Verify lockdown
cat /sys/kernel/security/lockdown

dmesg | grep -i lockdown
dmesg | grep -i ima
dmesg | grep -i evm

egrep -i 'IMA|EVM|module signature|lockdown' /var/log/kern.log
```

### 7.2 IMA Runtime Data

```bash
cat /sys/kernel/security/ima/ascii_runtime_measurements
```

---

## 8. Advanced: Appraisal and Policy Enforcement

### 8.1 Create Custom Policy

```bash
echo "appraise func=BPRM_CHECK" | sudo tee /sys/kernel/security/ima/policy
```

### 8.2 IMA Appraisal Risks

* Files must be signed via `evmctl` or `sign-file`
* Unsigned binaries may fail to execute
* Enable `CONFIG_IMA_APPRAISE_SIGNED_INIT` to limit failures to init binaries

---

## 9. Bonus: Best Practices

### 9.1 Reproducibility

* Use fixed toolchain versions (via `ccache`, `sccache`, or containerized builds)
* Set `CONFIG_BUILD_SALT` and `CONFIG_LOCALVERSION_AUTO=n`
* Track build metadata using reproducible build tools

### 9.2 Key Management

* Never expose developer keys publicly
* Rotate signing keys annually
* Use separate keys for development and production

### 9.3 Secure Bootloader Setup

* Only allow trusted kernels in UEFI boot manager
* Use `efibootmgr` to verify boot entries

### 9.4 Upstream Contributions

* Always run `scripts/checkpatch.pl` before submitting patches
* Sign off all commits: `git commit -s`
* Use `get_maintainer.pl` to send patches to the right mailing list

### 9.5 Automation

* Automate builds via CI (e.g., GitHub Actions, GitLab CI, Jenkins)
* Use signed commits and tags to track releases
* Maintain LSM policy files in version control

---

## 10. References

* [Linux Kernel Documentation](https://docs.kernel.org/)
* [Secure Boot & MOK](https://wiki.ubuntu.com/UEFI/SecureBoot)
* [Integrity Measurement Architecture](https://sourceforge.net/p/linux-ima/wiki/Home/)
* [Linux Foundation Kernel Guidelines](https://www.kernel.org/doc/html/latest/process/)

---

> **Note:** This guide is designed to help you meet industry-level security expectations without compromising developer usability. For production deployment, follow organizational key policies and use reproducible CI workflows.

---

# Linux Kernel Boot Troubleshooting (Host-Based)

## Introduction

This document is intended as a comprehensive troubleshooting guide for kernel boot issues encountered when working with a custom-built Linux kernel directly on host hardware (i.e., without virtualization). The structure, language, and technical clarity follow conventions laid out in the Linux Foundation’s "Beginner’s Guide to Linux Kernel Development (LFD103)" and official documentation practices from kernel.org.

This guide assumes the user is building and installing a custom kernel and facing the common issue:

```
VFS: Unable to mount root fs on unknown-block(0,0)
Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
```

This error signifies that the kernel could not locate or mount the root filesystem.

## Background and Purpose

The user has attempted to build and boot into a custom Linux kernel from source. Their primary objectives include:

* Learning kernel internals and development
* Contributing patches
* Avoiding virtualization (using a physical system)

The system fails at boot time with a kernel panic due to the inability to mount the root filesystem. The guide walks through why this happens, step-by-step debugging, and how to fix it, including recovery and best practices.

---

## Problem Analysis

The `VFS: unable to mount root fs` error usually stems from one or more of the following root causes:

| Cause                                             | Explanation                                                                                                |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Filesystem driver (e.g., ext4) built as module    | The kernel cannot load modules until the root filesystem is mounted, which leads to a circular dependency. |
| Block device driver (e.g., NVMe, AHCI) missing    | Without this, the kernel cannot access storage devices.                                                    |
| Partition table support (e.g., GPT, MBR) disabled | The kernel can’t identify or mount partitions without it.                                                  |
| Incorrect or missing `root=` parameter in GRUB    | The kernel is not instructed where to find the root filesystem.                                            |
| No initramfs provided when modules are required   | Necessary drivers/modules are unavailable at boot time.                                                    |
| Permissions or incomplete build                   | Missing `bzImage` or modules result in improper installation.                                              |

---

## Encountered Errors and Resolution

### Error 1: Kernel Panic - `VFS: Unable to mount root fs on unknown-block(0,0)`

**Diagnosis**: The kernel does not have access to the root partition.
**Solution**:

* Reconfigure the kernel using `make menuconfig`.

  * Ensure the following are **built-in** (set to `[*]`):

    * `CONFIG_EXT4_FS`
    * `CONFIG_NVME_CORE`, `CONFIG_BLK_DEV_NVME`
    * `CONFIG_SATA_AHCI`
    * Partition support:

      * `CONFIG_PARTITION_ADVANCED=y`
      * `CONFIG_EFI_PARTITION=y`

### Error 2: `/dev` does not contain storage devices (`sdX`/`nvmeX`)

**Diagnosis**: The kernel lacks necessary drivers.
**Solution**: Enable and build block device drivers into the kernel.

### Error 3: `Missing file: arch/x86/boot/bzImage`

**Diagnosis**: Kernel was not compiled or build failed.
**Solution**:

```bash
make -j$(nproc)
```

### Error 4: `.o.d: Permission denied`

**Diagnosis**: Root privileges used earlier; now files are not owned by the user.
**Solution**:

```bash
sudo chown -R $USER:$USER .
make clean
make -j$(nproc)
```

### Error 5: `No rule to make target 'modules.order'`

**Diagnosis**: Attempted `make modules_install` before a successful build.
**Solution**:

```bash
make -j$(nproc)
sudo make modules_install
```

### Error 6: `debian/canonical-certs.pem` missing during build

**Diagnosis**: Module signature verification enabled without required cert files.
**Solution**: Edit `.config` and ensure:

```
CONFIG_MODULE_SIG=n
CONFIG_SYSTEM_TRUSTED_KEYS=""
CONFIG_SYSTEM_REVOCATION_KEYS=""
```

Then rebuild with:

```bash
make olddefconfig
make clean
make -j$(nproc)
```

### Error 7: `.config` contains invalid symbol values like 'm'

**Diagnosis**: Incorrect manual configuration.
**Solution**:

```bash
make olddefconfig
```

### Error 8: `Enable loadable module support` not found in `menuconfig`

**Solution**: Manually add to `.config`:

```
CONFIG_MODULES=y
```

---

## Verification and Debugging Steps

* **List block devices**:

```bash
lsblk
```

* **Check if block devices appear**:

```bash
ls /dev/nvme* /dev/sd*
```

* **Check kernel config**:

```bash
zcat /proc/config.gz | grep EXT4
```

* **Inspect initramfs contents**:

```bash
lsinitramfs /boot/initrd.img-$(uname -r)
```

---

## Recovery Procedure (Using Stable Kernel)

1. Reboot into a known good kernel using GRUB > Advanced > Recovery Mode
2. Mount root filesystem read-write:

```bash
mount -o remount,rw /
```

3. Reconfigure and rebuild:

```bash
make menuconfig   # Correct missing options
make clean
make -j$(nproc)
sudo make modules_install
sudo make install
sudo update-grub
```

4. Confirm:

```bash
ls arch/x86/boot/bzImage
```

5. Check bootloader entries:

```bash
grep menuentry /boot/grub/grub.cfg
```

---

## Checklist Before Reboot

* [ ] ext4, NVMe/SATA, GPT support built-in (not as modules)?
* [ ] bzImage successfully created?
* [ ] modules installed without error?
* [ ] GRUB updated successfully?

---

## Summary

When facing `VFS: unable to mount root fs on unknown-block(0,0)`, the issue typically lies in the lack of built-in support for storage and filesystem drivers, partition table support, or misconfigured GRUB `root=` parameter.

The correct way to approach the issue:

* Always verify block device and filesystem support is built-in
* Maintain a working `.config` backup
* Avoid mixing `sudo` with kernel builds unless absolutely required
* Keep a stable kernel accessible for recovery

This process is part of the normal workflow of kernel experimentation and development.

Refer to the Linux Foundation LFD103 course and kernel.org documentation for further background and reference material.

---

*End of Document.*

