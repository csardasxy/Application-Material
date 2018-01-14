local _M = class("ActivityExchangeForm", BaseForm)

local FORM_SIZE = cc.size(970, 670)
local TAB_WIDTH = 200
local TAB_MARGIN_TOP = 20
local TAB_MARGIN_LEFT = 0
local ITEM_Height = 170

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    
    return panel    
end

function _M:init()
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local tabStrs, tabs = {Str(STR.ACTIVITY)..Str(STR.RULE), Str(STR.ARTIFACT)..Str(STR.EXCHANGE)}, {}
    for i, str in ipairs(tabStrs) do
        local tab = {
            _tag = i,
            _labelStr = tabStrs[i],
            _width = TAB_WIDTH,
            _handler = function(tag) self:showTab(tag) end,
        }

        table.insert(tabs, tab)
    end

    self._frame:setVisible(false)

    local contentBg = V.createHorizontalContentTab(cc.size(FORM_SIZE.width, FORM_SIZE.height), tabs)
    lc.addChildToPos(self._form, contentBg, cc.p(FORM_SIZE.width / 2, lc.h(contentBg) / 2))
    self._contentBg = contentBg

    local adSpr = lc.createSprite("res/jpg/7_artifact_bg.jpg")
    V.setMaxSize(adSpr, FORM_SIZE.width - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, FORM_SIZE.height - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM)
    lc.addChildToCenter(self._contentBg, adSpr, -1)
    self._adSpr = adSpr

    self:addExchangeList()
    self:refreshExchangeList()

    contentBg:showTab(1, true)

    self._form:setContentSize(cc.size(FORM_SIZE.width, FORM_SIZE.height + 60))
end

function _M:addExchangeList()
    local exchangeList = lc.List.createV(cc.size(lc.w(self._contentBg) - 40, lc.h(self._contentBg) - 40), 30, 0)
    exchangeList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._contentBg, exchangeList, cc.p(lc.cw(exchangeList) + 30, lc.ch(exchangeList) + 20), -1)
    self._exchangeList = exchangeList
end

