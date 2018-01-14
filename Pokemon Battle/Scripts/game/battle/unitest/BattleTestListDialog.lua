local _M = class("BattleTestListDialog", lc.ExtendUIWidget)
BattleTestListDialog = _M

_M.Mode = {
    list = 1,
    choice = 2,
    single_choice = 3,
}

_M.SwapTarget = {
    player = 1,
    opponent = 2,
}

_M.ITEM_SIZE = cc.size(210, 360)

-- battle test: make it single choice
local lastSelected = nil

function _M.create(...)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(...)
    
    return panel
end

function _M:init(battleUi, cardList, mode, title, touchTarget)
    self._battleUi = battleUi
    self._cardInfos = cardList
    self._mode = mode
    -- battle test: save title
    self._title = title
    self._touchTarget = touchTarget
    
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
        lc.addChildToPos(self, titleBg, cc.p(V.SCR_CW, V.SCR_CH + 220), 10)

        local light = lc.createSprite({_name = "img_form_title_light_1", _crect = V.CRECT_FORM_TITLE_LIGHT1_CRECT, _size = cc.size(200, V.CRECT_FORM_TITLE_LIGHT1_CRECT.height)})
        lc.addChildToPos(titleBg, light, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))

        local titleLabel = V.createTTF(title or "", V.FontSize.M1)
        titleLabel:setColor(V.COLOR_TEXT_TITLE)
        lc.addChildToPos(titleBg, titleLabel, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))

    elseif self._mode == _M.Mode.choice then
        local titleLabel = V.createTTF(title or "", V.FontSize.M1)
        lc.addChildToPos(self, titleLabel, cc.p(V.SCR_CW, V.SCR_CH + 220), 10)
        titleLabel:setColor(V.COLOR_TEXT_TITLE)

        local btn = V.createScale9ShaderButton("img_btn_1", function(sender) self:confirm() end, V.CRECT_BUTTON, 150)
        lc.addChildToPos(self, btn, cc.p(V.SCR_CW, 100), 10)
        btn:addLabel(Str(STR.OK))
        btn:setDisabledShader(V.SHADER_DISABLE)
        self._confirmButton = btn

    -- battle test: add "single choice"
    elseif self._mode == _M.Mode.single_choice then
        local titleBg = lc.createSprite({_name = "img_form_title_bg_1", _crect = V.CRECT_FORM_TITLE_BG1_CRECT, _size = cc.size(560, V.CRECT_FORM_TITLE_BG1_CRECT.height)})
        lc.addChildToPos(self, titleBg, cc.p(V.SCR_CW, V.SCR_CH + 220), 10)

        local light = lc.createSprite({_name = "img_form_title_light_1", _crect = V.CRECT_FORM_TITLE_LIGHT1_CRECT, _size = cc.size(200, V.CRECT_FORM_TITLE_LIGHT1_CRECT.height)})
        lc.addChildToPos(titleBg, light, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))

        local titleLabel = V.createTTF(title or "", V.FontSize.M1)
        titleLabel:setColor(V.COLOR_TEXT_TITLE)
        lc.addChildToPos(titleBg, titleLabel, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))

        local addLabel = function(btn, labelStr, color, position)
            local label = V.createBMFont(V.BMFont.huali_26, labelStr)
            if color then label:setColor(color) end
            if position then
                lc.addChildToPos(btn, label, position)
            else
                lc.addChildToPos(btn, label, cc.p(lc.w(btn) / 2, lc.h(btn) / 2 + 1))
            end
            btn._label = label

            if btn._icon then
                lc.offset(label, 16)
                btn._icon:setPositionX(30)
            end
        end

        -- todo: add left, right btn
        local btnDelete = V.createScale9ShaderButton("img_btn_squarel_s_1", function(sender) self:delete() end, V.CRECT_BUTTON, 120)
        lc.addChildToPos(self, btnDelete, cc.p(V.SCR_CW, 160), 10)
        addLabel(btnDelete, Str(STR.DELETE), nil, cc.p(lc.w(btnDelete) / 2, lc.h(btnDelete) / 2 - 13))
        self._deleteButton = btnDelete

        local btnLeft = V.createShaderButton("img_arrow_1", function(sender) self:move("left") end)
        lc.addChildToPos(self, btnLeft, cc.p(V.SCR_CW - 100, 145), 10)
        self._leftButton = btnLeft

        local btnRight = V.createShaderButton("img_arrow_1", function(sender) self:move("right") end)
        btnRight:setFlippedX(true)
        lc.addChildToPos(self, btnRight, cc.p(V.SCR_CW + 100, 145), 10)
        self._leftButton = btnLeft

    end

    -- reset
    self._checkFunction = nil
    self._confirmFunction = nil
    self._cancelFunction = nil
    self._selectedList = {}
    if lastSelected ~= nil then
        local card = self._cardInfos[lastSelected]
        self._selectedList[lastSelected] = card
    end
    
    self:initCardList()
    self:updateView()
