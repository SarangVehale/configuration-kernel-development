# Introduction to Building and Installing your First Kernel

This will walk you through building and installing a stable kernel on your newly configured development system.

## Learning Objectives

By the end of this, you should be able to : 
    - Clone the stable kernel git repository.
    - Review the basics of generating configurations from old configurations on your system
    - Build and install the kernel.

## Cloning the Stable Kernel Git

Start by cloning the stable kernel git, building and instaling the latest stable kernel. The stable cloning step below will creat a new directory named __linux_stable__ and populate it with the sources. The stable repository has serveral branches going back to __linux-2.6.11.y__ . Let's start with the [latest stable release](https://www.kernel.org/) branch. As of this writing, __linux-6.14.9__ is used in the following example. You can find the latest stable or a recent [active kernel release](https://www.kernel.org/category/releases.html). 

```bash
git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux_stable
cd linux_stable

git branch -a | grep linux-6
  remotes/origin/linux-6.0.y
  remotes/origin/linux-6.1.y
  remotes/origin/linux-6.10.y
  remotes/origin/linux-6.11.y
  remotes/origin/linux-6.12.y
  remotes/origin/linux-6.13.y
  remotes/origin/linux-6.14.y
  remotes/origin/linux-6.15.y
  remotes/origin/linux-6.2.y
  remotes/origin/linux-6.3.y
  remotes/origin/linux-6.4.y
  remotes/origin/linux-6.5.y
  remotes/origin/linux-6.6.y
  remotes/origin/linux-6.7.y
  remotes/origin/linux-6.8.y
  remotes/origin/linux-6.9.y

    
git checkout linux-6.14.y
```

## Copying the Configuration for Current Kernel from /boot 

Starting with the distribution configuration file is the safest approach for the very first kernel install on any system. You can copy the configuration for your current kernel from `/proc/config.gz` or `/boot`. For example, we are running Ubuntu 25.04, and `config-6.14.0-15-generic` is the configuration we have in `/boot` on our system. Pick the latest confiuration you have on your system and copy it to `linux_stable/.config`. In the following example, __config-6.14.0-15-generic__ is the latest kernel configuration.

```bash
ls /boot

config-6.12.30            initrd.img-6.14.0-15-generic  System.map-6.12.30
config-6.14.0-15-generic  initrd.img.old                System.map-6.14.0-15-generic
efi                       memtest86+ia32.bin            vmlinuz
grub                      memtest86+ia32.efi            vmlinuz-6.12.30
initrd.img                memtest86+x64.bin             vmlinuz-6.14.0-15-generic
initrd.img-6.12.30        memtest86+x64.efi             vmlinuz.old

cp /boot/config-6.14.0-15-generic /.config
```

## Compiling the Kernel

Run the following command to generate a kernel configuration file based on the current configuration. This step is importatnt to configure the kernel, which has a god chance to work correctly on your system. You will be prompted to tune the configuration to enable new features and drivers that have been added since Ubuntu snapshots the kernel from the mainline. `make all` will invoke `make oldconfig` in any case. Weshow these two steps seperately to call out the configuration file generation step.

```bash
make oldconfig
```

Another way to trim down the kernel and tailor it to your system is by using __make localmodconfig__. This option creates a configuration file based on the list of modules currently loadedon your system.

```bash
lsmod > /tmp/my-lsmod
make LSMOD=/tmp/my-lsmod localmodconfig
```

Once this step is complete, it is time to compile the kernel. Using the `-j` option helps the compiles go faster. The `-j` option specifies the number of jobs (__make commands__) to run simultaneously.

```bash
make -j3 all
```

## Installing the New Kernel 

Once the kernel compilation is complete, install the new kernel : 
`
su -c "make modules_install install"
`

The above command will instal the new kernel and run `update_grub` to add the new kernel to the grub menu. It is time to reboot the system to boot the newly installed kernel. Before we do that, let's save logs from the current kernel to compare and look for regressions and new errors. If any. Using the `-t` options allows us to generate `dmesg` logs without the timestamps, and makes it easier to compare the old and the new.

