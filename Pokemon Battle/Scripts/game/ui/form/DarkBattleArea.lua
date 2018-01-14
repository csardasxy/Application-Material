local _M = class("UnionBattleArea", lc.ExtendCCNode)
local CardThumbnail = require("CardThumbnail")
local CardInfoPanel = require("CardInfoPanel")
local TOP_HEIGHT = 300
local BOTTOM_HEIGHT = 100
local ITEM_W = 320
local ITEM_H = 500
local THUMBNAIL_SCALE = 0.7
local TROOP_THUMBNAIL_SCALE = 0.45
local FIND_PRICE = 1000

local TAG_CUSTOM_ITEM = 100

function _M.create(w, h)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(w, h)
    area:init()

    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        elseif evtName == "cleanup" then
            area:onCleanup()
        end
    end)

    return area
end

function _M:init()
    self._curTroopIndex = Data.TroopIndex.dark_battle1

    local bg = lc.createSprite("res/jpg/dark_battle_bg.jpg")
    lc.addChildToCenter(self, bg)

    self._areaNode = lc.createNode()
    self._areaNode:setContentSize(self:getContentSize())
    lc.addChildToCenter(self, self._areaNode)
    
    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.rank_list_dirty, function(event)
        if event._type == SglMsgType_pb.PB_TYPE_RANK_DARK_PRE then
            if self._indicator then
                self._indicator:removeFromParent()
                self._indicator = nil
            end
            self:enterDefultArea()
        end
    end))
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    table.insert(self._listeners, lc.addEventListener(Data.Event.gold_dirty, function(event)
        V.addPriceToBtn(self._findBtn, FIND_PRICE, Data.ResType.gold, 100)
    end))

end

function _M:initTopArea()
    local topArea = lc.createNode()
    topArea:setContentSize(self:getContentSize())
    lc.addChildToCenter(self, topArea)
    self._topArea = topArea

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(topArea, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - lc.h(titleBg) / 2 + 5))

    local title = V.createTTFStroke(Str(STR.DARK_BATTLE_CHAMPION), V.FontSize.S1)
    lc.addChildToPos(titleBg, title, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2))

    local createStage = function(level)
        local stage = ccui.Widget:create()
        stage:setContentSize(250, 236)

        local cx = lc.w(stage) / 2

        local ranks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_DARK_PRE)
        local user, rank
        if ranks and ranks[level] then
            rank = ranks[level]
            user = rank._user
        end

        if user then
            stage:setTouchEnabled(true)
            stage:addTouchEventListener(function(sender, evt)
                if evt == ccui.TouchEventType.ended then
                    require("ClashUserInfoForm").create(user._id):show() -- todo dark
                end
            end)
        end

        local bottom = cc.ShaderSprite:createWithFramename("img_stage_gold")
        lc.addChildToPos(stage, bottom, cc.p(cx, lc.h(bottom) / 2))

        local glow = cc.ShaderSprite:createWithFramename("img_stage_gold_light")
        glow:setScale(2)
        lc.addChildToPos(bottom, glow, cc.p(lc.w(bottom) / 2, lc.h(bottom) + 40))

        local avatar = require("UserWidget").create()
        lc.addChildToPos(stage, avatar, cc.p(cx, lc.h(stage) - lc.h(avatar) / 2 - 24))
        stage._avatar = avatar

        local trophy = V.createIconLabelArea("img_icon_res16_s", rank._value, 150)
        trophy._valBg:setScale(0.84)
        trophy._icon:setScale(0.84)
        lc.offset(trophy._icon, 10)
        lc.offset(trophy._label, - 10)
        lc.addChildToPos(stage, trophy, cc.p(cx, 88))
        stage._trophy = trophy._label

        local name = V.createTTF(user and user._name or string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.LORD)), V.FontSize.S2)
        lc.addChildToPos(stage, name, cc.p(cx, 24))
        stage._name = name

        local userClone = {_avatar = user and user._avatar, _vip = user and user._vip or 0}
        if level == 1 then
            userClone._avatarFrameId = 7512

        else
            bottom:setScaleY(0.9)
            lc.offset(avatar, 0, -4)
            lc.offset(trophy, 0, -2)
            lc.offset(name, 0, 4)

            if level == 2 then
                userClone._avatarFrameId = 7510
                bottom:setEffect(V.SHADER_COLOR_STAGE_SILVER)
                glow:setEffect(V.SHADER_COLOR_STAGE_SILVER)

            elseif level == 3 then
                userClone._avatarFrameId = 7511
                bottom:setEffect(V.SHADER_COLOR_STAGE_BRONZE)
                glow:setEffect(V.SHADER_COLOR_STAGE_BRONZE)
            end
        end

        avatar:setUser(userClone)

        return stage
    end

    local stage1 = createStage(1)
    lc.addChildToPos(topArea, stage1, cc.p(lc.w(self) / 2, lc.bottom(titleBg) + 8 - lc.h(stage1) / 2), 1)

    local stage2 = createStage(2)
    lc.addChildToPos(topArea, stage2, cc.p(math.max(lc.left(stage1) - 30 - lc.w(stage2), 0) + lc.w(stage2) / 2, lc.y(stage1)))

    local stage3 = createStage(3)
    lc.addChildToPos(topArea, stage3, cc.p(math.min(lc.right(stage1) + 30 + lc.w(stage2), lc.w(self)) - lc.w(stage3) / 2, lc.y(stage1)))

    topArea._stages = {stage1, stage2, stage3}
