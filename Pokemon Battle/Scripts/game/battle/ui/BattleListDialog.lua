local _M = class("BattleListDialog", lc.ExtendUIWidget)
BattleListDialog = _M

_M.Mode = {
    list = 1,
    choice = 2,
    single_choice = 3,
    compose = 4,
    merge = 5,
    exchange = 6,
}

_M.ITEM_SIZE = cc.size(350, 464)

function _M.create(...)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(...)
    
    return panel
end

function _M:init(battleUi, cardList, mode, title)
    self._battleUi = battleUi
    self._cardInfos = cardList
    self._mode = mode
    self._ignoreCancel = false

    self._showStatus = false
    if self._mode == _M.Mode.merge then self._showStatus = true
    elseif self._mode == _M.Mode.choice or self._mode == _M.Mode.single_choice then
        local cardStatus = {}
        local statusCount = 0
        for i = 1, #cardList do
            if cardStatus[cardList[i]._status] == nil then 
                cardStatus[cardList[i]._status] = true
                statusCount = statusCount + 1   
            end
        end
        if statusCount > 1 then self._showStatus = true end
    end
    
    -- self
    self:setContentSize(V.SCR_SIZE)
    self:setAnchorPoint(cc.p(0.5, 0.5))

    self:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            self:cancel()
        end
    end)

    -- init ui
    if self._mode == _M.Mode.list then
        local titleBg = lc.createSprite({_name = "img_form_title_bg_1", _crect = V.CRECT_FORM_TITLE_BG1_CRECT, _size = cc.size(560, V.CRECT_FORM_TITLE_BG1_CRECT.height)})
        lc.addChildToPos(self, titleBg, cc.p(V.SCR_CW, V.SCR_CH + 300), 10)

        local light = lc.createSprite({_name = "img_form_title_light_1", _crect = V.CRECT_FORM_TITLE_LIGHT1_CRECT, _size = cc.size(200, V.CRECT_FORM_TITLE_LIGHT1_CRECT.height)})
        lc.addChildToPos(titleBg, light, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))

        local titleLabel = V.createTTF(title or "", V.FontSize.M1)
        titleLabel:setColor(V.COLOR_TEXT_TITLE)
        lc.addChildToPos(titleBg, titleLabel, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))

    elseif self._mode == _M.Mode.choice or self._mode == _M.Mode.single_choice or self._mode == _M.Mode.merge or self._mode == _M.Mode.exchange then
        local title = V.createTTF(title or "", V.FontSize.M1)
        lc.addChildToPos(self, title, cc.p(V.SCR_CW, V.SCR_CH + 300), 10)
        title:setColor(V.COLOR_TEXT_TITLE)

        local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:confirm() end, V.CRECT_BUTTON_S, 150)
        lc.addChildToPos(self, btn, cc.p(V.SCR_CW, 60), 10)
        btn:addLabel(Str(STR.OK))
        btn:setDisabledShader(V.SHADER_DISABLE)
        self._confirmButton = btn

    elseif self._mode == _M.Mode.compose then
        local titleBg = lc.createSprite({_name = "img_title_bg", _size = cc.size(480, 52), _crect = cc.rect(115, 25, 1, 1)})
        lc.addChildToPos(self, titleBg, cc.p(V.SCR_CW, V.SCR_CH + 220), 10)

        local titleLabel = V.createBMFont(V.BMFont.huali_26, title or "")
        lc.addChildToPos(titleBg, titleLabel, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2))

    end

    -- reset
    self._checkFunction = nil
    self._confirmFunction = nil
    self._cancelFunction = nil
    self._selectedList = {}

    self:initCardList()
    self:updateView()
end

function _M:show()
    if self._mode == _M.Mode.merge and self._choiceParam then
        for i = 1, #self._allCards do self._selectedList[i] = true end
        if self:isChoiceSatisfied() then
            self:updateView()
        else
            self._selectedList = {}
        end
    end

    lc.addChildToCenter(self._battleUi._scene, self, BattleScene.ZOrder.top, BattleData.TAG_BATTLE_LIST_DIALOG)
end

function _M:hide()
    self:removeFromParent()
end

function _M:cancel()
    if self._ignoreCancel then return end

    if self._cancelFunction then
        self._cancelFunction(self)
    end

    self:hide()
end

function _M:confirm()
    if self._confirmFunction then
        self._confirmFunction(self)
    end

    self:hide()
end

function _M:confirmCompose(card)
    if self._confirmFunction then
        self._confirmFunction(card._infoId)
    end

    self:hide()
end

