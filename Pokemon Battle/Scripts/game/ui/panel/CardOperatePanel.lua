local _M = class("CardOperatePanel", require("BasePanel"))

local CardThumbnail = require("CardThumbnail")

_M.OperateMode = 
{
    compose = 1,
    upgrade = 2,
    decompose = 3,
    recovery = 4,
}

local DETAIL_AREA_SIZE = cc.size(340, 412)

local EFFECT_COLOR = {
    cc.c4f(0, 0.3, 0.1, 0.1),
    cc.c4f(0, 0.11, 0.5, 0.1),
    cc.c4f(0.45, 0.11, 0.5, 0.1),
    cc.c4f(0.45, 0.11, 0, 0.1),
    cc.c4f(0.4, 0, 0, 0.1)
}

local MODE_STR = {
    Str(STR.COMPOSE),
    Str(STR.UPGRADE),
    Str(STR.DECOMPOSE),
    Str(STR.RECOVERY),
}

function _M.create(infoId, mode, card)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(infoId, mode, card)
    return panel   
end

function _M:init(infoId, mode, card)
    _M.super.init(self, true)

    self._panelName = "CardOperatePanel"

    self._isShowResourceUI = true

    self._infoId = infoId   
    self._mode = mode
    self._card = card
    local level = P._playerCard._levels[infoId] or 1
    self._level = level
    
    -- bg
    local bg = lc.createSprite("res/jpg/ui_scene_bg.jpg")
    lc.addChildToCenter(self, bg)

    -- Top area
    local topArea = V.createTitleArea(MODE_STR[self._mode], function() self:hide() end)
    self:addChild(topArea)
    self._topArea = topArea

    -- bottom area
    self:createBottomArea()

    -- left thumbnail
    local leftThumbnail = self:createThumbnail(infoId, nil)
    lc.addChildToPos(self, leftThumbnail, cc.p(lc.w(self) / 2 - 230, lc.h(self) / 2 + 118))
    lc.offset(leftThumbnail, 0, -30)
    self._leftThumbnail = leftThumbnail

    local totalCount = P._playerCard:getCardCount(infoId)
    local countInTroop = P._playerCard:getCardCountInTroop(infoId)
    --[[
    self._max = totalCount - countInTroop
    if P._playerUnion._groupId then
       self._max = math.max(totalCount - 3, 0)
    end
    ]]
    self._max = self._mode == _M.OperateMode.recovery and totalCount - countInTroop or math.max(totalCount - 3, 0)
    
    local label1 = V.createTTF(lc.str(STR.CURRENT_OWN)..': '..totalCount)
    lc.addChildToPos(self, label1, cc.p(lc.left(leftThumbnail) + lc.w(label1) / 2, lc.bottom(leftThumbnail) - 26))
    self._label1 = label1

    local label2 = V.createTTF(lc.str(STR.INTROOPED)..': '..countInTroop)
    lc.addChildToPos(self, label2, cc.p(lc.left(leftThumbnail) + lc.w(label2) / 2, lc.bottom(label1) - 20))
    self._label2 = label2

    local label3 = V.createTTF(lc.str(STR.CAN_S)..lc.str(STR.DECOMPOSE)..': '..self._max)
    lc.addChildToPos(self, label3, cc.p(lc.left(leftThumbnail) + lc.w(label3) / 2, lc.bottom(label2) - 20))
    self._label3 = label3
    if  mode==_M.OperateMode.recovery then label3:setString(lc.str(STR.CAN_S)..lc.str(STR.RECOVERY)..': '..self._max)
    
    end


    -- btn
    local btn = V.createShaderButton("img_rebirth_btn", function(sender) 
        if self._mode == _M.OperateMode.upgrade then 
            self:onUpgrade()
        elseif self._mode == _M.OperateMode.compose then 
            self:onCompose()
        elseif self._mode == _M.OperateMode.decompose then 
            self:onDecompose()
        elseif self._mode == _M.OperateMode.recovery then 
            self:onRecovery()
        end 
    end)
    lc.addChildToPos(self, btn, cc.p(lc.w(self) / 2 + 200, 270))
    lc.offset(btn, 0, -60)
    self._btn = btn

    local label = V.createBMFont(V.BMFont.huali_32, labelStr)
    label:setColor(lc.Color3B.yellow)
    label:setAdditionalKerning(10)
    lc.addChildToPos(btn, label, cc.p(lc.w(btn) / 2, 30))
    btn._label = label

    local goldArea = V.createResIconLabel(130, "img_icon_res1_s")
    goldArea.update = function(self, gold)
        self._label:setString(gold)
        self._label:setColor(P._gold < gold and lc.Color3B.red or lc.Color3B.white)
    end
    lc.addChildToPos(btn, goldArea, cc.p(lc.w(btn) / 2 + 12, 62))
    self._goldArea = goldArea

    --TODO
    self._goldArea:setVisible(false)
    lc.offset(btn._label, 0, 20)

    self:onSelectMode(self._modeBtns[self._mode])
end

