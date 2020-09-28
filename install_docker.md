## Install needed script dependencies using your package manager

```sh
$ sudo apt-get install curl
or
$ sudo yum install curl
```

## Install latest Docker and Docker-compose

```sh
$ sudo ./install.sh
```

## Create the docker group

Create `docker` user group and add current user to avoid `sudo`.

```sh
$ sudo groupadd docker
```

Add your user to the docker group.

```sh
$ sudo usermod -aG docker $USER
```

Log out and log back in so that your group membership is re-evaluated.

## Install docker-compose

To aid fast installation we have provided this "install.sh" script. This script downloads and uses the Docker convenience script. Please note comments below:

Docker provides convenience scripts at [get.docker.com](https://get.docker.com) and [test.docker.com](https://test.docker.com) for installing edge and testing versions of Docker Engine - Community into development environments quickly and non-interactively. The source code for the scripts is in the docker-install repository. Using these scripts is not recommended for production environments, and you should understand the potential risks before you use them:
- The scripts require root or sudo privileges to run. Therefore, you should carefully examine and audit the scripts before running them.
- The scripts attempt to detect your Linux distribution and version and configure your package management system for you. In addition, the scripts do not allow you to customize any installation parameters. This may lead to an unsupported configuration, either from Docker’s point of view or from your own organization’s guidelines and standards.
- The scripts install all dependencies and recommendations of the package manager without asking for confirmation. This may install a large number of packages, depending on the current configuration of your host machine.
- The script does not provide options to specify which version of Docker to install, and installs the latest version that is released in the “edge” channel.
- Do not use the convenience script if Docker has already been installed on the host machine using another mechanism.
