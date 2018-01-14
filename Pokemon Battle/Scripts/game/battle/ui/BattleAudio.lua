local _M = class("BattleAudio")
BattleAudio = _M

function _M:ctor(battleUi)
   self._battleUi = battleUi
end

function _M:playHeroAudio(id, isDying)
    local heroAudio = Data._heroAudioInfo[id]
    if heroAudio ~= nil then
        local str = isDying and heroAudio._offVoice or heroAudio._onVoice
        self:playEffect(str)
    end
end

function _M:playSkillAudio(skillId, card, delay)
    local skillAudio = Data._skillAudioInfo[skillId]
    if skillAudio ~= nil and P._guideID >= 100 then
        if skillAudio._effect1 ~= "NULL" then
            self:playEffect(skillAudio._effect1)
        end
        
        if skillAudio._effect2 ~= "NULL" then
            delay = delay or 0.01
            self._battleUi:runAction(cc.Sequence:create(
                cc.DelayTime:create(delay),
                cc.CallFunc:create(function () self:playEffect(skillAudio._effect2) end)
            ))
        end
        
        local str = card._owner._avatar % 100 ~= 0 and skillAudio._voice1 or skillAudio._voice2
        self:playEffect(str)
    end
end

function _M:playEffect(str)
    if str == nil or str == "NULL" then return end
    
    if ClientData._isEffectOn then
        cc.SimpleAudioEngine:getInstance():playEffect("res/bat_audio/"..str..".mp3")
    end
end

return _M