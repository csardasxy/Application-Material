local _M = class("FindLadderArea", lc.ExtendCCNode)

local CardThumbnail = require("CardThumbnail")
local CardInfoPanel = require("CardInfoPanel")

local ITEM_W = 320
local ITEM_H = 500
local THUMBNAIL_SCALE = 0.7
local TROOP_THUMBNAIL_SCALE = 0.45

_M.TouchStatus = 
{
    press = 1,
    move = 2,
    tap = 3,
}

local MovingDir = 
{
    none = 0,
    horizontal = 1,
    vertical = 2,
}

local CardMode = 
{
    troop_card = 1,
    select_card = 2,
}

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

function _M:onEnter()
    self._listeners = {}

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    if not P._playerFindLadder._hasTicket then
        self:enterDoor()
    elseif P._playerFindLadder._characterId == 0 then
        self:enterSelectCharacter()
    elseif P._playerFindLadder._step <= P._playerFindLadder.MAX_TROOP_COUNT then
        self:enterSelectCards()
    else
        self:enterBattleField()
    end
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    ClientData.removeMsgListener(self)
end

function _M:onCleanup()
    self:releaseSelectCards()
    self:releaseTroopCards()

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/arena_door.jpg"))
end

function _M:onMsg(msg)
    local msgType = msg.type

    if msgType == SglMsgType_pb.PB_TYPE_WORLD_BUY_TICKET then
        V.getActiveIndicator():hide()
        self:enterSelectCharacter()

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_SELECT_CHAR then
        V.getActiveIndicator():hide()
        self:enterSelectCards()

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_SELECT_CARD then
        P._playerFindLadder._step = msg.Extensions[World_pb.SglWorldMsg.world_select_card_resp] 
        if P._playerFindLadder._step % P._playerFindLadder.SELECT_CARD_COUNT == 1 then  
            if P._playerFindLadder._step > P._playerFindLadder.MAX_TROOP_COUNT then
                self:enterBattleField()
            else
                self:updateSelectCards()
            end
        end

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_QUIT then
        ClientData.sendOpenBox(P._playerFindLadder._chest._infoId, 1)

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_USER_OPEN_CHEST then
        local resp = msg.Extensions[User_pb.SglUserMsg.user_open_chest_resp]

        P._playerFindLadder:clear()
        self._characterId = 0

        -- exit
        V.getActiveIndicator():hide()

        self:hideBattleField()
        self:enterDoor()

        -- reward 
        local RewardPanel = require("RewardPanel")
        RewardPanel.create(resp, RewardPanel.MODE_CHEST):show()
            
        return true

    end
    
    return false
end

function _M:init()
    self._characterId = P._playerFindLadder._characterId

    -- ui
    self._thumbnails = {}
end

function _M:onSelectCard(infoId)
    local index = P._playerFindLadder:getSelectCardIndex(infoId)
    
    P._playerFindLadder:addCardToTroop(infoId, index)

    ClientData.sendLadderSelectCard(index)

    local pos = self._movingSprite._srcPos
    self:updateSelectCards()
    self:runAction(lc.sequence(0, function () self:playAction(pos, infoId) end))
end

function _M:onSelectCharacter()
    P._playerFindLadder._characterId = self._characterId
    P._playerFindLadder._step = 1

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendLadderSelectCharacter(self._characterId)
end

function _M:onBuyTicket(resType)
    --[[
    if not P._playerFindLadder:getIsValidTime() then
        local str = P._playerFindLadder:getTimeTip()
        return ToastManager.push(str)
    end
    ]]

    if resType == Data.ResType.gold then
        if not V.checkGold(Data._globalInfo._buyTicketGold) then
            return
        end
        P:changeResource(Data.ResType.gold, -Data._globalInfo._buyTicketGold)
    
    elseif resType == Data.ResType.ingot then
        if not V.checkIngot(Data._globalInfo._buyTicketIngot) then
            return
        end
        P:changeResource(Data.ResType.ingot, -Data._globalInfo._buyTicketIngot)

    else
        if not P._propBag:hasProps(Data.PropsId.ladder_ticket, 1) then
            return ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[Data.PropsId.ladder_ticket]._nameSid)))
        end

        P._propBag:changeProps(Data.PropsId.ladder_ticket, -1)
    end 
        
    P._playerFindLadder._hasTicket = true

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendLadderBuyTicket(resType)
end

