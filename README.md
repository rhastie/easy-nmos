# Easy-NMOS Docker Compose Solution

This starter kit allows the user to launch a simple NMOS setup with minimal installation steps. It is composed of five Docker containers:

- an NMOS Registry (from [nmos-cpp](https://github.com/sony/nmos-cpp))
- the NMOS Connection API Bridge adapter (from [nmos-js](https://github.com/sony/nmos-js))
- Envoy, which provides the NMOS Connection API Bridge endpoint
- a virtual NMOS Node (from [nmos-cpp](https://github.com/sony/nmos-cpp)) which should automatically register
- the [AMWA NMOS Testing Tool](https://github.com/AMWA-TV/nmos-testing)

All you need is a Linux host (Windows and Mac hopefully coming soon), with a recent version of [Docker](https://docs.docker.com/engine) and [Docker Compose](https://docs.docker.com/compose/) installed. Alternatively, you can run the implementation inside a Linux virtual machine on any platform.

Finally, if you want/need access to the build instructions for these containers you can use the following links:

- [nmos-cpp](https://github.com/rhastie/build-nmos-cpp) container from NVIDIA
- [nmos-js Connection API Bridge](https://github.com/sony/nmos-js/tree/master/ConnectionBridge) adapter
- [Envoy](https://www.envoyproxy.io/docs/envoy/latest/start/docker) container
- [AMWA NMOS Testing Tool](https://github.com/AMWA-TV/nmos-testing) container from AMWA

## Brief installation instructions

### 0. Clone this repository locally or download and unpack the [archive](https://github.com/rhastie/easy-nmos/archive/master.zip)

### 1. Install Docker and Docker Compose

Follow the [short instructions](./install_docker.md).

### 2. Configure Compose IP addresses for your environment

You will need five unused IP addresses that all reside in the same subnet as the host IP address. The docker-compose script by default starts all the containers with externally facing IP addresses so that they are easily accessible from your LAN.

Configure the following inside the "docker-compose.yml" file
- Set a valid IP address for the NMOS Registry/Controller to be exposed on. Replace 192.168.6.101 with something unused and appropriate in the "Create nmos-registry container instance" section
- Set a valid IP address for the NMOS Virtual Node to be exposed on. Replace 192.168.6.102 with something unused and appropriate in the "Create nmos-virtnode container instance" section
- Set a valid IP address for the Connection API Bridge (Envoy) to be exposed on. Replace 192.168.6.104 in the "nmos-connection-bridge" service section
- Set a valid IP address for the bridge adapter. Replace 192.168.6.105 in the "nmos-connection-bridge-adapter" service section
- Configure `REGISTRY_QUERY_URL` and `APP_URL` as described in the [Connection API Bridge documentation](https://github.com/sony/nmos-js/tree/master/ConnectionBridge#running). Both use the Registry IP above in this deployment (default `http://192.168.6.101`)
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
| Connection API Bridge (Envoy)        | (not advertised via mDNS) | 8080 (HTTP) |
| AMWA NMOS Testing Tool               | nmos-testing.local  | 5000 (HTTP) |

These values appear in `docker-compose.yml`, `registry.json` and `node.json`.

### How to Browse to respective NMOS services and tools

Assuming your client device is correctly supporting mDNS and is on the same LAN as the host running the containers you should be able to use the mDNS hostnames. If this does not work please try the respective IP addresses etc.

Browse to the NMOS Controller (directly on the NMOS Registry)
```
http://nmos-registry.local/admin
```

Browse to the NMOS Controller through the Connection API Bridge (preferred when utilizing the Connection API bridge):
```
http://192.168.6.104:8080/admin
```

With the NMOS Controller loaded from that origin, Query API and Connection Bridge API default to the same host — in Settings → Advanced, set Connection Bridge Mode to Forced (or Auto). Leave the API URL fields at their defaults.
If you instead open the Registry `/admin` directly, set Connection Bridge API to `http://192.168.6.104:8080/x-nmos-bridge/v1.0` as well.

Replace `192.168.6.104` with the Connection API Bridge IP address configured in `docker-compose.yml`.

The bridge adapter and Envoy are described in [nmos-connection-bridge/README.md](nmos-connection-bridge/README.md).

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

## Next steps for this project

- Identify a Windows and Mac equivalent for `macvlan` driver in order to connect to LAN network
- Expand the README.md file to explain what can/can't be done with easy-nmos
- Expand the README.md to explain the use of the "registration.sh" script to disable the nmos-registry so that the testing tool can be used to test the nmos-virtnode - Current work-around is to use `docker-compose stop nmos-registry`
