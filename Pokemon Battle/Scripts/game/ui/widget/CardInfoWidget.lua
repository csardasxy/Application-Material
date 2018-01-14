local _M = class("CardInfoWidget", lc.ExtendUIWidget)

local DECORATED_LABEL_GAP = 12
local TEXT_LEFT = 24
local panelSpace = 75

local ICO_OPACITY_VALID = 255
local ICO_OPACITY_INVALID = 128

local NAME_COLOR_VALID = V.COLOR_TEXT_DARK
local NAME_COLOR_INVALID = V.COLOR_TEXT_GRAY
local NAME_COLOR_EXTRA = V.COLOR_TEXT_DARK
local DESC_COLOR_VALID = V.COLOR_TEXT_DARK
local DESC_COLOR_INVALID = NAME_COLOR_INVALID

function _M.create2(infoId, level, size, isBrief, card)
    local widget = _M.new(lc.EXTEND_LAYOUT)
    widget:init2(infoId, level, size, isBrief, card)
    return widget
end

function _M:init2(infoId, level, size, isBrief, card)
    self._infoId = infoId
    self._level = level
    self._isBrief = isBrief
    self._card = card
    self:setContentSize(size)
    
    local list = lc.List.createV(size, 1, 0)
    list:setBounceEnabled(false)
    list:setAnchorPoint(0.5, 1)
    lc.addChildToPos(self, list, cc.p(lc.cw(self), lc.top(self) - 64))
    self._list = list

    self:updateList2()
end

