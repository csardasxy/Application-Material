local _M = class("BattleScene", require("BaseScene"))
BattleScene = _M

_M.ZOrder =
{
    bg = 0,
    battle = 10,
    ui = 20,
    dialog = 30,
    form = 40,
    story = 50,

    top = 100,
}

function _M.create(input)
    return lc.createScene(_M, input)
end

function _M:init(input)
    if not _M.super.init(self, ClientData.SceneId.battle) then return false end
    
    self._input = input
    ClientData._battleScene = self

    -- Do not guide in the battle
    self._isGuideOnEnter = false

    self._battleUiNormal = BattleUi.create(self, input, "normal")
    self:addChild(self._battleUiNormal)

    self._battleUi = self._battleUiNormal

    ClientData.sendUserEvent({battleType = input._battleType, isAttacker = input._isAttacker})

    if P._guideID == 11 then
        local sprite = cc.Sprite:createWithTexture(V._rt:getSprite():getTexture())
        sprite:setFlippedY(true)
        V._rt:release()
        lc.addChildToCenter(self, sprite, 100000)
        self._screenShot = sprite
    end

    return true
end

function _M:playBgMusic()
    if P._guideID >= 21 then
        if self._battleUiNormal then
            if self._battleUiNormal._baseBattleType == Data.BattleType.base_PVP or self._battleUiNormal._baseBattleType == Data.BattleType.base_replay then
                lc.Audio.playAudio(AUDIO.M_BATTLE)
            else
                lc.Audio.playAudio(AUDIO.M_BATTLE)
            end
        else
            lc.Audio.playAudio(AUDIO.M_GUIDE2)
        end
    else
        lc.Audio.playAudio(AUDIO.M_GUIDE)
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    if self._battleUi and self._battleUi._isBattleFinished then
        return
    end

    GuideManager.releaseLayer()

    self:playBgMusic()
end

function _M:onCleanup()  
    _M.super.onCleanup(self)

    if ClientData._battleScene == self then
        ClientData._battleScene = nil
    end
end

-- override baseScene functions

function _M:onMsg(msg)
    if self._battleUiNormal and self._battleUiNormal:onMsg(msg) then 
        return true
    end
        
    return _M.super.onMsg(self, msg)
end

function _M:onMsgErrorStatus(msg, msgStatus)    
    if msgStatus == SglMsg_pb.PB_STATUS_BATTLE_JOIN_NOT_ALLOWED then
        if self._battleUiNormal then
                self._battleUiNormal:exitScene()
        end

        return true
    end

    return _M.super.onMsgErrorStatus(self, msg, msgStatus)
end

function _M:onIdle() 
    if self._battleUiNormal and self._battleUiNormal._resultDialog == nil then
        lc.Director:updateTouchTimestamp()
        return 
    end
    
    _M.super.onIdle(self)
end

function _M:onLogin()
    if _M.super.onLogin(self) then return true end
    
    ClientData._fromSceneId = nil
    self._battleUiNormal:exitScene()
    
    return true
end

function _M:onBattleRecover(input)
    local recover = function()
        V.getActiveIndicator():hide()
    
        if input._sceneType ~= self._battleUi._sceneType then
            self._battleUi:stopAllActions()

            -- Release last bg res
            --local sceneName = string.format("bat_scene_%d", self._battleUi._sceneType)
            --ClientData.unloadLCRes({sceneName..".jpm", sceneName..".png.sfb"})
            --lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename(string.format("res/bat_scene/%s_bg.jpg", sceneName)))    

            -- Load new bg res
            --ClientData.loadLCRes(string.format("res/bat_scene_%d.lcres", input._sceneType))
        end

        lc._runningScene = nil -- always replace new battle scene here
        lc.replaceScene(BattleScene.create(input))

        -- Notify server loading done
        ClientData.sendBattleLoadingDone()
    end

    recover()
end

function _M:onBattleEnd(resp)
    if self._isBattleWait then
        return _M.super.onBattleEnd(self, resp)
    end

    if self._battleUiNormal then
        self._battleUiNormal:onBattleEnd(resp)
    end
end

function _M:onBattleWait()
    _M.super.onBattleWait(self)
    self._isBattleWait = true
end

function _M:onExpeditionEx(input)
    self:onBattleRecover(input)
end

function _M:onReplay(input)
    self:onBattleRecover(input)
end

function _M:showReloadDialog(str, msgStatus)
    _M.super.showReloadDialog(self, str, msgStatus)
    self._battleUi:pause()
end

function _M:reconnect(msg)
    _M.super.reconnect(self, msg)
    self._battleUi:pause()

end

return _M