function _M:onFindingBattle()
    if P._playerFindLadder:getIsValidTime() then
        require("FindMatchPanel").create(Data.FindMatchType.ladder):show()
    else
        local str = P._playerFindLadder:getTimeTip()
        ToastManager.push(str)
    end
end

function _M:onFinishBattle()
    V.getActiveIndicator():show(Str(STR.WAITING))

    ClientData.sendLadderQuit()
end

-----------------------------------------------------------
-- door

function _M:enterDoor()
    if self._doorLayer ~= nil then return end

    local layer = lc.createNode(self:getContentSize())
    lc.addChildToCenter(self, layer, 1)
    self._doorLayer = layer

    self._doors = {}
    for i = 1, 2 do
        local door = cc.Sprite:create("res/jpg/arena_door.jpg")
        lc.addChildToCenter(layer, door)
        door:setAnchorPoint(cc.p(2 - i, 0.5))
        door:setFlippedX(i == 2)
        self._doors[i] = door
    end

    local tipNode = lc.createNode()
    lc.addChildToPos(layer, tipNode, cc.p(0, 0))
    layer._tipNode = tipNode

    local tipBg = lc.createSprite({_name = "img_com_bg_41", _size = cc.size(672, 54), _crect = cc.rect(29, 26, 1, 1)})
    lc.addChildToPos(tipNode, tipBg, cc.p(lc.cw(layer), 180))

    local tip = V.createTTF(P._playerFindLadder:getTimeTip(), V.FontSize.M2)
    lc.addChildToCenter(tipBg, tip)

    --[[
    if P._playerFindLadder:getIsValidTime() then
        tipBg:setVisible(false)
    end
    ]]
    
    -- btn
    local createBtn = function (resIcon, resCount, resType) 
        local btn = V.createScale9ShaderButton("img_btn_1", function(sender) 
            self:onBuyTicket(resType)
        end, V.CRECT_BUTTON, 180)
    
        local icon = lc.createSprite(resIcon)
        local label = V.createBMFont(V.BMFont.huali_26, resCount)

        lc.addChildToPos(btn, icon, cc.p(lc.cw(btn) - (lc.w(label) + 12) / 2, lc.ch(btn)))
        lc.addChildToPos(btn, label, cc.p(lc.right(icon) + lc.cw(label) + 12, lc.ch(btn)))

        return btn
    end

    local btnGem = createBtn("img_icon_res3_s", Data._globalInfo._buyTicketIngot, Data.ResType.ingot)
    lc.addChildToPos(tipNode, btnGem, cc.p(lc.cw(layer) - 120, 80))

    if P._propBag:hasProps(Data.PropsId.ladder_ticket, 1) then
        local btnTicket = createBtn("img_icon_props_s7106", 1, Data.PropsId.ladder_ticket)
        lc.addChildToPos(tipNode, btnTicket, cc.p(lc.cw(layer) + 120, 80))
    else
        local btnGold = createBtn("img_icon_res1_s", Data._globalInfo._buyTicketGold, Data.ResType.gold)
        lc.addChildToPos(tipNode, btnGold, cc.p(lc.cw(layer) + 120, 80))
    end

    V.getResourceUI():setMode(Data.PropsId.ladder_ticket)
    
end

function _M:hideDoor()
    if not self._doorLayer then
        return
    end

    local layer = self._doorLayer
    layer._tipNode:setVisible(false)

    for i = 1, #self._doors do
        local pos = cc.p(i == 1 and 0 or lc.w(self._doorLayer), lc.ch(self._doorLayer))

        local door = self._doors[i]
        door:runAction(lc.sequence(
            lc.moveTo(0.8, pos),
            lc.call(function () 
                layer:removeFromParent()
            end)
        ))
    end

    --self._doorLayer:removeFromParent()
    self._doorLayer = nil
    self._doors = nil

    V.getResourceUI():setMode(Data.ResType.ladder_trophy)