function _M:createBottomArea()
    local bottomBg = lc.createImageView({_name = 'img_travel_bottom', _crect = cc.rect(124, 0, 4, 79), _size = cc.size(920, 79)})
    lc.addChildToPos(self, bottomBg, cc.p(lc.w(self) / 2, lc.h(bottomBg) / 2))
    self._modeBtns = {}
    local strs = {'compose', 'upgrade', 'decompose', 'decompose'}
    local titleIds = {STR.COMPOSE, STR.UPGRADE, STR.DECOMPOSE, STR.RECOVERY}
    for i = 1, 4 do
        local btn = V.createShaderButton('img_btn_card_op_unfocus', function(sender) self:onSelectMode(sender) end)
        btn._index = i
        lc.addChildToPos(bottomBg, btn, cc.p(lc.w(bottomBg) / 2 + 192 * (-2 + i), 58), 1)
        local icon = lc.createSprite('img_icon_card_op_'..strs[i])
        lc.addChildToCenter(btn, icon)
        lc.offset(icon, 0, 16)
        local title = V.createBMFont(V.BMFont.huali_26, Str(titleIds[i]))
        lc.addChildToCenter(btn, title)
        lc.offset(title, 0, -24)
        self._modeBtns[#self._modeBtns + 1] = btn
    end
    bottomBg:setVisible(false)
end

function _M:onSelectMode(modeBtn)
    self._mode = modeBtn._index
    self._count = 0

    for i = 1, 3 do
        self._modeBtns[i]:loadTextureNormal(i == self._mode and 'img_btn_card_op_focus' or 'img_btn_card_op_unfocus', ccui.TextureResType.plistType)
    end

    self._topArea._title:setString(MODE_STR[self._mode])
    self._btn._label:setString(MODE_STR[self._mode])

    self:updateView()
end

function _M:createThumbnail(infoId)
    local thumbnail = CardThumbnail.create(infoId)
    thumbnail:setTouchEnabled(true)
    thumbnail:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            local CardInfoPanel = require("CardInfoPanel")
            CardInfoPanel.create(infoId, level, CardInfoPanel.OperateType.na):show()
        end
    end)

    return thumbnail
end

function _M:createArrow()
    local arrow = lc.createSprite("img_arrow_right")
    arrow:setScale(0.5)
    arrow:setColor(V.COLOR_TEXT_GREEN)
    return arrow
end

function _M:createDetailDividingLine()
    local area = ccui.Widget:create()

    local line = V.createDividingLine(260, cc.c3b(14, 140, 228))
    area:setContentSize(line:getContentSize())
    lc.addChildToCenter(area, line)

    return area
end

function _M:createDetailEvoArea()    
    local card, newCard = self._leftThumbnail._card, self._rightThumbnail._card
    
    local area = ccui.Widget:create()

    local leftPart = V.createEvolutionArea(card:getQuality(), card:getStar() + 1)
    local rightPart = V.createEvolutionArea(newCard:getQuality(), card:getStar() + 1)

    local arrow = self:createArrow()

    area:setContentSize(lc.w(self._detailList), lc.h(leftPart))

    lc.addNodesToCenterH(area, {leftPart, arrow, rightPart}, 10, lc.h(area) / 2)
    lc.offset(arrow, 0, 2)

    return area
end

function _M:createDetailSkillArea()
    local info, cardType = Data.getInfo(self._infoId)
    local skillId, skillLevel, newSkillId, newSkillLevel
    
    if cardType == Data.CardType.monster then
        --TODO--
        for i = 1, 3 do
            skillId, newSkillId = info._skillId[i], info._skillId[i]
            skillLevel, newSkillLevel = self._level, self._level + 1
            if skillId ~= newSkillId or skillLevel ~= newSkillLevel then
                break
            end
        end
    else
        --TODO--
        for i = 1, 3 do
            skillId, newSkillId = info._skillId[i], info._skillId[i]
            skillLevel, newSkillLevel = self._level, self._level + 1
            if skillId ~= newSkillId or skillLevel ~= newSkillLevel then
                break
            end
        end
    end

    if skillId == 0 then return end

    local area = ccui.Widget:create()
    local skillInfo, newSkillInfo = Data._skillInfo[skillId], Data._skillInfo[newSkillId]

    local icon = lc.createSprite(string.format("img_icon_skill_%d", math.floor(skillId / Data.INFO_ID_GROUP_SIZE)))
    icon:setScale(0.8)

    local nameStr = Str(skillInfo._nameSid)
    if skillInfo._val[skillLevel] > 0 then nameStr = nameStr..string.format(" %d", skillLevel) end
    local name = V.createTTF(nameStr)

    local desc
    if skillId == newSkillId then
        desc = V.createSkillDesc(skillInfo, skillLevel, newSkillLevel, lc.w(self._detailList) - 40)
    else
        desc = V.createSkillDesc(newSkillInfo, newSkillLevel, nil, lc.w(self._detailList) - 40)
    end
    
    area:setContentSize(lc.w(self._detailList), math.floor(lc.sh(icon)) + lc.h(desc) + 10)
    V.addSkillTapHandler(area, newSkillId, newSkillLevel)

    
    lc.addChildToPos(area, icon, cc.p(20 + math.floor(lc.sw(icon)) / 2, lc.h(area) - math.floor(lc.sh(icon)) / 2))

    if skillId ~= newSkillId or newSkillLevel > skillLevel then
        lc.addChildToPos(area, name, cc.p(lc.right(icon) + 16 + lc.w(name) / 2, lc.top(icon) - 20))

        local arrow = self:createArrow()
        lc.addChildToPos(area, arrow, cc.p(lc.right(name) + 10 + lc.sw(arrow) / 2, lc.y(name)))

        if skillId == newSkillId then
            local level = V.createTTF(tostring(newSkillLevel), nil, V.COLOR_TEXT_GREEN)
            lc.addChildToPos(area, level, cc.p(lc.right(arrow) + 10 + lc.w(level) / 2, lc.y(name)))
        else
            local nameStr = Str(newSkillInfo._nameSid)
            if newSkillInfo._val[newSkillLevel] > 0 then nameStr = nameStr..string.format(" %d", newSkillLevel) end
            local newName = V.createTTF(nameStr, nil, V.COLOR_TEXT_GREEN)
            lc.addChildToPos(area, newName, cc.p(lc.right(arrow) + 10 + lc.w(newName) / 2, lc.y(name)))
        end
    else
        local unlock = V.createTTF(string.format(Str(STR.BRACKETS_S), Str(STR.GET)), nil, V.COLOR_TEXT_GREEN)
        lc.addChildToPos(area, unlock, cc.p(lc.right(icon) + 16 + lc.w(unlock) / 2, lc.top(icon) - 20))
        lc.addChildToPos(area, name, cc.p(lc.right(unlock) + 6 + lc.w(name) / 2, lc.y(unlock)))
    end
    
    lc.addChildToPos(area, desc, cc.p(lc.w(area) / 2, lc.h(desc) / 2))

    return area