end

function _M:show()
    lc.addChildToCenter(self._battleUi._scene, self, BattleScene.ZOrder.top)
end

function _M:hide()
    self._selectedList = {}
    lastSelected = nil
    self:removeFromParent()
end

function _M:cancel()
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

function _M:delete()
    if lastSelected then
        
        local card = self._cardInfos[lastSelected]

        if self._touchTarget == self._battleUi.TouchTarget.player_grave then
            if card then
                local cardSprite = self._battleUi._playerUi:getCardSprite(card)
                self._battleUi._player:removeCardFromGrave(card)
                self._battleUi._player:removeCardFromCards(card)
                self._battleUi._playerUi:removeCardFromGrave(card)
                self._battleUi._playerUi:removeCardFromSprites(cardSprite)
                cardSprite:removeFromParent()

            end

        elseif self._touchTarget == self._battleUi.TouchTarget.player_hand then
            if card then
                local cardSprite = self._battleUi._playerUi:getCardSprite(card)
                self._battleUi._player:removeCardFromHand(card)
                self._battleUi._player:removeCardFromCards(card)
                self._battleUi._playerUi:removeCardFromHand(card)
                self._battleUi._playerUi:removeCardFromSprites(cardSprite)
                cardSprite:removeFromParent()
                self._battleUi._playerUi:replaceHandCards(0)

            end

        elseif self._touchTarget == self._battleUi.TouchTarget.opponent_grave then
            if card then
                local cardSprite = self._battleUi._opponentUi:getCardSprite(card)
                self._battleUi._opponent:removeCardFromGrave(card)
                self._battleUi._opponent:removeCardFromCards(card)
                self._battleUi._opponentUi:removeCardFromGrave(card)
                self._battleUi._opponentUi:removeCardFromSprites(cardSprite)
                cardSprite:removeFromParent()
            end

        elseif self._touchTarget == self._battleUi.TouchTarget.opponent_hand then
            if card then
                local cardSprite = self._battleUi._opponentUi:getCardSprite(card)
                self._battleUi._opponent:removeCardFromHand(card)
                self._battleUi._opponent:removeCardFromCards(card)
                self._battleUi._opponentUi:removeCardFromHand(card)
                self._battleUi._opponentUi:removeCardFromSprites(cardSprite)
                cardSprite:removeFromParent()
                self._battleUi._opponentUi:replaceHandCards(0)

            end
        elseif self._touchTarget == self._battleUi.TouchTarget.player_pile then
            if card then
                local cardSprite = self._battleUi._playerUi:getCardSprite(card)
                self._battleUi._player:removeCardFromPile(card)
                self._battleUi._player:removeCardFromCards(card)
                -- battle test: no cardspriate stored in table, do nothing
--                self._battleUi._playerUi:removeCardFromPile(card)
--                self._battleUi._playerUi:removeCardFromSprites(cardSprite)
--                cardSprite:removeFromParent()
                self._battleUi:updatePile(self._battleUi._playerUi)
            end
        elseif self._touchTarget == self._battleUi.TouchTarget.opponent_pile  then
            if card then
                local cardSprite = self._battleUi._opponentUi:getCardSprite(card)
                self._battleUi._opponent:removeCardFromPile(card)
                self._battleUi._opponent:removeCardFromCards(card)
                -- battle test: no cardspriate stored in table, do nothing
--                self._battleUi._opponentUi:removeCardFromPile(card)
--                self._battleUi._opponentUi:removeCardFromSprites(cardSprite)
--                cardSprite:removeFromParent()
                self._battleUi:updatePile(self._battleUi._opponentUi)
            end
        end
        