end

-----------------------------------------------------------
-- select character

function _M:enterSelectCharacter()
    if self._characterLayer ~= nil then return end

    self:hideDoor()

    local layer = lc.createNode(self:getContentSize())
    lc.addChildToCenter(self, layer)
    self._characterLayer = layer

    local titleBg = lc.createSprite({_name = "img_title_bg", _size = cc.size(480, 52), _crect = cc.rect(115, 25, 1, 1)})
    lc.addChildToPos(layer, titleBg, cc.p(lc.cw(layer), lc.h(layer) - 40))

    local label = V.createBMFont(V.BMFont.huali_26, Str(STR.PVP_SELECT_YOUR_CHARACTER))
    lc.addChildToCenter(titleBg, label)

    local width = 980
    local list = lc.List.createH(cc.size(lc.w(layer), ITEM_H), math.max(0, (lc.w(layer) - width) / 2))
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(layer, list, cc.p(lc.cw(layer), lc.ch(layer) + 20))
    self._characterList = list

    for i = 1, #P._playerFindLadder._characters do
        local infoId = P._playerFindLadder._characters[i]
        local item = self:createCharacterItem(infoId)
        list:pushBackCustomItem(item)
    end

    local btn = V.createScale9ShaderButton("img_btn_1", function(sender) 
        self:onSelectCharacter()
    end, V.CRECT_BUTTON, 180)
    lc.addChildToPos(layer, btn, cc.p(lc.cw(layer), 60))
    btn:addLabel(Str(STR.OK))

    if self._characterId == 0 then
        self._characterId = P._playerFindLadder._characters[1]
    end

    self:selectCharacter(self._characterId)
end

function _M:hideSelectCharacter()
    if not self._characterLayer then
        return
    end

    self._characterLayer:removeFromParent()
    self._characterLayer = nil
end

function _M:createCharacterItem(infoId)
    local info = Data._characterInfo[infoId]

    local layout = V.createShaderButton(nil, function(sender) 
        self:selectCharacter(info._id)
    end)
    layout._id = info._id
    layout:setContentSize(ITEM_W, ITEM_H)
    
    local nameBg = lc.createSprite({_name = 'img_com_bg_43', _size = cc.size(ITEM_W, V.CRECT_COM_BG43.height), _crect = V.CRECT_COM_BG43})
    lc.addChildToPos(layout, nameBg, cc.p(lc.cw(layout), lc.ch(nameBg)), 1)
    layout._nameBg = nameBg

    local name = V.createBMFont(V.BMFont.huali_26, Str(info._nameSid))
    lc.addChildToCenter(nameBg, name)

    local bones = DragonBones.create(Data.CharacterNames[info._id])
    bones:gotoAndPlay(string.format("effect_%02d", info._id))
    bones:setScale(0.5)
    lc.addChildToPos(layout, bones, cc.p(lc.x(nameBg), lc.top(nameBg) + 120))

    local light = lc.createSprite('img_light')
    light:setScale(5.5)
    lc.addChildToPos(layout, light, cc.p(lc.x(nameBg), lc.top(nameBg) + 180), -1)
    layout._light = light

    local particle = Particle.create('xuanzhong')
    particle:setPositionType(cc.POSITION_TYPE_GROUPED) 
    lc.addChildToPos(layout, particle, cc.p(lc.x(nameBg), lc.top(nameBg) + 20), -1)
    layout._particle = particle

    if info._id == 2 then lc.offset(bones, 10, 0) end

    return layout
end

function _M:selectCharacter(id)
    self._characterId = id
    
    local items = self._characterList:getItems()
    for i = 1, #items do
        local item = items[i]

        item._nameBg:setSpriteFrame(lc.FrameCache:getSpriteFrame(item._id == id and 'img_com_bg_44' or 'img_com_bg_43'), V.CRECT_COM_BG43)
        item._nameBg:setContentSize(ITEM_W, V.CRECT_COM_BG43.height)

        item._light:setVisible(item._id == id)
        item._particle:setVisible(item._id == id)
    end