end

function _M:createDetailValueChangeArea()
    local height, lineH, ptH = 0, 48, 20
    
    local info, cardType = Data.getInfo(self._infoId)
    local atkValue, newAtkValue
    if cardType == Data.CardType.monster then
        atkValue, newAtkValue = info._atk[self._level], info._atk[self._level + 1]
        height = height + lineH
    end

    local hpValue, newHpValue
    if cardType == Data.CardType.monster then
        hpValue, newHpValue = info._hp[self._level], info._hp[self._level + 1]
        height = height + lineH
    end

    if height == 0 then return nil end

    local area = ccui.Widget:create()
    area:setContentSize(lc.w(self._detailList), height)

    local addLine = function(symName, symScale, value, newValue, pt, newPt, y, symOffsetY)
        if value == nil or value == newValue then return y end

        local symbol
        if lc.FrameCache:getSpriteFrame(symName) then
            symbol = lc.createSprite(symName)
        else
            symbol = V.createTTF(symName, V.FontSize.S1, V.COLOR_LABEL_LIGHT)
        end
        symbol:setScale(symScale)
        symbol:setAnchorPoint(1, 0.5)

        lc.addChildToPos(area, symbol, cc.p(80, y + (symOffsetY or 0)))

        local arrow = self:createArrow()
        lc.addChildToPos(area, arrow, cc.p(190, y))

        local val2Str = function(val)
            if val < 1 then
                return string.format("%d%%", val * 100)
            else
                return tostring(val)
            end
        end

        value = V.createTTF(val2Str(value), V.FontSize.S1)
        lc.addChildToPos(area, value, cc.p(lc.left(arrow) - 10 - lc.w(value) / 2, y))

        newValue = V.createTTF(val2Str(newValue), V.FontSize.S1, V.COLOR_TEXT_GREEN)
        lc.addChildToPos(area, newValue, cc.p(lc.right(arrow) + 10 + lc.w(value) / 2, y))

        if pt and newPt > pt then
            y = y - 30

            arrow = self:createArrow()
            lc.addChildToPos(area, arrow, cc.p(190, y))

            pt = V.createKeyValueLabel(string.format("(%s", Str(STR.POTENTIAL)), val2Str(pt), V.FontSize.S2, true)
            pt:addToParent(area, cc.p(lc.left(arrow) - 10 - pt:getTotalWidth(), y))

            newPt = V.createTTF(val2Str(newPt), nil, V.COLOR_TEXT_GREEN)
            lc.addChildToPos(area, newPt, cc.p(lc.right(arrow) + 10 + lc.w(newPt) / 2, y))

            local endBracket = V.createTTF(")", nil, V.COLOR_LABEL_LIGHT)
            lc.addChildToPos(area, endBracket, cc.p(lc.right(newPt) + lc.w(endBracket) / 2, y))

            y = y - lineH - ptH + 30
        else
            y = y - lineH
        end

        return y
    end

    local y = height - lineH / 2
    y = addLine("card_cost", 0.5, repValue, newRepValue, nil, nil, y)
    y = addLine("card_atk", 1.0, atkValue, newAtkValue, nil, nil, y, 2)
    y = addLine("card_def", 1.0, hpValue, newHpValue, nil, nil, y)
    
    return area
end

