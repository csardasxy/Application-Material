local _M = class("SkillWidget", lc.ExtendUIWidget)

local SKILL_WIDGET_W = 250
local SKILL_WIDGET_H = 66

function _M.create(skillId, curLevel, dstLevel, bgColor, bgOpacity, fontColor)
    local widget = _M.new(lc.EXTEND_IMAGE, "img_com_bg_7", ccui.TextureResType.plistType)
    widget:setScale9Enabled(true)
    widget:setCapInsets(V.CRECT_COM_BG7)
    widget:setContentSize(cc.size(SKILL_WIDGET_W, SKILL_WIDGET_H))
    widget:setColor(bgColor)
    widget:setOpacity(bgOpacity)
    widget:setTouchEnabled(true)
    widget:init(skillId, curLevel, dstLevel, bgColor, bgOpacity, fontColor)
    return widget
end

function _M:init(skillId, curLevel, dstLevel, bgColor, bgOpacity, fontColor)
    self._skillId = skillId
    self._curLevel = curLevel
    self._dstLevel = dstLevel
    
    local marginLeft = 22
    local marginTop = 16
    local space = 8

    local skill = Data._skillInfo[skillId]
    local name = Str(skill._nameSid)
    if skill._val[1] ~= 0 then
        name = name..string.format(" %d", curLevel)
    end 
        
    local skillIco = cc.Sprite:createWithSpriteFrameName(string.format("img_icon_skill_%d", Data.getSkillType(skill._id)))
    skillIco:setScale(0.8)
    local skillName = cc.Label:createWithTTF(name, V.TTF_FONT, V.FontSize.S2)
    skillName:setColor(fontColor)
    lc.addChildToPos(self, skillIco, cc.p(lc.sw(skillIco) / 2 + marginLeft, lc.h(self) / 2))
    lc.addChildToPos(self, skillName, cc.p(lc.right(skillIco) + lc.w(skillName) / 2 + space, lc.y(skillIco)))
    self._skillName = skillName
    
    local incLevel = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.S2)
    incLevel:setColor(lc.Color3B.red)
    self:addChild(incLevel)
    self._incLevel = incLevel
    self:updateDstLevel(dstLevel)
    
    local button = V.createShaderButton("img_btn_squarel_s_2", function(sender) self:onSkillDetail() end)    
    local label = V.createBMFont(V.BMFont.huali_20, "...")
    label:setScale(0.8)
    lc.addChildToCenter(button, label)    
    lc.addChildToPos(self, button, cc.p(SKILL_WIDGET_W - lc.w(button) / 2 - 6, SKILL_WIDGET_H / 2))
    self._button = button
    
    local detail = require("SkillDetailWidget").create(skillId, curLevel, dstLevel, true, bgColor, bgOpacity, fontColor, fontColor)
    detail:setAnchorPoint(0.5, 0)
    detail:setVisible(false)
    detail:setPosition(SKILL_WIDGET_W / 2, SKILL_WIDGET_H)
    self:addChild(detail)
    self._detail = detail
end

function _M:onSkillDetail()
    if not self._detail:isVisible() then
        self._detail:updateDisplayLevel(self._dstLevel)
        self._detail:setVisible(true)
    else
        self._detail:setVisible(false)
    end
end

function _M:updateDstLevel(dstLevel)
    self._dstLevel = dstLevel
    
    local skill = Data._skillInfo[self._skillId]
    if self._dstLevel == self._curLevel or skill._val[1] == 0 then
        self._incLevel:setVisible(false)
    else
        self._incLevel:setVisible(true)
        self._incLevel:setString(string.format("->%d", dstLevel))
        self._incLevel:setPosition(lc.right(self._skillName) + lc.w(self._incLevel) / 2, lc.y(self._skillName))
    end
end

return _M