# Easy-NMOS Docker Compose Solution - INCOMPLETE INSTRUCTIONS

Currently only works on Linux (not Windows / Mac) due to the use of the macvlan driver to expose the container IP addresses - I'm looking at potentially using a network bridge to alleviate this issue but that requires some further work.

## Brief installation instructions (needs further work)
### 0. Clone this repository locally or download and unpack the [archive](https://github.com/rhastie/easy-nmos/archive/master.zip)

### 1. Install Docker and Docker Compose

Follow [short instructions.](./install_docker.md)

### 2. Configure Compose IP addresses for your environment
You will need 3 unused IP addresses that all reside in the same subnet as the host IP address. The docker-compose script by default starts all the containers with an external facing IP addresses so that they are easily accessible from your LAN

Configure the following inside the "docker-compose.yml" file
- Set a valid IP address for the NMOS Registry/Controller to be exposed on. Replace 192.168.6.101 with something unused and appropriate in the "Create nmos-registry container instance" section
- Set a valid IP address for the NMOS Virtual Node to be exposed on. Replace 192.168.6.102 with something unused and appropriate in the "Create nmos-virtnode container instance" section
- Set a valid IP address for the AMWA NMOS Testing Tool to be exposed on. Replace 192.168.6.103 with something unused and appropriate in the "Create nmos-testing container instance"
section
- Adjust the network interface to use your specific host interface. Replace the "parent: ens33" to match your external facing interface in the "external" section at the end of the file
- Adjust the external subnet to use. Replace the "subnet: 192.168.6.0/24" so that it correctly sets the subnet for the IP addresses you've defined above in the "external" section at the end of the file
- Note: In order for the Node to be correctly accessible the IP address specified must be different to the host IP address

### 3. Start Docker Compose to start Easy NMOS
You should just be able to `docker-compose up` and then access the relevant host IP address and port

## Quick Start Guide
### Default Ports and mDNS hostnames
Default Container mDNS hostnames:

- NMOS Registry/Controller/MQTT Broker - Use "nmos-registry.local"
- NMOS Virtual Node - Use "nmos-virtnode.local"
- AMWA NMOS Testing Tool - Use "nmos-testing.local"

Default Ports that are opened:

- NMOS Registry/Controller on port 80
- NMOS Virtual Node on port 80
- AMWA NMOS Testing Tool on port 5000
- MQTT Broker on port 1883

### How to Browse to respective NMOS services and tools
Assuming your client device is correctly supporting mDNS and is on the same LAN as the host running the containers you should be able to use the mDNS hostnames. If this does not work please try the respective IP addresses etc.

Browse to the NMOS Controller
```
http://nmos-registry.local/admin
```

Browse to the AMWA NMOS Testing Tool
```
http://nmos-testing.local:5000/
```

Browse to the APIs of the NMOS Registry
```
http://nmos-registry.local/x-nmos
```

Browse to the APIs of the NMOS Node
```
http://nmos-virtnode.local/x-nmos
```

### Needs more work to briefly explain what can/can't be done and the use of the "registration.sh" script to disable the nmos-registry so that the testing tool can be used to test the nmos-virtnode