end

function _M:enterDefultArea()
    if self._topArea then
        self._topArea:removeFromParent()
        self._topArea = nil
    end
    self:initTopArea()

    local layout = self._areaNode
    self:releaseTroopCards()
    layout:removeAllChildren()

    self._troopArea = self:createTroopArea(layout)
    self:updateTroopList(self._curTroopIndex)

    local troopBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender)
        self:releaseTroopCards()
        lc.pushScene(require("HeroCenterScene").create(self._curTroopIndex))
    end, V.CRECT_BUTTON_S, 100)
    troopBtn:addLabel(Str(STR.MANAGE_CARDS))
    lc.addChildToPos(layout, troopBtn, cc.p(lc.cw(layout) + 300, lc.top(self._troopArea) + lc.ch(troopBtn) + 20))

    local rankBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender)
        require("RankForm").create(Data.RankRange.dark):show()
    end, V.CRECT_BUTTON_S, 100)
    rankBtn:addLabel(Str(STR.RANK))
    lc.addChildToPos(layout, rankBtn, cc.p(lc.cw(layout) + 300, lc.top(troopBtn) + lc.ch(rankBtn) + 20))

    local logBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender)
        require("LogForm").create(Battle_pb.PB_BATTLE_DARK):show()
    end, V.CRECT_BUTTON_S, 100)
    logBtn:addLabel(Str(STR.LOG))
    lc.addChildToPos(layout, logBtn, cc.p(lc.cw(layout) - 300, lc.top(self._troopArea) + lc.ch(logBtn) + 20))

    local careerBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender)
        require("DarkUserInfoForm").create():show()
    end, V.CRECT_BUTTON_S, 100)
    careerBtn:addLabel(Str(STR.RANK_HISTORY))
    lc.addChildToPos(layout, careerBtn, cc.p(lc.cw(layout) - 300, lc.top(logBtn) + lc.ch(careerBtn) + 20))

    local findBtn = V.createScale9ShaderButton("img_btn_1", function(sender)
        if P._playerFindDark:getIsValidTime() ~= 0 then
            return ToastManager.push(Str(STR.DARK_BATTLE_NOT_STARTED))
        end
        if P:getItemCount(Data.ResType.gold) < FIND_PRICE then
        return ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
        end
        self:find()
    end, V.CRECT_BUTTON, 200)
    lc.addChildToPos(layout, findBtn, cc.p(lc.cw(layout), lc.ch(layout) - 25))
    V.addPriceToBtn(findBtn, FIND_PRICE, Data.ResType.gold, 100)
    self._findBtn = findBtn

    local timeBg = lc.createSprite("wait_text_bg")
    timeBg:setScale(lc.w(layout) / lc.w(timeBg), 41 / lc.h(timeBg))
    lc.addChildToPos(layout, timeBg, cc.p(lc.cw(layout), lc.top(findBtn) + 25))

    local timeLabel = V.createTTF(P._playerFindDark:getStartTimeTip(), V.FontSize.S2)
    lc.addChildToPos(layout, timeLabel, cc.p(lc.cw(layout), lc.top(findBtn) + 25))

    if P._playerFindDark:isInDarkBattle() then
        self:find()
    end

end

function _M:find()
    local ret, str = P._playerCard:checkDarkTroops()
    if not ret then
        return ToastManager.push(str)
    end
    local price = Data._globalInfo._darkDuelCost
    if not P._playerFindDark:isInDarkBattle() and not P:hasResource(Data.ResType.gold, price) then
        return ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
    end
    if V._findMatchPanel then return end
    require("FindMatchPanel").create(Data.FindMatchType.dark):show()
end

function _M:createTroopArea(layer)
    local troopArea = lc.createSprite({_name = "img_troop_bg_1", _size = cc.size(lc.w(self), 212), _crect = cc.rect(47, 0, 1, 212)})
    lc.addChildToPos(layer, troopArea, cc.p(lc.cw(layer), lc.ch(troopArea)))

    local list = lc.List.createH(cc.size(lc.w(troopArea) - 50, lc.h(troopArea) - 6), 20, 10)
    lc.addChildToPos(troopArea, list, cc.p(24, 0))
    self._troopList = list

    self._troopBtns = {}
    for i = 1, 3 do
        local btn = self:createTroopBtn(i)
        lc.addChildToPos(troopArea, btn, cc.p(lc.cw(troopArea) + (i - 2) * 140, lc.h(troopArea) + 30))
        btn:setLocalZOrder(1 == i and 1 or -1)
        self._troopBtns[i] = btn
    end
    
    return troopArea
