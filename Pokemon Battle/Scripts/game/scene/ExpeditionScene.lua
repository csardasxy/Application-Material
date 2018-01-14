local _M = class("ExpeditionScene", require("BaseUIScene"))

_M.PlayerType = {
    npc = 1,
    boss = 2,
}

function _M.create(...)
    return lc.createScene(_M, ...)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.expedition, STR.COPY_EXPEDITION, require("BaseUIScene").STYLE_SIMPLE, true) then return false end

    --bg
    self._bg:setTexture("res/jpg/copy_bg.jpg")
    self._bg:setPosition(cc.p(V.SCR_CW, lc.ch(self._bg)))

    -- bottom
    --[[local bottom = lc.createSprite({_name = 'img_com_bg_27', _crect = V.CRECT_COM_BG27, _size = cc.size(V.SCR_W, 60)}) 
    lc.addChildToPos(self, bottom, cc.p(V.SCR_CW, lc.ch(bottom)))
    bottom:setOpacity(200)]]

    local layer = V.createShaderButton(nil, function () self:hideInfo() end)
    layer:setContentSize(V.SCR_SIZE)
    lc.addChildToCenter(self, layer, -1)

    local size = cc.size(V.SCR_W - 200, V.SCR_H - 310)
    local node = lc.createNode()
    node:setContentSize(size)
    node:setAnchorPoint(cc.p(0.5, 0.5))
    lc.addChildToPos(self, node, cc.p(V.SCR_CW, size.height / 2 + 70))
    self._playerLayer = node
        
    -- ui
    local btn = V.createShaderButton("img_btn_wheel", function () 
        lc.pushScene(require("LotteryScene").create())
    end)
    lc.addChildToPos(self, btn, cc.p(V.SCR_W - lc.cw(btn) - 16, lc.ch(btn) + 16))
    self._btnLottery = btn

    local label = V.createBMFont(V.BMFont.huali_26, lc.str(STR.LOTTERY))
    lc.addChildToPos(btn, label, cc.p(lc.cw(btn), 10), 10)

    -- count down
    local label = V.createBMFont(V.BMFont.huali_26, lc.str(STR.REFRESH_COUNTDOWN))
    lc.addChildToPos(self, label, cc.p(V.SCR_CW, lc.ch(label) + 16))
    self._countDownLabel = label

    -- data  
    ClientData._expeditionNpcInfos = {}
    ClientData._expeditionBossInfo = {}
    ClientData._lotteryPower = 0
    self._lastNpcUpdate = 0
    self._lastBossUpdate = 0
    self._lastLotteryUpdate = 0
    self._nextRefresh = 0

    self._dropInfos = {}
    for _, info in pairs(Data._dropInfo) do
        if info._type == 1009 then
            self._dropInfos[#self._dropInfos + 1] = info
        end
    end
    table.sort(self._dropInfos, function (a, b) return a._value < b._value end)

    return true
end

function _M:syncData()
    _M.super.syncData(self)
    
    V.popScene()
end

function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
    
    if self._lastNpcUpdate ~= 0 then
        self:updateCountDown()
    end

    -- effect
    if not self._effectBones then
        local bones = DragonBones.create("maoxianditu")
        lc.addChildToCenter(self, bones)
        bones:gotoAndPlay("effect1")
        self._effectBones = bones
    end

    if not self._btnLottery._bones then
        local bones = DragonBones.create("choujiang")
        lc.addChildToCenter(self._btnLottery, bones)
        bones:gotoAndPlay("effect1")
        self._btnLottery._bones = bones
    end

    if self._nextRefresh == 0 then
        V.getActiveIndicator():show(Str(STR.WAITING))
        ClientData.sendGetExpeditionEx()
    end
end

function _M:onExit()
    _M.super.onExit(self)

    ClientData.removeMsgListener(self)

    self:clearCountDown()

    if self._effectBones then
        self._effectBones:removeFromParent()
        self._effectBones = nil
    end

    if self._btnLottery._bones then
        self._btnLottery._bones:removeFromParent()
        self._btnLottery._bones = nil
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/copy_bg.jpg"))
end

function _M:updatePlayers()
    self._playerLayer:removeAllChildren()

    self._playerItems = {}
    for i = 1, # ClientData._expeditionNpcInfos do
        local info = ClientData._expeditionNpcInfos[i]
        table.insert(self._playerItems, self:createPlayerItem(info))
    end

    if ClientData._expeditionBossInfo._type then
        local info = ClientData._expeditionBossInfo
        table.insert(self._playerItems, self:createPlayerItem(info))
    end
end

function _M:createPlayerItem(info)
    local pos = self:calRandomPos(info._randomSeed)
    local zorder = V.SCR_H - pos.y
    local playerIcon = string.format('img_expedition_avatar_%02d', info._avatar)
    local maskName = string.format('img_expedition_mark_%02d', info._level or 3)
    local bottomName = string.format('img_expedition_bottom_%02d', info._level or 3)

    local btn = V.createShaderButton(nil)
    btn._callback = function () return self:showInfo(info, btn) end
    btn:setPosition(pos)
    btn:setLocalZOrder(zorder)
    self._playerLayer:addChild(btn)
    btn._position = pos

    local avatarBg = lc.createSprite(maskName)
    btn:setContentSize(cc.size(lc.w(avatarBg) + 16, lc.h(avatarBg) + 16))
    btn:setAnchorPoint(cc.p(0.5, 0))
    lc.addChildToCenter(btn, avatarBg)
    avatarBg._pos = cc.p(avatarBg:getPosition())
    
    local avatar = lc.createSprite(playerIcon)
    local pos = cc.p(lc.cw(avatarBg) + 2, lc.h(avatarBg) - lc.ch(avatar) + 6)
    if info._type == _M.PlayerType.boss then
        pos.y = pos.y - 32
    end
    lc.addChildToPos(avatarBg, avatar, pos)
    avatar._posY = avatar:getPositionY()

    avatarBg:runAction(lc.rep(
        lc.sequence(lc.moveTo(0.5, cc.p(avatarBg._pos.x, avatarBg._pos.y - 5)), lc.moveTo(0.5, cc.p(avatarBg._pos.x, avatarBg._pos.y + 5)))
    ))

    local bottom = lc.createSprite(bottomName)
    lc.addChildToPos(btn, bottom, cc.p(lc.cw(btn), -10), -1)

    return btn
end

function _M:onSelectPlayer(info)
    local cost = self:getCost(info)
    if info._challengeCount == 0 and not V.checkGold(cost) then
        return
    end
        
    self:hideInfo()
    ClientData._battleFromCopy = {_type = Data.CopyType.expedition_ex}

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData._expeditionCurNpc = info._id + 1
    ClientData.sendWorldExpeditionEx(P._curTroopIndex, info._id, info._type == _M.PlayerType.boss)
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status
    
    if msgType == SglMsgType_pb.PB_TYPE_WORLD_GET_EXPEDITION_EX then
        V.getActiveIndicator():hide()

        local pbExpeditionEx = msg.Extensions[World_pb.SglWorldMsg.world_get_expedition_ex_resp]
        
        ClientData._expeditionNpcInfos = {}
        for i = 1, #pbExpeditionEx.troops do
            local pb = pbExpeditionEx.troops[i]
            local player = {}
            table.insert(ClientData._expeditionNpcInfos, player)

            player._type = _M.PlayerType.npc
            player._level = pb.level
            player._randomSeed = pb.random_position
            player._id = i - 1
            player._infoId = pb.troop_data.info.id
            player._avatar = pb.troop_data.info.avatar
            player._name = pb.troop_data.info.name
            player._challengeCount = pb.chanllenge_count
            player._nextRefresh = math.floor(pb.next_refresh / 1000)

            if player._avatar > 100 then
                player._avatar = math.floor(player._avatar / 100)
            end
        end 

        ClientData._expeditionBossInfo = {}
        if pbExpeditionEx:HasField("boss") then
            local pb = pbExpeditionEx.boss
            if pb.boss.info.avatar ~= 0 then 
                local player = ClientData._expeditionBossInfo

                player._type = _M.PlayerType.boss
                player._challengeCount = pb.chanllenge_count
                player._randomSeed = pb.random_position
                player._id = pb.boss.id
                player._infoId = pb.boss.info.id
                player._name = pb.boss.info.name
                player._avatar = pb.boss.info.avatar
                player._nextRefresh = math.floor(pb.next_refresh / 1000)
            end
        end

        ClientData._expeditionCurNpc = pbExpeditionEx.cur_npc
        ClientData._lotteryPower = pbExpeditionEx.lottery_power

        self._lastNpcUpdate = pbExpeditionEx.last_npc_update_time
        self._lastBossUpdate = pbExpeditionEx.last_boss_update_time
        self._lastLotteryUpdate = pbExpeditionEx.last_lottery_power_update_time
        self._nextRefresh = pbExpeditionEx.next_refresh

        self:updatePlayers()
        self:updateCountDown(true)

        return true
    end
end

function _M:calRandomPos(randomSeed, randomCount)
    if not randomCount then
        randomCount = 0
    end

    local func = function ()
        randomSeed = (randomSeed * 1103515245 + 12345) % 65536
        return randomSeed / 65536
    end

    local x = func() * lc.w(self._playerLayer)
    local y = func() * lc.h(self._playerLayer)

    if randomCount > 50 then
        return cc.p(x, y)
    end

    for i = 1, #self._playerItems do
        local pos = self._playerItems[i]._position

        if math.abs(pos.x - x) < 50 and math.abs(pos.y - y) < 50 then
            return self:calRandomPos(randomSeed, randomCount + 1)
        end
    end

    return cc.p(x, y)
end

function _M:showInfo(info, btn)
    local worldPos = btn:convertToWorldSpace(cc.p(lc.cw(btn), lc.ch(btn)))
    local pos = cc.p(worldPos.x, worldPos.y)
    local size = cc.size(370, 420)
    pos.x = pos.x + ((pos.x + size.width + lc.cw(btn)) < V.SCR_W and 1 or -1) * (size.width / 2 + lc.cw(btn))
    if pos.y - size.height / 2 < 50 then 
        pos.y = 50 + size.height / 2
    elseif pos.y + size.height / 2 > V.SCR_H - 60 then
        pos.y = V.SCR_H - 60 - size.height / 2
    end

    self:hideInfo()

    local layout = ccui.Layout:create()
    layout:setContentSize(size)
    layout:setAnchorPoint(0.5, 0.5)
    layout:setTouchEnabled(true)
    lc.addChildToPos(self, layout, pos)
    self._infoLayer = layout

    local bg = lc.createSprite({_name = "img_com_bg_50", _crect = cc.rect(42, 40, 1, 1), _size = size})
    lc.addChildToCenter(layout, bg)

    local vector = lc.createSprite("img_com_bg_51")
    local vectorPos = cc.p(pos.x > worldPos.x and (2 - lc.cw(vector)) or (lc.w(bg) + lc.cw(vector) - 2), lc.ch(bg) + worldPos.y - pos.y + 10)
    lc.addChildToPos(bg, vector, vectorPos)
    vector:setFlippedX(pos.x < worldPos.x)

    local btn = V.createScale9ShaderButton("img_btn_1", function(sender) 
        self:onSelectPlayer(info) 
    end, V.CRECT_BUTTON, 180)
    lc.addChildToPos(layout, btn, cc.p(lc.cw(layout), 0))
    btn:addLabel(lc.str(STR.CHALLENGE))

    local line = lc.createSprite("img_divide_line_5")
    lc.addChildToPos(bg, line, cc.p(lc.cw(bg), lc.h(bg) - 60))
    line:setScale(1.8, 0.5)

    local line = lc.createSprite("img_divide_line_5")
    lc.addChildToPos(bg, line, cc.p(lc.cw(bg), 150))
    line:setScale(1.8, 0.5)

    local characterInfo = Data._characterDescInfo[info._avatar]
    if characterInfo then
        --local name = V.createTTF(lc.str(characterInfo._nameSid), V.FontSize.M2, V.COLOR_GLOW_BLUE)
        local name = V.createTTF(info._name, V.FontSize.M2, V.COLOR_GLOW_BLUE)
        lc.addChildToPos(bg, name, cc.p(lc.cw(bg), lc.h(bg) - 34))

        local desc = V.createTTF(lc.str(characterInfo._descSid), V.FontSize.S2, nil, cc.size(size.width - 60, 0))
        lc.addChildToPos(bg, desc, cc.p(lc.cw(bg), lc.h(bg) - 90 - lc.ch(desc)))
    end

    local dropInfo = self._dropInfos[(info._level or 3) + 1]
    if dropInfo then
        local label = V.createBMFont(V.BMFont.huali_26, lc.str(STR.TASK))
        lc.addChildToPos(bg, label, cc.p(lc.cw(label) + 30, 120))
        label:setColor(V.COLOR_LABEL_LIGHT)

        local icon = IconWidget.createByInfoId(dropInfo._pid[1][1], dropInfo._pid[1][2])
        lc.addChildToPos(bg, icon, cc.p(lc.cw(bg), lc.y(label) - 20))
        icon:setScale(0.8)
        icon._countBg:setVisible(true)
    end

    if info._challengeCount then
        local label = V.createTTF(lc.str(STR.REMAIN_CHALLENGE_TIMES)..": "..info._challengeCount, V.FontSize.S2)
        lc.addChildToPos(bg, label, cc.p(lc.cw(label) + 30, 150 + lc.ch(label) + 10))

        if info._challengeCount == 0 then
            btn._label:setPosition(lc.cw(btn) - 44, lc.ch(btn))

            local gold = lc.createSprite("img_icon_res1_s")
            lc.addChildToPos(btn, gold, cc.p(lc.cw(btn) + 4, lc.ch(btn)))

            local cost = self:getCost(info)
            local label = V.createBMFont(V.BMFont.huali_26, -cost)
            lc.addChildToPos(btn, label, cc.p(lc.cw(btn) + 50, lc.ch(btn)))
        end
    end

    local seconds = info._nextRefresh - ClientData.getCurrentTime()
    local label = V.createTTF(lc.str(STR.LEAVE_COUNTDOWN)..": "..self:getRemainSecondsStr(seconds), V.FontSize.S2)
    label:setAnchorPoint(0, 0.5)
    label._seconds = seconds
    label:runAction(lc.rep(lc.sequence(
        lc.delay(1.0),
        function ()
            label._seconds = math.max(0, label._seconds - 1)
            label:setString(lc.str(STR.LEAVE_COUNTDOWN)..": "..self:getRemainSecondsStr(label._seconds))
        end
    )))
    lc.addChildToPos(bg, label, cc.p(30, 150 + lc.ch(label) + 34))
end

function _M:hideInfo()
    if self._infoLayer then
        self._infoLayer:removeFromParent()
        self._infoLayer = nil
    end
end

function _M:updateCountDown(isForce)
    if (not isForce) and self._countDown and self._countDown <= 0 then
        self:clearCountDown()

        V.getActiveIndicator():show(Str(STR.WAITING))
        ClientData.sendGetExpeditionEx()
        return
    end

    if isForce or (not self._countDown) then
        self._countDown = math.floor(self._nextRefresh / 1000 - ClientData.getCurrentTime())

        self._countDownLabel:stopAllActions()
        self._countDownLabel:runAction(lc.rep(lc.sequence(
            lc.delay(1.0),
            function ()
                self._countDown = self._countDown - 1
                self:updateCountDown()
            end
        )))
    end

    self._countDownLabel:setString(lc.str(STR.REFRESH_COUNTDOWN).." "..self:getRemainSecondsStr(self._countDown))
end

function _M:clearCountDown()
    self._countDown = nil
    self._countDownLabel:stopAllActions()
end

function _M:getCost(info)
    local cost = 0
    if info._type == _M.PlayerType.boss then
        cost = Data._globalInfo._expeditionBossCost
    else
        local costs = {Data._globalInfo._expeditionSimpleNPCCost, Data._globalInfo._expeditionMediumNPCCost, Data._globalInfo._expeditionHardNPCCost}
        cost = costs[info._level + 1]
    end
    return cost
end

function _M:getRemainSecondsStr(seconds)
    local hour = math.floor(seconds / 3600)
    local minute = math.floor((seconds - hour * 3600) / 60)
    local second = math.floor(seconds % 60)
    local str = string.format("%d:%02d:%02d", hour, minute, second)
    return str
end

return _M