end

-----------------------------------------------------------
-- select cards

function _M:enterSelectCards()
    if self._cardsLayer ~= nil then return end

    self:hideSelectCharacter()

    local layer = lc.createNode(self:getContentSize())
    lc.addChildToCenter(self, layer)
    self._cardsLayer = layer

    local troopArea = self:createTroopArea(layer)

    -- title
    local titleBg = lc.createSprite({_name = "img_title_bg", _size = cc.size(480, 52), _crect = cc.rect(115, 25, 1, 1)})
    lc.addChildToPos(layer, titleBg, cc.p(lc.cw(layer), lc.h(layer) - 40))

    local str = string.format(lc.str(STR.SELECT_CARD), 0, P._playerFindLadder.TOTAL_CARD_COUNT, P._playerFindLadder.SELECT_CARD_COUNT)
    local title = V.createBMFont(V.BMFont.huali_26, str)
    lc.addChildToCenter(titleBg, title)
    self._selectTitle = title

    -- btn
    --[[local btn = V.createScale9ShaderButton("img_btn_1", function(sender) 
        self:enterBattleField()
    end, V.CRECT_BUTTON, 180)
    lc.addChildToPos(layer, btn, cc.p(lc.cw(layer) + 120, lc.top(troopArea) + 50))
    btn:addLabel(Str(STR.OK))
    self._confirmSelectBtn = btn]]

    -- cards
    local gap = 10
    local width = P._playerFindLadder.TOTAL_CARD_COUNT * (V.CARD_SIZE.width * THUMBNAIL_SCALE + gap) - gap
    local list = lc.List.createH(cc.size(lc.w(self), 300), math.max(20, (lc.w(layer) - width) / 2), gap)
    lc.addChildToPos(troopArea, list, cc.p(0, 300))
    self._selectCardList = list

    for i = 1, P._playerFindLadder.TOTAL_CARD_COUNT do
        local infoId = 10001

        local layout = ccui.Layout:create()
        layout:setContentSize(cc.size(190, 270))
        layout:setAnchorPoint(0.5, 0.5)
        list:pushBackCustomItem(layout)

        local item = CardThumbnail.createFromPool(infoId, THUMBNAIL_SCALE)
        item._thumbnail:setTouchEnabled(true)
        item._thumbnail:addTouchEventListener(function(sender, evt) 
            self:onTouchThumbnail(sender, evt, CardMode.select_card)
        end)
        lc.addChildToCenter(layout, item)
        table.insert(self._thumbnails, item)
    end

    self:updateSelectCards()
end

function _M:hideSelectCards()
    if not self._cardsLayer then
        return
    end

    self:releaseSelectCards()
    self:releaseTroopCards()

    self._cardsLayer:removeFromParent()
    self._cardsLayer = nil
    self._troopList = nil
    self._selectCardList = nil
end

