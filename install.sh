#!/bin/sh

get_latest_release() {
  curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Install Docker Engine using the get-docker convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
chmod 755 ./get-docker.sh
./get-docker.sh

#Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
