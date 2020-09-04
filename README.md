# INCOMPLETE INSTRUCTIONS

Currently only works on Linux (not Windows / Mac) due to the use of the macvlan driver to expose the Node - I'm looking at potentially using a network bridge to alleviate this issue but that requires some further work.


## Brief installation instructions (needs further work)

Install docker:

```sh
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh
```

Install docker-compose:

```sh
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

Configure the following inside the "docker-compose.yml" file
- Set a valid IP address for the Node to be exposed on. Replace 192.168.6.101 with something unused and appropriate in the "Create node container instance" section
- Adjust the network interface to use to match your host interface. Replace the "parent: ens33" to match your external facing interface in the "external" section at the end of the file
- Adjust the external subnet to use. Replace the "subnet: 192.168.6.1/24" to marry with the IP address you defined above in the "external" section at the end of the file

  
Ports that are opened:

Registry/Controller on 8010
Node on 11000
Testing tool on 5000

You will need to set an external IP address in the "docker-compose.yml" and replace the "192.168.6.101" with a valid address on your network if you want to be able to access the node externally. This IP must be different to the host IP address

You should just be able to "docker-compose up" and then access the relevant host IP address and port

