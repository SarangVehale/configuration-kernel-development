# Getting your system ready 

Let's get started. The first order of business is finding a development system that best suits your needs. A regular laptop is a good choice for a basic development system, unless a specific architecture and/or configuration is needed.

The second step is to install the Linux distribution of your choice. There are several distributions to choose from : 

- [Fedora](https://docs.fedoraproject.org/en-US/fedora/rawhide/install-guide/)
- [Debian releases](https://www.debian.org/releases/stretch/installmanual) - we recommend installing the current stable release, which you can pick from the Index of Releases
- [OpenSUSE](https://www.opensuse.org/)
- [Ubuntu](https://tutorials.ubuntu.com/tutorial/tutorial-install-ubuntu-desktop#0)

This document will provide the details on configuring a kernel developement system that runs a recent Ubuntu distribution. Please follow the <i>[Install Ubuntu Desktop tutorial](https://tutorials.ubuntu.com/tutorial/tutorial-install-ubuntu-desktop#0)</i> to install the Ubuntu release of your choice. [Ubuntu tutorials](https://tutorials.ubuntu.com/) are a good resource. [Create a bootable USB stick on Ubuntu](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-ubuntu#0) and [Create a bootable USB stick on Windows](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-windows#0) show you how to create a bootable USB sticks, which you will need to do first, and then install Ubuntu desktop using it. You have a few other options, such as installing Ubuntu side-by-side with Windows or installing an Ubuntu virtual machine under a hypervisor, such as Oracle VirtualBox or VMWare. We will not talk about how to install Ubuntu in this document. We leave you with tips below on how much disk space to allocate.

On development and test systems, it is a good idea to ensure ample space for kernels in the boot partitions. It is recommended that you choose a whole disk install orset aside 3 GB of disk space for the boot partition. 

Once the distribution is installed and the system is ready for development packages, enable the root account and <b> sudo</b> for your user account. The system might already have the <b>build-essential</b> package, which you need to build Linux kernels on an x86_64 system. Recenet Ubuntu distributions install a lot of the tools we will need.

```bash
sudo apt-get install build-essential vim git cscope libncurses-dev libssl-dev bison flex
sudo apt-get install git-email
```

Once you have a development system, it is time to check if your system supports the [Minimal requirements to compile the Kernel](https://www.kernel.org/doc/html/latest/process/changes.html); these change from time to time. It is a good idea to make sure your system is configured correctly. 

You can also run the script in the repo to check and install the requirements. 

1. Check requirements and install if not satisfied.
	```bash
	chmod +x check_deps.sh
	./check_deps.sh
	```
2. Verify the results
	```bash
	chmod +x verify_deps.sh
	./verify_deps.sh
	```

The next step is [finding information on email clients and configuring your email client](https://www.kernel.org/doc/html/latest/process/email-clients.html) to send patces and respond to emails. We highly recommend using git send-email to send patches. You refer to the official documentation or the guide given in the repo.