function _M:updateSelectCards()
    -- desc
    local count, monsterCount, magicCount, trapCount = P._playerFindLadder:getTroopCardCount()
    local str = string.format(lc.str(STR.FIND_ARENA_TIPS), count, P._playerFindLadder.MAX_TROOP_COUNT, monsterCount, magicCount + trapCount) 
    self._troopDescLabel:setString(str)

    -- select cards
    local cards = P._playerFindLadder:getSelectCards()

    local selectedCardCount = 0
    for i = 1, #cards do
        local card = cards[i]
        local thumbnail = self._thumbnails[i]

        thumbnail._thumbnail:updateComponent(card._infoId)
        thumbnail:setVisible(true)

        if not card._isValid then
            thumbnail._thumbnail:setGray(true)
            selectedCardCount = selectedCardCount + 1
        else
            thumbnail._thumbnail:setGray(false)
        end
    end

    for i = 1, #cards do
        local thumbnail = self._thumbnails[i]
        if selectedCardCount == P._playerFindLadder.SELECT_CARD_COUNT then
            thumbnail._isValid = false
        else
            thumbnail._isValid =  cards[i]._isValid
        end

        if selectedCardCount == 0 then
            thumbnail._thumbnail:setOpacity(0)
            thumbnail._thumbnail:runAction(lc.fadeTo(1, 255))
            local par1 = Particle.create("chuxian")
            lc.addChildToCenter(thumbnail, par1)
        else
            thumbnail._thumbnail:setOpacity(255)
        end
    end

    local count = P._playerFindLadder.SELECT_CARD_COUNT - selectedCardCount
    local str = string.format(lc.str(STR.SELECT_CARD), count, P._playerFindLadder.TOTAL_CARD_COUNT, P._playerFindLadder.SELECT_CARD_COUNT)
    self._selectTitle:setString(str)

    -- troop list
    self:updateTroopList()

    --self._confirmSelectBtn:setVisible(index < #P._playerFindLadder._cardsPool)
end

function _M:updateTroopList()
    local itemList = self:remainItemFromList()
    self:releaseTroopCards()

    local items = {}
    for _, card in ipairs(P._playerFindLadder._troopCards) do
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
                self:onTouchThumbnail(sender, evt, CardMode.troop_card)
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

function _M:releaseSelectCards()
    if #self._thumbnails > 0 then
        for _, thumbnail in ipairs(self._thumbnails) do
            CardThumbnail.releaseToPool(thumbnail)
        end
        self._thumbnails = {}
    end
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

function _M:createTroopArea(layer)
    local troopArea = lc.createSprite({_name = "img_troop_bg_1", _size = cc.size(lc.w(self), 212), _crect = cc.rect(47, 0, 1, 212)})
    lc.addChildToPos(layer, troopArea, cc.p(lc.cw(layer), lc.ch(troopArea)))

    local list = lc.List.createH(cc.size(lc.w(troopArea) - 40, lc.h(troopArea) - 6), 20, 10)
    lc.addChildToPos(troopArea, list, cc.p(24, 0))
    self._troopList = list

    local ladder = P._playerFindLadder
    local str = string.format(lc.str(STR.FIND_ARENA_TIPS), ladder.MAX_TROOP_COUNT, ladder.MAX_TROOP_COUNT, ladder.MAX_TROOP_COUNT, ladder.MAX_TROOP_COUNT) 
    local desc = V.createTTF(str, V.FontSize.S1, lc.Color3B.black)

    local infoBg = lc.createSprite({_name = "img_tip_bg2", _size = cc.size(lc.w(desc) + 40 + 40, 51), _crect = cc.rect(36, 25, 1, 1)})
    --lc.addChildToPos(layer, infoBg, cc.p(lc.cw(infoBg) + 200, lc.top(troopArea) + lc.ch(infoBg) + 10))
    lc.addChildToPos(layer, infoBg, cc.p(lc.cw(infoBg) + 30, lc.top(troopArea) + lc.ch(infoBg) + 10))
    lc.addChildToPos(infoBg, desc, cc.p(lc.cw(desc) + 40, lc.ch(infoBg)))
    self._troopDescLabel = desc

    return troopArea
end

function _M:onTouchThumbnail(sender, type, mode)
    if type == ccui.TouchEventType.began then
        sender:stopAllActions()
        sender:runAction(lc.scaleTo(0.1, 0.95))
        self:onItemPress(sender, mode)

    elseif type == ccui.TouchEventType.ended or type == ccui.TouchEventType.canceled then
        sender:stopAllActions()
        sender:runAction(lc.scaleTo(0.08, 1.0))
        self:onItemTap(sender, mode)

    elseif type == ccui.TouchEventType.moved then        
        self:onItemMove(sender, mode)
    end
end

function _M:onItemPress(item, mode)   
    if self._movingSprite then return end

    self._touchStatus = _M.TouchStatus.press
    self._movingDir = MovingDir.none
end

function _M:onItemMove(item, mode)
    if self._touchStatus == _M.TouchStatus.tap then 
        return 
    end  
    
    self._touchStatus = _M.TouchStatus.move

    if self._movingSprite == nil then
        if self._movingDir == MovingDir.none then
            local deltaX = math.abs(cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition()).x)
            local deltaY = math.abs(cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition()).y)
            if deltaX > 32 or deltaY > 32 then
                self._movingDir = deltaX >= deltaY and MovingDir.horizontal or MovingDir.vertical
            end
        end 
        
        if mode == CardMode.select_card and self._movingDir == MovingDir.vertical and item._item._isValid then
            self:createMovingSpriteAndMaskLayer(item)
            if self._selectCardList then
                self._selectCardList:setIsScrollEnabled(false)
            end
        end
    end

    -- do not use else
    if self._movingSprite then
        self._movingSprite:setPosition(cc.pAdd(self._movingSprite._srcPos, cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition())))
        --self:checkList((type == _M.MODE_TROOP) and self._troopList or self._cardList)
    end
