local _M = class("CardInfoPanel", require("BasePanel"))
local CardOperatePanel = require("CardOperatePanel")

local BAR_CONTENT_WIDTH = 1000

local RIGHT_AREA_W = 490

local MARGIN_TOP = 10
local MARGIN_BOTTOM = 10
local MARGIN_CENTER = 8

local DECORATED_LABEL_GAP = 26
local CONTENT_LEFT_MARGIN = 36
local CONTENT_RIGHT_MARGIN = 36

local ICO_OPACITY_VALID = 255
local ICO_OPACITY_INVALID = 128

local MAX_PATH_DESC_WIDTH = 350

local PANEL_SCALE = 0.88

local NAME_COLOR_VALID = V.COLOR_TEXT_GREEN_DARK
local NAME_COLOR_INVALID = V.COLOR_TEXT_GRAY
local DESC_COLOR_VALID = V.COLOR_TEXT_LIGHT
local DESC_COLOR_INVALID = NAME_COLOR_INVALID

_M.OperateType = 
{
    na              = 1,
    troop           = 2,
    view            = 3,
    operate         = 4,
    recovery        = 5,
}

function _M.create(infoId, level, operateType, card, statusStrs)

    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    infoId = P._playerCard:convert2CardId(infoId)
    local cardInfo, cardType = Data.getInfo(infoId)
    --print("isMonser:"..cardType == Data.CardType.monster)
    if operateType == _M.OperateType.operate and cardInfo and cardInfo._packageId[1] == Data.UNION_SHOP_PACKAGE_ID then
        operateType = _M.OperateType.recovery
        if not card then
            for _, info in ipairs(Data._unionProductsExInfo) do
                if info._cardId == infoId then
                    card = info
                    break
                end
            end
        end
    end
    if operateType then _M._operateType = operateType end
    if _M._operateType == nil then _M._operateType = _M.OperateType.na end
    panel:init(infoId, level, card, statusStrs)
    return panel
end

