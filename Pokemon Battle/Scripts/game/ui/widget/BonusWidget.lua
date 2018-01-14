local _M = class("BonusWidget", lc.ExtendUIWidget)

local WIDGET_HEIGHT = 190

local MARGIN_LEFT = 20
local MARGIN_RIGHT = 20
local MARGIN_TOP = 10

local BUTTON_WIDTH = 140

function _M.create(w, bonus, titleStr, descStr)
    local panel = _M.new(lc.EXTEND_LAYOUT)
    panel:setContentSize(w, WIDGET_HEIGHT)
    panel:init(bonus, titleStr, descStr)

    return panel
end

function _M:init(bonus, titleStr, descStr)
    self:setBackGroundImage("img_troop_bg_6", ccui.TextureResType.plistType)
    self:setBackGroundImageScale9Enabled(true)
    self:setBackGroundImageCapInsets(V.CRECT_TROOP_BG)
    --[[
    local deco = lc.createSprite('img_bg_deco_29')
    deco:setPosition(cc.p(lc.w(self) - lc.w(deco) / 2, lc.h(self) / 2))
    self:addProtectedChild(deco)]]

    --local titleBg = lc.createSprite{_name = "img_com_bg_12", _crect = V.CRECT_COM_BG12, _size = cc.size(lc.w(self) - MARGIN_LEFT - MARGIN_RIGHT, V.CRECT_COM_BG12.height)}
    local titleBg = lc.createNode(cc.size(860, 45))
    titleBg:setPosition(lc.w(titleBg) / 2, lc.h(self) - lc.h(titleBg) / 2 - MARGIN_TOP)
    self:addProtectedChild(titleBg)
    self._titleBg = titleBg

    local title = V.createTTFStroke("", V.FontSize.S1)
    title:setColor(V.COLOR_TEXT_LIGHT)
    title:setPosition(0, lc.h(titleBg) / 2)
    titleBg:addChild(title)
    self._title = title

    local desc =  V.createTTF("", V.FontSize.S2)
    desc:setColor(V.COLOR_TEXT_TITLE_DESC)
    titleBg:addChild(desc)
    self._desc = desc

    if bonus._id then
        local time = V.createTTF("", V.FontSize.S2, V.COLOR_TEXT_TITLE)
        time:setAnchorPoint(1, 0.5)
        lc.addChildToPos(titleBg, time, cc.p(lc.w(titleBg), lc.h(titleBg) / 2))
        self._time = time
    end

    self:setBonus(bonus, titleStr, descStr)
end

function _M:setBonus(bonus, titleStr, descStr)
    self._bonus = bonus

    local title = self._title
    title:setString(titleStr or Str(bonus._info._nameSid))
    title:setPositionX(40 + lc.w(title) / 2)

    local desc = self._desc
    desc:setString(descStr or "")
    desc:setPosition(lc.right(title) + 28 + lc.w(desc) / 2, lc.bottom(title) + lc.h(desc) / 2)

    local time = self._time
    if time then
        time:setString(ClientData.getTimeAgo(bonus._timestamp))
    end

    V.checkNewFlag(self, 0)

    self:removeAllChildren()
    self._progBar = nil

    local marginTop = lc.bottom(self._titleBg) - 2
    self:addBonusItems(marginTop)
    self:addButton(marginTop)

    local info = bonus._info
    if info then
        if info._type == Data.BonusType.grain or info._type == Data.BonusType.online or info._type == Data.BonusType.facebook then
            local tip = V.createTTF("", V.FontSize.S1, V.COLOR_TEXT_WHITE)
            tip:setScale(0.8)
            tip:setAnchorPoint(1, 1)
            lc.addChildToPos(self, tip, cc.p(lc.right(self._button), lc.bottom(self._button) - 20))
            self._tip = tip

        else
            if info._val > 0 and (bonus.isChapter and not bonus:isChapter() and not bonus:isTeach()) then
                local progBar = V.createLabelProgressBar(BUTTON_WIDTH)
                lc.addChildToPos(self, progBar, cc.p(lc.w(self) - BUTTON_WIDTH / 2 - MARGIN_RIGHT - 10, lc.bottom(self._button) - 6 - lc.h(progBar) / 2))
                self._progBar = progBar
            end
        end
    end

    self:updateView()