end

function _M:onItemTap(item, mode)
    self._touchStatus = _M.TouchStatus.tap

    local infoId = item._infoId

    if self._movingDir == MovingDir.none then
        if mode == CardMode.troop_card then
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
        else
            local panel = CardInfoPanel.create(infoId, 1, CardInfoPanel.OperateType.na)
            panel:show()
        end

    elseif mode == CardMode.select_card and self._movingSprite then
        -- add card to troop
        local cardCount = P._playerFindLadder:getTroopCardCount()
        if cardCount < P._playerFindLadder.MAX_TROOP_COUNT then
            if lc.y(self._movingSprite) < self._separatorPos then
                self:onSelectCard(infoId)
            end                    

        -- unable add to troop
        else
            ToastManager.push(Str(STR.FULL_IN_TROOP))
        end

    end

    -- clear
    if self._maskLayer then
        self._maskLayer:removeFromParent(true)
        self._maskLayer = nil
    end
    if self._movingSprite then
        self._movingSprite:removeFromParent()
        self._movingSprite = nil
    end
    if self._selectCardList then
        self._selectCardList:setIsScrollEnabled(true)
    end
end

function _M:createMovingSpriteAndMaskLayer(item)
    local toList = self._troopList

    local srcPos = item:convertToWorldSpace(cc.p(lc.w(item) / 2, lc.h(item) / 2))
    srcPos = self:convertToNodeSpace(srcPos)

    local infoId = item._infoId

    local thumbnail = CardThumbnail.create(infoId, THUMBNAIL_SCALE)
    self:addChild(thumbnail, ClientData.ZOrder.ui + 2)
    self._movingSprite = thumbnail
    
    self._movingSprite._srcPos = srcPos
    self._movingSprite._abc = 1
    self._movingSprite:setPosition(cc.pAdd(srcPos, cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition())))

    local startPos = toList:convertToWorldSpace(cc.p(0, 0))
    startPos = self:convertToNodeSpace(startPos)
    startPos.x = 0
    local stencilRect = cc.rect(startPos.x, startPos.y, lc.w(self), lc.h(toList))

    local mask = cc.LayerColor:create(cc.c4b(0, 0, 0, 192), lc.w(self), lc.h(self))
    self._maskLayer = V.createClipNode(mask, stencilRect, true)
    self:addChild(self._maskLayer, ClientData.ZOrder.ui + 1)

    -- The separator pos between toList and fromList
    self._separatorPos = startPos.y + stencilRect.height
end

function _M:remainItemFromList()
    local itemList = {}

    local items = self._troopList:getItems()
    for i = #items, 1, -1 do
        local layout = items[i];

        local inList = false
        for _, card in ipairs(P._playerFindLadder._troopCards) do
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

function _M:playAction(startPos, infoId)
    local endPos = cc.p(lc.cw(self), lc.ch(self._troopList))

    local items = self._troopList:getItems()
    for _, item in ipairs(items) do
        if item._card._infoId == infoId then
            endPos = self:convertToNodeSpace(item:convertToWorldSpace(cc.p(lc.cw(item), lc.ch(item))))
            break
        end
    end

    local node = cc.Node:create()
    lc.addChildToPos(self, node, startPos)

    local par1 = Particle.create("sz1")
    lc.addChildToCenter(node, par1)

    local par2 = Particle.create("sz2")
    lc.addChildToCenter(node, par2)

    node:setScale(2.0)
    node:runAction(lc.sequence(
        lc.moveTo(0.4, endPos),
        lc.call(function () 
            par1:setDuration(0.1)
            par2:setDuration(0.1)
        end),
        lc.delay(1.0),
        lc.remove()
        ))