```bash
dmesg -t > dmesg_current
dmesg -t -k > dmesg_kernel
dmesg -t -l emerg > dmesg_current_emerg
dmesg -t -l alert > dmesg_current_alert
dmesg -t -l crit > dmesg_current_crit
dmesg -t -l err > dmesg_current_err
dmesg -t -l warn > dmesg_current_warn
dmesg -t -l info > dmesg_current_info
```

In general, `dmesg` should be clean, with no `emerg, alert, crit` and `err` level messages. If you see any of these, it might indicate some hardware and/or kernel problems.

If the __dmesg_current__ is zero in length, secure boot is likely enabled on your system. When secure boot is enbled, you won't be able to boot the newly installed kernel, as it is unsigned. You can disable secure boot temporarily on startup with the MOK manager. Your system should already have mokutil.

Let's first make sure secure boot is indeed enabled:
```bash 
mokutil --sb-state
```

If you see the following, you are all set to boot your newly installed kernel:

```bash 
SecureBoot disabled
Platform is in Setup Mode
``` 

If you see the following, disable secure boot temporarily on startup with MOK manager:

```bash 
SecureBoot enabled
SecureBoot validation is disabled in shim
```

Disable validation:

```bash 
sudo mokutil --disable-validation
root password
mok password: 12345678
mok password: 12345678
sudo reboot
```

The machine will reboot to a blue screen, the MOK manager menu. Type the number(s) shown on the screen: if it is 7, it is the 7th character of the password. So, keep 12345678. The question to answer is Yes to disable secure boot. Reboot.

You’ll see on startup after a new message (top left) saying <<Booting in insecure mode>>. The machine will boot normally after, and secure boot remains enabled. This change is permanent, a clean install won't overwrite it. You must keep it that way.

To re-enable it (please note that you won't be able to boot the kernels you build if you re-enable):

```bash 
sudo mokutil --enable-validation
root password
mok password: 12345678
mok password: 12345678
sudo reboot
```


Reference: [How to replace or remove kernel with signed kernels](https://askubuntu.com/questions/1119734/how-to-replace-or-remove-kernel-with-signed-kernels)

## Booting the Kernel

Let's take care of several important steps before trying out the newly installed kernel. There is no guarantee that the new kernel will boot. As a safeguard, we want to ensure that at least one good kernel is installed and what we can select it from the boot menu. By default, grub tries to boot the default kernel, which is the newly installed kernel. We change the default grub configuration file `/etc/default/grub` to the boot menu, and pause it so we can select the kernel to boot.

> Please note that this option is specific to Ubuntu, and other distributions might have a different way of specifying boot menu options.

__Increase the GRUB_TIMEOUT value to 10 seconds, so grub paues in menu long enough to choose a kernel to boot:__ 

    - Uncomment <b>GRUB_TIMEOUT</b> and set it to 10 : 
        <b> GRUB_TIMEOUT = 10 </b>

    - Comment out __GRUB_TIMEOUT_STYLE = hidden__

If the newly installed kernel fails to boot, it is helpful to see the early messages to determine why.

<b>
Enable printing early boot messages to vga using the earlyprintk=vga kernel boot option : 

GRUB_CMDLINE_LINUX="earlyprintk=vga"

Run update-grub to update the grub configuration in `/boot`
</b>

```bash
sudo update-grub
```

Now, it's time to restart the system. Once the new kernel comes up, compare the saved `dmseg` from the old kernel with the new one, and see if there are any regressions. If the newly installed kernel fails to boot, you must boot a good kernel and then investigate why the new kernel was unable to boot.

These steps are not specific to stable kernels. You can check out `linux_mainline` or `linux-next` and follow the same recipe of generating a new configuration from an `oldconfig`, build, and install the `mainline` or `linux-next` kernels.