end

function _M:onEnter()
    self._listener = lc.addEventListener(Data.Event.bonus_dirty, function(event)
        if event._data == self._bonus then
            self:updateView()
        end
    end)

    self:scheduleUpdateWithPriorityLua(function(dt) self:onSchedule(dt) end, 0)
end

function _M:onExit()
    lc.Dispatcher:removeEventListener(self._listener)
    self:unscheduleUpdate()
end

function _M:onSchedule(dt)
    local info = self._bonus._info
    if info then
        if info._type == Data.BonusType.online then
            self:updateOnlineBonusTip()
        end
    end
end

function _M:updateOnlineBonusTip()
    local bonus, info = self._bonus, self._bonus._info
    local prevBonus = bonus:getPrevBonus()
    if prevBonus == nil or prevBonus._isClaimed then
        if bonus._isClaimed or bonus:canClaim() then
            self._tip:setString("")
        else
            local dt = math.ceil(info._val - bonus._value)
            if dt < 0 then dt = 0 end
            self._tip:setString(string.format(Str(STR.CLAIM_AFTER1), ClientData.formatPeriod(dt)))
        end
    else
        local dt = info._val - (prevBonus and prevBonus._info._val or 0)
        if dt < 0 then dt = 0 end
        self._tip:setString(string.format(Str(STR.CLAIM_AFTER2), ClientData.formatPeriod(dt, 1)))
    end
end

function _M:addBonusItems(marginTop)
    local items = {}

    local bonusInfo = self._bonus._info
    if bonusInfo then
        local ids = bonusInfo._rid
        local levels = bonusInfo._level
        local counts = bonusInfo._count
        local isFragments = bonusInfo._isFragment

        for i, id in ipairs(ids) do
            local item = IconWidget.create{_infoId = id, _level = levels[i], _isFragment = isFragments[i] > 0, _count = counts[i]}
            item._name:setColor(lc.Color3B.white)
            table.insert(items, item)
        end
    else
        for _, bonus in ipairs(self._bonus._extraBonus) do
            local item = IconWidget.create(bonus)
            item._name:setColor(lc.Color3B.white)
            table.insert(items, item)
        end
    end

    P:sortResultItems(items)

    local x, y = MARGIN_LEFT + 20, marginTop
    for _, item in ipairs(items) do
        --item._name:setColor(V.COLOR_BMFONT)
        lc.addChildToPos(self, item, cc.p(x + lc.w(item) / 2, y - lc.h(item) / 2 + 4))
        x  = x + lc.w(item) + 10

        item:checkHighlight()

        if self._bonus._isClaimed then
            for _, item in ipairs(items) do
                if item._light1 then item._light1:setVisible(false) end
                if item._light2 then item._light2:setVisible(false) end
            end
        end
    end
    self._items = items
end

function _M:addButton(marginTop)    
    local flag = V.createStatusLabel(Str(STR.CLAIMED), V.COLOR_TEXT_GREEN)
    lc.addChildToPos(self, flag, cc.p(lc.w(self) - lc.w(flag) / 2 - MARGIN_RIGHT - 10, marginTop - lc.h(flag) / 2), 1)
    self._claimedFlag = flag

    local button = V.createScale9ShaderButton("img_btn_1_s", 
        function(sender)
            if self._callback then
                self._callback(self._bonus)
            end

            local curStep = GuideManager.getCurStepName()
            if curStep == "claim task" or string.find(curStep, "goto task") then
                GuideManager.finishStepLater()
            end

            -- Only remove soft guide finger
            if sender._softGuideFinger then
                GuideManager.releaseFinger()
            end
            for _, item in ipairs(self._items) do
                if item._light1 then item._light1:setVisible(false) end
                if item._light2 then item._light2:setVisible(false) end
            end
        end,
    V.CRECT_BUTTON_S, BUTTON_WIDTH)
    button:addLabel("")
    button:setDisabledShader(V.SHADER_DISABLE)

    lc.addChildToPos(self, button, cc.p(lc.w(self) - BUTTON_WIDTH / 2 - MARGIN_RIGHT - 10, marginTop - lc.h(button) / 2 - 42), 1)
    self._button = button