function _M:createDetailSkillPoolArea()
    local card, skills, prompt, digCountTip = self._leftThumbnail._card, {}
    local skillLevelMin, skillLevelMax

    if card._newSkillCache > 0 then
        local typeName = ClientData.getStrByCardType(card._type)
        local tipStr = string.format(Str(STR.PROMPT_SUB_CACHE), typeName, Str(STR.SKILL_ADDITION), Str(STR.UPGRADE))
        local area = V.createBoldRichText(tipStr, V.RICHTEXT_PARAM_LIGHT_S1, 290)
        return area

    else
        

        if #skills > 0 then
            table.sort(skills, function(a, b) return a._id < b._id end)

            local area, lineH = ccui.Widget:create(), 50
        
            prompt = V.createTTF(prompt, V.FontSize.S1, V.COLOR_LABEL_LIGHT)
            local height = lc.h(prompt) + 20 + lineH * #skills

            if digCountTip then
                height = height + 30
            end

            area:setContentSize(lc.w(self._detailList), height)

            local y = height - lc.h(prompt) / 2
            lc.addChildToPos(area, prompt, cc.p(lc.w(area) / 2, y))

            if digCountTip then
                digCountTip = V.createBoldRichText(digCountTip, V.RICHTEXT_PARAM_LIGHT_S2)
                y = lc.bottom(prompt) - 4 - lc.h(digCountTip) / 2
                lc.addChildToPos(area, digCountTip, cc.p(lc.w(area) / 2, y))
            end

            y = y - lc.h(prompt) / 2 - 20 - lineH / 2

            for _, info in ipairs(skills) do
                local skillArea = ccui.Widget:create()
                skillArea:setContentSize(lc.w(area), lineH)
                V.addSkillTapHandler(skillArea, info._id, skillLevelMin)

                local icon = lc.createSprite(string.format("img_icon_skill_%d", Data.getType(info._id)))
                icon:setScale(0.8)
                lc.addChildToPos(skillArea, icon, cc.p(20 + math.floor(lc.sw(icon)) / 2, lineH / 2))

                local nameStr
                
                if info._val[1] > 0 then
                    nameStr = string.format("%s %d - %d", Str(info._nameSid), skillLevelMin, math.min(skillLevelMax, CardHelper.getSkillMaxLevel(info._id)))
                else
                    nameStr = string.format("%s", Str(info._nameSid))
                end
                
                local name = V.createTTF(nameStr)
                lc.addChildToPos(skillArea, name, cc.p(lc.right(icon) + 16 + lc.w(name) / 2, lineH / 2))

                lc.addChildToPos(area, skillArea, cc.p(lc.w(area) / 2, y))
                y = y - lineH
            end

            return area
        end
    end
end

function _M:updateView()
    local totalCount = P._playerCard:getCardCount(self._infoId)
    local countInTroop = P._playerCard:getCardCountInTroop(self._infoId)

    self._max = self._mode == _M.OperateMode.recovery and totalCount - countInTroop or math.max(totalCount - 3, 0)
    self._label1:setString(lc.str(STR.CURRENT_OWN)..': '..totalCount)
    self._label2:setString(lc.str(STR.INTROOPED)..': '..countInTroop)
    if self._mode == _M.OperateMode.recovery then
        self._label3:setString(lc.str(STR.CAN_S)..lc.str(STR.RECOVERY)..': '..self._max)
    else
        self._label3:setString(lc.str(STR.CAN_S)..lc.str(STR.DECOMPOSE)..': '..self._max)
    end

    self:updateRightThumbnail()
    --self:updateCardInfoArea()
    self:updateCardUpgradeArea()
    self:updateCountSelectArea()

    self:updateCosumeMaterialArea()
    self:updateGotMaterialArea()
    self._goldArea:update(self:getConsumeGold())
end

function _M:updateCardInfoArea()
    if self._cardInfoArea ~= nil then 
        self._cardInfoArea:removeFromParent() 
        self._cardInfoArea = nil
    end

    if self._mode == _M.OperateMode.upgrade then return end

    local areaH = lc.h(self) - 200
    local area = V.createFrameBox(DETAIL_AREA_SIZE)
    
    local list = require('CardInfoWidget').create(self._infoId, self._level, cc.size(lc.w(area) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(area) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM), false)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list, -1)

    lc.addChildToPos(self, area, cc.p(lc.w(self) / 2 + 330, lc.y(self._leftThumbnail)))    

    self._cardInfoArea = area
end

function _M:updateCardUpgradeArea()
    if self._cardUpgradeArea ~= nil then 
        self._cardUpgradeArea:removeFromParent() 
        self._cardUpgradeArea = nil
    end

    if self._mode ~= _M.OperateMode.upgrade then return end
    if self._level == Data.CARD_MAX_LEVEL then return end

    local bg = V.createFrameBox(DETAIL_AREA_SIZE)    
    bg:setPosition(lc.w(self) / 2, lc.top(self._leftThumbnail) - lc.h(bg) / 2)
    self:addChild(bg)
    
    list = lc.List.create(cc.size(lc.w(bg) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(bg) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM), 20, 20)
    lc.addChildToCenter(bg, list, -1)
    self._detailList = list

    local addArea = function(area, addDividingLine)
        if area then
            if addDividingLine ~= false then
                list:pushBackCustomItem(self:createDetailDividingLine())
            end

            list:pushBackCustomItem(area)
        end
        return area
    end

    local cardType = Data.getType(self._infoId)
    if cardType == Data.CardType.monster then
        --addArea(self:createDetailEvoArea(), false)
        addArea(self:createDetailValueChangeArea(), false)
    end

    addArea(self:createDetailSkillArea())

    self._cardUpgradeArea = bg
