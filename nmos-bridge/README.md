# NMOS Bridge

Provides the Envoy bootstrap configuration used by Easy-NMOS to expose the
NMOS Registry and NMOS Bridge through one browser-facing endpoint.

The adapter runs in its own small container (`node:22-alpine`). It is not part
of the `rhastie/nmos-cpp` image. Compose builds it directly from the
[`nmos-bridge/adapter`](https://github.com/sony/nmos-js/tree/master/nmos-bridge/adapter)
source in nmos-js, pinned by commit SHA in `docker-compose.yml`.

The files under `envoy/` are copies of
[`nmos-bridge/envoy/`](https://github.com/sony/nmos-js/tree/master/nmos-bridge/envoy)
from that same pin (`envoy.yaml` and `location_rewrite.lua`). When bumping the
adapter context SHA, refresh both files from
`nmos-bridge/envoy/` at that commit so the bootstrap matches the routes
and Lua filters the adapter emits.