end

-----------------------------------------------------------
-- battle field

function _M:enterBattleField()
    if self._battleLayer ~= nil then return end

    self:hideSelectCards()
    
    -- init
    local layer = lc.createNode(self:getContentSize())
    lc.addChildToCenter(self, layer, 100)
    self._battleLayer = layer

    local troopArea = self:createTroopArea(layer)
    self:updateTroopList()

    -- battle filed
    local bg = lc.createSprite({_name = "img_troop_bg_3", _crect = cc.rect(20, 22, 1, 1), _size = cc.size(750, 360)})
    lc.addChildToPos(layer, bg, cc.p(lc.cw(layer), lc.h(layer) - lc.ch(bg) - 20))

    local line = lc.createSprite({_name = "img_divide_line_10", _crect = cc.rect(1, 14, 1, 1), _size = cc.size(3, lc.h(bg) - 20)})
    lc.addChildToPos(bg, line, cc.p(lc.cw(bg), lc.ch(bg)))

    -- win and lose
    local winTitle = V.createTTF(lc.str(STR.BATTLE_WIN_COUNT), V.FontSize.M2, V.COLOR_GLOW)
    lc.addChildToPos(bg, winTitle, cc.p(lc.cw(bg) - 190, lc.h(bg) - 30))
    winTitle:enableShadow(lc.Color4B.black)

    local loseTitle = V.createTTF(lc.str(STR.BATTLE_LOSE_COUNT), V.FontSize.M2, V.COLOR_GLOW_BLUE)
    lc.addChildToPos(bg, loseTitle, cc.p(lc.cw(bg) - 190, lc.ch(bg) - 50))
    loseTitle:enableShadow(lc.Color4B.black)
    
    local winBg = lc.createSprite("img_troop_win")
    lc.addChildToPos(bg, winBg, cc.p(lc.x(winTitle), lc.bottom(winTitle) - lc.ch(winBg)))

    local countLabel = V.createTTF("0", 60)
    lc.addChildToPos(winBg, countLabel, cc.p(lc.cw(winBg), lc.ch(winBg)))
    countLabel:enableShadow(lc.Color4B.black)
    self._winCound = countLabel

    self._loseSprites = {}
    for i = 1, 3 do
        local spr = lc.createSprite("img_troop_bg_4")
        lc.addChildToPos(bg, spr, cc.p(lc.x(loseTitle) + 80 * (i - 2), lc.bottom(loseTitle) - lc.ch(spr) - 10))

        local icon = lc.createSprite("img_troop_x")
        lc.addChildToPos(spr, icon, cc.p(lc.cw(spr), lc.ch(spr)))
        self._loseSprites[i] = icon
    end

    -- reward
    local rewardTitle = V.createTTF(lc.str(STR.BATTLE_WIN_REWARD), V.FontSize.M2, V.COLOR_GLOW)
    lc.addChildToPos(bg, rewardTitle, cc.p(lc.cw(bg) + 190, lc.h(bg) - 30))
    rewardTitle:enableShadow(lc.Color4B.black)

    local bonesNames = {"1baoxiang", "2baoxiang", "3baoxiang", "4baoxiang", "5baoxiang"}
    local chestInfo = Data._propsInfo[Data.PropsId.ladder_chest + P._playerFindLadder._winCount + 1]

    local btn = V.createShaderButton(nil, function ()
        require("LadderChestForm").create(chestInfo._id):show()
    end)
    btn:setContentSize(cc.size(160, 130))
    lc.addChildToPos(bg, btn, cc.p(lc.x(rewardTitle), lc.y(rewardTitle) - 100))

    local bones = DragonBones.create(bonesNames[chestInfo._picId - 7820 + 1])
    lc.addChildToCenter(btn, bones)
    bones:setScale(0.6)
    bones:gotoAndPlay("effect4")

    local str = string.format("%s: %d/%d", lc.str(STR.BATTLE_WIN_PROGRESS), 0, 0)
    local progressTip = V.createTTF(str, V.FontSize.M2, V.COLOR_GLOW_BLUE)
    lc.addChildToPos(bg, progressTip, cc.p(lc.cw(bg) + 190, lc.ch(bg) - 50))
    progressTip:enableShadow(lc.Color4B.black)
    self._progressTip = progressTip

    local bar = V.createProgressBar(260)
    lc.addChildToPos(bg, bar, cc.p(lc.x(progressTip), lc.bottom(progressTip) - 40))
    self._progressBar = bar

    -- btn
    local btn = V.createScale9ShaderButton("img_btn_1", function(sender) 
        self:onFindingBattle()
    end, V.CRECT_BUTTON, 180)
    lc.addChildToPos(bg, btn, cc.p(lc.cw(bg), 0))
    btn:addLabel(Str(STR.BATTLE))
    self._btnFind = btn

    local btnLog = V.createScale9ShaderButton("img_btn_1_s", function() 
        require("LogForm").create(Battle_pb.PB_BATTLE_WORLD_LADDER_EX):show() 
    end, V.CRECT_BUTTON_S, 100)
    lc.addChildToPos(layer, btnLog, cc.p(lc.w(layer) - lc.cw(btnLog) -20, lc.top(troopArea) + lc.ch(btnLog)))
    btnLog:addLabel(Str(STR.LOG))  
    
    local btnGiveup = V.createScale9ShaderButton("img_btn_3_s", function(sender) 
        require("Dialog").showDialog(Str(STR.CONFIRM_TO_GIVEUP), function () self:onFinishBattle() end)
    end, V.CRECT_BUTTON_S, 100)
    lc.addChildToPos(layer, btnGiveup, cc.p(lc.left(btnLog) - lc.cw(btnGiveup) -20, lc.y(btnLog)))
    btnGiveup:addLabel(Str(STR.GIVEUP))
    self._btnGiveup = btnGiveup  
    
    local btn = V.createScale9ShaderButton("img_btn_3", function(sender) 
        self:onFinishBattle()
    end, V.CRECT_BUTTON, 180)
    lc.addChildToPos(bg, btn, cc.p(lc.cw(bg), 0))
    btn:addLabel(Str(STR.DONE))
    self._btnFinish = btn

    self:updateBattleField()