function _M:updateList2()
    local list = self._list

    list:removeAllItems()

    local info, cardType = Data.getInfo(self._infoId)

    if (V.isInBattleScene() and self._card and #self._card._skills > 0) or (not V.isInBattleScene() and info._skillId[1] ~= 0) then
        list:pushBackCustomItem(self:createSkill2())
    end
    --[[
    if self._isBrief then
        local h = 20
        for i = 1, #list:getItems() do
            h = h + lc.h(list:getItems()[i]) + 20
        end
        h = h - 20
        self:setContentSize(lc.w(list), h)
        list:setContentSize(lc.w(list), h)
        list:setPositionY(math.floor(h / 2))
    end
    ]]
end 

function _M:createSkill2()
    local item, infoId, w, marginTop = self:createItemBegin2(Str(STR.SKILL))
    local info, cardType = Data.getInfo(infoId)

    local skills = {}
    if V.isInBattleScene() and self._card then
        for i = 1, #self._card._skills do
            local skillInfo = Data._skillInfo[self._card._skills[i]._id]
            local skill = {
                _skillInfo = skillInfo,
                _skillLevel = self._level,
                _provider = self._card._skills[i]._provider,
            }
            table.insert(skills, skill)
        end
    else
        for i = 1, #info._skillId do
            local skillInfo = Data._skillInfo[info._skillId[i]]
            if skillInfo then
                local skill = {
                    _skillInfo = skillInfo,
                    _skillLevel = self._level,
                }
                table.insert(skills, skill)
            end
        end
    end
    
    local nameDescGap = 4
    local iconNameGap = 10

    for i, skill in ipairs(skills) do
        local iconName, nameStr, descStr = V.getSkillDisplayInfo(skill._skillInfo._id, skill._skillLevel)
        if skill._provider == BattleData.SkillProvider.extra or skill._provider == BattleData.SkillProvider.given then
            nameStr = nameStr..' ('..Str(STR.BATTLE_CARD_EXTRA_SKILL)..')'
        end

        local skillIco = lc.createSprite(iconName)
        local skillName = item:createText(nameStr)
        
        local skillDesc = item:createText(descStr, nil, w - 2 * lc.w(skillIco) - 2 * iconNameGap + 10)

        skillIco:setOpacity(ICO_OPACITY_VALID)
        skillName:setColor((skill._provider == BattleData.SkillProvider.extra or skill._provider == BattleData.SkillProvider.given) and NAME_COLOR_EXTRA or NAME_COLOR_VALID)
        skillDesc:setColor(DESC_COLOR_VALID) 
        skillIco:setScale(0.6)
        local itemH = math.max(lc.h(skillIco) * 0.6, lc.h(skillName) + lc.h(skillDesc) + nameDescGap)
        itemH = itemH + 12
        local skillItem = ccui.Widget:create()
        skillItem:setContentSize(w, itemH)

        local skillFrame = lc.createSprite({_name = "card_frame_skill_fame", _crect = cc.rect(4, 4, 1, 1), _size = cc.size(lc.w(skillItem) + 2, lc.h(skillItem))})
        lc.addChildToCenter(skillItem, skillFrame)

        V.addSkillTapHandler(skillItem, skill._skillInfo._id, skill._skillLevel)
        lc.addChildToPos(item, skillItem, cc.p(w / 2, marginTop))
        lc.addChildToPos(skillItem, skillIco, cc.p(lc.w(skillIco) / 2, lc.h(skillItem) / 2))
        lc.addChildToPos(skillItem, skillName, cc.p(lc.cw(skillItem), lc.top(skillIco) - lc.h(skillName) / 2))
        lc.addChildToPos(skillItem, skillDesc, cc.p(lc.cw(skillItem), lc.bottom(skillName) - lc.h(skillDesc) / 2 - nameDescGap))
        
        
        --[[ TODO
        if cardType == Data.CardType.monster and not Data.isRebirthId(infoId) then
            local evolutionArea = V.createEvolutionArea(card:getQuality(), (i < 3 and i or 4))
            lc.addChildToPos(skillItem, evolutionArea, cc.p(lc.w(skillItem) - lc.w(evolutionArea) / 2, lc.y(skillName) - 1))
        end
        ]]

        marginTop = marginTop + lc.h(skillName) + nameDescGap + lc.h(skillDesc) + 28
    end

    return self:createItemEnd2(item, w, marginTop)
end

function _M.create(infoId, level, size, isBrief, card)
    local widget = _M.new(lc.EXTEND_LAYOUT)
    widget:init(infoId, level, size, isBrief, card)
    return widget
end

function _M:init(infoId, level, size, isBrief, card)
    self._infoId = infoId
    self._level = level
    self._isBrief = isBrief
    self._card = card
    self:setContentSize(size)
    
    local list = lc.List.createV(size, 16, 0)
    list:setAnchorPoint(0.5, 1)
    lc.addChildToCenter(self, list)
    self._list = list

    self:updateList()
end

function _M:updateList()
    local list = self._list

    list:removeAllItems()

    local info, cardType = Data.getInfo(self._infoId)

    if not self._isBrief then
        if cardType == Data.CardType.monster then
            list:pushBackCustomItem(self:createHead())
        end
        
        list:pushBackCustomItem(self:createDesc())

    end

    if (cardType == Data.CardType.monster) 
        and ((info._joinResult ~= nil and info._joinResult[1] ~= 0) 
        or (info._joinComponent ~= nil and info._joinComponent[1] ~= 0)) then
    end
    --[[
    if not self._isBrief and ClientData._userRegion and #Str(info._guideSid) > 1 then
        list:pushBackCustomItem(self:createGuide())
    end
    ]]
    if self._isBrief then
        local h = 20
        for i = 1, #list:getItems() do
            h = h + lc.h(list:getItems()[i]) + 20
        end
        h = h - 20
        self:setContentSize(lc.w(list), h)
        list:setContentSize(lc.w(list), h)
        list:setPositionY(math.floor(h / 2))
    end
end 

function _M:createItemBegin(str)
    local marginTop = 10
    local w = lc.w(self._list) - 20

    local item = ccui.Widget:create()
    item:setContentSize(w, 0)
    item.createText = function(self, str, color, width)
        local text = V.createTTF(str)
        if color then text:setColor(color) end
        if width then text:setDimensions(width, 0) end
        return text
    end

    item.createRichText = function(self, str, color, width)
        local text = V.createTTF(str)
        if width ~= nil and lc.w(text) > width + 4 then
            text = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S3, width + 4)
        else
            text = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S3)
        end
        text:setAnchorPoint(cc.p(0, 0.5))
        return text
    end

    if str then
        local title = V.addDecoratedLabel(item, str, cc.p(lc.cw(item), 0), DECORATED_LABEL_GAP)
        item._title = title
        marginTop = marginTop + lc.h(title) + 4
    else
        marginTop = marginTop - 8
    end

    return item, self._infoId, w, marginTop
end

function _M:createItemBegin2(str)
    local marginTop = 26
    local w = lc.w(self._list) - 10

    local item = ccui.Widget:create()
    item:setContentSize(w, 0)
    item.createText = function(self, str, color, width)
        local text = V.createTTF(str, V.FontSize.S4)
        if color then text:setColor(color) end
        if width then text:setDimensions(width, 0) end
        return text
    end

    item.createRichText = function(self, str, color, width)
        local text = V.createTTF(str)
        if width ~= nil and lc.w(text) > width + 4 then
            text = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S2, width + 4)
        else
            text = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S2)
        end
        text:setAnchorPoint(cc.p(0, 0.5))
        return text
    end

    return item, self._infoId, w, marginTop
end

function _M:createItemEnd2(item, w, marginTop)
    local h = marginTop
    item:setContentSize(cc.size(w, marginTop))

    for _, child in ipairs(item:getChildren()) do
        marginTop = child:getPositionY()
        child:setPositionY(h - marginTop - lc.sh(child) / 2)
    end

    self._list:setContentSize(lc.w(self._list), lc.h(item))
    return item
end