end

function _M:registerCallback(handler)
    self._callback = handler
end

function _M:updateView()
    local bonus, info = self._bonus, self._bonus._info
    local canClaim = bonus:canClaim()

    if self._progBar then
        local bonusCid = info._cid
        local val, dstVal = bonus._value, info._val
        if bonusCid == 205 or bonusCid == 305 then
            -- Evolution bonus
            val = val + 1
            dstVal = dstVal + 1
        end

        self._progBar._bar:setPercent(val * 100 / dstVal)
        self._progBar._bar:setColor(canClaim and lc.Color3B.green or lc.Color3B.white)
        local isGold = bonus._info._type==Data.BonusType.gold_cost or bonus._info._type==Data.BonusType.gold_gain
        self._progBar:setLabel(val, dstVal, isGold)

        self._progBar:setVisible(not bonus._isClaimed)
    end

    if self._tip then
        if info._type == Data.BonusType.online then
            self:updateOnlineBonusTip()

        else
            self._tip:setString("")
        end
    end

    local btn = self._button
    if btn then
        btn:setVisible(not bonus._isClaimed)
        self._claimedFlag:setVisible(bonus._isClaimed)

        V.checkNewFlag(self, 0)

        if not bonus._isClaimed then
            btn:setEnabled(true)

            if canClaim then
                if bonus._claimTimesMax then
                    local times = bonus._value - bonus._claimTimes
                    btn._label:setString(times == 1 and Str(STR.CLAIM) or Str(STR.CLAIM_ALL))
                    
                    local flag = V.checkNewFlag(self, times, -32, -20, 1)
                    if flag then flag:setSpriteFrame("img_new_g") end
                    
                else
                    btn._label:setString(Str(STR.CLAIM))
                end

                btn:loadTextureNormal("img_btn_1_s", ccui.TextureResType.plistType)
            else
                local bonusCid = info._cid
                if (bonusCid ~= 101 or info._type == Data.BonusType.novice) and bonusCid ~= 301 and bonusCid ~= 302 and bonusCid ~= 304 and
                   bonusCid ~= 401 and bonusCid ~= 402 and bonusCid ~= 404 and info._type ~= Data.BonusType.grain and info._type ~= Data.BonusType.online and
                   info._type ~= Data.BonusType.fund_all and info._type ~= Data.BonusType.fund_level and info._type ~= Data.BonusType.invite and info._type ~= Data.BonusType.level and info._type ~= Data.BonusType.bottle and info._type ~= Data.BonusType.login_day then
                    btn._label:setString(Str(STR.GO))
                    btn:loadTextureNormal("img_btn_2_s", ccui.TextureResType.plistType)
                else
                    btn:setEnabled(false)
                    btn:setSwallowTouches(false)

                    btn._label:setString(Str(STR.CLAIM))
                end
            end    
            btn:setContentSize(cc.size(BUTTON_WIDTH, V.CRECT_BUTTON_S.height))
       --[[ else
            for _, item in ipairs(self._items) do
                if item ~= nil and item._light1 then item._light1:setVisible(false) end
                if item ~= nil and item._light2 then item._light2:setVisible(false) end
            end]]
        end
    end
end

function _M:adjustPosition(hasAllButton)
    if hasAllButton then
        self._button:setPositionY(WIDGET_HEIGHT/2+15)
        self._button:setContentSize(cc.size(BUTTON_WIDTH, 50))
        self._button._label:setPositionY(25)
        self._progBar:setPositionY(lc.ch(self._progBar)+ 15)
    end
end

return _M