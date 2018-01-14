local _M = class("DragonBones", function(str) return cc.DragonBonesNode:createWithDecrypt(string.format("res/effects/%s.lcres", str), str, str) end)
DragonBones = _M

function _M.create(str)
    local spr = _M.new(str)
    spr:init(str)
    
    spr:registerScriptHandler(function(evtName)
        if evtName == "cleanup" then
            spr:onCleanup()
        end
    end)
    
    return spr
end

function _M:onCleanup()
    if ClientData._dragonBonesTexture[self._name] ~= nil then
        ClientData._dragonBonesTexture[self._name] = ClientData._dragonBonesTexture[self._name] - 1
    end

    if ClientData._dragonBonesTexture[self._name] == 0 then
        local fname = self._name..".png"
        if lc.TextureCache:getTextureForKey(fname) ~= nil then
            cc.DragonBonesNode:removeTextureAtlas(self._name)
            lc.TextureCache:removeTextureForKey(fname)
            --lc.log("unload dragonbones  "..fname)
        end
    end
end

function _M:init(str)
    self._name = str
    
    ClientData._dragonBonesTexture = ClientData._dragonBonesTexture or {}
    ClientData._dragonBonesTexture[self._name] = (ClientData._dragonBonesTexture[self._name] or 0) + 1
end

return _M