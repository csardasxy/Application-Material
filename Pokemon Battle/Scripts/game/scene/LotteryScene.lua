local _M = class("LotteryScene", require("BaseUIScene"))

local TOTAL_COUNT = 12
local MULTI_TIMES = 10

function _M.create(...)
    return lc.createScene(_M, ...)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.lottery, STR.LOTTERY, require("BaseUIScene").STYLE_SIMPLE, true) then return false end

    -- data
    local infos = {}
    for _, info in pairs(Data._dropInfo) do
        if info._type == 1008 then
            infos[#infos + 1] = info
        end
    end
    table.sort(infos, function (a, b) return a._value < b._value end)

    local hour, day, month, year = ClientData.getServerDate()
    self._info = infos[month]

    self._btnMulti = self:createBtn("img_wheel_multi", MULTI_TIMES, function(sender) self:onMulti() end)
    lc.addChildToPos(self, self._btnMulti, cc.p(lc.w(self) - lc.cw(self._btnMulti) + 42, lc.ch(self._btnMulti) - 58))

    self:createWheel()
    self:createBar()
    
    return true
end

function _M:syncData()
    _M.super.syncData(self)
    
    V.popScene(true)
end


function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
    V.getResourceUI():setMode(Data.PropsId.lottery_token)

    self:updateUi()
end

function _M:onExit()
    _M.super.onExit(self)

    ClientData.removeMsgListener(self)
    V.getResourceUI():setMode(Data.ResType.gold)
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/lottery_bg.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/wheel_bg.jpg"))
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_WORLD_LOTTERY then
        V.getActiveIndicator():hide()

        -- lottery
        local pbRes = msg.Extensions[World_pb.SglWorldMsg.world_lottery_resp]
        if #pbRes == 1 then
            self:startStopWheel({{info_id = pbRes[1].info_id, num = pbRes[1].num, level = 1}})
        else
            local bonuses = {}
            for i = 1, #pbRes do
                bonuses[pbRes[i].info_id] = (bonuses[pbRes[i].info_id] or 0) + pbRes[i].num
            end
            local data = {}
            for k, v in pairs(bonuses) do
                data[#data + 1] = {info_id = k, num = v, level = 1}
            end

            self:showLotteryReward(data)
        end

        return true
    end

    return false
end

function _M:createWheel()
    --bg
    self._bg:setTexture("res/jpg/lottery_bg.jpg")
    self._bg:setLocalZOrder(-2)

    local bg = lc.createSpriteWithMask("res/jpg/wheel_bg.jpg")
    lc.addChildToPos(self, bg, cc.p(V.SCR_CW + 36, V.SCR_CH - 30))
    self._wheel = bg

    local spr = lc.createSprite("img_lottery_1")
    lc.addChildToPos(self, spr, cc.p(lc.x(bg) + 2, lc.y(bg) + lc.ch(bg) + 4))

    local spr = lc.createSprite("img_lottery_3")
    lc.addChildToPos(self, spr, cc.p(lc.x(bg), lc.y(bg) - lc.ch(bg) - 20))

    local spr = lc.createSprite("img_lottery_2")
    lc.addChildToPos(self, spr, cc.p(lc.x(bg) + lc.cw(bg) + 14, lc.y(bg) - 4))

    local spr = lc.createSprite("img_lottery_2")
    lc.addChildToPos(self, spr, cc.p(lc.x(bg) - lc.cw(bg) - 14, lc.y(bg) - 4))
    spr:setFlippedX(true)

    local bones = DragonBones.create("maoxian")
    lc.addChildToPos(self, bones, cc.p(lc.x(bg) - 36, lc.y(bg) + 30))
    bones:gotoAndPlay("effect1")
    self._bones = bones

    -- button
    self._btnSingle = self:createBtn("img_wheel_start", 1, function(sender) self:onSingle() end)
    lc.addChildToPos(self, self._btnSingle, cc.p(lc.x(bg), lc.y(bg) + 30))

    -- reward
    local rewardNode = cc.Node:create()
    lc.addChildToCenter(bg, rewardNode)
    self._rewardNode = rewardNode

    local chestNode = cc.Node:create()
    lc.addChildToCenter(self._wheel, chestNode)
    self._chestNode = chestNode

    local urInfo = self._info._pid[TOTAL_COUNT + 1]

    for i = 1, TOTAL_COUNT do
        local id = self._info._pid[i][1]
        local count = self._info._pid[i][2]

        local rot = 360 / TOTAL_COUNT * (i - 0.5)
        local rad = math.rad(rot)
        local pos = cc.p(250 * math.sin(rad), 250 * math.cos(rad))
        local countPos = cc.p(190 * math.sin(rad), 190 * math.cos(rad))

        if id == Data.ResType.gold or id == Data.ResType.ingot or id == Data.PropsId.lottery_token then
            local str = ""
            if id == Data.ResType.gold then
                str = "img_wheel_gold_"..(count < 30 and 1 or (count < 60 and 2 or 3))
            elseif id == Data.ResType.ingot  then
                str = "img_wheel_gem_"..(count < 50 and 1 or 2)
            else
                str = "img_wheel_lottery"
            end

            local icon = lc.createSprite(str)
            lc.addChildToPos(rewardNode, icon, pos)
            icon:setRotation(rot)

        else
            local icon = require("IconWidget").createByInfoId(id, count, 0)
            lc.addChildToPos(rewardNode, icon, pos)
            icon:setScale(0.8)
            icon:setRotation(rot)
        end

        local count = V.createBMFont(V.BMFont.huali_26, "x"..count)
        lc.addChildToPos(rewardNode, count, countPos)
        count:setRotation(rot)

        local urIcon = require("IconWidget").createByInfoId(urInfo[1], urInfo[2], 0)
        lc.addChildToPos(chestNode, urIcon, pos)
        urIcon:setScale(0.8)
        urIcon:setRotation(rot)
    end

end

function _M:createBar()
    -- bar
    local progressBar = ccui.LoadingBar:create()
    progressBar:loadTexture("img_expedition_bar_bg", ccui.TextureResType.plistType)
    progressBar:setAnchorPoint(0.5, 0.5)
    progressBar:setRotation(-90)
    lc.addChildToPos(self, progressBar, cc.p(V.SCR_CW - 364, V.SCR_CH - 80))
    self._lotteryBar = progressBar

    local barTotal = V.createBMFont(V.BMFont.huali_32, Data._globalInfo._expeditionEnergyProgress)
    lc.addChildToPos(self, barTotal, cc.p(lc.x(progressBar), lc.y(progressBar) - 20))

    local barLine = V.createBMFont(V.BMFont.huali_32, "----")
    lc.addChildToPos(self, barLine, cc.p(lc.x(progressBar), lc.y(progressBar)))

    local barCount = V.createBMFont(V.BMFont.huali_32, 0)
    lc.addChildToPos(self, barCount, cc.p(lc.x(progressBar), lc.y(progressBar) + 20))
    self._lotteryCount = barCount

    local urInfo = self._info._pid[TOTAL_COUNT + 1]
    local urIcon = require("IconWidget").createByInfoId(urInfo[1], urInfo[2], 0)
    lc.addChildToPos(self, urIcon, cc.p(lc.x(progressBar), V.SCR_CH + 246))
    urIcon:setScale(1.1)    
end

function _M:createBtn(img, times, callback)
    local btn = V.createShaderButton(img, callback)
    btn:setDisabledShader(V.SHADER_DISABLE)

    local lottery = lc.createSprite("img_icon_props_s"..Data.PropsId.lottery_token)
    lc.addChildToPos(btn, lottery, cc.p(lc.cw(btn) - 20, lc.ch(btn) + 10))
    btn._lottery = lottery

    local label = V.createBMFont(V.BMFont.huali_32, times)
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(lottery, label, cc.p(lc.w(lottery) + 10, lc.ch(lottery)))
    lottery._label = label

    local ingot = lc.createSprite("img_icon_res3_s")
    lc.addChildToPos(btn, ingot, cc.p(lc.cw(btn) - (times == 1 and 20 or 28), lc.ch(btn) + 10))
    btn._ingot = ingot

    local label = V.createBMFont(V.BMFont.huali_32, Data._globalInfo._expeditionDialCost * times)
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(ingot, label, cc.p(lc.w(ingot) + 10, lc.ch(ingot)))
    ingot._label = label

    return btn
end

function _M:updateUi()
    if P._propBag:hasProps(Data.PropsId.lottery_token, 1) then
        self._btnSingle._lottery:setVisible(true)
        self._btnSingle._ingot:setVisible(false)
    else
        self._btnSingle._lottery:setVisible(false)
        self._btnSingle._ingot:setVisible(true)
        self._btnSingle._ingot._label:setColor(P:hasResource(Data.ResType.ingot, Data._globalInfo._expeditionDialCost) and lc.Color3B.white or lc.Color3B.red)
    end

    if P._propBag:hasProps(Data.PropsId.lottery_token, MULTI_TIMES) then
        self._btnMulti._lottery:setVisible(true)
        self._btnMulti._ingot:setVisible(false)
    else
        self._btnMulti._lottery:setVisible(false)
        self._btnMulti._ingot:setVisible(true)
        self._btnMulti._ingot._label:setColor(P:hasResource(Data.ResType.ingot, Data._globalInfo._expeditionDialCost * MULTI_TIMES) and lc.Color3B.white or lc.Color3B.red)
    end

    if ClientData._lotteryPower == Data._globalInfo._expeditionEnergyProgress then
        self._rewardNode:setVisible(false)
        self._chestNode:setVisible(true)
    else
        self._rewardNode:setVisible(true)
        self._chestNode:setVisible(false)
    end

    self:updateBar()
end

function _M:updateBar()
    local percent = math.pow(ClientData._lotteryPower / Data._globalInfo._expeditionEnergyProgress, 0.5)
    self._lotteryBar:setPercent(percent * 100)
    self._lotteryCount:setString(ClientData._lotteryPower)
end

function _M:onSingle()
    if P._propBag:hasProps(Data.PropsId.lottery_token, 1) or V.checkIngot(Data._globalInfo._expeditionDialCost) then
        if not P._propBag:hasProps(Data.PropsId.lottery_token, 1) then
            require("Dialog").showDialog(Str(STR.CONFIRM_LOTTERY_BY_INGOT, true), function()
                self:sendLottery(1)
                self:startWheel()
            end) 
        else
            self:sendLottery(1)
            self:startWheel()
        end
    end
end

function _M:onMulti()
    if P._propBag:hasProps(Data.PropsId.lottery_token, MULTI_TIMES) or V.checkIngot(Data._globalInfo._expeditionDialCost * MULTI_TIMES) then
        if not P._propBag:hasProps(Data.PropsId.lottery_token, MULTI_TIMES) then
            require("Dialog").showDialog(Str(STR.CONFIRM_LOTTERY_BY_INGOT, true), function()
                self:sendLottery(MULTI_TIMES)
            end) 
        else
            self:sendLottery(MULTI_TIMES)
        end
    end
end

function _M:sendLottery(times)
    self:enableBtns(false)
    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendWorldLottery(P._propBag:hasProps(Data.PropsId.lottery_token, times), times)
end

function _M:startWheel()
    self._wheel:stopAllActions()
    self._wheel:setRotation(0)
    self._wheel:runAction(lc.rep( 
        lc.rotateBy(1.0, 720)
        )) 

    if not self._wheelParticle then
        local par = Particle.create("choujiangtexiao")
        lc.addChildToPos(self, par, cc.p(self._bg:getPosition()))
        self._wheelParticle = par
    end

    if self._bones then
        self._bones:gotoAndPlay("effect2")
    end

    self:stopWheelEffect()
    if ClientData._isEffectOn then
        local playWheelEffect = function() self._effectId = cc.SimpleAudioEngine:getInstance():playEffect("res/audio/e_find_match.wav", false) end
        self._effectScheduleId = lc.Scheduler:scheduleScriptFunc(playWheelEffect, 0.95, false)
        playWheelEffect()
    end
end

function _M:startStopWheel(data)
    local index = 0
    for i = 1, #self._info._pid do
        local info = self._info._pid[i]
        if data[1].info_id == info[1] and data[1].num == info[2] then
            index = i
            break
        end
    end 

    local rot = 720 - (index - 0.5) * 360 / TOTAL_COUNT - self._wheel:getRotation() % 360
    self._wheel:stopAllActions()
    self._wheel:runAction(lc.sequence( 
        lc.ease(lc.rotateBy(2.0, rot), "O", 1.8),
        lc.call(function () self:stopWheel(data) end)
        ))

    self:showCostEffect()
end

function _M:stopWheel(data)
    self._wheel:stopAllActions()
    self._wheel:runAction(lc.sequence( 
        lc.delay(1.0),
        lc.call(function () 
            self:showLotteryReward(data)
        end)
        ))

    if self._wheelParticle then
        self._wheelParticle:setDuration(0.1)
        self._wheelParticle = nil
    end

    if self._bones then
        self._bones:gotoAndPlay("effect1")
    end

    self:stopWheelEffect()
end

function _M:stopWheelEffect()
    if self._effectId then
        cc.SimpleAudioEngine:getInstance():stopEffect(self._effectId)
        lc.Audio.stopAudio(AUDIO.E_FIND_MATCH_OVER)
        self._effectId = nil
    end

    lc.Audio.stopAudio(AUDIO.E_FIND_MATCH_OVER)

    if self._effectScheduleId then
        lc.Scheduler:unscheduleScriptEntry(self._effectScheduleId)
        self._effectScheduleId = nil
    end
end

function _M:showCostEffect()
    -- power
    local label = V.createBMFont(V.BMFont.huali_32, "+1")
    lc.addChildToPos(self, label, cc.p(self._lotteryBar:getPosition()))
    label:runAction(lc.sequence(
        lc.moveBy(1.5, cc.p(0, 75)), 
        lc.remove()))

    self:updateBar()

    -- cost
    local icon, value
    if self._btnSingle._lottery:isVisible() then
        icon = lc.createSprite("img_icon_props_s"..Data.PropsId.lottery_token)
        value = V.createBMFont(V.BMFont.huali_32, "-1")
    else
        icon = lc.createSprite("img_icon_res3_s")
        value = V.createBMFont(V.BMFont.huali_32, -Data._globalInfo._expeditionDialCost)
    end
    lc.addChildToPos(self, icon, cc.p(lc.x(self._btnSingle) - 20, lc.y(self._btnSingle) + 30))
    lc.addChildToPos(icon, value, cc.p(lc.w(icon) + 10, lc.ch(icon)))
    value:setAnchorPoint(0, 0.5)

    icon:runAction(lc.sequence(
        lc.moveBy(1.5, cc.p(0, 75)), 
        lc.remove()))
end

function _M:showLotteryReward(data)
    local RewardPanel = require("RewardPanel")
    RewardPanel.create(data, RewardPanel.MODE_LOTTERY):show()

    self:updateUi()
    self:enableBtns(true)
end

function _M:enableBtns(isEnable)
    self._btnSingle:setEnabled(isEnable)
    self._btnMulti:setEnabled(isEnable)
    self._titleArea._btnBack:setEnabled(isEnable)
end

return _M