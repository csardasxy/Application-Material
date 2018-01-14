local _M = class("ComposeForm", BaseForm)
require("BattleListDialog")
local ConfirmCompose = require("PromptForm").ConfirmCompose
local CardSprite = require("CardSprite")
local FORM_SIZE = cc.size(900, 700)

local SLOT_POS =
{
        cc.p(-250,150),
        cc.p(-250,0),
        cc.p(-250,-150),
        cc.p(250,150),
        cc.p(250,0),
        cc.p(250,-150),
}

function _M.create(rarePackageCards, packgeId)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(rarePackageCards, packgeId)
    return panel
end

function _M:init(rarePackageCards, packgeId)
    self._rarePackageCards = rarePackageCards
    self._packgeId = packgeId
    self._selectCards = {}
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local form = self._form
    self:createTransferArea()
end

function _M:onCleanup()
    _M.super.onCleanup(self)
end

function _M:createTransferArea()
    local area = lc.createNode(self._frame:getContentSize())
    area:setVisible(true)
    lc.addChildToCenter(self._frame, area)
    self._transferArea = area

    local cx = lc.w(area) / 2
    local y = 440

    local circle1 = lc.createSpriteWithMask("res/jpg/add_card_bg.jpg")
    local addBtn = V.createShaderButton(nil, function(sender) self:selectTargetCard() end)
    local addImage = lc.createSprite("img_compose_add")
    addBtn:setContentSize(cc.size(240,400))
    lc.addChildToCenter(addBtn, addImage)
    lc.addChildToCenter(circle1, addBtn)
    local targetCardNode = lc.createNode()
    lc.addChildToCenter(addBtn, targetCardNode)
    addBtn.targetCardNode = targetCardNode
    self._addTargetBtn = addBtn

    local circle = lc.createNode(circle1:getContentSize())    
    lc.addChildToPos(area, circle, cc.p(cx, y), 1)
    self._circle = circle

--    local light = lc.createSprite("img_transfer_bg_light")
--    light:setScale(28)
--    lc.addChildToCenter(circle, light, -1)

--    circle1:runAction(lc.rep(lc.rotateBy(4, 360)))
    lc.addChildToCenter(circle, circle1, -1)

--    local circle2 = lc.createSpriteWithMask("transfer_bg_2")    
--    circle2:runAction(lc.rep(lc.rotateBy(4, -360)))
--    lc.addChildToCenter(circle, circle2)

    self._slots = {}
    self._slotBtns = {}
    for i = 1, #SLOT_POS do
        local slotBg = lc.createSpriteWithMask("img_slot")
        lc.addChildToPos(circle, slotBg, cc.p( SLOT_POS[i].x+lc.cw(circle), SLOT_POS[i].y+lc.ch(circle)))
        local slotBtn = V.createShaderButton(nil, function(sender) self:selectCard(i) end)
        slotBtn:setContentSize(cc.size(60,60))
        local addImage = lc.createSprite("img_compose_add", cc.p(lc.cw(slotBtn), lc.ch(slotBtn)))
        addImage:setScale(lc.w(slotBtn)/lc.w(addImage) , lc.h(slotBtn)/lc.h(addImage))
        slotBtn:addChild(addImage)
        slotBtn:setVisible(false)
        lc.addChildToCenter(slotBg, slotBtn)
        local slotNode = lc.createNode()
        lc.addChildToCenter(slotBg, slotNode)
        table.insert(self._slots, slotNode)
        table.insert(self._slotBtns, slotBtn)
    end

--    self._centerSlot = V.createShaderButton("img_transfer_slot_big", function(sender) end)
--    lc.addChildToCenter(circle, self._centerSlot)

--    local btnAutoAdd = V.createScale9ShaderButton("img_btn_2", function(sender) self:transferAutoAdd() end, V.CRECT_BUTTON, 160)
--    btnAutoAdd:addLabel(Str(STR.AUTO_ADD))
--    lc.addChildToPos(circle, btnAutoAdd, cc.p(lc.w(circle) / 2, 10))

    local btnCompose = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onConfirmCompose() end, cc.rect(0,0,0,0) , 200 , 80)
    btnCompose:setDisabledShader(V.SHADER_DISABLE)
    lc.addChildToPos(area, btnCompose, cc.p(lc.cw(area) , 80))
    
    local label = V.createBMFont(V.BMFont.huali_32, Str(STR.MERGE_RESULT))
    label:setColor(lc.Color3B.white)
    label:setAdditionalKerning(10)
    lc.addChildToPos(btnCompose, label, cc.p(lc.w(btnCompose) / 2, 40))

--    local goldArea = V.createResIconLabel(130, "img_icon_res1_s")
--    local gold = 10000
--    goldArea._label:setString(string.format("%d", gold))
--    goldArea.updateColor = function(self)
--        self._label:setColor(P._gold < gold and lc.Color3B.red or lc.Color3B.white)
--    end
--    goldArea:updateColor()
--    lc.addChildToPos(btnCompose, goldArea, cc.p(lc.w(btnCompose) / 2 + 12, 62))
    self._composeBtn = btnCompose
    local bgWidth = 400
    local tipBg = lc.createSprite("img_com_bg_38")
    tipBg:setScale(bgWidth/lc.w(tipBg),80/lc.h(tipBg))
    lc.addChildToPos(area, tipBg, cc.p(cx+bgWidth/2 , 180))
    local tipBg2 = lc.createSprite("img_com_bg_38")
    tipBg2:setScale(-bgWidth/lc.w(tipBg2),80/lc.h(tipBg2))
    lc.addChildToPos(area, tipBg2, cc.p(cx-bgWidth/2 , 180))

    local tip = V.createTTF(Str(STR.COMPOSE_TIP) , V.FontSize.S1, V.COLOR_TEXT_LIGHT, cc.size(500,0) , cc.TEXT_ALIGNMENT_CENTER )
    lc.addChildToPos(area, tip, cc.p(cx , 180))

    self:clearSelectedCards()

