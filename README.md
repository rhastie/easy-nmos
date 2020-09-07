# INCOMPLETE INSTRUCTIONS

Currently only works on Linux (not Windows / Mac) due to the use of the macvlan driver to expose the Node - I'm looking at potentially using a network bridge to alleviate this issue but that requires some further work.


## Brief installation instructions (needs further work)

### Install Docker and Docker Compose
Install latest Docker and Docker-compose:

```sh
$ sudo ./install.sh
```

To aid fast installation we have provided an "install.sh" script. This script downloads and uses the Docker convenience script. Please note comments below:

Docker provides convenience scripts at [get.docker.com](https://get.docker.com) and [test.docker.com](https://test.docker.com) for installing edge and testing versions of Docker Engine - Community into development environments quickly and non-interactively. The source code for the scripts is in the docker-install repository. Using these scripts is not recommended for production environments, and you should understand the potential risks before you use them:
- The scripts require root or sudo privileges to run. Therefore, you should carefully examine and audit the scripts before running them.
- The scripts attempt to detect your Linux distribution and version and configure your package management system for you. In addition, the scripts do not allow you to customize any installation parameters. This may lead to an unsupported configuration, either from Docker’s point of view or from your own organization’s guidelines and standards.
- The scripts install all dependencies and recommendations of the package manager without asking for confirmation. This may install a large number of packages, depending on the current configuration of your host machine.
- The script does not provide options to specify which version of Docker to install, and installs the latest version that is released in the “edge” channel.
- Do not use the convenience script if Docker has already been installed on the host machine using another mechanism.

### Configure Compose for your environment
Configure the following inside the "docker-compose.yml" file
- Set a valid IP address for the Node to be exposed on. Replace 192.168.6.101 with something unused and appropriate in the "Create node container instance" section
- Adjust the network interface to use your specific host interface. Replace the "parent: ens33" to match your external facing interface in the "external" section at the end of the file
- Adjust the external subnet to use. Replace the "subnet: 192.168.6.1/24" so that it correctly sets the subnet for the IP address you defined above in the "external" section at the end of the file
- Note: In order for the Node to be correctly accessible the IP address specified must be different to the host IP address

Ports that are opened:

- NMOS Registry/Controller on port 8010
- NMOS Virtual Node on port 11000
- NMOS API Testing Tool on port 5000
- MQTT Broker on port 1883

### Start Docker Compose to start Easy NMOS
You should just be able to "docker-compose up" and then access the relevant host IP address and port
