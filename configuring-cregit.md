# cregit Full Dockerized Setup & Usage Guide

## Overview

This documentation describes how to set up a fully containerized environment to run [cregit](https://github.com/dmgerman/cregit), a tool that provides semantic history and blame information on Git repositories. It uses Ubuntu 20.04 for compatibility with the `srcML` tool and includes every necessary detail to ensure production-grade reproducibility.

---

## Contents

* [System Requirements](#system-requirements)
* [Dockerfile](#dockerfile)
* [Building the Docker Image](#building-the-docker-image)
* [Running the Container](#running-the-container)
* [cregit Setup Instructions](#cregit-setup-instructions)
* [Workflow to Analyze a Git Repository](#workflow-to-analyze-a-git-repository)
* [Troubleshooting](#troubleshooting)
* [FAQ](#faq)

---

## System Requirements

* Docker (20.10 or later)
* Internet connection (to pull packages and repositories)
* Git repository to analyze

---

## Dockerfile

```Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Base tools and repo
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        gnupg && \
    add-apt-repository universe && \
    apt-get update

# System dependencies
RUN apt-get install -y --no-install-recommends \
        git build-essential cmake perl openjdk-11-jdk \
        libarchive-dev libxml2-dev libcurl4-openssl-dev \
        libxslt1-dev libboost-all-dev libssl-dev \
        libxerces-c-dev exuberant-ctags libdbi-perl \
        libhtml-fromtext-perl libset-scalar-perl libdbd-sqlite3-perl \
        unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install sbt
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" > /etc/apt/sources.list.d/sbt.list && \
    curl -sL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823 | gpg --dearmor -o /etc/apt/trusted.gpg.d/sbt.gpg && \
    apt-get update && apt-get install -y sbt && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install srcML
RUN curl -L -o /tmp/srcml.deb https://github.com/srcML/srcML/releases/download/1.0.0/srcml_1.0.0-1_amd64.deb && \
    apt-get update && \
    apt-get install -y ./tmp/srcml.deb && \
    rm /tmp/srcml.deb

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
WORKDIR /workspace
CMD ["/bin/bash"]
```

---

## Building the Docker Image

Run this in the directory where your Dockerfile is saved:

```bash
docker build -t cregit-env .
```

---

## Running the Container

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  --name cregit_container \
  cregit-env
```

---

## cregit Setup Instructions

### 1. Clone cregit repositories:

```bash
git clone https://github.com/dmgerman/cregit-scala.git
cd cregit-scala
```

### 2. Clone and build `bfg-repo-cleaner` (blobexec branch)

```bash
git clone --branch blobexec https://github.com/dmgerman/bfg-repo-cleaner.git
cd bfg-repo-cleaner
sbt bfg/assembly
```

### 3. Build Scala tools in cregit:

```bash
cd ../cregit-scala/slickGitLog
sbt one-jar
cd ../persons
sbt one-jar
cd ../remapCommits
sbt one-jar
```

### 4. Build srcMLtoken C++ code:

```bash
cd ../tokenize/srcMLtoken
make
```

---

## Workflow to Analyze a Git Repository

1. **Set environment variables**

```bash
export BFG_MEMO_DIR=/tmp/memo
export BFG_TOKENIZE_CMD=/workspace/cregit-scala/tokenize/tokenizeSrcMl.pl \
  --srcml2token=/workspace/cregit-scala/tokenize/srcMLtoken/srcml2token \
  --srcml=srcml \
  --ctags=/usr/bin/ctags
```

2. **Create cregit view of the repo**

```bash
java -jar /workspace/bfg-repo-cleaner/bfg/target/scala-2.12/bfg-cregit.jar \
  '--blob-exec:/workspace/cregit-scala/tokenizeByBlobId/tokenBySha.pl=\.[ch]$' \
  --no-blob-protection /workspace/your-repo
```

3. **Create history databases**

```bash
java -jar slickGitLog.jar /tmp/original.db /workspace/your-repo
java -jar slickGitLog.jar /tmp/cregit.db /workspace/cregit-repo
```

4. **Generate persons db**

```bash
java -jar persons.jar /workspace/your-repo /tmp/data.xls /tmp/persons.db
```

5. **Run blame**

```bash
perl blameRepoFiles.pl --verbose --formatBlame=./formatBlame.pl /workspace/cregit-repo /tmp/blame '\.[ch]$'
```

6. **Map commits**

```bash
java -jar remapCommits.jar /tmp/cregit.db /workspace/cregit-repo
```

7. **Generate HTML**

```bash
perl prettyPrintFiles.pl --verbose /tmp/cregit.db /tmp/persons.db \
  /workspace/your-repo /tmp/blame /tmp/html \
  https://github.com/your/repo/commit/ '\.[ch]$'
```

---

## Troubleshooting

### `dpkg-deb: error: '/tmp/srcml.deb' is not a Debian format archive`

Use `curl -L` to follow redirects, and double-check the link.

### `sbt` compilation errors

Ensure you're using Java 11 (`openjdk-11-jdk`) as newer versions may not be compatible with some cregit Scala code.

### `ctags not found`

Ensure `exuberant-ctags` is installed and accessible via `/usr/bin/ctags`.

---

## FAQ

### Can I use a newer version of Ubuntu?

It’s **not recommended** unless `srcML` provides updated `.deb` packages or you build from source.

### Can I run this on macOS or Windows?

Yes, using Docker Desktop with shared volume mounts.

### What languages are supported by cregit?

cregit primarily supports C and C++ using `srcML`. Future support for more languages may follow srcML's parser extensions.

### Can I use Python with srcML?

Yes! Use `pip install pylibsrcml` to experiment with the Python bindings outside of cregit.

---

## License

cregit is released under the **GPL-3.0** license.

---

## Acknowledgments

This documentation is based on the work of Dr. Daniel M. German and collaborators in the cregit and srcML communities.