--    for i = 1, 2 do
--        local light = lc.createSprite("img_transfer_light")
--        light:setAnchorPoint(i == 1 and 0.95 or 0.05, 0.08)
--        light:setFlippedX(i == 2)
--        light:runAction(lc.rep(lc.sequence(lc.rotateTo(4, i == 1 and -3 or 3), lc.rotateTo(4, 0))))
--        lc.addChildToPos(area, light, cc.p(i == 1 and (lc.w(area) - 50) or 50, lc.h(area) - 120))
--        local joint = lc.createSprite("img_transfer_light_joint")
--        joint:setAnchorPoint(i == 1 and 1 or 0, 1)
--        joint:setFlippedX(i == 2)
--        lc.addChildToPos(area, joint, cc.p(i == 1 and (lc.w(area) - 8) or 8, lc.h(area) - 8))
--        local beam = lc.createSprite("img_transfer_beam")
--        beam:setScale(4)
--        beam:setAnchorPoint(i == 1 and 1 or 0, 0.5)
--        beam:setFlippedX(i == 2)
--        lc.addChildToPos(light, beam, cc.p(i == 1 and 38 or (lc.w(light) - 38), -4))
--    end
end

function _M:selectTargetCard()
    local cardInfos = {}
    for i=1,#self._rarePackageCards do
        local cardInfo = {}
        cardInfo._infoId = self._rarePackageCards[i]
        table.insert(cardInfos, cardInfo)
    end
    local list = BattleListDialog.create(lc._runningScene, cardInfos, BattleListDialog.Mode.compose, Str(STR.SELECT_COMPOSE_CARD))
    list:setChoiceFunction(function(sender) end,function(sender) self:onTargetSelected(sender) end , function(sender) end)
    list:show()
end

function _M:onTargetSelected(card)
    self._targetCard = card
    self._addTargetBtn.targetCardNode:removeAllChildren()
    local cardSprite = V.createCardFrame(self._targetCard)
    lc.addChildToCenter(self._addTargetBtn.targetCardNode, cardSprite)
    self:clearSelectedCards()
end

function _M:selectCard(index)
    local exceptCards, selectCard = {}, {}

    for i = 1, #self._slots do
        local card = self._slots[i]._card
        if card ~= nil then
            if i ~= index then
                exceptCards[#exceptCards + 1] = card
            else
                selectCard = card
            end
        end
    end

    local composeCards = {}
    for i=1,#self._rarePackageCards do
        if self._rarePackageCards[i]~=self._targetCard then
            local cardNum = P._playerCard:getCardCount(self._rarePackageCards[i])
            local cardInTroop = P._playerCard:getCardCountInTroop(self._rarePackageCards[i])
            local extraNum = cardNum - cardInTroop
            if(extraNum > 0) then
                table.insert(composeCards, self._rarePackageCards[i])
            end
        end
    end
    
    
    local form = require("CardSelectForm").createRareComposeForm(composeCards, self._selectCards)
    form:registerSelectedHandler(function(selectedCards)
        self:updateSelectedCards(selectedCards)
        end)
    form:show()
end

function _M:updateSelectedCard(index, card)
    local slot = self._slots[index]

    slot:removeAllChildren()
    slot._card = nil

    if card ~= nil then
        local icon = IconWidget.createByInfoId(card)
        icon._callback = function() self:selectCard(index) end
        lc.addChildToCenter(slot, icon)
        slot._card = card
    end
end

function _M:updateSelectedCards(selectedCards)
    local index = 1
    for k,v in pairs(selectedCards) do
        for i=1,v do
            local slot = self._slots[index]
            local slotBtn = self._slotBtns[index]
            slotBtn:setVisible(self._targetCard~=nil)
            slot:removeAllChildren()
            slot._card = nil

            local icon = IconWidget.createByInfoId(k)
            icon._callback = function() self:selectCard(index) end
            lc.addChildToCenter(slot, icon)
            slot._card = k
            index = index+1
        end
    end
    for i=index, #self._slots do
        local slot = self._slots[i]
        local slotBtn = self._slotBtns[i]
        slotBtn:setVisible(self._targetCard~=nil)
        slot:removeAllChildren()
        slot._card = nil
    end

    self._composeBtn:setEnabled(index==7)
end

function _M:clearSelectedCards()
    self._selectCards = {}
    self:updateSelectedCards(self._selectCards)
end

function _M:transferAutoAdd()
    local autoCards = {}

    local cards = P._playerCard:getCards(self._cardType)
    for k, v in pairs(cards) do
        if v:getQuality() == Data.CardQuality.good and not v._isSelected then
            autoCards[#autoCards + 1] = v 
        end
    end

    local j = 1
    for i = 1, #self._slots do
        if autoCards[j] == nil then break end
        local slot = self._slots[i]
        if slot._card == nil then
            self:updateSelectedCard(i, autoCards[j])
            j = j + 1
        end
    end
end

function _M:onConfirmCompose()
    function callBack()
        P._playerCard:addCard(self._targetCard, 1)
        for k,v in pairs(self._selectCards) do
            P._playerCard:removeCard(k, v)
        end
        self:hide()
        require("RewardCardPanel").create(Str(STR.MERGE_RESULT)..Str(STR.SUCCESS), {{_infoId=self._targetCard}}):show()
        lc.Audio.playAudio(AUDIO.E_CARD_GET)

        ClientData.sendCardCompose(self._packgeId, self._targetCard, self._selectCards)
    end
    ConfirmCompose.create(self._targetCard, self._selectCards, callBack):show()

end

return _M