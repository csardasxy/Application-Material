local _M = class("DescForm", BaseForm)

local FORM_WIDTH = 720
local PATH_SIZE = cc.size(560, 250)

function _M.createByFixity(fixity)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)    
    panel:initByFixity(fixity)

    return panel
end

function _M:initByFixity(fixity)
    _M.super.init(self, cc.size(FORM_WIDTH, 440), Str(fixity._info._nameSid), bor(BaseForm.FLAG.BASE_TITLE_BG, BaseForm.FLAG.PAPER_BG))
    
    local iconSize, margin = 200, 20
    local icon = lc.createSprite(string.format("f%d", fixity._info._id))
    local scaleX, scaleY = math.min(iconSize / lc.w(icon), 1), math.min(iconSize / lc.h(icon), 1)
    icon:setScale(scaleX < scaleY and scaleX or scaleY)
    lc.addChildToPos(self._form, icon, cc.p(_M.FRAME_THICK_LEFT + margin + iconSize / 2, lc.bottom(self._titleFrame) - margin - iconSize / 2), 2)

    if fixity._info._id == 1003 then
        lc.addChildToPos(icon, lc.createSprite("f1003_5"), cc.p(lc.w(icon) / 2, lc.h(icon) / 2 + 10))
    end

    local strs = string.splitByChar(Str(fixity._info._descSid), '|')
    local descStr, infoStr = strs[2], strs[1]

    local desc = V.createTTF(descStr, V.FontSize.S1, V.COLOR_TEXT_DARK, cc.size(360, 90), cc.TEXT_ALIGNMENT_LEFT, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    lc.addChildToPos(self._form, desc, cc.p(_M.LEFT_MARGIN + iconSize + margin + margin + lc.w(desc) / 2, lc.bottom(self._titleFrame) - margin - lc.h(desc) / 2 - 20))
    
    local unlock = V.createTTF(string.format(Str(STR.BRACKETS_S), string.format(Str(STR.LORD_UNLOCK_LEVEL), P._playerCity:getUnlockLevel(fixity))),
                                        V.FontSize.S1, V.COLOR_TEXT_GREEN_DARK)
    lc.addChildToPos(self._form, unlock, cc.p(lc.right(desc) - lc.w(unlock) / 2, lc.bottom(self._titleFrame) - margin - iconSize + lc.h(unlock) / 2 + 30))

    local info = V.createTTF(infoStr, nil, V.COLOR_LABEL_DARK, cc.size(480, 0), cc.TEXT_ALIGNMENT_LEFT)
    lc.addChildToPos(self._form, info, cc.p(lc.w(self._form) / 2, _M.BOTTOM_MARGIN + margin + margin + lc.h(info) / 2))
end

function _M.create(data)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(data)
    return panel
end

function _M:init(data)
    local info, type = Data.getInfo(data._infoId)
    local height = _M.FRAME_THICK_TOP + 30
    local isDepot = (lc._runningScene._sceneId == ClientData.SceneId.depot)
    local showOwnCount, ownCount = data._showOwnCount or (data._count ~= nil), P:getItemCount(data._infoId)

    local iconCount = data._count
    if not showOwnCount then
        iconCount = ownCount
    end

    local icon = IconWidget.create({_infoId = data._infoId, _count = iconCount}, IconWidget.DisplayFlag.COUNT)
    icon:setTouchEnabled(false)
    icon._marginTop = height
    self._icon = icon
    
    local name = V.createTTF(ClientData.getNameByInfoId(data._infoId), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(400, 40)}
    nameBg:setColor(lc.Color3B.black)
    nameBg:setOpacity(100)
    lc.addChildToPos(nameBg, name, cc.p(30 + lc.w(name) / 2, lc.h(nameBg) / 2 - 1))

    local descOffsetY = 60
    local descStr = Str(info._descSid)
    local desc
    if string.find(descStr, '|') ~= nil then
        desc = V.createBoldRichText(descStr, V.RICHTEXT_PARAM_LIGHT_S1, 440)
    else
        desc = V.createTTF(descStr, V.FontSize.S1, V.COLOR_TEXT_LIGHT, cc.size(440, 0))
    end
    height = height + math.max(lc.h(icon), descOffsetY + lc.h(desc))
    
    -- Create path
    local pathBg = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = PATH_SIZE}
    pathBg._marginTop = height + 20
    
    local pathList = lc.List.createV(cc.size(PATH_SIZE.width - 40, PATH_SIZE.height - 14))
    pathList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(pathBg, pathList, cc.p(lc.w(pathBg) / 2, lc.h(pathBg) / 2))
    
    local paths, lineH = string.splitByChar(Str(info._pathSid), '/'), 32
    local pathH = 50 + lineH * #paths

    if data._infoId == Data.PropsId.legend_chest then
        pathH = pathH + 60 + (math.floor((#Data._globalInfo._legendHero - 1) / 4) + 1) * (IconWidget.SIZE + 40)
    end

    local pathItem = ccui.Widget:create()
    pathItem:setContentSize(lc.w(pathList), pathH)

    local label = cc.Label:createWithTTF(Str(STR.GET_PATH), V.TTF_FONT, V.FontSize.S1)
    label:setColor(V.COLOR_TEXT_ORANGE)
    lc.addChildToPos(pathItem, label, cc.p(lc.w(pathItem) / 2, pathH - 16))

    local pathY = pathH - 50
    for _, pathStr in ipairs(paths) do
        local path = V.createBoldRichText(pathStr, {_normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_ORANGE_LIGHT, _fontSize = V.FontSize.S1})
        lc.addChildToPos(pathItem, path, cc.p(lc.w(pathItem) / 2, pathY - lineH / 2))
        pathY = pathY - lineH
    end

    if data._infoId == Data.PropsId.legend_chest then
        -- Legend hero box
        local x, y = 0, pathY - 40

        V.addDecoratedLabel(pathItem, Str(STR.LEGEND_BOX_monsters), cc.p(lc.w(pathItem) / 2, y), 26)
        
        y = y - 50
        self._legendHeroIcons = {}
        for i, infoId in ipairs(Data._globalInfo._legendHero) do
            local icon = IconWidget.create({_infoId = infoId})
            self._legendHeroIcons[infoId] = icon

            -- Check whether user has this hero
            local cards, hasCard = P._playerCard:getCards(Data.CardType.monster)
            for k, v in pairs(cards) do
                if v._infoId == infoId then
                    hasCard = true
                    break
                end
            end
            icon:setGray(not hasCard)

            lc.addChildToPos(pathItem, icon, cc.p(x + IconWidget.SIZE / 2 + 46, y - IconWidget.SIZE / 2))
            if i % 4 == 0 then
                x, y = 0, y - IconWidget.SIZE - 40
            else
                x = x + IconWidget.SIZE + 20
            end
        end

        height = height + 30
    end

    pathList:pushBackCustomItem(pathItem)
    
    height = height + 20 + lc.h(pathBg) + 30 + _M.FRAME_THICK_BOTTOM

    -- Check item function
    if isDepot then
        if type == Data.CardType.props then
            if info._type == Data.PropsType.box then
                height = height + 20 + lc.frameSize("img_btn_1").height
            elseif info._id == Data.PropsId.vip_card then
                height = height + 60 + lc.frameSize("img_btn_1").height
            end
        end
    end

    _M.super.init(self, cc.size(FORM_WIDTH, height), nil, bor(BaseForm.FLAG.PAPER_BG))

    local form = self._form
    
    lc.addChildToPos(form, icon, cc.p(120, height - lc.h(icon) / 2 - icon._marginTop))
    lc.addChildToPos(form, nameBg, cc.p(lc.right(icon) - 10 + lc.w(nameBg) / 2, lc.top(icon) - lc.h(nameBg) / 2 - 10))
    lc.addChildToPos(form, desc, cc.p(lc.right(icon) + 20 + lc.w(desc) / 2, lc.top(icon) - descOffsetY - lc.h(desc) / 2))
    lc.addChildToPos(form, pathBg, cc.p(lc.w(form) / 2, height - pathBg._marginTop - lc.h(pathBg) / 2))
    
    if isDepot then
        if type == Data.CardType.props then
            local useFunc
            if info._type == Data.PropsType.box then
                useFunc = self.openBox
            elseif info._id == Data.PropsId.vip_card then
                useFunc = self.useVipCard

                local progress = V.createLabelProgressBar(250)
                lc.addChildToPos(form, progress, cc.p(lc.w(form) / 2 + 30, lc.bottom(pathBg) - 30))
                self._vipProgress = progress

                local vipLabel = V.createBMFont(V.BMFont.huali_26, "VIP0")
                lc.addChildToPos(form, vipLabel, cc.p(lc.left(progress) - lc.w(vipLabel) / 2 - 16, lc.y(progress)))
                vipLabel:setColor(V.COLOR_TEXT_VIP)
                self._vipLabel = vipLabel

                self:updateVipProgress()
            end

            if useFunc then
                local btnUseOnce = V.createScale9ShaderButton("img_btn_1", function() useFunc(self, data, 1) end, V.CRECT_BUTTON, 150)
                btnUseOnce:addLabel(string.format(Str(STR.USE_TIMES), 1))
                lc.addChildToPos(form, btnUseOnce, cc.p(lc.w(form) / 2 - 100, _M.FRAME_THICK_BOTTOM + 30 + lc.h(btnUseOnce) / 2))

                local multiTimes = math.min(data._infoId == Data.PropsId.legend_chest and 5 or 10, data._count)
                if data._count > 300 then
                    multiTimes = 50
                end
                local btnUseMulti = V.createScale9ShaderButton("img_btn_1", function(sender) useFunc(self, data, sender._times) end, V.CRECT_BUTTON, 150)
                btnUseMulti:addLabel(string.format(Str(STR.USE_TIMES), multiTimes))
                lc.addChildToPos(form, btnUseMulti, cc.p(lc.w(form) / 2 + 100, lc.y(btnUseOnce)))
                self._btnUseMulti = btnUseMulti

                btnUseMulti._times = multiTimes
                self._btnUseMulti = btnUseMulti

                if data._infoId == Data.PropsId.legend_chest then
                    self:updateLegendBoxOpenTimes()
                end
            end
        end
    else
        -- Display current count
        if Data.isCardBack(data._infoId) or Data.isAvatarFrame(data._infoId) then
            local label = (ownCount > 0 and Str(STR.UNLOCKED) or Str(STR.LOCK))
            local lock = V.createTTF(label, V.FontSize.S1, (ownCount > 0 and V.COLOR_LABEL_LIGHT or V.COLOR_TEXT_RED_DARK))
            lc.addChildToPos(form, lock, cc.p(lc.w(form) - lc.w(lock) / 2 - 80, lc.y(nameBg)))
        else
            if ownCount ~= nil and ownCount >= 0 then
                local have
                if Data.isUnionRes(data._infoId) then
                    local union = P._playerUnion:getMyUnion()
                    if data._infoId==Data.ResType.union_act then
                        local isMax,exp = P._playerUnion:getUnionUpgradeExp()
                        local maxStr = ""
                        if  isMax then
                            maxStr = Str(STR.UNION_LEVEL_MAX)
                        else
                            maxStr = string.format("(%s: %s)", Str(STR.UNION_EXP_MAX), exp)
                        end
                        have = V.createTTF(maxStr, V.FontSize.S1, V.COLOR_LABEL_LIGHT)
                    else
                        have = V.createTTF(string.format("(%s: %s)", Str(STR.MAX), P._playerUnion:getMaxResource(data._infoId)), V.FontSize.S1, V.COLOR_LABEL_LIGHT)
                    end
                elseif showOwnCount then
                    have = V.createTTF(string.format("(%s: %s)", Str(STR.CURRENT_OWN), ClientData.formatNum(ownCount, 9999)), V.FontSize.S1, V.COLOR_LABEL_LIGHT)
                    
                end

                if have then
                    lc.addChildToPos(form, have, cc.p(lc.w(form) - lc.w(have) / 2 - 60, lc.y(nameBg)))
                end
            end
        end
    end

    local curStep = GuideManager.getCurStepName()
    if curStep == "leave claim" then
        GuideManager.pauseGuide()
    end
end

function _M:hide()
    _M.super.hide(self)

    local curStep = GuideManager.getCurStepName()
    if curStep == "leave claim" then
        GuideManager.resumeGuide()
    end
end

function _M:updateLegendBoxOpenTimes()
    if self._legendBoxOpenTip then
        self._legendBoxOpenTip:removeFromParent()
    end

    local timesLimit = Data._globalInfo._vipLegendChest[P._vip + 1]
    local timesRemain = timesLimit - P._legendBoxOpenRemainTimes
    local timesStr = ((P._legendBoxOpenTimes == 0 or timesRemain <= 1) and Str(STR.LEGEND_BOX_OPEN_TIP_NOW) or string.format(Str(STR.LEGEND_BOX_OPEN_TIP), timesRemain))

    local tip = V.createBoldRichText(timesStr, V.RICHTEXT_PARAM_DARK_S1)
    lc.addChildToPos(self._form, tip, cc.p(lc.w(self._form) / 2, lc.top(self._btnUseMulti) + 10 + lc.h(tip) / 2))
    self._legendBoxOpenTip = tip
end

function _M:openBox(prop, count)
    local info = Data.getInfo(prop._infoId)
    if info._type ~= Data.PropsType.box then
        return
    end

    if count == 0 then
        count = 1
    end

    local result = P._propBag:useProp(prop, count)
    if result == Data.ErrorType.ok then
        V.getActiveIndicator():show(Str(STR.OPENING), nil, {_prop = prop, _useCount = count})
        ClientData.sendOpenBox(prop._infoId, count)

--        P._playerAchieve:dailyTaskDone(Data.DailyTaskType.open_box, count)
    else
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(STR.PROPS_TYPE_BOX)))
    end
end

function _M:useVipCard(prop, count)
    local info = Data.getInfo(prop._infoId)
    if info._id ~= Data.PropsId.vip_card then
        return
    end

    if count == 0 then
        count = 1
    end

    local result = P._propBag:useProp(prop, count)
    if result == Data.ErrorType.ok then        
        ClientData.sendUseVipCard(count)

        local preVip, vipExp = P._vip, count * Data._globalInfo._vipCardFactor
        P:changeVIPExp(vipExp)

        self:updateVipProgress(true)
        self:onPropUsed(prop, count)

        if P._vip > preVip then
            require("LevelUpPanel").createVip(preVip, P._vip):show()
        end
    else
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(STR.SID_PROPS_NAME_7098)))
    end 
