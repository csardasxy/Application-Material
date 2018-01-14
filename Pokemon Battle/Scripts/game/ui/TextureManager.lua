local _M = {}

local MAX_TEXTURE_COUNT = 90

function _M.init()
    _M._textures = {}
    _M._count = 0
    _M._tick = 0
end

function _M.clear()
    for k, v in pairs(_M._textures) do
        lc.App:unloadRes(k)
    end
    _M.init()
end

function _M.loadTexture(frameName, fileName)
    if not _M._textures[frameName] then
        if _M._count == MAX_TEXTURE_COUNT then
            _M.unloadOldestTexture()
        end

        lc.App:loadRes(fileName)
        _M._count = _M._count + 1

        --print ('[TextureManager] LOAD', frameName, _M._count, _M._tick)
    end
    
    _M._textures[frameName] = _M._tick
    _M._tick = _M._tick + 1
end

function _M.unloadOldestTexture()
    local minTick = 0xFFFFFFFF
    local minName = nil
    for k, v in pairs(_M._textures) do
        if v < minTick then
            minTick = v
            minName = k
        end
    end

    if minName ~= nil then
        lc.App:unloadRes(minName)
        _M._textures[minName] = nil
        _M._count = _M._count - 1
        --print ('[TextureManager] UNLOAD', minName, _M._count, minTick)
    end
end

function _M.preloadTextures(names)
    for i = 1, #names do
        _M.loadTexture(names[i])
    end
end

TextureManager = _M
return _M