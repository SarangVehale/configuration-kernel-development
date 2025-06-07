# Writing your First Kernel Patch

## Learning Objectives

By the end of this chapter, you should be able to : 
    - Make a kernel change.
    - Test your patch.
    - Commit your change and generate your patch.
    - Validation if your patch meets coding style guidelines.

## 1. Creating a user-specific git configurtion file

Let's start by configuring global git options, and then you can go on to cloning the kernel repository.

Create a user-specific Git configuration file named `.gitconfig` in your home directory with your name, email and other needed configurations. This information is used for commits and patch generation.

```bash
[user]
    name = Your name
    email = your.email@example.com

[format]
    signoff = true

[core] 
    editor = vim

[sendemail]
    smtpserver = mail.xxxx.com
    smtpserverport = portum
    smtpencryption = tls
    smtpuser = user 
    smtppass = password
```

This is a standard template that is quite the standard. Here is a `gitconfig` that I usually use since I have it configured using `gmail`

```bash
[user]
	name = Your Name 
	email = your.email@example.com

[sendemail]
	smtpServer = smtp.gmail.com
	smtpServerPort = 587
	smtpEncryption = tls
	smtpUser = your.email@example.com
	from = your.email@example.com
	confirm = auto
[credential]
    helper = /usr/lib/git-core/git-credential-libsecret

[format]
    signoff = true

[core]
    editor = vim

```
What different in this config is that it uses `gmail` as it's mailing server and uses `libsecret` to securely store the app-password for `gmail`, so that I won't have to enter it every time commiting patches.

The __email in the `.gitconfig` file should be the same email you will use to send patches.__. The __name__ is the __Author__ name, and the __email__ is the __email__ is the email adderss for the commit. Linux kernel developers will not accept a patch where the __From__ email differs from the __Signed-off-by__ line, which is what will happen if these two emails do not match. Configuring __signoff = true__ as shown above adds the __Signed-off-line__ witht he configured email as shown above in __email = your.email@example.com__ to the commit. This can be done manually by running the `git` command with the `-s` option.
E.g. : 
```bash
git commit -s
```   
Configure the __name =__ field with your full legal name. We mentioned earlier that by adding your __Signed-off-line__ to a patch, you certify that you have read and understood the [Developer's Certificate of Origin](https://www.kernel.org/doc/html/latest/process/submitting-patches.html) and abide by the [Linux Kernel Enforcement Statement](https://www.kernel.org/doc/html/latest/process/kernel-enforcement-statement.html). Please review the documents before you send patches to the kernel.

## 2. Kernel Configuration

Let's work with the mainline kernel to create your first patch. By this time if you should already have the mailine kernel running on your system. While doing that, copy the distribution configuration file to generate the kernel configuration. Now let's talk about the kernel configuration. 

The Linux Kernel is entirely configurable. Drivers can be configured to be installed and completely diabled. Here are three options for driver installation : 
    - Disabled
    - Built into the kernel (vmlinux image) to be loaded at boot time
    - Built as module to be loaded as needed using __modprobe__.

To avoid large kernel images, it is a good idea to configure drivers as modules. Modules (.ko files) can be loaded when the kernel detects hardware that matches the driver. Building drivers as modules allows them to be loaded on demand, instead of keeping them around in the kernel image even when the hardware is either not being used or not even present on the system. 

We discussed generating the new configuration with the old one as the starting point. New releases often introduce new configuration variables and, in some cases, rename the configuration symbols. The latter causes problems, and `make oldconfig` might not generate a new working kernel.

Run `make listnewconfig` after copying the configuration from `/boot` to the `.config` file, to see alist of new configuration symbols. [Kconfig make config](https://www.kernel.org/doc/html/latest/kbuild/kconfig.html) is a good source about __Kconfig__ and __make config__. Please refere to the [Kernel Build System](https://www.kernel.org/doc/html/latest/kbuild/index.html) to understand the kernel build framwork and the kernel makefiles.

## 3. Creating a New Branch

Before making a change, let's create a new branch in the __linux_mainline__ repository you cloned earlier to write your first patch. We will start by adding a remote first to do a rebase (pick up new changes made tot he mainline).

```bash
cd linux_mainline
git branch -a
* master
  remotes/linux/master
  remotes/origin?HEAD -> origin/master
  remtoes/origin/master
```

## 4. Adding a Remote

Let's add `git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git` as the remote named linux. Adding a remote helps us fetch changes and choose a tag to rebase from.

```bash
git remote add linux git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
git fetch linux

remote: Counting objects: 3976, done.
remote: Compressing objects: 100% (1988/1988), done.
remote: Total 3976 (delta 2458), reused 2608 (delta 1969)
Receiving objects: 100% (3976/3976), 6.67 MiB | 7.80 MiB/s, done.
Resolving deltas: 100% (2458/2458), done.
From git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux
   2a11c76e5301..ecb095bff5d4   master -> linux/master
 * [new tag]                  v5.x-rc3 -> v5.x-rc3

```

We can pick a tag to rebase to. In this case, there is only one new tag. Let's hold off on the rebase and start writing a new patch.

## 5. Checkout the Branch

To check out a branch, run : 

```bash
git checkout -b work
master
* work
  remotes/linux/master
  remotes/origin/HEAD -> origin/master
  remotes/origin/master
```

## 6. Making Changes to a Driver