end

function _M:updateCountSelectArea()
    if self._countSelectArea ~= nil then 
        self._countSelectArea:removeFromParent() 
        self._countSelectArea = nil
    end

    if self._mode == _M.OperateMode.upgrade then return end

    local area = lc.createNode()
    area:setContentSize(V.CARD_SIZE)
    lc.addChildToPos(self, area, cc.p(lc.w(self) / 2 + 200, lc.y(self._leftThumbnail)))
    lc.offset(area, 0, 70)

    local titleBg = lc.createSprite({_name = 'img_com_bg_32', _crect = V.CRECT_COM_BG32, _size = cc.size(200, V.CRECT_COM_BG32.height)})
    lc.addChildToPos(area, titleBg, cc.p(lc.w(area) / 2, lc.h(area) - 100))
    local title = V.createBMFont(V.BMFont.huali_26, MODE_STR[self._mode]..lc.str(STR.AMOUNT))
    lc.addChildToCenter(titleBg, title)

    local widget = require("SelectCountWidget").create(function(count)
        self:updateCount(count)
    end, 140, math.min(self._max, 100), 0)
    widget._countVal:setString(self._count)
    self._countWidget = widget
    lc.addChildToPos(area, widget, cc.p(lc.w(area) / 2, lc.bottom(titleBg) - 20 - widget.HEIGHT / 2))
    lc.offset(widget._btnAddTen, -105, -70)
    lc.offset(widget._btnReduceTen, 105, -70)

    self._countSelectArea = area
end

function _M:updateRightThumbnail()
    if self._rightThumbnail ~= nil then 
        self._rightThumbnail:removeFromParent() 
        self._rightThumbnail = nil
    end

    if self._mode ~= _M.OperateMode.upgrade then return end
    if self._level == Data.CARD_MAX_LEVEL then return end

    local rightThumbnail = self:createThumbnail(self._infoId, self._level + 1)
    rightThumbnail:setPosition(lc.w(self) / 2 + 330, lc.y(self._leftThumbnail))
    self:addChild(rightThumbnail)
    self._rightThumbnail = rightThumbnail
end


function _M:updateGotMaterialArea()
    if self._gotMatArea ~= nil then 
        self._gotMatArea:removeFromParent() 
        self._gotMatArea = nil
    end

    if self._mode == _M.OperateMode.upgrade and self._level == Data.CARD_MAX_LEVEL then return end

    local mats ={}
    local createMat = function(infoId, propType, count)
        local mat = {}
        if propType then
            --mat._icon = IconWidget.create(P._propBag._props[propType], 0)--IconWidgetFlag.ITEM_NO_NAME)
            mat._icon = IconWidget.create({_infoId = propType, _num = P:getItemCount(propType)}, 0)--IconWidgetFlag.ITEM_NO_NAME)
            mat._need = count or card:getRebirthNeedCount()
        else
            mat._icon = IconWidget.create({_infoId = infoId, _isFragment = false, _count = P._playerCard:getCardCount(infoId)}, 0)--IconWidgetFlag.ITEM_NO_NAME)
            mat._need = count or card:getRebirthNeedCount()
        end
        return mat
    end

    if self._mode == _M.OperateMode.upgrade then
    elseif self._mode == _M.OperateMode.compose then
        table.insert(mats, createMat(self._infoId, nil, self._count))
    elseif self._mode == _M.OperateMode.decompose then
        local dustType, dustCount = P._playerCard:getDecomposeDust(self._infoId)
        dustCount = dustCount * self._count
        table.insert(mats, createMat(self._infoId, dustType, dustCount))
    elseif self._mode == _M.OperateMode.recovery then
        local dustType, dustCount = P._playerCard:getRecoveryDust(self._card._id)
        dustCount = dustCount * self._count
        table.insert(mats, createMat(self._infoId, dustType, dustCount))
    end

    local matArea = V.createMaterialArea(mats, lc.str(STR.GET)..lc.str(STR.RESOURCE), false)
    --lc.addChildToPos(self, matArea, cc.p(lc.w(self) / 2 + 330, 110))
    lc.addChildToPos(self, matArea, cc.p(lc.w(self) / 2 + 200, 260))
    self._gotMatArea = matArea
end

function _M:getConsumeGold()
    local gold = 0
    if self._mode == _M.OperateMode.upgrade then
        gold = P._playerCard:getUpgradeGold(self._infoId)
    elseif self._mode == _M.OperateMode.compose then
        gold = P._playerCard:getComposeGold(self._infoId) * self._count
    elseif self._mode == _M.OperateMode.decompose then
        gold = P._playerCard:getDecomposeGold(self._infoId) * self._count
    end
    return gold
end

