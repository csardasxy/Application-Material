local _M = class("TimesShopArea", lc.ExtendCCNode)
local CardInfoPanel = require("CardInfoPanel")
--local AREA_WIDTH_MAX = 800

function _M.create(scene, info, areaW, areaH)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(areaW, areaH)
    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        elseif evtName == "cleanup" then
            area:onCleanUp()
        end
    end)
    area:init(scene, info)
    return area

end

function _M:init(scene, info)
    self._curRecruitInfo = info
    self._packageCards = {}
    self._tavernScene = scene

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    local chest = lc.createSpriteWithMask("res/jpg/times_limit_chest.jpg")
    lc.addChildToPos(self, chest, cc.p(lc.cw(self), lc.ch(self) + 40))
    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendCardBoxInfo(info._value)

    local cardsNode = lc.createNode()
    lc.addChildToPos(self, cardsNode, cc.p(lc.cw(self), lc.ch(self) + 20))
    self._cardsNode = cardsNode

    local icoName = ClientData.getPropIconName(Data.PropsId.times_package_ticket)
    local resNeed = info._param[2]

    local btn = V.createResConsumeButton(230, 100, icoName, resNeed, Str(STR.SETTING_OPEN), "img_btn_1_s")
    lc.offset(btn._resArea, 0, -10)
    lc.offset(btn._label, 0, -10)
    lc.addChildToPos(self, btn, cc.p(lc.cw(self), lc.bottom(chest) - lc.ch(btn) - 0))
    btn:setDisabledShader(V.SHADER_DISABLE)
    btn._callback = function() self:sendBuyPackage() end
    self._btn = btn

    local remianTimes = 5
    local remainNumLabel = V.createTTF(string.format(Str(STR.REMAIN_BUY_TIMES), remianTimes), V.FontSize.S1)
    lc.addChildToPos(chest, remainNumLabel, cc.p(lc.cw(chest), 45))
    self._remainNumLabel = remainNumLabel

    local activityInfo = ClientData.getActivityByParam(info._value - 200000)
    local time = V.createBMFont(V.BMFont.huali_26, ClientData.getActivityDurationStr(activityInfo))
    lc.addChildToPos(self, time, cc.p(lc.cw(self), lc.h(self) - 20))
end

function _M:showCardBox()
    local cards = {}
    for _, card in ipairs(self._packageCards) do
        local cardSp = require("CardThumbnail").create(card._infoId, 0.65)
        local cardBtn = V.createShaderButton(nil, function(sender) CardInfoPanel.create(card._infoId, 1, CardInfoPanel.OperateType.view):show() end)
        cardBtn:setContentSize(cardSp:getContentSize())
        lc.addChildToCenter(cardBtn, cardSp)
        table.insert(cards, cardBtn)
    end
    lc.addNodesToCenterH(self._cardsNode, cards, 20)
    self:refreshView()
end

function _M:refreshView()
    local recruitInfo = self._curRecruitInfo
    local resNeed = recruitInfo._param[2]
    self._btn._resLabel:setColor(P._propBag:hasProps(Data.PropsId.times_package_ticket, resNeed) and V.COLOR_TEXT_WHITE or V.COLOR_TEXT_RED)
    local remianTimes = 5
    for _, card in pairs(self._packageCards) do
        remianTimes = remianTimes - P._playerCard:getCardCount(card._infoId)
    end
    self._remainNumLabel:setString(string.format(Str(STR.REMAIN_BUY_TIMES), remianTimes))
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_CARD_LOTTERY then
        if self._tavernScene._detailInfoOnce then return false end
        local newCards = {}
        local objTypes = {}
        local objs = msg.Extensions[Card_pb.SglCardMsg.card_lottery_resp]
        for _, obj in ipairs(objs) do
            local objType = Data.getType(obj.info_id)
            if P._playerCard:addCard(obj.info_id, obj.num) then
                objTypes[objType] = true
            end
            table.insert(newCards, {_infoId = obj.info_id, _num = obj.num})
        end
        for type in pairs(objTypes) do
            P._playerCard:sendCardListDirty(type)
        end

        V.getActiveIndicator():hide()

        require("RewardCardPanel").create(Str(STR.GET)..Str(STR.CARD), newCards):show()
        lc.Audio.playAudio(AUDIO.E_CARD_GET)

        self:refreshView()

    elseif msgType == SglMsgType_pb.PB_TYPE_CARDBOX_INFO then
        if self._tavernScene._detailInfoOnce then return false end
        local objs = msg.Extensions[Card_pb.SglCardMsg.card_box_info_resp]

        self._packageCards = {}
        for i = 1, #objs do
            self._packageCards[i] = {_infoId = objs[i].info_id, _getNum = objs[i].get_num, _remainNum = objs[i].remain_num}
        end

        V.getActiveIndicator():hide()
        self:showCardBox()

    end

    return false
end

function _M:sendBuyPackage()
    lc.Audio.playAudio(AUDIO.E_TAVERN_BUY_PACKAGE)
    
    local recruitInfo = self._curRecruitInfo

    local remianTimes = 5
    for _, card in pairs(self._packageCards) do
        remianTimes = remianTimes - P._playerCard:getCardCount(card._infoId)
    end

    local resNeed = recruitInfo._param[2]
    if not P._propBag:hasProps(Data.PropsId.times_package_ticket, resNeed) then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[Data.PropsId.times_package_ticket]._nameSid)))
        require("ExchangeResForm").create(Data.PropsId.times_package_ticket):show()
        return false
    elseif remianTimes <= 0 then
        ToastManager.push(Str(STR.TIMES_NOT_ENOUGH))
        return false
    else
        V.getActiveIndicator():show(Str(STR.RECRUITING))
        ClientData.sendCardLottery(recruitInfo._value, false, true)
        P._propBag:changeProps(Data.PropsId.times_package_ticket, -resNeed)
        self:refreshView()
    end
end

function _M:onEnter()
    self:refreshView()
    
    local listeners = {}

    table.insert(listeners, lc.addEventListener(Data.Event.prop_dirty, function(evt)
        if evt._data._infoId == Data.PropsId.times_package_ticket then 
            self:refreshView()
        end
    end))

    self._listeners = listeners
end

function _M:onExit()
end

function _M:onCleanUp()
    for _,v in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(v)
    end
    ClientData.removeMsgListener(self)
    lc.TextureCache:removeTextureForKey("res/jpg/times_limit_chest.jpg")
end

return _M