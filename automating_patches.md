
## 1️⃣ Automating Patches

### How to create patches from your commits

After editing your kernel repo, follow this workflow:

```bash
# Stage your changes
git add path/to/changed/file.c

# Commit with sign-off (mandatory for kernel)
git commit -s -m "Subsystem: short description of your change

Detailed explanation of your change if needed."
```

* The `-s` adds the **Signed-off-by** line (your developer certification).

---

### Generate patch files to send via email

To create a patch file for a single commit:

```bash
git format-patch -1 HEAD
```

For multiple commits, e.g. last 3:

```bash
git format-patch -3
```

This creates `.patch` files you can send.

---

### Automate patch generation and sending

You can write a shell script like this:

```bash
#!/bin/bash

# Commit changes with message passed as argument
git add .
git commit -s -m "$1"

# Generate patch for last commit
git format-patch -1 HEAD

# Send patch email (config your SMTP and send-email first!)
git send-email --to=linux-subsystem@vger.kernel.org *.patch
```

> You **must** configure `git send-email` with your SMTP server for sending patches.

---

## 2️⃣ Submitting Patches

### The kernel patch workflow

1. **Find the right mailing list** — every subsystem has one (e.g., `netdev@vger.kernel.org` for networking, `linux-mm@vger.kernel.org` for memory management).
2. **Subscribe to the mailing list** (optional but recommended).
3. **Send your patch with `git send-email`**.
4. **Follow feedback and revise your patch** if needed.
5. When accepted, your patch gets merged by the maintainer and eventually reaches Linus.

---

### Finding where to send patches

Use these resources:

* [Kernel Maintainers](https://kernel.org/doc/html/latest/process/maintainer.html#subsystem-maintainers) — official list of maintainers + emails
* `MAINTAINERS` file in the kernel repo — who to send patches to
* `scripts/get_maintainer.pl` — handy script to suggest recipients:

```bash
./scripts/get_maintainer.pl path/to/your/file.c
```

---

## 3️⃣ Navigating Subsystems

### Understanding kernel subsystems

* Kernel is modular; divided into subsystems like:

| Subsystem      | Directory  | Mailing List                    |
| -------------- | ---------- | ------------------------------- |
| Networking     | `net/`     | `netdev@vger.kernel.org`        |
| Filesystems    | `fs/`      | `linux-fsdevel@vger.kernel.org` |
| Memory Mgmt    | `mm/`      | `linux-mm@vger.kernel.org`      |
| Device Drivers | `drivers/` | varies by driver type           |

---

### Tips for picking a subsystem to work on

* Start with drivers or staging drivers — easier to understand.
* Read subsystem README files in `Documentation/`.
* Watch mailing lists for active discussions.
* Use `git log` and `git blame` to understand recent changes.

---

### Tools for navigation

* `cscope` or `ctags` for code browsing.
* `git log --follow path/to/file.c` to see history.
* `scripts/checkpatch.pl` to check your code style before submission.

---

## Summary Workflow Example

```bash
# 1. Clone and set up
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux

# 2. Make changes
# (edit code)

# 3. Commit with sign-off
git add drivers/your_driver.c
git commit -s -m "driver: fix issue with XYZ"

# 4. Generate patch
git format-patch -1 HEAD

# 5. Find maintainer emails
./scripts/get_maintainer.pl drivers/your_driver.c

# 6. Send patch via email
git send-email --to=maintainers@example.com 0001-driver-fix-issue-with-XYZ.patch
```

---

