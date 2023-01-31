# Easy-NMOS Docker Compose Solution

This starter kit allows the user to launch a simple NMOS setup with minimal installation steps. It is composed of three Docker containers:

- an NMOS Registry (from [nmos-cpp](https://github.com/sony/nmos-cpp))
- a virtual NMOS Node (from [nmos-cpp](https://github.com/sony/nmos-cpp)) which should automatically register
- the [AMWA NMOS Testing Tool](https://github.com/AMWA-TV/nmos-testing)

All you need is a Linux host (Windows and Mac hopefully coming soon), with a recent version of [Docker](https://docs.docker.com/engine) and [Docker Compose](https://docs.docker.com/compose/) installed. Alternatively, you can run the implementation inside a Linux virtual machine on any platform.

Finally, if you want/need access to the build instructions for these containers you can use the following links:

- [nmos-cpp](https://github.com/rhastie/build-nmos-cpp) container from NVIDIA
- [AMWA NMOS Testing Tool](https://github.com/AMWA-TV/nmos-testing) container from AMWA

## Brief installation instructions

### 0. Clone this repository locally or download and unpack the [archive](https://github.com/rhastie/easy-nmos/archive/master.zip)

### 1. Install Docker and Docker Compose

Follow the [short instructions](./install_docker.md).

### 2. Configure Compose IP addresses for your environment

You will need 3 unused IP addresses that all reside in the same subnet as the host IP address. The docker-compose script by default starts all the containers with externally facing IP addresses so that they are easily accessible from your LAN.

Configure the following inside the "docker-compose.yml" file
- Set a valid IP address for the NMOS Registry/Controller to be exposed on. Replace 192.168.6.101 with something unused and appropriate in the "Create nmos-registry container instance" section
- Set a valid IP address for the NMOS Virtual Node to be exposed on. Replace 192.168.6.102 with something unused and appropriate in the "Create nmos-virtnode container instance" section
- Set a valid IP address for the AMWA NMOS Testing Tool to be exposed on. Replace 192.168.6.103 with something unused and appropriate in the "Create nmos-testing container instance"
section
- Adjust the network interface to use your specific host interface. Replace the "parent: ens33" to match your external facing interface in the "external" section at the end of the file
- Adjust the external subnet to use. Replace the "subnet: 192.168.6.0/24" so that it correctly sets the subnet for the IP addresses you've defined above in the "external" section at the end of the file
- Note: In order for the Node to be correctly accessible the IP address specified must be different to the host IP address

### 3. Start Docker Compose to start Easy-NMOS

You should just be able to `docker-compose up` and then access the relevant host IP address and port.

In order to ensure you keep the docker images up-to-date, just `docker-compose pull` before the `docker-compose up`.

## Quick Start Guide

### Default Ports and mDNS hostnames

| Services | mDNS name | Opened ports |
|---|---|---|
| NMOS Registry/Controller/MQTT Broker | nmos-registry.local | 80 (HTTP), 81 (WebSocket), 1883 (MQTT) |
| NMOS Virtual Node                    | nmos-virtnode.local | 80 (HTTP), 81 (WebSocket) |
| AMWA NMOS Testing Tool               | nmos-testing.local  | 5000 (HTTP) |

These values appear in "docker-compose.yml", "registry.json" and "node.json".

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

## Advanced usage

### Configuration for routed networks

Out of the box, docker-compose v3.x does not support syntax for the addition of default gateways as documented [here](https://docs.docker.com/compose/compose-file/compose-file-v3/#note-additional-ipam-configurations-such-as-gateway-are-only-honored-for-version-2-at-the-moment).

A solution is to create the macvlan network outside of docker-compose, and then reference the network in the docker-compose.yml manifest file. Docker (different to docker-compose) allows the creation of a macvlan network with a default gateway, for off subnet and internet connectivity. You can create the macvlan network using the following command:

~~~
docker network create -d macvlan \   
--subnet=192.168.6.0/24 \
--gateway=192.168.6.1 \
-o parent=enp0s3 nmos_mac_vlan
~~~

The subnet and parent are unique to your system, see step 2 in the brief installation instructions above. The gateway is the address of the router that will forward/receive traffic to/from remote networks. 

You can use "docker network ls" to verify that the macvlan network is created:

~~~
docker network ls                 
NETWORK ID     NAME                    DRIVER    SCOPE
7399d0e2639c   bridge                  bridge    local
d1f4218115ba   host                    host      local
80aba987d32c   nmos_mac_vlan           macvlan   local
c387a789c9f4   none                    null      local
~~~

You can now edit the docker-compose.yml file to reference the external network rather than create a new one. To do this, remove the following section:

~~~
networks:
    external:
        # Create external macvlan subnet using host physical interface allowing containers to have their own IP addresses
        driver: macvlan
        driver_opts:
            parent: enp0s8
        ipam:
            config:
            - subnet: 192.168.6.0/24
~~~

and replace with:

~~~
networks:
    external:
        name: nmos_mac_vlan
        external: true
~~~

The IP addresses of the individual services must also be set appropriatley, see step 2 of the brief installation instructions section above.

## Next steps for this project

- Identify a Windows and Mac equivalent for `macvlan` driver in order to connect to LAN network
- Expand the README.md file to explain what can/can't be done with easy-nmos
- Expand the README.md to explain the use of the "registration.sh" script to disable the nmos-registry so that the testing tool can be used to test the nmos-virtnode - Current work-around is to use `docker-compose stop nmos-registry`
