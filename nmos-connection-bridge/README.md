# NMOS Connection API Bridge

Provides the Envoy bootstrap configuration used by Easy-NMOS to expose the
NMOS Registry and Connection API Bridge through one browser-facing endpoint.

The adapter runs in its own small container (`node:22-alpine`). It is not part
of the `rhastie/nmos-cpp` image. Compose builds it directly from the
[`ConnectionBridge/adapter`](https://github.com/sony/nmos-js/tree/master/ConnectionBridge/adapter)
source in nmos-js, pinned by commit SHA in `docker-compose.yml`.

The files under `envoy/` are copies of
[`ConnectionBridge/envoy/`](https://github.com/sony/nmos-js/tree/master/ConnectionBridge/envoy)
from that same pin (`envoy.yaml` and `location_rewrite.lua`). When bumping the
adapter context SHA, refresh both files from
`ConnectionBridge/envoy/` at that commit so the bootstrap matches the routes
and Lua filters the adapter emits.