end

function _M:updateVipProgress(isShowEffect)
    self._vipLabel:setString(string.format("VIP%d", P._vip))

    self._vipProgress:setLabel(P._vipExp, P:getVIPupExp())
    self._vipProgress._bar:setPercent(P._vipExp * 100 / P:getVIPupExp())

    if isShowEffect then
        V.showVipExpEffect(self._vipProgress)
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    if self._legendHeroIcons then
        table.insert(self._listeners, lc.addEventListener(Data.Event.card_add, function(event)
            local icon = self._legendHeroIcons[event._infoId]
            if icon then
                icon:setGray(false)
            end
        end))
    end

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end

    ClientData.removeMsgListener(self)

    GuideManager.resumeGuide()
end

function _M:onPropUsed(prop, count)
    -- Update icon count    
    prop._count = prop._count - count
    self._icon:resetData(prop)

    -- Update label on multi-open button
    if self._btnUseMulti and prop._count < self._btnUseMulti._times then
        self._btnUseMulti._label:setString(string.format(Str(STR.USE_TIMES), prop._count))
        self._btnUseMulti._times = prop._count
    end

    if self._btnUseMulti and prop._count > 300 then
        self._btnUseMulti._label:setString(string.format(Str(STR.USE_TIMES), 50))
        self._btnUseMulti._times = 50
    end

    if prop._count == 0 then
        if prop._infoId == Data.PropsId.vip_card then
            self:runAction(lc.sequence(1.5, function() self:hide() end))
        else
            self:hide()
        end
    end

    if prop._infoId == Data.PropsId.legend_chest then
        P._legendBoxOpenTimes = P._legendBoxOpenTimes + count

        P._legendBoxOpenRemainTimes = P._legendBoxOpenRemainTimes + count
        if P._legendBoxOpenRemainTimes >= Data._globalInfo._vipLegendChest[P._vip + 1] then
            P._legendBoxOpenRemainTimes = 0
        end

        self:updateLegendBoxOpenTimes()
    end

    local eventCustom = cc.EventCustom:new(Data.Event.use_prop)
    eventCustom._prop = prop
    eventCustom._useCount = count
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_USER_OPEN_CHEST then
        local resp = msg.Extensions[User_pb.SglUserMsg.user_open_chest_resp]

        local data = V.getActiveIndicator():hide()
        
        local RewardPanel = require("RewardPanel")
        RewardPanel.create(resp, RewardPanel.MODE_CHEST):show()

        self:onPropUsed(data._prop, data._useCount)

        return true
    end    
    
    return false
end

return _M