--        table.remove(self._cardInfos, lastSelected)
        lastSelected = nil
        self:removeAllChildren()
        self:init(self._battleUi, self._cardInfos, self._mode, self._title, self._touchTarget)
    else
        ToastManager.push(Str(STR.SELECT_CARD_FIRST), 1.0)
    end
end

function _M:move(flag)
    if lastSelected then

        local card1 = self._cardInfos[lastSelected]
        local moveTo
        if flag == "left" then
            if lastSelected == 1 then
                return
            else
                moveTo = lastSelected - 1
            end
        elseif flag == "right" then
            if lastSelected == #self._cardInfos then
                return
            else
                moveTo = lastSelected + 1
            end
        end
        local card2 = self._cardInfos[moveTo]

        -- battle test: move player grave area card
        if self._touchTarget == self._battleUi.TouchTarget.player_grave then
            if card1 and card2 then
                self:swap(card1, card2)
                self._battleUi._playerUi:swapCardsInGrave(card1, card2)
            end

        -- battle test: move player hand card
        elseif self._touchTarget == self._battleUi.TouchTarget.player_hand then
            if card1 and card2 then
                self:swap(card1, card2)
                self._battleUi._playerUi:swapCardsInHand(card1, card2)
            end

        -- battle test: move opponent grave area card
        elseif self._touchTarget == self._battleUi.TouchTarget.opponent_grave then
            if card1 and card2 then
                self:swap(card1, card2)
                self._battleUi._opponentUi:swapCardsInGrave(card1, card2)
            end

        -- battle test: move opponent hand card
        elseif self._touchTarget == self._battleUi.TouchTarget.opponent_hand then
            if card1 and card2 then
                self:swap(card1, card2)
                self._battleUi._opponentUi:swapCardsInHand(card1, card2)
            end

        elseif self._touchTarget == self._battleUi.TouchTarget.player_pile then
            if card1 and card2 then
                self:swap(card1, card2)
                self._battleUi._playerUi:swapCardsInPile(card1, card2)
            end

        elseif self._touchTarget == self._battleUi.TouchTarget.opponent_pile then
            if card1 and card2 then
                self:swap(card1, card2)
                self._battleUi._opponentUi:swapCardsInPile(card1, card2)
            end

        end
        
        self:removeAllChildren()
        lastSelected = moveTo
        self:init(self._battleUi, self._cardInfos, self._mode, self._title, self._touchTarget)
    else
        ToastManager.push(Str(STR.SELECT_CARD_FIRST), 1.0)
    end
end

-- swap items in self._cardInfos
function _M:swap(card1, card2)
    lc.log("swap start -------------------------------")
    for i = 1, #self._cardInfos do
        lc.log(i .. " -- " .. self._cardInfos[1]._id)
    end 

    for i = 1, #self._cardInfos do
        if card1 == self._cardInfos[i] then
            self._cardInfos[i] = card2
        elseif card2 == self._cardInfos[i] then
            self._cardInfos[i] = card1
        end
    end

    
    for i = 1, #self._cardInfos do
        lc.log(i .. " -- " .. self._cardInfos[1]._id)
    end 
    
    lc.log("swap start -------------------------------")
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
        local list = lc.List.createH(cc.size(V.SCR_W, _M.ITEM_SIZE.height))
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
    
    local cardSprite = require("CardThumbnail").create(card._infoId)
    lc.addChildToCenter(widget, cardSprite)
    cardSprite:setScale(0.7)

    return widget
end

function _M:onSelectItem(card, index)
    if self._mode == _M.Mode.list then
        local CardInfoPanel = require("CardInfoPanel")
        local cardInfoPanel = CardInfoPanel.create(card._infoId, 1, CardInfoPanel.OperateType.na, card, statusStrs)
        cardInfoPanel:show()

    elseif self._mode == _M.Mode.choice then
        if not self:isInSelectedList(index) then
            self:addToSelectedList(index)
        else
            self:removeFromSelectedList(index)
        end
    elseif self._mode == _M.Mode.single_choice then
        if not self:isInSelectedList(index) then
            if lastSelected ~= nil then
                self:removeFromSelectedList(lastSelected)
            end
            self:addToSelectedList(index)
            lastSelected = index
        else
            self:removeFromSelectedList(index)
            lastSelected = nil
        end
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
                bones:setScale(1.4)
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