function _M:updateCount(count)
    self._count = count or 0
    self:updateCosumeMaterialArea()
    self:updateGotMaterialArea()
    self._goldArea:update(self:getConsumeGold())
end

function _M:showEffect()
    local info, cardType = Data.getInfo(self._infoId)

    local scene, thumbnail = lc._runningScene, self._leftThumbnail
    
    local pos = lc.convertPos(cc.p(lc.w(thumbnail) / 2, lc.h(thumbnail) / 2), thumbnail, scene)
    local particle = Particle.create("par_card_rebirth5")
    particle:setStartColor(EFFECT_COLOR[info._quality])
    particle:setEndColor(EFFECT_COLOR[info._quality])
    lc.addChildToPos(scene._scene, particle, pos, ClientData.ZOrder.effect)

    scene:runAction(lc.sequence(0.5,
        function()
            self:onUpgradeSuccess()
        end
    ))

    lc.Audio.playAudio(AUDIO.E_CARD_EVOLUTE)
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    self._listeners = {}    
    table.insert(self._listeners, lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.gold_dirty, function(event) self._goldArea:update(self:getConsumeGold()) end))
    
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 1)

    if GuideManager.getCurStepName() == "enter evolve card" then
        GuideManager.finishStepLater()
    end
end

function _M:onExit()
    _M.super.onExit(self)

    ClientData.removeMsgListener(self)
    
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    ClientData.removeMsgListener(self)
end

function _M:onUpgrade()
    local str = Str(STR.UPGRADE)
    local cardType = Data.getType(self._infoId)

    local result = P._playerCard:upgradeCard(self._infoId)
    
    if result == Data.ErrorType.ok then
        V.getActiveIndicator():show()

        self:showEffect()

        ClientData.sendCardUpgrade(self._infoId)
        
        local stepName = GuideManager.getCurStepName()
        if stepName == "evolve card" then
            GuideManager.finishStep(true)
        end
               
    elseif result == Data.ErrorType.card_already_max_level then
        ToastManager.push(string.format(Str(STR.REACH_MAX_LEVEL), Str(STR.CARD)))
    elseif result == Data.ErrorType.card_not_support then
        ToastManager.push(string.format(Str(STR.NOTEVOLUTION), str))
    elseif result == Data.ErrorType.need_more_polish then
        ToastManager.push(Str(STR.NOT_ENOUGH_POLISH))   
    elseif result == Data.ErrorType.need_more_evolutematerial then
        ToastManager.push(Str(STR.NOT_ENOUGH_EVOLUTION_DRUG))
    elseif result == Data.ErrorType.need_more_stonerare then
        ToastManager.push(Str(STR.NOT_ENOUGH_STONE_RARE))
    elseif result == Data.ErrorType.need_more_stonelegend then
        ToastManager.push(Str(STR.NOT_ENOUGH_STONE_LEGEND))
    elseif result == Data.ErrorType.need_more_flowerrare then
        ToastManager.push(Str(STR.NOT_ENOUGH_FLOWER_RARE))
    elseif result == Data.ErrorType.need_more_flowerlegend then
        ToastManager.push(Str(STR.NOT_ENOUGH_FLOWER_LEGEND))
    elseif result == Data.ErrorType.need_more_horse_shoes or result == Data.ErrorType.need_more_horse_armor then
        ToastManager.push(Str(STR.NOT_ENOUGH_HORSE_TRAIN_MAT))
    elseif result == Data.ErrorType.need_more_gold then
        ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
        require("ExchangeResForm").create(Data.ResType.gold):show()
    elseif result == Data.ErrorType.need_more_samecard then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH_SAME_CARD), ClientData.getStrByCardType(cardType))) 
    elseif result == Data.ErrorType.card_cannot_compose then
        ToastManager.push(param)
    end
end

