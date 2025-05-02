# [Aria2](https://github.com/aria2/aria2) + [AriaNg webui](https://github.com/mayswind/AriaNg) inside a container

- **[Github](https://github.com/hurlenko/aria2-ariang-docker)**
- **[Dockerhub](https://hub.docker.com/r/hurlenko/aria2-ariang/)**

## Introduction

AriaNg is a modern web frontend making [aria2](https://github.com/aria2/aria2) easier to use. AriaNg is written in pure html & javascript, thus it does not need any compilers or runtime environment. You can just put AriaNg in your web server and open it in your browser. AriaNg uses responsive layout, and supports any desktop or mobile devices.

## Table of Contents

- [Aria2 + AriaNg webui inside a container](#aria2--ariang-webui-inside-a-container)
  - [Introduction](#introduction)
  - [Table of Contents](#table-of-contents)
  - [Screenshots](#screenshots)

## Screenshots

### Desktop

![AriaNg](https://raw.githubusercontent.com/mayswind/AriaNg-WebSite/master/screenshots/desktop.png)

### Mobile device

![AriaNg](https://raw.githubusercontent.com/mayswind/AriaNg-WebSite/master/screenshots/mobile.png)

### Supported environment variables

- `PUID` - Userid who will own all downloaded files and configuration files (Default `0` which is root)
- `PGID` - Groupid who will own all downloaded files and configuration files (Default `0` which is root)
- `RPC_SECRET` - The Aria2 RPC secret token (Default: not set)
- `EMBED_RPC_SECRET` - INSECURE: embeds `RPC_SECRET` into web ui js code. This allows you to skip entering the secret but everyone who has access to the webui will be able to see it. Only use this with some sort of authentication (e.g. basic auth)
- `BASIC_AUTH_USERNAME` - username for basic auth
- `BASIC_AUTH_PASSWORD` - password for basic auth
- `ARIA2RPCPORT` - The port that will be used for rpc calls to aria2. Usually you want to set it to the port your website is running on. For example if your AriaNg instance is accessible on `https://ariang.mysite.com` you need to set `ARIA2RPCPORT` to `443` (default https port), otherwise AriaNg won't be able to access aria2 rpc running on the default port `8080`. You can set the port in the web ui by going to `AriaNg Settings` > `Rpc` tab > `Aria2 RPC Address` field, and changing the default rpc port to whatever you need, but this has to be done per browser.

> Note, both `BASIC_AUTH_USERNAME` and `BASIC_AUTH_PASSWORD` must be set in order to enable basic authentication.

### Supported volumes

- `/aria2/data` The folder of all Aria2 downloaded files
- `/aria2/conf` The Aria2 configuration file

### User / Group identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1001` and `PGID=1001`, to find yours use `id user` as below:

```bash
id username
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```