function _M:createItemEnd(item, w, marginTop)
    local h = marginTop
    item:setContentSize(cc.size(w, marginTop))
    for _, child in ipairs(item:getChildren()) do
        marginTop = child:getPositionY()
        child:setPositionY(h - marginTop - lc.sh(child) / 2)
    end

    return item
end

function _M:createHead()
    local marginTop = 10
    local w = lc.w(self._list) - 20
    local h = 146
    local item = ccui.Widget:create()
    item:setContentSize(w, 0)
    
    local info = Data.getInfo(self._infoId)
    
    item.createText = function(self, str, color, width)
        local text = V.createTTF(str)
        if color then text:setColor(color) end
        if width then text:setDimensions(width, 0) end
        return text
    end
    item.createRichText = function(self, str, color, width)
        local text = V.createTTF(str)
        if width ~= nil and lc.w(text) > width + 4 then
            text = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S4, width + 4)
        else
            text = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S4)
        end
        return text
    end

    local evolveWidth = 0
    
    if info._evoResult ~= nil and info._evoResult[1] ~= 0 then
        local str = Str(STR.CARD_EVOLVE)
        local evolvePanel = lc.createSprite({_name = 'card_info_widget', _crect = cc.rect(26, 49, 5, 5), _size = cc.size(118, h)})
        lc.addChildToPos(item, evolvePanel, cc.p(w / 2 - 150, 0))

        local evolvePanelBg = lc.createSprite('card_frame_stage')
        lc.addChildToPos(evolvePanel, evolvePanelBg, cc.p(lc.cw(evolvePanel) - 1, lc.ch(evolvePanel) - 12))

        local evolutionIcon = cc.ShaderSprite:createWithFramename(V.getCardIconName(info._evoResult[1], true))
        lc.addChildToCenter(evolvePanelBg, evolutionIcon)
        item._evolutionIcon = evolutionIcon

        local title = V.addDecoratedLabel(evolvePanel, str, cc.p(lc.cw(evolvePanel) - 5, lc.h(evolvePanel) - 17), DECORATED_LABEL_GAP)
        item._title = title
        evolveWidth = lc.w(evolvePanel) + 4
    end

    local w2 = w - evolveWidth - 12
    local dataPanel = lc.createSprite({_name = 'card_info_widget', _crect = cc.rect(26, 49, 5, 5), _size = cc.size(w2, h)})
    lc.addChildToPos(item, dataPanel, cc.p(evolveWidth + 6 + w2 / 2, 0))
    local str1 = Str(STR.CARD_DETAILS)
    local title1 = V.addDecoratedLabel(dataPanel, str1, cc.p(lc.cw(dataPanel), lc.h(dataPanel) - 17), DECORATED_LABEL_GAP)

    local str = ''
    if info._categoryData then
        str = "No."..string.format("%03d", info._categoryData[1]).."\n"..Str(info._categoryInfo).."\n"..Str(STR.CARD_BODYHEIGHT)..": "..string.format("%d\'%02d\"", info._categoryData[2] / 100, info._categoryData[2] % 100).."\n"..Str(STR.CARD_BODYWEIGHT)..": "..string.format("%.1f Lbs",info._categoryData[3] / 10)
    end

    local keyword = item:createText(str, V.COLOR_TEXT_LIGHT, w2 - 10)
    lc.addChildToPos(dataPanel, keyword, cc.p(lc.cw(dataPanel) + 16, lc.ch(dataPanel) - 10))
    
    marginTop = marginTop + h + 4
    
    local h = marginTop
    item:setContentSize(cc.size(w, marginTop))

    for _, child in ipairs(item:getChildren()) do
        marginTop = child:getPositionY()
        child:setPositionY(h - marginTop - lc.sh(child) / 2)
    end

    return item
end

function _M:createCategory()
    local item, infoId, w, marginTop = self:createItemBegin(Str(STR.CARD_CATEGORY))

    local info = Data.getInfo(infoId)

    local category = item:createText(Str(STR.CARD_CATEGORY_BEGIN + info._category)..' - '..Str(info._skillId[1] == 0 and STR.CARD_CATEGORY_NORMAL or STR.CARD_CATEGORY_EFFECT), V.COLOR_TEXT_LIGHT, w - 10)
    lc.addChildToPos(item, category, cc.p(w / 2, marginTop))

    return self:createItemEnd(item, w, marginTop + lc.h(category))
end

function _M:createKeyword()
    local item, infoId, w, marginTop = self:createItemBegin(Str(STR.CARD_KEYWORD))

    local info = Data.getInfo(infoId)

    local keyword = item:createText(Str(STR.CARD_KEYWORD_BEGIN + info._keyword), V.COLOR_TEXT_LIGHT, w - 10)
    lc.addChildToPos(item, keyword, cc.p(w / 2, marginTop))

    return self:createItemEnd(item, w, marginTop + lc.h(keyword))