function _M:onUpgradeSuccess()
    V.getActiveIndicator():hide()

    local rewardPanel = require("RewardCardPanel").create(Str(STR.UPGRADE)..Str(STR.SUCCESS), {{_infoId = self._infoId, _num = 1}})
    rewardPanel:show()

    --local newSkillId, newSkillLevel = card:getCacheSkill()
    --if newSkillId then
    if false then
        -- Add new skill info to the reward panel
        local skillInfo, hasSkill = Data._skillInfo[newSkillId], card._newSkillId > 0
        local titleStr, newNameStr, oldNameStr
        titleStr = string.format("%s%s", Str(STR.GET), Str(STR.SKILL_ADDITION))
        newNameStr = string.format("%s (+%d)", Str(skillInfo._nameSid), newSkillLevel)
        if hasSkill then oldNameStr = string.format("%s (+%d)", Str(Data._skillInfo[card._newSkillId]._nameSid), card._newSkillLevel) end
        local name = V.createTTF(newNameStr, hasSkill and V.FontSize.S1 or V.FontSize.M1, V.COLOR_TEXT_GREEN_DARK)
        
        local icon = lc.createSprite(string.format("img_icon_skill_%d", Data.getSkillType(skillInfo._id)))
        icon:setScale(hasSkill and 0.6 or 0.8)

        local w, h = math.max(240, math.floor(lc.sw(icon)) + 10 + lc.w(name) + 60), 140
        if hasSkill then
            w, h = w + 200, h + 30
        end

        local bg = lc.createImageView{_name = "img_com_bg_4", _crect = V.CRECT_COM_BG4, _size = cc.size(w, h)}
        V.addSkillTapHandler(bg, newSkillId, 1)

        local title = V.createTTF(titleStr, V.FontSize.S1, V.COLOR_LABEL_DARK)
        lc.addChildToPos(bg, title, cc.p(w / 2, h - 20 - lc.h(title) / 2))
        lc.addNodesToCenterH(bg, {icon, name}, 10, hasSkill and 94 or 54)

        if hasSkill then
            local strParts = string.splitByChar(Str(STR.PROMPT_SUB_REPLACE), '|')
            local promptSub = ccui.RichTextEx:create()
            promptSub:insertElement(ccui.RichItemLabel:create(0, V.COLOR_TEXT_DARK, 255, strParts[1], V.TTF_FONT, V.FontSize.S2))
            
            local icon = lc.createSprite(string.format("img_icon_skill_%d", Data.getType(card._newSkillId)))
            icon:setScale(0.5)
            local iconNode = lc.createNode(cc.size(30, 30))
            lc.addChildToCenter(iconNode, icon)

            promptSub:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, iconNode))
            promptSub:insertElement(ccui.RichItemLabel:create(0, V.COLOR_TEXT_GREEN_DARK, 255, oldNameStr, V.TTF_FONT, V.FontSize.S2))
            promptSub:insertElement(ccui.RichItemLabel:create(0, V.COLOR_TEXT_DARK, 255, strParts[2], V.TTF_FONT, V.FontSize.S2))

            lc.addChildToPos(bg, promptSub, cc.p(lc.w(bg) / 2, 50))
            V.addSkillTapHandler(promptSub, card._newSkillId, 1)

            lc.offset(rewardPanel._btnBack, -lc.w(rewardPanel._btnBack) / 2 - 10)

            local btnSub = V.createScale9ShaderButton("img_btn_1_s", function()
                card._newSkillId = newSkillId
                card._newSkillLevel = newSkillLevel
                card._newSkillCache = 0
                card:sendCardDirty()

                ClientData.sendCardSetSkill(card._id, card._infoId, true)
                self:updateView()

                rewardPanel:hide()
            end, V.CRECT_BUTTON_1_S, lc.w(rewardPanel._btnBack))

            rewardPanel._btnBack._callback = function()
                card._newSkillCache = 0

                ClientData.sendCardSetSkill(card._id, card._infoId, false)
                self:updateView()

                rewardPanel:hide()
            end

            btnSub:addLabel(Str(STR.REPLACE))
            lc.addChildToPos(rewardPanel, btnSub, cc.p(lc.w(rewardPanel) / 2 + 10 + lc.w(btnSub) / 2, lc.y(rewardPanel._btnBack)))

            rewardPanel:addTouchEventListener(function() end)
        else
            card._newSkillId = newSkillId
            card._newSkillLevel = newSkillLevel
            card._newSkillCache = 0
            card:sendCardDirty()

            self:updateView()
        end

        lc.addChildToPos(rewardPanel, bg, cc.p(lc.w(rewardPanel) / 2, lc.top(rewardPanel._btnBack) + 110))

        lc.addChildToCenter(lc._runningScene._scene, Particle.create("par_card_rebirth4"), ClientData.ZOrder.effect)
    else
        self._level = self._level + 1

        lc.addChildToCenter(lc._runningScene._scene, Particle.create("par_card_rebirth3"), ClientData.ZOrder.effect)

        self:updateView()

        if GuideManager.getCurStepName() == "evolve card 2" then
            GuideManager.finishStepLater()
        end
    end
end

function _M:onCompose()
    local cardType = Data.getType(self._infoId)
    local result = P._playerCard:composeCard(self._infoId, self._count)
            
    if result == Data.ErrorType.ok then
        local thumbnail = self._leftThumbnail
        local particle = Particle.create("par_card_mix")
        if thumbnail then
            particle:setPosition(self:convertToNodeSpace(thumbnail:convertToWorldSpace(cc.p(lc.w(thumbnail) / 2, lc.h(thumbnail) / 2))))
        else
            particle:setVisible(false)
        end
        self:addChild(particle, ClientData.ZOrder.effect)
    
        V.getActiveIndicator():show()
        self:runAction(cc.Sequence:create(cc.DelayTime:create(particle:getDuration()), cc.CallFunc:create(function() 
            V.getActiveIndicator():hide()    

            ClientData.sendCardCompose(self._infoId, self._count)
                
            particle:stopSystem()             
            particle:removeFromParent()
            
            if cardType == Data.CardType.monster then
                local eventCustom = cc.EventCustom:new(Data.Event.mix_hero)                    
                lc.Dispatcher:dispatchEvent(eventCustom)
            end

            lc.Audio.playAudio(AUDIO.E_CARD_MIX)

            require("RewardCardPanel").create(Str(STR.COMPOSE)..Str(STR.SUCCESS), {{_infoId = self._infoId, _num = self._count}}):show()

            self:updateView()
        end)))
    elseif result == Data.ErrorType.need_more_gold then
        ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
        require("ExchangeResForm").create(Data.ResType.gold):show()
    elseif result == Data.ErrorType.need_more_dust then
        local strs = {[Data.CardType.monster] = STR.SID_PROPS_NAME_7015, [Data.CardType.magic] = STR.SID_PROPS_NAME_7016, [Data.CardType.trap] = STR.SID_PROPS_NAME_7017}
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(strs[cardType])))
    end
