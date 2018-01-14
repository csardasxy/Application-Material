local _M = class("SkillDetailWidget", lc.ExtendUIWidget)

function _M.create(skillId, curLevel, dstLevel, isShowBtn, bgColor, bgOpacity, nameColor, descColor)
    local widget = _M.new(lc.EXTEND_IMAGE, "img_com_bg_7", ccui.TextureResType.plistType)
    widget:setScale9Enabled(true)
    widget:setCapInsets(V.CRECT_COM_BG7)
    widget:setContentSize(cc.size(230, 200))
    widget:setColor(bgColor)
    widget:setOpacity(bgOpacity)
    widget:setTouchEnabled(true)
    widget:init(skillId, curLevel, dstLevel, isShowBtn, nameColor, descColor)
    return widget
end

function _M:init(skillId, curLevel, dstLevel, isShowBtn, nameColor, descColor)
    self._skillId = skillId
    self._curLevel = curLevel
    self._dstLevel = dstLevel
    self._displayLevel = curLevel

    local marginLeft = 10
    local marginTop = 24
    local space = 10

    local skill = Data._skillInfo[skillId]
    local name = Str(skill._nameSid)
    if skill._val[1] ~= 0 then
        name = name..string.format(" %d", self._displayLevel)
    end
    local desc = ClientData.getSkillDesc(skillId, self._displayLevel)
     
    local skillIco = cc.Sprite:createWithSpriteFrameName(string.format("img_icon_skill_%d", Data.getSkillType(skill._id)))
    skillIco:setScale(0.8)
    local skillName = cc.Label:createWithTTF(name, V.TTF_FONT, V.FontSize.S2)
    skillName:setColor(nameColor)
    
    local x = (lc.w(self) - lc.w(skillIco) - lc.w(skillName) - space) / 2
    lc.addChildToPos(self, skillIco, cc.p(x + lc.w(skillIco) / 2, lc.h(self) - lc.h(skillIco) / 2 - marginTop))
    lc.addChildToPos(self, skillName, cc.p(lc.right(skillIco) + lc.w(skillName) / 2 + space, lc.y(skillIco)))
    
    local skillDesc = cc.Label:createWithTTF(desc, V.TTF_FONT, V.FontSize.S2, cc.size(lc.w(self) - 40, 0))
    skillDesc:setColor(descColor)
    lc.addChildToPos(self, skillDesc, cc.p(lc.w(self) / 2, lc.bottom(skillIco) - lc.h(skillDesc) / 2 - space))

    self._skillIco = skillIco
    self._skillName = skillName
    self._skillDesc = skillDesc

    if isShowBtn and skill._val[1] ~= 0 then
        local btnLeft = V.createShaderButton("img_icon_minus", function(sender)
            if self._displayLevel > 1 then
                self:updateDisplayLevel(self._displayLevel - 1)
            end
        end)
        local btnRight = V.createShaderButton("img_icon_add", function(sender)
            if self._displayLevel < #skill._val and skill._val[self._displayLevel + 1] ~= 0 then
                self:updateDisplayLevel(self._displayLevel + 1)
            end    
        end)
        local w = lc.w(btnLeft)
        btnLeft:setTouchRect(cc.rect(-w, -w, w * 3, w * 3))
        btnRight:setTouchRect(cc.rect(-w, -w, w * 3, w * 3))
        lc.addChildToPos(self, btnLeft, cc.p(marginLeft + w / 2, lc.y(skillIco)))
        lc.addChildToPos(self, btnRight, cc.p(lc.w(self) - marginLeft - w / 2, lc.y(skillIco)))
    end
end

function _M:updateDisplayLevel(displayLevel)
    self._displayLevel = displayLevel

    local skill = Data._skillInfo[self._skillId] 
    if skill._val[1] ~= 0 then 
        self._skillName:setString(Str(skill._nameSid)..string.format(" %d", self._displayLevel))
    else
        self._skillName:setString(Str(skill._nameSid))
    end
    self._skillDesc:setString(ClientData.getSkillDesc(self._skillId, self._displayLevel))
end

return _M