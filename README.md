Ports that are opened:

Registry/Controller on 8010
Node on 11000
Testing tool on 5000

You will need to set an external IP address in the "docker-compose.yml" and replace the "192.168.6.101" with a valid address on your network if you want to be able to access the node externally. This IP must be different to the host IP address

You should just be able to "docker-compose up" and then access the relevant host IP address and port

