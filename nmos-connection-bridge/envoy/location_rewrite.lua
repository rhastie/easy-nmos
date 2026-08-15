-- Handle Connection API Bridge upstream 3xx Location headers.
--
-- Relative Location values are resolved against the reconstructed upstream
-- request path (base_path + suffix of the downstream bridge path). That path
-- is the same for every candidate of a target. Clients must not see Locations
-- that only make sense relative to the Device URL.
--
-- Policy:
-- - Path-relative or root-relative (path-absolute) whose resolved path is
--   under this target's Connection API base_path: rewrite onto the bridge.
-- - Absolute http(s) (or scheme-relative resolved with the client scheme)
--   whose host/port matches a candidate and whose path is under base_path:
--   rewrite onto the bridge (client scheme/host/port).
-- - Absolute http(s) / scheme-relative for any other authority, or a matching
--   candidate whose path is outside base_path: leave unchanged (the Location
--   already names a precise URL).
-- - Path-relative or root-relative outside base_path: replace the response
--   with 502 and NMOS error JSON; set
--   x-nmos-bridge-error: unsupported upstream location: <location>
--   (an absolute Device URL cannot be reconstructed without knowing which
--   candidate Envoy selected).
--
-- Envoy internal redirects are not used: they require a fully qualified
-- Location and then re-select a route by path. A Device path such as
-- /x-nmos/connection/... would not match a bridge route under
-- /x-nmos-bridge/... (and would not hit the Query API cluster either).
--
-- Per-route context is set into dynamic metadata namespace
-- nmos_bridge_location by the nmos.bridge.location_meta Lua filter
-- (LuaPerRoute from the adapter).
--
-- Structure: generic URL/string helpers, then bridge-specific helpers, then
-- policy (handle_location) and Envoy entry points. Pure helpers are exported
-- via the module return value for unit tests; Envoy loads this file for the
-- global envoy_on_* entry points and ignores the return. Envoy Lua has no URL
-- library, so most of the file is RFC 3986-oriented parse/resolve support.

local M = {}
local DYN = "nmos_bridge_location"

-- ---------------------------------------------------------------------------
-- Generic URL / string helpers (no bridge policy)
-- ---------------------------------------------------------------------------

local function split_host_port(host, scheme)
    local default_port = (scheme == "https") and "443" or "80"
    local h, p = host:match("^%[([^%]]+)%]:(%d+)$")
    if h then
        return h, p
    end
    h = host:match("^%[([^%]]+)%]$")
    if h then
        return h, default_port
    end
    h, p = host:match("^([^:]+):(%d+)$")
    if h then
        return h, p
    end
    return host, default_port
end

local function parse_authority_pathquery(rest, default_scheme)
    local authority, pathquery = rest:match("^([^/?#]+)(.*)$")
    if not authority then
        return nil
    end
    if pathquery == nil or pathquery == "" then
        pathquery = "/"
    end
    local host, port = split_host_port(authority, default_scheme)
    return host, port, pathquery
end

local function parse_absolute(url)
    local s_flag, rest = url:match("^[Hh][Tt][Tt][Pp]([Ss]?)://(.+)$")
    if not rest then
        return nil
    end
    local scheme = (s_flag ~= nil and s_flag ~= "") and "https" or "http"
    local host, port, pathquery = parse_authority_pathquery(rest, scheme)
    if not host then
        return nil
    end
    return scheme, host, port, pathquery
end

local function split_path_rest(pathquery)
    local path, rest = pathquery:match("^([^?#]*)(.*)$")
    if path == nil then
        return nil, nil
    end
    return path, rest
end

