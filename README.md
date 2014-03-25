# Docker Webmail

* Mailpile
* Encryption
* Mail server defaults
* PGP

# Getting Started

Configure `aliases`, `domains`, `passwords` to your liking.

_These commands need more arguments to work properly._

```bash
# Build that container
$ docker build -t mail-server:0.1 .
```

```bash
# Run that container
$ docker run -d mail-server:0.1
```

# Credit

* Initial Dockerfile: [lava/dockermail](https://github.com/lava/dockermail)
* Initial mail configuration: [blog.yrden.de](https://blog.yrden.de/2013/08/02/my-mail-setup.html)
