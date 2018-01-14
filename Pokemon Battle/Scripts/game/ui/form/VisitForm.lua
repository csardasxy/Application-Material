local _M = class("DescForm", BaseForm)
local CardThumbnail = require("CardThumbnail")
local CardInfoPanel = require("CardInfoPanel")

local FORM_SIZE = cc.size(1000, 710)

function _M.create(input, type)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(input, type)
    return panel
end

function _M:init(input, type)
    local title = type == nil and Str(STR.INFO) or Str(STR.RECOMMEND_TROOP)
    self._type = type
    _M.super.init(self, FORM_SIZE, title, 0)

    local troopBg = lc.createSprite({_name = "troop_bg", _crect = cc.rect(0, 0, 1, 365), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, 470)})
    lc.addChildToPos(self._frame, troopBg, cc.p(FORM_SIZE.width / 2, 50 + lc.h(troopBg) / 2))
    self._troopBg = troopBg

    local list = lc.List.createH(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, V.CARD_SIZE.height), 30, 30)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(troopBg, list)
    lc.offset(list, 0, 10)
    self._list = list

    if type ~= nil then
        self._input = input
        self._user = ClientData.getAttackUserFromInput(input)
        self._troop = ClientData.pbTroopToTroop(self._user._troopCards)
        self:updateView()
    else
        self._userId = input
        self._indicator = V.showPanelActiveIndicator(self._form)
    end
end

function _M:onShowActionFinished()
    if self._type == nil then
        ClientData.sendUserVisit(self._userId)
    end
end

function _M:updateView()
    local user = self._user
    local type = self._type
    local troopInfo = self._troop
    local y = lc.bottom(self._titleFrame) - 20

    local flag = UserWidget.Flag.LEVEL_NAME
    if type == Data.RecommendTroop.player then
        flag = bor(flag, UserWidget.Flag.REGION)
    end
    local widget = self._widget
    if not widget then
        widget = require("UserWidget").create(user, flag)
        if widget._regionArea then
            lc.offset(widget._regionArea, 20, -100)
            widget._regionArea:setColor(V.COLOR_TEXT_WHITE)
        end
        lc.addChildToPos(self._frame, widget, cc.p(60 + lc.w(widget) / 2, y - 50))
        self._widget = widget
    end

    local label = self._label
    if not label then
        label = V.createTTFBold(Str(STR.CUR_TROOP), V.FontSize.S1, V.COLOR_TEXT_TITLE)
        label:enableOutline(lc.Color4B.black, 2)
        lc.addChildToPos(self._frame, label, cc.p(20 + lc.cw(label), lc.ch(label) + 10))
        self._label = label
    end

    local countLabel = self._countLabel
    if not countLabel then
        local monsterCount, magicTrapCount = 0, 0
        for _, card in ipairs(troopInfo) do
            local cardType = Data.getType(card._infoId)
            if cardType == Data.CardType.monster then monsterCount = monsterCount + card._num
            else magicTrapCount = magicTrapCount + card._num
            end
        end
        countLabel = V.createTTFBold(string.format(Str(STR.TROOP_ALL_COUNT), monsterCount, magicTrapCount, 0), V.FontSize.S1)
        lc.addChildToPos(self._frame, countLabel, cc.p(lc.right(label) + 40 + lc.cw(countLabel), lc.y(label)))
        self._countLabel = countLabel
    end

    self:updateTroopList()
    
    local trainBtn = self._trainBtn
    if not trainBtn then
        trainBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onTrain() end, V.CRECT_BUTTON_1_S, 150)
        trainBtn:addLabel(Str(STR.TRAIN))
        trainBtn:setVisible(self._input ~= nil)
        lc.addChildToPos(self._frame, trainBtn, cc.p(FORM_SIZE.width - 120, y - 50))
        self._trainBtn = trainBtn
    end
end

function _M:updateTroopList()
    local troopInfo = self._troop

    self:releaseTroopCards()
    
    local items = {}
    for _, card in ipairs(troopInfo) do
        local cardType = Data.getType(card._infoId)
        local layout
        if not layout then
            layout = V.createShaderButton(nil, function()
                CardInfoPanel.create(card._infoId, 1, CardInfoPanel.OperateType.view):show()
            end)
            layout:retain()
         
            local item = CardThumbnail.createFromPool(card._infoId, 0.6)
            item._countArea:update(true, card._num)
            layout:setContentSize(item._thumbnail:getContentSize())
            layout:setAnchorPoint(cc.p(0.5, 0.5))
            lc.addChildToPos(layout, item, cc.p(lc.cw(layout), lc.ch(layout) + 8))
            item._thumbnail:setGray(P._playerCard:getCardCount(card._infoId) < card._num)
            layout._item = item
        else
            layout._item._countArea:update(true, card._num)
            layout._item._thumbnail:setGray(P._playerCard:getCardCount(card._infoId) < card._num)
        end

        table.insert(items, layout)  
        layout._card = card
    end

    table.sort(items, function(a, b)
        local originIdA = Data.getOriginId(a._card._infoId)
        local originIdB = Data.getOriginId(b._card._infoId)
        if originIdA < originIdB then return true
        elseif originIdA > originIdB then return false
        else return a._card._infoId < b._card._infoId
        end
    end)

    for _, item in ipairs(items) do
        self._list:pushBackCustomItem(item)
    end

    local label = self._label

    self._list:refreshView()
    self._list:scrollToLeft(0.1, true)
end

function _M:onReplay()
    lc._runningScene:onReplay(self._input)
end

function _M:onTrain()
    local trainInput = ClientData.genRecommendTrainInput(self._input)
    lc.replaceScene(require("ResSwitchScene").create(lc._runningScene._sceneId, ClientData.SceneId.battle, trainInput))
end

function _M:onEnter()
    _M.super.onEnter(self)

    if self._type == nil then
        ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
    end
end

function _M:onExit()
    _M.super.onExit(self)

    if self._type == nil then
        ClientData.removeMsgListener(self)
    end
end

function _M:onCleanup()
    self:releaseTroopCards()

    _M.super.onCleanup(self)
end

function _M:releaseTroopCards()
    if self._list then
        local items = self._list:getItems()
        for _, layout in ipairs(items) do
            CardThumbnail.releaseToPool(layout._item)        
            layout:release() 
        end
        self._list:removeAllItems()
    end
end

function _M:onMsg(msg)
    local msgType = msg.type        
    if msgType == SglMsgType_pb.PB_TYPE_USER_VISIT then
        self._indicator:removeFromParent()
        
        local resp = msg.Extensions[User_pb.SglUserMsg.user_visit_resp]
        self._user = require("User").create(resp.user_info)
        self._troop = ClientData.pbTroopToTroop(resp.troop)
        self:updateView()

        return true
    end    
    
    return false
end

return _M