-- If path equals prefix or is prefix/..., return (suffix, query/fragment).
-- suffix is "" or "/...". Otherwise nil.
local function path_suffix_after(pathquery, prefix)
    local path, rest = split_path_rest(pathquery)
    if path == nil then
        return nil
    end
    if path == prefix then
        return "", rest
    end
    local with_slash = prefix .. "/"
    if path:sub(1, #with_slash) == with_slash then
        return path:sub(#prefix + 1), rest
    end
    return nil
end

-- RFC 3986 §5.2.4 remove_dot_segments (path only).
local function remove_dot_segments(path)
    -- 1. The input buffer is initialized with the now-appended path
    --    components and the output buffer is initialized to the empty
    --    string.
    local input = path
    local output = {}
    -- 2. While the input buffer is not empty, loop as follows:
    while input ~= "" do
        -- A. If the input buffer begins with a prefix of "../" or "./",
        --    then remove that prefix from the input buffer; otherwise,
        if input:sub(1, 3) == "../" then
            input = input:sub(4)
        elseif input:sub(1, 2) == "./" then
            input = input:sub(3)
        -- B. if the input buffer begins with a prefix of "/./" or "/.",
        --    where "." is a complete path segment, then replace that
        --    prefix with "/" in the input buffer; otherwise,
        elseif input:sub(1, 3) == "/./" then
            input = "/" .. input:sub(4)
        elseif input == "/." then
            input = "/"
        -- C. if the input buffer begins with a prefix of "/../" or "/..",
        --    where ".." is a complete path segment, then replace that
        --    prefix with "/" in the input buffer and remove the last
        --    segment and its preceding "/" (if any) from the output
        --    buffer; otherwise,
        elseif input:sub(1, 4) == "/../" then
            input = "/" .. input:sub(5)
            if #output > 0 then
                table.remove(output)
            end
        elseif input == "/.." then
            input = "/"
            if #output > 0 then
                table.remove(output)
            end
        -- D. if the input buffer consists only of "." or "..", then remove
        --    that from the input buffer; otherwise,
        elseif input == "." or input == ".." then
            input = ""
        -- E. move the first path segment in the input buffer to the end of
        --    the output buffer, including the initial "/" character (if
        --    any) and any subsequent characters up to, but not including,
        --    the next "/" character or the end of the input buffer.
        else
            local seg, rest = input:match("^(/?[^/]*)(.*)$")
            if not seg then
                break
            end
            table.insert(output, seg)
            input = rest
        end
    end
    -- 3. Finally, the output buffer is returned as the result.
    return table.concat(output)
end

-- Resolve a path-relative reference against a path (no query/fragment on the
-- base for merge; ref may carry ?/#).
local function resolve_path_relative(base_path, reference)
    local ref_path, ref_rest = split_path_rest(reference)
    if ref_path == nil then
        return nil
    end
    local base_dir = base_path:match("^(.*)/") or ""
    local merged = base_dir .. "/" .. ref_path
    return remove_dot_segments(merged) .. (ref_rest or "")
end

local function header_safe(value)
    return (value:gsub("[\r\n]", ""))
end

-- Escape a string for inclusion in a JSON string value.
local function json_string(value)
    local out = {}
    for i = 1, #value do
        local c = value:sub(i, i)
        local b = string.byte(c)
        if c == "\\" then
            table.insert(out, "\\\\")
        elseif c == '"' then
            table.insert(out, '\\"')
        elseif c == "\b" then
            table.insert(out, "\\b")
        elseif c == "\f" then
            table.insert(out, "\\f")
        elseif c == "\n" then
            table.insert(out, "\\n")
        elseif c == "\r" then
            table.insert(out, "\\r")
        elseif c == "\t" then
            table.insert(out, "\\t")
        elseif b < 0x20 then
            table.insert(out, string.format("\\u%04x", b))
        else
            table.insert(out, c)
        end
    end
    return table.concat(out)
end

-- ---------------------------------------------------------------------------
-- Bridge-specific helpers
-- ---------------------------------------------------------------------------

local function authority_key(host, port)
    return host:lower() .. ":" .. port
end

local function matches_upstream(
    loc_scheme,
    loc_host,
    loc_port,
    upstream_scheme,
    upstream_authorities
)
    if loc_scheme ~= upstream_scheme then
        return false
    end
    local want = authority_key(loc_host, loc_port)
    for entry in string.gmatch(upstream_authorities, "[^,]+") do
        local host, port = split_host_port(entry, upstream_scheme)
        if authority_key(host, port) == want then
            return true
        end
    end
    return false
end

-- Reconstruct the upstream request path from the downstream bridge path.
local function upstream_path_from_downstream(downstream_path, bridge_path, base_path)
    if downstream_path == nil or downstream_path == "" then
        return base_path
    end
    local suffix = path_suffix_after(downstream_path, bridge_path)
    if suffix == nil then
        return base_path
    end
    return base_path .. suffix
end

local function rewrite_onto_bridge(pathquery, base_path, bridge_path)
    local suffix, rest = path_suffix_after(pathquery, base_path)
    if suffix == nil then
        return nil
    end
    return bridge_path .. suffix .. rest
end

local function reject_unsupported(response_handle, location)
    local msg = "unsupported upstream location: " .. location
    local body =
        '{"code":502,"error":"' .. json_string(msg) .. '","debug":null}'
    response_handle:headers():replace(":status", "502")
    response_handle:headers():replace("content-type", "application/json")
    response_handle:headers():add("x-nmos-bridge-error", header_safe(msg))
    response_handle:headers():remove("location")
    -- always_wrap_body: an upstream 3xx typically has no body to wrap.
    -- setBytes does not update Content-Length; set it from the returned size.
    local content_length = response_handle:body(true):setBytes(body)
    response_handle:headers():replace("content-length", content_length)
end

-- ---------------------------------------------------------------------------
-- Policy
-- ---------------------------------------------------------------------------

-- Returns rewritten Location string, "reject", or nil to leave unchanged.
local function handle_location(
    location,
    base_path,
    bridge_path,
    bridge_scheme,
    bridge_host,
    upstream_scheme,
    upstream_authorities,
    downstream_path
)
    if location == nil or location == "" then
        return nil
    end

    -- root-relative (path-absolute)
    if location:sub(1, 1) == "/" and location:sub(2, 2) ~= "/" then
        local rewritten = rewrite_onto_bridge(location, base_path, bridge_path)
        if rewritten ~= nil then
            return rewritten
        end
        return "reject"
    end

    -- path-relative (no scheme; not scheme-relative)
    if location:sub(1, 2) ~= "//" and not location:match("^[A-Za-z][A-Za-z0-9+.-]*:") then
        local up_path =
            upstream_path_from_downstream(downstream_path, bridge_path, base_path)
        local resolved = resolve_path_relative(up_path, location)
        if resolved == nil then
            return "reject"
        end
        local rewritten = rewrite_onto_bridge(resolved, base_path, bridge_path)
        if rewritten ~= nil then
            return rewritten
        end
        return "reject"
    end

    -- scheme-relative: fill scheme from the downstream request, then absolute
    local absolute = location
    if location:sub(1, 2) == "//" then
        absolute = bridge_scheme .. ":" .. location
    elseif not location:lower():match("^https?://") then
        -- non-http(s) absolute
        return "reject"
    end

    local loc_scheme, loc_host, loc_port, pathquery = parse_absolute(absolute)
    if not loc_scheme then
        return "reject"
    end
    if
        not matches_upstream(
            loc_scheme,
            loc_host,
            loc_port,
            upstream_scheme,
            upstream_authorities
        )
    then
        -- foreign absolute / scheme-relative: leave the original Location
        return nil
    end
    local rewritten = rewrite_onto_bridge(pathquery, base_path, bridge_path)
    if rewritten == nil then
        -- candidate authority but path outside Connection API base: the
        -- Location already names a precise URL (e.g. /x-manifest/)
        return nil
    end
    return bridge_scheme .. "://" .. bridge_host .. rewritten
end

-- ---------------------------------------------------------------------------
-- Envoy entry points
-- ---------------------------------------------------------------------------

function envoy_on_request(request_handle)
    local headers = request_handle:headers()
    local host = headers:get(":authority") or headers:get("host")
    local path = headers:get(":path")
    local scheme = headers:get("x-forwarded-proto")
    if scheme == nil or scheme == "" then
        scheme = headers:get(":scheme")
    end
    if scheme == nil or scheme == "" then
        scheme = "http"
    end
    if host == nil or host == "" then
        return
    end
    local md = request_handle:streamInfo():dynamicMetadata()
    md:set(DYN, "host", host)
    md:set(DYN, "scheme", scheme)
    if path ~= nil and path ~= "" then
        md:set(DYN, "path", path)
    end
end

function envoy_on_response(response_handle)
    local status = tonumber(response_handle:headers():get(":status"))
    if status == nil or status < 300 or status >= 400 then
        return
    end
    local location = response_handle:headers():get("location")
    if location == nil or location == "" then
        return
    end

    local dyn = response_handle:streamInfo():dynamicMetadata():get(DYN)
    if dyn == nil then
        return
    end
    local base_path = dyn["base_path"]
    local bridge_path = dyn["bridge_path"]
    local upstream_scheme = dyn["upstream_scheme"]
    local upstream_authorities = dyn["upstream_authorities"]
    local bridge_host = dyn["host"]
    local bridge_scheme = dyn["scheme"]
    local downstream_path = dyn["path"]
    if
        base_path == nil
        or bridge_path == nil
        or upstream_scheme == nil
        or upstream_authorities == nil
        or bridge_host == nil
        or bridge_scheme == nil
    then
        return
    end

    local result = handle_location(
        location,
        base_path,
        bridge_path,
        bridge_scheme,
        bridge_host,
        upstream_scheme,
        upstream_authorities,
        downstream_path
    )
    if result == "reject" then
        reject_unsupported(response_handle, location)
        return
    end
    if result ~= nil and result ~= location then
        response_handle:headers():replace("location", result)
    end
end

-- Pure helpers (Envoy entry points stay global; reject_unsupported needs handles).
M.path_suffix_after = path_suffix_after
M.remove_dot_segments = remove_dot_segments
M.resolve_path_relative = resolve_path_relative
M.parse_absolute = parse_absolute
M.rewrite_onto_bridge = rewrite_onto_bridge
M.handle_location = handle_location

return M