function _M:init(infoId, level, card, statusStrs)
    _M.super.init(self, false)
    
    self._panelName = "CardInfoPanel"

    self._infoId = infoId
    self._level = level or P._playerCard._levels[infoId] or 1
    self._card = card
    self._statusStrs = statusStrs
    self._hasStatus = self._statusStrs ~= nil and (#self._statusStrs[1] + #self._statusStrs[2] > 0)
    
    self:addChild(self:createTopArea())
    self:addChild(self:createCard())
    self:addChild(self:createRightArea())
    --self:addChild(self:createBottomArea())

    self._topArea:setVisible(false)
end

function _M:setCardList(cards, index, title)

    self._topArea:setVisible(true)
    self._topArea._posLabel:setString(index..'/'..#cards)

    self._cardList = cards
    self._cardListIndex = index

    self:checkCardList()
end

function _M:setCardCount(count)
    self._count = count
    if self._countLabel == nil then
        local label = V.createBMFont(V.BMFont.huali_26, Str(STR.AMOUNT)..': '..count)
        label:setAnchorPoint(0, 0.5)
        lc.addChildToPos(self, label, cc.p(56, lc.h(self) - lc.h(label) / 2 - 54))
        self._countLabel = label
    else
        self._countLabel:setString(Str(STR.AMOUNT)..': '..count)
    end
end

function _M:checkCardList()
    if self._cardList == nil then return end

    local cards, index = self._cardList, self._cardListIndex
    local arrowW, arrowH = 60, 100

    local showCardInfoPanel = function(isNext)
        self._cardListIndex = self._cardListIndex + (isNext and 1 or -1)

        local anotherCard = cards[self._cardListIndex]
        local infoId, num
        if type(anotherCard) == 'number' then
            infoId = anotherCard
        else
            infoId = anotherCard._infoId
            num = anotherCard._num
        end
        local panel = _M.create(infoId, nil)
        panel:setCardList(cards, self._cardListIndex, Str(STR.CARD_LIST))
        if num ~= nil then panel:setCardCount(num) end
        panel:show()

        self:hide()
    end

    local setArrowEnabled = function(arrow, isEnabled)
        arrow:setEnabled(isEnabled)
        arrow:setSwallowTouches(true)

        arrow._arrow:setVisible(isEnabled)
    end

    local arrowL = self._arrowLeft
    if arrowL == nil then
        arrowL = V.createArrowButton(true, cc.size(arrowW, arrowH), function() showCardInfoPanel(false) end)
        lc.addChildToPos(self, arrowL, cc.p(arrowW / 2 + 10, V.SCR_CH))
        self._arrowLeft = arrowL
    end

    local arrowR = self._arrowRight
    if arrowR == nil then
        arrowR = V.createArrowButton(false, cc.size(arrowW, arrowH), function() showCardInfoPanel(true) end)
        lc.addChildToPos(self, arrowR, cc.p(lc.w(self) - arrowW / 2 - 10, V.SCR_CH))
        self._arrowRight = arrowR
    end

    setArrowEnabled(arrowL, cards[index - 1] ~= nil)
    setArrowEnabled(arrowR, cards[index + 1] ~= nil)
end

function _M:createCurrentOwn()
    local label = V.createBMFont(V.BMFont.huali_26, '')
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(self._bottomArea, label, cc.p(6, lc.h(self._bottomArea) - lc.h(label) / 2))
    self._currentOwnLabel = label

    self:updateCurrentOwn()
end

function _M:createTopArea()
--[[
    local titleStr = Str(STR.CARD_LIST)
    local backFunc = function()
        self:hide()

        if GuideManager.getCurStepName() == "leave card info" then
            GuideManager.finishStep()
        end
    end
]]
    local area = ccui.Widget:create()
    area:setPosition(V.SCR_CW, 20)
    area:setContentSize(V.SCR_W, 20)
    local posLabel = V.createBMFont(V.BMFont.huali_32, '1/1')
    lc.addChildToPos(area, posLabel, cc.p(lc.cw(area), lc.ch(area)), 3)
    area._posLabel = posLabel

    self._topArea = area
    return area
end

function _M:createBottomArea()
    local area = ccui.Layout:create()
    area:setContentSize(lc.w(self._thumbnail), V.PANEL_BOTTOM_HEIGHT)
    area:setAnchorPoint(0.5, 0.5)
    area:setPosition(lc.x(self._thumbnail), lc.bottom(self._thumbnail) - 20 - lc.h(area) / 2)
    self._bottomArea = area

    if _M._operateType >= _M.OperateType.view then
        --self:createCurrentOwn()
    end

    if (_M._operateType == _M.OperateType.operate or _M._operateType == _M.OperateType.recovery) and P._guideID >= 500 then
        local info = Data.getInfo(self._infoId)
        if self._level < Data.CARD_MAX_LEVEL then
            if _M._operateType == _M.OperateType.operate then
                local btnUpgrade = V.createScale9ShaderButton("img_btn_2", function(sender)
                    CardOperatePanel.create(self._infoId, CardOperatePanel.OperateMode.decompose):show()
                end, V.CRECT_BUTTON, 120)
                btnUpgrade:addLabel(Str(STR.DECOMPOSE))
                lc.addChildToPos(area, btnUpgrade, cc.p(lc.w(btnUpgrade) / 2, lc.h(area) / 2 - 44))

                local btnDecomposeAll = V.createScale9ShaderButton("img_btn_2", function(sender)
                    self:onDecomposeAll()
                end, V.CRECT_BUTTON, 120)
                btnDecomposeAll:addLabel(Str(STR.DECOMPOSE_ALL))
                lc.addChildToPos(area, btnDecomposeAll, cc.p(lc.right(btnUpgrade) + 20 + lc.w(btnDecomposeAll) / 2, lc.y(btnUpgrade)))
            elseif _M._operateType == _M.OperateType.recovery then
                local btnUpgrade = V.createScale9ShaderButton("img_btn_2", function(sender)
                    CardOperatePanel.create(self._infoId, CardOperatePanel.OperateMode.recovery, self._card):show()
                end, V.CRECT_BUTTON, 120)
                btnUpgrade:addLabel(Str(STR.RECOVERY))
                lc.addChildToPos(area, btnUpgrade, cc.p(lc.cw(area), lc.ch(area) - 44))
            end
        end
    end

    return area
end

function _M:createCard()
    local visibleSize = lc.Director:getVisibleSize()

    local skinId = nil 
    if _M._operateType ~= _M.OperateType.na then
        skinId = P._playerCard:getSkinId(self._infoId)
    end

    local thumbnail = require("CardThumbnail").create(self._infoId, nil, skinId)
    thumbnail:setTouchEnabled(false)
    thumbnail:setPosition(visibleSize.width / 2 - lc.cw(thumbnail), V.SCR_CH)
    
    self._thumbnail = thumbnail

    thumbnail:setScale(PANEL_SCALE)

    return thumbnail
end

function _M:createRightArea()
    local areaH = 678
    local area = V.createFrameBox(cc.size(RIGHT_AREA_W, areaH))
    area:setPosition(lc.right(self._thumbnail) + MARGIN_CENTER + RIGHT_AREA_W / 2, lc.y(self._thumbnail))
    
    local bgs = lc.createSprite({_name = "img_troop_bg_2", _size = cc.size(lc.w(area) - 50, lc.h(area) - 103), _crect = cc.rect(16, 14, 9, 6)})     
    bgs:setAnchorPoint(0.5, 0)
    lc.addChildToPos(area, bgs, cc.p(lc.cw(area), lc.bottom(area) - 8))

    local size = cc.size(lc.w(area) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(area) - 144)
    area._lists = {}

    local titles = {}
    if self._hasStatus then 
        titles[#titles + 1] = Str(STR.STATUS) 
        
        local list = lc.List.createV(size, 16, 20)
        list:setAnchorPoint(0.5, 0.5)
        list:pushBackCustomItem(self:createStatus(size))
        lc.addChildToPos(area, list, cc.p(lc.w(area) / 2, lc.h(area) / 2))    
        area._lists[#area._lists + 1] = list    
    end

    local info, cardType = Data.getInfo(self._infoId)
    if info._skillId[1] ~= 0 then
        titles[#titles + 1] = Str(STR.SKILL)
        local list = lc.List.createV(size, 16, 20)
        list:setAnchorPoint(0.5, 0.5)
        lc.addChildToPos(area, list, cc.p(lc.w(area) / 2, lc.h(area) / 2))
        for i = 1, #info._skillId do
            local item = ccui.Widget:create()
            local itemSize = cc.size(lc.w(list) - 34, lc.h(list) / 3 - 30)
            item:setContentSize(itemSize)
            local itemBg = lc.createSprite({_name = 'card_info_widget', _crect = cc.rect(26, 49, 5, 5), _size = itemSize})
            lc.addChildToCenter(item, itemBg, -1)

            local skill = V.createMonsterSkill(info._skillId[i], itemSize, false, true)
            skill._name:setColor(V.COLOR_TEXT_ORANGE)
            skill._name:enableOutline(lc.Color4B.black, 1)
            skill._desc:setColor(V.COLOR_TEXT_WHITE)
            lc.offset(skill._desc, 0, -10)
            --[[lc.offset(skill._name, 0, 10)
            lc.offset(skill._damage, 0, 10)
            lc.offset(skill._icon, 0, 10)]]
            --print("!!!!!!!!!!!!!!!!!!!!!!!!power label is:"..skill._powerLabel)
            skill._name:setScale(0.9)
            skill._damage:setScale(0.9)
            skill._icon:setScale(0.9)
            lc.addChildToCenter(item, skill)
            list:pushBackCustomItem(item)
        end  
        area._lists[#area._lists + 1] = list  
    end

    titles[#titles + 1] = Str(STR.INFO)
    local list = require('CardInfoWidget').create(self._infoId, self._level, size, false, self._card)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(area, list, cc.p(lc.w(area) / 2, lc.h(area) / 2))  
    area._lists[#area._lists + 1] = list  
    --[[
    if not GuideManager.isGuideInCity() and not V.isInBattleScene() then
        titles[#titles + 1] = Str(STR.PACKAGE)
        local list = lc.List.createV(size, 16, 20)
        list:setAnchorPoint(0.5, 0.5)
        local infos = Data.getPackages(self._infoId)
        if #infos > 0 then
            list:pushBackCustomItem(self:createPackage(size, infos))
        end
        lc.addChildToPos(area, list, cc.p(lc.w(area) / 2, lc.h(area) / 2))  
        area._lists[#area._lists + 1] = list 
    end
    ]]
    V.addHorizontalTabButtons2(self, titles, lc.top(area) - 50 + 22, lc.left(area) - 70 - (self._hasStatus and 120 or 0), 800)
    self._detailArea = area

    area:setScale(PANEL_SCALE)

    return area
end

function _M:showTab(tag)
    for i = 1, #self._detailArea._lists do
        self._detailArea._lists[i]:setVisible(i == tag)
    end
    
    self._tabArea:showTab(tag)
end

--[[
function _M:createItemBegin(str)
    local marginTop = 12
    local w = lc.w(self._detailArea._list)

    local item = ccui.Widget:create()
    item:setContentSize(w, 0)
    item.createText = function(self, str, color, width)
        local text = V.createTTF(str)
        if color then text:setColor(color) end
        if width then text:setDimensions(width, 0) end
        return text
    end

    if str then
        local title = V.addDecoratedLabel(item, str, cc.p(w / 2, 0), DECORATED_LABEL_GAP)
        item._title = title
        marginTop = marginTop + lc.h(title)
    end

    return item, self._infoId, w, marginTop
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
]]

function _M:createPackage(size, infos)
    local item = ccui.Widget:create()
    item:setContentSize(size.width, #infos * 80 + 40)

    local marginTop = lc.h(item) - 40
    for i = 1, #infos do
        marginTop = self:addPackageLine(infos[i], item, marginTop)    
    end

    return item
end

function _M:addPackageLine(info, item, marginTop)
    local label = V.createTTF(Str(info._nameSid), V.FontSize.M2, V.COLOR_TEXT_ORANGE)
    lc.addChildToPos(item, label, cc.p(lc.w(label) / 2 + 10, marginTop))

    local button = V.createScale9ShaderButton("img_btn_1_s", function(sender) 
        self:hide()

        if lc._runningScene._sceneId ~= ClientData.SceneId.tavern then
            V.popScene(true)
            lc.pushScene(require("TavernScene").create(info._value))
        end
    end, V.CRECT_BUTTON_S, 100)
    button:addLabel(Str(STR.GO))
    lc.addChildToPos(item, button, cc.p(lc.w(item) - lc.w(button) / 2 - 10, marginTop))

    if GuideManager.isGuideInCity() or V.isInBattleScene() then
        button:setDisabledShader(V.SHADER_DISABLE)
        button:setEnabled(false)
        button:setSwallowTouches(false)
    end

    marginTop = marginTop - 80
    return marginTop
end

function _M:addPathDesc(item, str, marginTop)
    local btnSize = lc.frameSize("img_btn_1_s")

    local desc = ccui.RichTextEx:create()
    desc:setMaxWidth(MAX_PATH_DESC_WIDTH)
    local pos1 = string.find(str, "|")
    if pos1 then
        local pos2 = string.find(str, "|", pos1 + 1)
        if pos2 then
            desc:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, string.sub(str, 0, pos1 - 1), V.TTF_FONT, V.FontSize.S2))
            desc:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_GREEN_DARK, 255, string.sub(str, pos1 + 1, pos2 - 1), V.TTF_FONT, V.FontSize.S2))
            desc:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, string.sub(str, pos2 + 1), V.TTF_FONT, V.FontSize.S2))
        end
    else
        desc:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, str, V.TTF_FONT, V.FontSize.S2))
    end
    desc:setCascadeOpacityEnabled(true)
    desc:formatText()

    lc.addChildToPos(item, desc, cc.p(lc.w(desc) / 2 + 10, marginTop + btnSize.height / 2 - lc.h(desc) / 2))
end

function _M:createStatus(size)

    local h = 10
    local colors = {cc.c3b(26, 254, 7), cc.c3b(250, 10, 10)}
    local labels = {}
    for i = 1, #self._statusStrs do
        for j = 1, #self._statusStrs[i] do
            local label = V.createTTF(self._statusStrs[i][j], V.FontSize.S1, colors[i], cc.size(size.width - 32, 0), cc.TEXT_ALIGNMENT_LEFT, cc.VERTICAL_TEXT_ALIGNMENT_TOP)
            label:setAnchorPoint(0, 1)
            labels[#labels + 1] = label
            h = lc.h(label) + 10
        end
    end

    local item = ccui.Widget:create()
    item:setContentSize(size.width - 32, h)

    local y = h - 10
    for i = 1, #labels do
        lc.addChildToPos(item, labels[i], cc.p(0, y))
        y = y - lc.h(labels[i]) - 10
    end

    return item
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    -- The priority should be higher
    listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)
    table.insert(self._listeners, listener)

    local listener = lc.addEventListener(Data.Event.card_dirty, function(event) 
        if event._infoId == self._infoId then 
            self:updateCurrentOwn() 
            if _M._operateType ~= _M.OperateType.na then
                self._thumbnail:updateComponent(self._infoId, P._playerCard:getSkinId(self._infoId))
            end
        end
    end)
    table.insert(self._listeners, listener)
    
    local curStep = GuideManager.getCurStepName()
    if curStep == "show card info" then
        GuideManager.finishStepLater()
    elseif curStep == "leave card reward" or curStep == "leave claim" then
        GuideManager.pauseGuide()
    end

    --self:updateView()

    self:showTab(self._tabArea._focusTabIndex or 1)
end

function _M:onExit()
    _M.super.onExit(self)
    
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    GuideManager.resumeGuide()
end

function _M:updateView()
    self:showTab(self._tabArea._focusTabIndex or 1)
end

function _M:updateCurrentOwn()
    if self._currentOwnLabel then
        self._currentOwnLabel:setString(Str(STR.CURRENT_OWN)..': '..P._playerCard:getCardCount(self._infoId))
    end
end

function _M:onDecomposeAll()
    local sr, r, n = P._playerCard:getCanDecomposeCount()
    if sr + r + n <= 0 then
        ToastManager.push(Str(STR.DECOMPOSE_ALL_INVALID))
        return
    end
    return require("Dialog").showDialog(string.format(Str(STR.DECOMPOSE_ALL_CONFIRM, true), sr, r, n), function() self:doDecomposeAll() end)
end

function _M:doDecomposeAll()
    local dust = P._playerCard:decomposeAll()
    if dust > 0 then
        ClientData.sendCardDecomposeBatch()
    end
    ToastManager.push(string.format(Str(STR.DECOMPOSE_SUCCESS), dust, Str(Data._resInfo[Data.ResType.gold]._nameSid)))
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "show card attr" then
        GuideManager.setOperateLayer(self._detailArea._tabs[2])
    elseif curStep == "show card path" then
        GuideManager.setOperateLayer(self._detailArea._tabs[3])
    elseif curStep == "leave card info" then
        GuideManager.setOperateLayer(self._topArea._btnBack, nil, self._detailArea._tabs)
    elseif curStep == "equip hero" then
        GuideManager.setOperateLayer(self._bottomArea._btnEquip)
    else
        return
    end
    
    event:stopPropagation()    
end

return _M