function _M:refreshExchangeList()
    local exchangeList = self._exchangeList
    local exchanges = {}
    for i, info in ipairs(Data._exchangeInfo) do
        if info._activityId == 22 then
            table.insert(exchanges, info)
        end
    end
    exchangeList:bindData(exchanges, function(item, data) self:setOrCreateItem(item, data) end, math.min(6, #exchanges))
    for i = 1, exchangeList._cacheCount do
        local item = self:setOrCreateItem(nil, exchanges[i])
        exchangeList:pushBackCustomItem(item)
--        if i ~= #exchangeInfo then
--            local seperator = V.createDividingLine(lc.w(exchangeList), V.COLOR_DIVIDING_LINE_LIGHT)
--            exchangeList:pushBackCustomItem(item)
--        end
    end

--    local items = exchangeList:getItems()
--    for _, item in ipairs(items) do
--        local index = exchangeList:getIndex(item)
--        item._seperator:setVisible(index ~= #exchanges - 1)
--    end
end

function _M:setOrCreateItem(layout, exchange)
    if not layout then
        layout = ccui.Widget:create()
        layout:setContentSize(lc.w(self._contentBg), ITEM_Height)
        layout._items = {}
        layout._exchange = exchange

        local bonusId = exchange._reward
        local bonusInfo = Data._bonusInfo[bonusId]
        local rewardId = bonusInfo._rid[1]
        local rewardIcon = IconWidget.create({_infoId = rewardId, _count = bonusInfo._count[1]})
        lc.addChildToPos(layout, rewardIcon, cc.p(lc.w(layout) - lc.w(rewardIcon) + 6, lc.ch(layout) - 8))
        rewardIcon._nameColor = V.COLOR_TEXT_WHITE
        layout._rewardIcon = rewardIcon

        local exchangeNum = P._playerMarket._exchangeMap[exchange._id] or 0
        local exchangeBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender)
            local itemEnough = true
            local exchange = layout._exchange
            local itemIds = exchange._item
            for i, id in ipairs(itemIds) do
                if P:getItemCount(id) < exchange._number[i] then
                    itemEnough = false
                    break
                end
            end
            if itemEnough then
                local exchangeNum = P._playerMarket._exchangeMap[exchange._id] or 0
                if exchange._time ~= 0 then
                    local remainNum = exchange._time - exchangeNum
                    if remainNum <= 0 then
                        return ToastManager.push(Str(STR.EXCHANGED))
                    end
                end

                P._playerMarket:exchangeProp(exchange)
                
                local RewardPanel = require("RewardPanel")
                RewardPanel.create({{info_id = rewardId, num = bonusInfo._count[1]}}, RewardPanel.MODE_EXCHANGE):show()
                self:refreshExchangeList()
            else
                return ToastManager.push(Str(STR.EXCHANGE_ITEM_NOT_ENOUGH))
            end
        end, V.CRECT_BUTTON_S, 110)
        exchangeBtn:setDisabledShader(V.SHADER_DISABLE)
        lc.addChildToPos(layout, exchangeBtn, cc.p(lc.left(rewardIcon) - lc.cw(exchangeBtn) - 16, lc.y(rewardIcon)))
        exchangeBtn:addLabel(Str(STR.EXCHANGE))

        local title

--        local numLabel = V.createTTF(string.format(Str(STR.REMAIN_BUY_TIMES), exchange._time - exchangeNum), V.FontSize.S3)
--        lc.addChildToPos(layout, numLabel, cc.p(lc.x(exchangeBtn), lc.top(exchangeBtn) + lc.ch(numLabel)))

        

        local seperator = V.createDividingLine(lc.w(self._exchangeList), V.COLOR_DIVIDING_LINE_LIGHT)
        lc.addChildToPos(layout, seperator, cc.p(lc.cw(self._exchangeList), lc.ch(seperator)))
        layout._seperator = seperator

        layout.update = function(exchange)
            layout._exchange = exchange
            local data = self._exchangeList._data
            seperator:setVisible(exchange ~= data[#data])
            if exchange._time ~= 0 then
                local exchangeNum = P._playerMarket._exchangeMap[exchange._id] or 0
                if exchange._time - exchangeNum <= 0 then
                    exchangeBtn._label:setString(Str(STR.EXCHANGED))
                    exchangeBtn:setEnabled(false)
                else
                    exchangeBtn._label:setString(Str(STR.EXCHANGE))
                end
            else
                exchangeBtn._label:setString(Str(STR.EXCHANGE))
            end

            for _, item in ipairs(layout._items) do
                item:setVisible(false)
            end

            local itemIds = exchange._item
            for i, id in ipairs(itemIds) do
                local item = layout._items[i]
                local count = P:getItemCount(id)
                if not item then
                    item = IconWidget.create({_infoId = id, _count = count})
                    item:setScale(0.9)
                    lc.addChildToPos(layout, item, cc.p(20 + (i - 0.5) * (lc.w(item) - 10), lc.ch(layout) - 15))
                    item._name:setColor(V.COLOR_TEXT_WHITE)
                    item._nameColor = V.COLOR_TEXT_WHITE
                    table.insert(layout._items, i, item)
                else
                    item:resetData({_infoId = id, _count = count})
                    item:setVisible(true)
                end
                item:setGray(count <= 0)
                item._countBg:setVisible(count > 0)
            end

            local bonusId= exchange._reward
            local bonusInfo = Data._bonusInfo[bonusId]
            local rewardId = bonusInfo._rid[1]
            rewardIcon:resetData({_infoId = rewardId, _count = bonusInfo._count[1]})

            if title then
                title:removeFromParent()
                title = nil
            end

            title = V.createBoldRichTextMultiLine(string.format(Str(exchange._time > 1 and STR.EXCHANGE_TIP2 or STR.EXCHANGE_TIP1), exchange._time, exchange._time - exchangeNum), V.RICHTEXT_PARAM_LIGHT_S2)
            lc.addChildToPos(layout, title, cc.p(lc.cw(title) + 32, 148))
        end
    end

    layout.update(exchange)
    return layout
end

function _M:showTab(index)
    self._adSpr:setVisible(false)
    self._exchangeList:setVisible(false)
    if index == 2 then
        self._exchangeList:setVisible(true)
    else
        self._adSpr:setVisible(true)
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onCleanup()
    lc.TextureCache:removeTextureForKey("res/jpg/7_artifact_bg.jpg")
end

return _M