function _M:initCardList()
    self._allCards = {}

    if _M.ITEM_SIZE.width * #self._cardInfos < V.SCR_W then
        for i = 1, #self._cardInfos do
            local card = self._cardInfos[i]
            local pos = cc.p(V.SCR_CW + (i - (#self._cardInfos + 1) / 2) * _M.ITEM_SIZE.width, V.SCR_CH)

            local widget = self:createCardItem(card, i)
            lc.addChildToPos(self, widget, pos)
            table.insert(self._allCards, widget)
        end

    else
        local list = lc.List.createH(cc.size(V.SCR_W, _M.ITEM_SIZE.height+100))
        list:setAnchorPoint(cc.p(0.5, 0.5))
        lc.addChildToCenter(self, list)

        for i = 1, #self._cardInfos do
            local card = self._cardInfos[i]

            local widget = self:createCardItem(card, i)
            list:pushBackCustomItem(widget)
            table.insert(self._allCards, widget)
        end
    end
end

function _M:createCardItem(card, index)
    local widget = V.createShaderButton(nil, function(sender) self:onSelectItem(card, index) end)
    widget:setContentSize(_M.ITEM_SIZE)
    widget:setAnchorPoint(cc.p(0.5, 0.5))
    
    local cardSprite = require("CardThumbnail").create(card._infoId, nil, card._owner._skins[card._infoId])
    lc.addChildToCenter(widget, cardSprite)
    cardSprite:setScale(0.7)

    if self._mode == _M.Mode.compose then
        local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:confirmCompose(card) end, V.CRECT_BUTTON_S, 150)
        lc.addChildToPos(cardSprite, btn, cc.p(lc.cw(cardSprite), -50), 10)
        btn:addLabel(Str(STR.OK))
        btn:setDisabledShader(V.SHADER_DISABLE)
        cardSprite._confirmButton = btn
    
    elseif self._showStatus then
        local statusStr = {
            [BattleData.CardStatus.board] = STR.BATTLE_BOARD,
            [BattleData.CardStatus.hand] = STR.BATTLE_HAND,
            [BattleData.CardStatus.grave] = STR.BATTLE_GRAVE,
            [BattleData.CardStatus.pile] = STR.TROOP,
        }
        local label = V.createBMFont(V.BMFont.huali_26, statusStr[card._status] and Str(statusStr[card._status]) or '')
        lc.addChildToPos(widget, label, cc.p(lc.cw(widget), -12))

    end

    return widget
end

function _M:onSelectItem(card, index)
    if self._mode == _M.Mode.list then
        local CardInfoPanel = require("CardInfoPanel")
        local cardInfoPanel = CardInfoPanel.create(card._infoId, 1, CardInfoPanel.OperateType.na, card, statusStrs)
        cardInfoPanel:show()

    elseif self._mode == _M.Mode.choice or self._mode == _M.Mode.merge or self._mode == _M.Mode.exchange then
        if not self:isInSelectedList(index) then
            self:addToSelectedList(index)
        else
            self:removeFromSelectedList(index)
        end
    elseif self._mode == _M.Mode.single_choice then
        if not self:isInSelectedList(index) then
            self._selectedList = {}
            self:addToSelectedList(index)
        else
            self:removeAllFromSelectedList()
        end
    elseif self._mode == _M.Mode.compose then
        local CardInfoPanel = require("CardInfoPanel")
        local cardInfoPanel = CardInfoPanel.create(card._infoId, 1, CardInfoPanel.OperateType.na, card, statusStrs)
        cardInfoPanel:show(BattleScene.ZOrder.top)
    end
end

--------------------------------------------
-- choice function

function _M:setChoiceFunction(checkFunc, confirmFunc, cancelFunc)
    self._checkFunction = checkFunc
    self._confirmFunction = confirmFunc
    self._cancelFunction = cancelFunc
end

function _M:addToSelectedList(index)
    self._selectedList[index] = true 

    self:updateView()
end

function _M:removeFromSelectedList(index)
    self._selectedList[index] = false
    
    self:updateView() 
end

function _M:removeAllFromSelectedList()
    self._selectedList = {}
    
    self:updateView() 
end

function _M:isInSelectedList(index)
    return self._selectedList[index]
end

function _M:getSelectedCount()
    local count = 0
    for i, v in pairs(self._selectedList) do
        if v then
            count = count + 1
        end
    end
    return count
end

function _M:getSelectedCards()
     local cards = {}
     for i, v in pairs(self._selectedList) do
        if v then
            cards[#cards + 1] = self._cardInfos[i]
        end
    end

    return cards
end

function _M:isChoiceSatisfied()
    if self._checkFunction then
        return self._checkFunction(self)
    end

    return false
end

function _M:updateView()
    for i = 1, #self._allCards do
        local widget = self._allCards[i]
        if self:isInSelectedList(i) then
            if not widget._glow then
                local bones = DragonBones.create("xuanzhong")
                bones:gotoAndPlay("effect1")
                bones:setScale(2.3)
                lc.addChildToCenter(widget, bones, -1)
                widget._glow = bones
            end
        else
            if widget._glow then
                widget._glow:removeFromParent()
                widget._glow = nil
            end
        end
    end

    if self._confirmButton then
        local isSatisfied = self:isChoiceSatisfied()
        self._confirmButton:setEnabled(isSatisfied)
    end
end