---
id: local-development
title: Local Development
sidebar_label: Local Development
---

Please read through the [CONTRIBUTING.md](https://github.com/mozilla/fxa/blob/master/CONTRIBUTING.md) file
to get a better understanding of how to write a patch for Firefox Accounts.

# fxa-local-dev

Follow the README.md in the [fxa-local-dev repository](https://github.com/mozilla/fxa-local-dev)
to get started.

### Updating npm shrinkwrap

* Install the [npmshrink](https://www.npmjs.com/package/npmshrink) tool.
* If you are updating the fxa-content-server run `npmshrink:prod` in the root directory.
All other repos use `npmshrink`.

# fxa-dev

We use an AWS Ansible-based docker development environment
called [fxa-dev](https://github.com/mozilla/fxa-dev) to deploy different versions of the FxA stack.
It can be found here [https://github.com/mozilla/fxa-dev](https://github.com/mozilla/fxa-dev) (make sure to use the `docker` branch).

## Notes

You can find a lot of important information about fxa-dev usage in its [README.md](https://github.com/mozilla/fxa-dev#usage).
Here are some additional notes that expand on the README:

### SSH

You can ssh into the EC2 instance with `ssh ec2-user@meta-{{ whatever you configured in foo.yml }}`.

### Ansible Logs

If the box failed to deploy properly, ssh into it and check `/var/log/cloud-init-output.log`

The Ansible polling / update log can be found here: `/var/log/ansible/update.log`

### Docker Commands

[Build](https://docs.docker.com/engine/reference/commandline/build/)

```
docker build --no-cache=true -t TAG_NAME .
```

Use `--file` to specify a custom Dockerfile file like `--file Dockerfile-build`.

Example: `docker build --no-cache=true -t vladikoff/123done  .`

Tag

```
docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]
```

Example: `docker tag vladikoff/123done vladikoff/123done:oauth-keys`

Push

```
docker push NAME[:TAG]
```

Example: `docker push vladikoff/123done:oauth-keys`

Other

`docker ps` - show running containers. Keep an eye on the `NAMES` column.

`docker logs [NAME]` - show logs for a particular container.

`docker restart [NAME]` - restart a container.

Shell into containers

```
sudo docker exec -i -t [container_name] /bin/sh
```

Example: `sudo docker exec -i -t redis /bin/sh`

Output the arguments the process was started with:

```
sudo docker exec -it auth-server sh -c 'ps aux' # finds the PID
sudo docker exec -it auth-server sh -c 'cat /proc/8/environ | xargs -0 -n 1' # outputs args
```

Using `strace` to debug issues:

```
sudo strace -f -s 256 -tt -p 19023
```

where `19023` is the pid of the node process running under docker. `strace` captures and records all system calls.


### MySQL SSH Access

You can access the MySQL database via SSH. Here's an example configuration using Sequel Pro on macOS.
Make sure to specify your SSH Password using a path to your private key. In this example we
are connecting to a stack called `test62`:

<img src=https://i.imgur.com/T9yL9Ti.jpg width=350 />