end

function _M:onDecompose()
    local cardType = Data.getType(self._infoId)
    if self._count == 0 then
        ToastManager.push(Str(STR.SELECT_COUNT_FIRST))
        return
    elseif self._count > self._max then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), ClientData.getStrByCardType(cardType))) 
        return
    end

    if P._playerCard:getCardCount(self._infoId) - self._count <= 3 then
        return require("Dialog").showDialog(string.format(Str(STR.FEW_AFTER_DECOMPOSE)), function() self:doDecompose() end)
    end

    self:doDecompose()
end

function _M:doDecompose()
    local result = P._playerCard:decomposeCard(self._infoId, self._count)            
    if result == Data.ErrorType.ok then
        local thumbnail = self._leftThumbnail
        local particle = Particle.create("par_card_mix")
        if thumbnail then
            particle:setPosition(self:convertToNodeSpace(thumbnail:convertToWorldSpace(cc.p(lc.w(thumbnail) / 2, lc.h(thumbnail) / 2))))
        else
            particle:setVisible(false)
        end
        self:addChild(particle, ClientData.ZOrder.effect)
    
        V.getActiveIndicator():show()
        self:runAction(cc.Sequence:create(cc.DelayTime:create(particle:getDuration()), cc.CallFunc:create(function() 
            V.getActiveIndicator():hide()    

            ClientData.sendCardDecompose(self._infoId, self._count)
                
            particle:stopSystem()             
            particle:removeFromParent()
            
            if cardType == Data.CardType.monster then
                --local eventCustom = cc.EventCustom:new(Data.Event.mix_hero)                    
                --lc.Dispatcher:dispatchEvent(eventCustom)
            end

            lc.Audio.playAudio(AUDIO.E_CARD_MIX)

            local dustType, dustCount = P._playerCard:getDecomposeDust(self._infoId)
            local RewardPanel = require("RewardPanel")
            RewardPanel.create({{_infoId = dustType,  _count = dustCount * self._count}}, RewardPanel.MODE_SPLIT):show()
            
            self:updateView()
        end)))
    elseif result == Data.ErrorType.need_more_gold then
        ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
        require("ExchangeResForm").create(Data.ResType.gold):show()
    elseif result == Data.ErrorType.need_more_samecard then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), ClientData.getStrByCardType(cardType))) 
    end
end

function _M:onRecovery()
    local cardType = Data.getType(self._infoId)
    if self._count == 0 then
        ToastManager.push(Str(STR.SELECT_COUNT_RECOVERY))
        return
    elseif self._count > self._max then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), ClientData.getStrByCardType(cardType))) 
        return
    end

    if P._playerCard:getCardCount(self._infoId) - self._count <= 3 then
        return require("Dialog").showDialog(string.format(Str(STR.FEW_AFTER_RECOVERY)), function() self:doRecovery() end)
    end

    self:doRecovery()
end

function _M:doRecovery()
    local result = P._playerCard:recoveryCard(self._infoId, self._count, nil, self._card._id)            
    if result == Data.ErrorType.ok then
        local thumbnail = self._leftThumbnail
        local particle = Particle.create("par_card_mix")
        if thumbnail then
            particle:setPosition(self:convertToNodeSpace(thumbnail:convertToWorldSpace(cc.p(lc.w(thumbnail) / 2, lc.h(thumbnail) / 2))))
        else
            particle:setVisible(false)
        end
        self:addChild(particle, ClientData.ZOrder.effect)
    
        V.getActiveIndicator():show()
        self:runAction(cc.Sequence:create(cc.DelayTime:create(particle:getDuration()), cc.CallFunc:create(function() 
            V.getActiveIndicator():hide()    

            ClientData.sendCardRecovery(self._infoId, self._count)
                
            particle:stopSystem()             
            particle:removeFromParent()
            
            lc.Audio.playAudio(AUDIO.E_CARD_MIX)

            local dustType, dustCount = P._playerCard:getRecoveryDust(self._card._id)
            local RewardPanel = require("RewardPanel")
            RewardPanel.create({{_infoId = dustType,  _count = dustCount * self._count}}, RewardPanel.MODE_SPLIT):show()
            
            self:updateView()
        end)))
    elseif result == Data.ErrorType.need_more_samecard then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), ClientData.getStrByCardType(cardType))) 
    end
end

function _M:onMsg(msg)
    local msgType = msg.type

    if msgType == SglMsgType_pb.PB_TYPE_CARD_EVOLUTION then
        

    end

    return false    
end

function _M:onGuide(event)
    if GuideManager.getCurStepName():hasPrefix("evolve card") then
        GuideManager.setOperateLayer(self._consumeMatArea._btn)
    else
        return
    end

    event:stopPropagation()
end

return _M