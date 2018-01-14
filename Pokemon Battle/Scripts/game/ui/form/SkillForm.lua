local _M = class("SkillForm", BaseForm)

local FORM_WIDTH = 720
local POP_PANEL_SIZE = cc.size(200, 320)

local DESC_PARAM = {_fontSize = V.FontSize.S1, _curColor = V.COLOR_TEXT_LIGHT, _nextColor = V.COLOR_TEXT_GREEN_DARK}

function _M.create(skillId, level)
    local form = _M.new(lc.EXTEND_LAYOUT_MASK)    
    form:init(skillId, level)
    return form
end

function _M:init(skillId, level)
    local info = Data._skillInfo[skillId]

    self._skillInfo = info
    self._skillLevel = level

    local tempArea = self:createSkillArea(CardHelper.getSkillMaxLevel(skillId))
    local areaH = lc.h(tempArea)

    local area = self:createSkillArea(level, areaH)

    local refSkills, refSkillCount, refStatusCount = info._refSkills, 0, 0
    for _, skillId in ipairs(refSkills) do
        if skillId > 100 and skillId < 20000 then refSkillCount = refSkillCount + 1
        elseif skillId > 0 and skillId <= 100 then refStatusCount = refStatusCount + 1
        end
    end

    local h = areaH + _M.FRAME_THICK_V + 80
    if refSkillCount > 0 then
        h = h + 64 + math.floor((refSkillCount + 1) / 2) * 54
    end
    if refStatusCount > 0 then
        h = h + 64 + refStatusCount * 54
    end

    local refCards, refCardCount = {}, 0
    for _, card in ipairs(info._refCards) do
        if card > 10000 and card < 50000 then 
            refCardCount = refCardCount + 1 
            refCards[#refCards + 1] = card
        end
    end
    if refCardCount > 0 then
        h = h + 50 + refCardCount * 100
    end

    _M.super.init(self, cc.size(FORM_WIDTH, h), nil, bor(BaseForm.FLAG.PAPER_BG))

    local form = self._form
    lc.addChildToPos(form, area, cc.p(FORM_WIDTH / 2, h - _M.FRAME_THICK_TOP - 30 - areaH / 2))
    self._skillArea = area

    self._maxLevel = CardHelper.getSkillMaxLevel(skillId)
    --[[
    if self._maxLevel > 1 then
        -- Add arrows
        local btnW = 120

        local btnArrowLeft = V.createArrowButton(true, cc.size(btnW, areaH), function(sender) self:onBtnArrow(sender) end)
        lc.addChildToPos(form, btnArrowLeft, cc.p(_M.FRAME_THICK_LEFT + btnW / 2 - 10, lc.y(area)))
        self._btnArrowLeft = btnArrowLeft
        if level == 1 then btnArrowLeft:setVisible(false) end

        local btnArrowRight = V.createArrowButton(false, cc.size(btnW, lc.h(area)), function(sender) self:onBtnArrow(sender) end)
        lc.addChildToPos(form, btnArrowRight, cc.p(lc.w(form) - _M.FRAME_THICK_RIGHT - btnW / 2 + 10, lc.y(area)))
        self._btnArrowRight = btnArrowRight
        if level == self._maxLevel then btnArrowRight:setVisible(false) end
    end
    ]]

    -- Create reference skill button
    local marginTop = lc.bottom(area)
    if refSkillCount > 0 then
        local line = lc.createSprite('img_divide_line_8')
        line:setScale((lc.w(form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT) / lc.w(line), 1)
        lc.addChildToPos(form, line, cc.p(lc.w(form) / 2, marginTop - 10))

        local label = cc.Label:createWithTTF(Str(STR.SKILL_REF), V.TTF_FONT, V.FontSize.M1)
        label:setColor(V.COLOR_TEXT_ORANGE)
        lc.addChildToPos(form, label, cc.p(FORM_WIDTH / 2, marginTop - 40), 60)

        local y, isSingle = lc.bottom(label) - 16
        if refSkillCount == 1 then
            isSingle = true
        end

        local crect = cc.rect(V.CRECT_COM_BG5.x, 0, V.CRECT_COM_BG5.width, lc.frameSize("img_com_bg_5").height)
        for i, id in ipairs(refSkills) do
            if id > 100 and id < 20000 then
                local button = V.createScale9ShaderButton("img_com_bg_5", function()
                    _M.create(id, 1):show()
                end, crect, 220)
                local _, nameStr = V.getSkillDisplayInfo(id, 1)
                local label = V.createTTF(nameStr, V.FontSize.S1)
                lc.addChildToCenter(button, label)
                
                local isLeft = (i % 2 == 1)
                local x = (FORM_WIDTH / 2 + (isSingle and 0 or (isLeft and - 120 or 120)))
                lc.addChildToPos(form, button, cc.p(x, y - lc.h(button) / 2))

                if not isLeft then
                    y = y - 54
                end
            end
        end

        marginTop = marginTop - 64 - math.floor((refSkillCount + 1) / 2) * 54
    end

    if refStatusCount > 0 then
        local line = lc.createSprite('img_divide_line_8')
        line:setScale((lc.w(form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT) / lc.w(line), 1)
        lc.addChildToPos(form, line, cc.p(lc.w(form) / 2, marginTop - 10))

        local label = cc.Label:createWithTTF(Str(STR.SKILL_STATUS_REF), V.TTF_FONT, V.FontSize.M1)
        label:setColor(V.COLOR_TEXT_ORANGE)
        lc.addChildToPos(form, label, cc.p(FORM_WIDTH / 2, marginTop - 40), 60)

        local y, isSingle = lc.bottom(label) - 16        
        for i, id in ipairs(refSkills) do
            if id > 0 and id < 100 then
                local status = V.createBoldRichText(Str(STR.SKILL_STATUS1 + id - 1), V.RICHTEXT_PARAM_LIGHT_S2)
                local x = FORM_WIDTH / 2
                lc.addChildToPos(form, status, cc.p(x, y - lc.h(status) / 2))

                y = y - 40
            end
        end

        marginTop = marginTop - 64 - math.floor((refStatusCount + 1) / 2) * 54
    end

    if refCardCount > 0 then
        local line = lc.createSprite('img_divide_line_8')
        line:setScale((lc.w(form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT) / lc.w(line), 1)
        lc.addChildToPos(form, line, cc.p(lc.w(form) / 2, marginTop - 10))

        local label = cc.Label:createWithTTF(Str(STR.SKILL_CARD_REF), V.TTF_FONT, V.FontSize.M1)
        label:setColor(V.COLOR_TEXT_ORANGE)
        lc.addChildToPos(form, label, cc.p(FORM_WIDTH / 2, marginTop - 40), 60)

        local iconW, gap = 100, 20
        local x = (lc.w(form) - refCardCount * iconW - (refCardCount - 1) * gap) / 2
        local y = lc.bottom(label) - 8
        for i = 1, refCardCount do
            local icon = IconWidget.create({_infoId = refCards[i]})
            icon._name:setColor(V.COLOR_BMFONT)
            lc.addChildToPos(form, icon, cc.p(x + iconW / 2, y - lc.h(icon) / 2))
            x = x + iconW + gap
        end
    end
end

function _M:createSkillArea(level, height)
    local area = lc.createNode()
    area:setCascadeOpacityEnabled(true)

    local info = self._skillInfo
    local skillType = Data.getSkillType(info._id)

    local icon = lc.createSprite(string.format("img_icon_skill_%d", skillType))
    local desc = V.createSkillDesc(info._id, level, nil, 500, DESC_PARAM)
    area._desc = desc

    height = height or lc.h(icon) + lc.h(desc) + 50
    area:setContentSize(lc.w(desc), height)
    
    lc.addChildToPos(area, icon, cc.p(lc.w(area) / 2 - 120, height - lc.h(icon) / 2))

    local crect = cc.rect(V.CRECT_COM_BG5.x, 0, V.CRECT_COM_BG5.width, lc.frameSize("img_com_bg_5").height)
                     
    local button = V.createScale9ShaderButton("img_com_bg_5", function() self:onShowSkills() end, crect, 220)
    local _, nameStr = V.getSkillDisplayInfo(info._id, level)
    local label = V.createTTF(nameStr, V.FontSize.S1)
    lc.addChildToCenter(button, label)
    button:setCascadeOpacityEnabled(true)
    button._label = label
    area._btn = button

    lc.addChildToPos(area, button, cc.p(lc.right(icon) + 10 + lc.w(button) / 2, lc.y(icon)))
    
    if info._val[1] == 0 then
        button:setEnabled(false)
        button:setColor(lc.Color3B.gray)
    end

    local typeStr = Str(STR[string.format("SKILL_TYPE_%d", skillType)])
    local skillTypeLabel = V.createTTF(typeStr, nil, V.COLOR_LABEL_LIGHT)
    lc.addChildToPos(area, skillTypeLabel, cc.p(lc.w(area) / 2, lc.bottom(icon) - 4 - lc.h(skillTypeLabel) / 2))

    lc.addChildToPos(area, desc, cc.p(lc.w(area) / 2, lc.bottom(skillTypeLabel) - 20 - lc.h(desc) / 2))

    return area
end

function _M:onShowSkills()
    --[[
    local info, level, buttonDefs = self._skillInfo, self._skillLevel, {}
    for i = 1, self._maxLevel do
        local name = string.format("%s %d", Str(STR.LEVEL), i)
        table.insert(buttonDefs, {_str = name, _handler = function() self:onSelectSkill(i) end})
    end
    
    local panel = require("TopMostPanel").ButtonList.create(POP_PANEL_SIZE)
    if panel then
        local gPos = lc.convertPos(cc.p(0, 0), self._skillArea._btn)
        panel:setButtonDefs(buttonDefs)
        panel:setPosition(gPos.x + lc.w(panel) / 2 + 8, gPos.y - lc.h(panel) / 2 - 6)
        panel:linkNode(self._skillArea._btn)
        panel:show()
    end
    ]]
end

function _M:onSelectSkill(level)
    if level == self._skillLevel then return end

    self._skillLevel = level
    local skillId = self._skillInfo._id

    local _, nameStr = V.getSkillDisplayInfo(skillId, level)
    self._skillArea._btn._label:setString(nameStr)

    local desc = self._skillArea._desc
    local x, y = desc:getPosition()
    desc:removeFromParent()
    desc = V.createSkillDesc(skillId, level, nil, 300, DESC_PARAM)
    lc.addChildToPos(self._skillArea, desc, cc.p(x, y))
    self._skillArea._desc = desc

    --self._btnArrowLeft:setVisible(level ~= 1)
    --self._btnArrowRight:setVisible(level ~= self._maxLevel)
end

function _M:onBtnArrow(arrow)
    self._skillArea._btn:setEnabled(false)

    self._btnArrowLeft:setVisible(true)
    self._btnArrowRight:setVisible(true)

    local offset, x, y = lc.x(self._skillArea) - lc.w(self._skillArea) / 2, lc.w(self._form) / 2, lc.y(self._skillArea)
    local nextLevel, nextSkillArea
    if arrow == self._btnArrowLeft then
        nextLevel = self._skillLevel - 1
        nextSkillArea = self:createSkillArea(self._skillLevel - 1)
    else
        nextLevel = self._skillLevel + 1
        nextSkillArea = self:createSkillArea(self._skillLevel + 1)
        offset = -offset
    end

    self._btnArrowLeft:setVisible(nextLevel ~= 1)
    self._btnArrowRight:setVisible(nextLevel ~= self._maxLevel)

    nextSkillArea._btn:setEnabled(false)
    nextSkillArea:setOpacity(0)
    lc.addChildToPos(self._form, nextSkillArea, cc.p(x - offset, y))

    local curSkillArea, duration = self._skillArea, lc.absTime(0.2)
    curSkillArea:stopAllActions()
    curSkillArea:runAction(lc.sequence({lc.moveTo(duration, x + offset, y), lc.fadeOut(duration)}, lc.remove()))

    nextSkillArea:runAction(lc.sequence({lc.moveTo(duration, x, y), lc.fadeIn(duration)}, function() nextSkillArea._btn:setEnabled(true) end))
    self._skillArea = nextSkillArea
    self._skillLevel = nextLevel
end

return _M