end

function _M:createDesc()
    local item, infoId, w, marginTop = self:createItemBegin(Str(STR.CARD_INTRO))

    local info = Data.getInfo(infoId)

    local desc = item:createRichText(Str(info._descSid), V.COLOR_TEXT_LIGHT, w - 40)
    lc.addChildToPos(item, desc, cc.p(TEXT_LEFT, marginTop))
    
    local panel = lc.createSprite({_name = 'card_info_widget', _crect = cc.rect(26, 49, 5, 5), _size = cc.size(w - 12, lc.h(desc) + panelSpace)})
    lc.addChildToPos(item, panel, cc.p(lc.cw(item), lc.ch(item)))
    panel:setLocalZOrder(-1)

    return self:createItemEnd(item, w, marginTop + lc.h(desc) + panelSpace - lc.h(item._title))
end

function _M:createGuide()
    local item, infoId, w, marginTop = self:createItemBegin(Str(STR.CARD_USEGUIDE))

    local info = Data.getInfo(infoId)

    local desc = item:createRichText(Str(info._guideSid, true), V.COLOR_TEXT_LIGHT, w - 40)
    lc.addChildToPos(item, desc, cc.p(TEXT_LEFT, marginTop))

    local panel = lc.createSprite({_name = 'card_info_widget', _crect = cc.rect(26, 49, 5, 5), _size = cc.size(w - 12, lc.h(desc) + panelSpace)})
    lc.addChildToPos(item, panel, cc.p(lc.cw(item), lc.ch(item)))
    panel:setLocalZOrder(-1)

    return self:createItemEnd(item, w, marginTop + lc.h(desc) + panelSpace - lc.h(item._title))
end

function _M:createUseLimit()
    local item, infoId, w, marginTop = self:createItemBegin(Str(STR.USE_LIMITED))

    local info = Data.getInfo(infoId)

    local desc = item:createText(string.format(Str(STR.USE_LIMIT_DESC), info._maxCount), V.COLOR_TEXT_LIGHT, w - 10)
    lc.addChildToPos(item, desc, cc.p(w / 2, marginTop))

    return self:createItemEnd(item, w, marginTop + lc.h(desc))
end

function _M:createSkillAddition()
    local item, card, w, marginTop = self:createItemBegin(Str(STR.SKILL)..Str(STR.ADDITION))
    
    if card._newSkillId > 0 then
        local desc = cc.Label:createWithTTF(Str(STR.SKILL_ADDITION_DESC), V.TTF_FONT, V.FontSize.S2)
        desc:setColor(DESC_COLOR_VALID)
        lc.addChildToPos(item, desc, cc.p(w / 2, marginTop))
        marginTop = marginTop + lc.h(desc) + 10

        local skillIco, skillName
        if card._newSkillId > 1000 then
            skillIco = lc.createSprite(string.format("img_icon_skill_%d", Data.getType(card._newSkillId)))
            skillIco:setScale(0.6)

            skillName = V.createTTF(string.format("%s (+%d)", Str(Data._skillInfo[card._newSkillId]._nameSid), self._infoId._newSkillLevel), V.FontSize.S1)

            V.addSkillTapHandler(item, card._newSkillId, 1)
        else
            skillName = V.createTTF(Str(STR.EQUIP_POLISH_RANDOM), V.FontSize.S1)
        end
        
        if card:isSkillValid() then
            if skillIco then skillIco:setOpacity(ICO_OPACITY_VALID) end
            skillName:setColor(NAME_COLOR_VALID)
        else
            if skillIco then skillIco:setOpacity(ICO_OPACITY_INVALID) end
            skillName:setColor(NAME_COLOR_INVALID)
        end

        local skillItem = lc.createNode(cc.size(w, skillIco and lc.sh(skillIco) or lc.h(skillName)))
        lc.addChildToPos(item, skillItem, cc.p(w / 2, marginTop))

        if skillIco then
            lc.addNodesToCenterH(skillItem, {skillIco, skillName}, 10)
        else
            lc.addChildToCenter(skillItem, skillName, 10)
        end

        marginTop = marginTop + lc.h(skillItem) + 10
    else
        local desc1 = V.createBoldRichText(Str(STR.FORGING_LEVEL_ARRIVE), {_normalClr = DESC_COLOR_VALID, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S2})
        local evoArea = V.createEvolutionArea(card:getQuality(), 5)
        local desc2 = item:createText(Str(STR.GET_RANDOM_SKILL_ADDITION), DESC_COLOR_VALID)

        lc.addNodesToCenterH(item, {desc1, evoArea, desc2}, 4, marginTop)
        evoArea:setPositionY(marginTop - 2)

        marginTop = marginTop + lc.h(evoArea) + 10
    end
    
    return self:createItemEnd(item, w, marginTop)
end

return _M