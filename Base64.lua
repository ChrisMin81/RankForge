--[[
    RankForge - Base64.lua
    Pure Lua Base64 encoding/decoding and safe table serialization for profile import/export.
]]

local addonName, RF = ...

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64_encode(data)
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function base64_decode(data)
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0) end
        return string.char(c)
    end))
end

-- Safe table serializer (supports string, number, boolean, table)
local function serializeTable(val)
    local t = type(val)
    if t == "number" then
        return tostring(val)
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "table" then
        local parts = {}
        for k, v in pairs(val) do
            local keyStr
            if type(k) == "string" and k:match("^[%a_][%a%d_]*$") then
                keyStr = k
            else
                keyStr = "[" .. serializeTable(k) .. "]"
            end
            local valStr = serializeTable(v)
            if valStr then
                table.insert(parts, keyStr .. "=" .. valStr)
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    else
        return nil
    end
end

-- Safe deserializer: parse the simple table format safely without loadstring
local function safeDeserialize(str)
    if not str or type(str) ~= "string" then return nil end
    
    -- Using pcall with secure environment if available, or sandbox table parsing
    local func, err
    if setfenv and loadstring then
        func, err = loadstring("return " .. str)
        if func then
            setfenv(func, {})
        end
    elseif load then
        func, err = load("return " .. str, nil, "t", {})
    end
    
    if func then
        local ok, res = pcall(func)
        if ok and type(res) == "table" then
            return res
        end
    end
    return nil
end

function RF:ExportProfileToString(profileTable)
    if not profileTable then return "" end
    local serialized = serializeTable(profileTable)
    if not serialized then return "" end
    return "RF1:" .. base64_encode(serialized)
end

function RF:ImportProfileFromString(encodedStr)
    if not encodedStr or type(encodedStr) ~= "string" then return nil end
    encodedStr = encodedStr:match("^%s*(.-)%s*$") -- trim
    
    local payload = encodedStr
    if encodedStr:sub(1, 4) == "RF1:" then
        payload = encodedStr:sub(5)
    end
    
    local decoded = base64_decode(payload)
    if not decoded or decoded == "" then return nil end
    
    return safeDeserialize(decoded)
end