end

function _M:createTroopBtn(index)
    local btn = V.createScale9ShaderButton(index == 1 and "troop_select_light" or "troop_select_dark", function(sender)
        for i, btn in ipairs(self._troopBtns) do
            btn:loadTextureNormal(i == index and "troop_select_light" or "troop_select_dark", ccui.TextureResType.plistType)
            btn:setEnabled(i ~= index)
            btn:setLocalZOrder(i == index and 1 or -1)
            btn:setContentSize(cc.size(120, 77))
            btn:setCapInsets(cc.rect(38, 0, 1, 77))
        end
        
        self._curTroopIndex = Data.TroopIndex.dark_battle1 + index - 1
        self:updateTroopList(self._curTroopIndex)
    end, cc.rect(38, 0, 1, 77), 120)
    btn:addLabel(Str(STR.TROOP)..index)
    btn:setEnabled(Data.TroopIndex.dark_battle1 + index - 1 ~= self._curTroopIndex)
    return btn
end

function _M:updateTroopList(troopsIndex)
    local itemList = self:remainItemFromList(troopsIndex)
    self:releaseTroopCards()

    local items = {}
    for _, card in ipairs(P._playerCard._troops[troopsIndex]) do
        local layout
        for i = 1, #itemList do
            if itemList[i]._card._infoId == card._infoId then
                layout = itemList[i]
                break
            end
        end

        if not layout then
            layout = ccui.Layout:create()
            layout:retain()
         
            local item = CardThumbnail.createFromPool(card._infoId, TROOP_THUMBNAIL_SCALE)
            item._countArea:update(true, card._num)
            layout:setContentSize(item._thumbnail:getContentSize())
            layout:setAnchorPoint(cc.p(0.5, 0.5))
            lc.addChildToPos(layout, item, cc.p(lc.cw(layout), lc.ch(layout) + 10))

            item._thumbnail:setTouchEnabled(true)
            item._thumbnail:addTouchEventListener(function(sender, evt)
                self:onTouchThumbnail(sender, evt)
            end)

            layout._item = item
        else
            layout._item._countArea:update(true, card._num)
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
        self._troopList:pushBackCustomItem(item)
    end
end

function _M:onTouchThumbnail(sender, type)
    if type == ccui.TouchEventType.began then
        sender:stopAllActions()
        sender:runAction(lc.scaleTo(0.1, 0.95))
    elseif type == ccui.TouchEventType.ended or type == ccui.TouchEventType.canceled then
        sender:stopAllActions()
        sender:runAction(lc.scaleTo(0.08, 1.0))
        self:onItemTap(sender)
    end
end

function _M:onItemTap(item)
    local infoId = item._infoId

    local deltaX = math.abs(cc.pSub(item:getTouchEndPosition(), item:getTouchBeganPosition()).x)
    local deltaY = math.abs(cc.pSub(item:getTouchEndPosition(), item:getTouchBeganPosition()).y)
    if deltaX < 32 and deltaY < 32 then
        local cards = {}
        local index = 0
        local items = self._troopList:getItems()
        for i = 1, #items do
            local t = items[i]._item._thumbnail
            cards[#cards + 1] = {_infoId = t._infoId, _num = t._count}
            if item == t then
                index = i
            end
        end

        local panel = CardInfoPanel.create(infoId, 1, CardInfoPanel.OperateType.na)
        panel:setCardList(cards, index, Str(STR.CUR_TROOP))
        panel:setCardCount(item._count)
        panel:show()
    end
end

function _M:remainItemFromList(troopsIndex)
    local itemList = {}

    local items = self._troopList:getItems()
    for i = #items, 1, -1 do
        local layout = items[i]

        local inList = false
        for _, card in ipairs(P._playerCard._troops[troopsIndex]) do
            if layout._card._infoId == card._infoId then
                inList = true
                break
            end
        end 

        if inList then
            table.insert(itemList, layout)
            self._troopList:removeItem(i - 1, false)
        end
    end

    return itemList
end

function _M:releaseTroopCards()
    if self._troopList then
        local items = self._troopList:getItems()
        for _, layout in ipairs(items) do
            CardThumbnail.releaseToPool(layout._item)        
            layout:release() 
        end
        self._troopList:removeAllItems()
    end
end

function _M:onEnter()
    self:updateView()
end

function _M:isDataReady()
    return P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_DARK_PRE)
end

function _M:updateView()
    if not self._indicator then
        self._indicator = V.showPanelActiveIndicator(self)
    end
    ClientData.sendRankRequest(SglMsgType_pb.PB_TYPE_RANK_DARK_PRE)
end

function _M:onExit()
    
    self:releaseTroopCards()
    
    ClientData.removeMsgListener(self)
end

function _M:onMsg(msg)
    local msgType = msg.type

    return false
end

function _M:onCleanup()
    lc.TextureCache:removeTextureForKey("res/jpg/dark_battle_bg.jpg")
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

return _M