end

function _M:updateBattleField()
    self._winCound:setString(P._playerFindLadder._winCount)
    
    self._progressBar._bar:setPercent(P._playerFindLadder._winCount / P._playerFindLadder.MAX_BATTLE_COUNT * 100)
    
    local str = string.format("%s: %d/%d", lc.str(STR.BATTLE_WIN_PROGRESS), P._playerFindLadder._winCount, P._playerFindLadder.MAX_BATTLE_COUNT)
    self._progressTip:setString(str)

    local count, monsterCount, magicCount, trapCount = P._playerFindLadder:getTroopCardCount()
    local str = string.format(lc.str(STR.FIND_ARENA_TIPS), count, P._playerFindLadder.MAX_TROOP_COUNT, monsterCount, magicCount + trapCount) 
    self._troopDescLabel:setString(str)

    for i = 1, #self._loseSprites do
        self._loseSprites[i]:setVisible(i <= P._playerFindLadder._loseCount)
    end

    local isFinish = (P._playerFindLadder._winCount >= P._playerFindLadder.MAX_BATTLE_COUNT) or (P._playerFindLadder._loseCount >= P._playerFindLadder.MAX_LOSE_COUNT)
    self._btnFind:setVisible(not isFinish)
    self._btnGiveup:setVisible(not isFinish)
    self._btnFinish:setVisible(isFinish)
end

function _M:hideBattleField()
    if not self._battleLayer then
        return
    end

    self:releaseTroopCards()

    self._battleLayer:removeFromParent()
    self._battleLayer = nil
    self._troopList = nil
end

return _M