local _M = class("RecommendTroopListForm", BaseForm)

local FORM_SIZE = cc.size(840, 700)
local REFRESH_HEIGHT = 110

_M.Tab = {
    system          = Data.RecommendTroop.system,
    player           = Data.RecommendTroop.player,
}

function _M.create()
    local form = _M.new(lc.EXTEND_LAYOUT_MASK)
    form:init()
    return form
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.RECOMMEND_TROOP), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    local tabs = nil
    tabs = {
        {_str = Str(STR.SYSTEM_RECOMMEND), _index = _M.Tab.system},
        {_str = Str(STR.PLAYER_TROOP), _index = _M.Tab.player},
    }

    local tabArea = V.createVerticalTabListArea(lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM, tabs, function(tab, isSameTab, isUserBehavior) self:showTab(tab._index, not isSameTab, isUserBehavior) end)
    tabArea._subTabExpandCallback = function(tab) self:showTabFlag() end
    lc.addChildToPos(self._frame, tabArea, cc.p(V.FRAME_INNER_LEFT + lc.w(tabArea) / 2, lc.h(self._frame) / 2), 0)
    self._tabArea = tabArea

    local list = lc.List.createV(cc.size(lc.w(self._frame) - lc.right(tabArea) - V.FRAME_INNER_RIGHT - 24, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM - REFRESH_HEIGHT), 10, 10)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._frame, list, cc.p(lc.right(tabArea) + 14 + lc.w(list) / 2, lc.h(self._frame) / 2 - REFRESH_HEIGHT / 2))
    self._list = list

    local refreshBg = lc.createSprite("res/jpg/recommend_bg.jpg")
    lc.addChildToPos(self._frame , refreshBg , cc.p((lc.w(self._frame) + lc.right(tabArea)) / 2 - 14, lc.h(self._frame) - V.FRAME_INNER_TOP - REFRESH_HEIGHT / 2), -1)

    local refreshBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender) 
        sender:setEnabled(false)
        ClientData:sendGetRecommendTroops()
    end, V.CRECT_BUTTON_S, 150)
    refreshBtn:addLabel(Str(STR.REFRESH_TROOP))
    refreshBtn:setDisabledShader(V.SHADER_DISABLE)
    refreshBtn:setEnabled(false)
    lc.addChildToPos(refreshBg, refreshBtn, cc.p(lc.w(refreshBg) * 3 / 4, lc.ch(refreshBg)))
    self._refreshBtn = refreshBtn

    ClientData:sendGetRecommendTroops()
    self._tabArea:showTab(_M.Tab.system, false)
end

function _M:showTab(tabIndex, isForce, isUserBehavior)
    if not isForce then return end

    self._focusTabIndex = tabIndex
    self._refreshBtn:setVisible(tabIndex == _M.Tab.player)
    self:refreshList()

end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    local listener = lc.addEventListener(Data.Event.recommend_troop_dirty, function(event)
        self._refreshBtn:setEnabled(true)
        local trophy = P._trophy or 0
        trophy = math.max(800, trophy)
        local recommends = P._playerCard:getRecommendTroops()
        if #recommends > 0 then
            ToastManager.push(string.format(Str(STR.RECOMMEND_TROOP_TIP), #recommends, trophy + 100, trophy + 200))
        end
        self:refreshList()
    end)
    table.insert(self._listeners, listener)
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end

end

function _M:refreshList()
    local list = self._list

    local data = {}
    if self._focusTabIndex == _M.Tab.system then
        data = P._playerCard:getSystemRecommendTroops()
    elseif self._focusTabIndex == _M.Tab.player then
        data = P._playerCard:getRecommendTroops()
    end
    list:bindData(data, function(item, info) self:setOrCreateItem(item, info) end, math.min(6, #data))

    for i = 1, list._cacheCount do
        list:pushBackCustomItem(self:setOrCreateItem(nil, data[i]))
    end
    
    list:checkEmpty(Str(STR.LIST_EMPTY_NO_RECOMMEND))

--    local sprite = lc.createSprite("img_com_bg_35")
--    lc.addChildToCenter(list, sprite)

    list:refreshView()
    list:gotoTop()
end

function _M:setOrCreateItem(item, info)
    if item == nil then
        item = lc.createImageView{_name = "img_com_bg_35", _crect = V.CRECT_COM_BG35}
        item:setContentSize(cc.size(lc.w(self._list), 108))

        local deco = lc.createSprite('img_bg_deco_29')
        local scale = 100 / lc.h(deco)
        deco:setScale(scale)
        lc.addChildToPos(item, deco, cc.p(lc.w(item) - lc.w(deco) * scale / 2, lc.ch(item)))
        
        item:setTouchEnabled(true)
        item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

        local number = V.createBMFont(V.BMFont.huali_32, "")
        lc.addChildToPos(item, number, cc.p(64, lc.h(item) / 2 + 2))
        
        item:addTouchEventListener(function(sender, type)
            if type == ccui.TouchEventType.ended then
--                if sender._info and self._list then
--                    if sender._info._user._id ~= P._id then
--                        V.operateUser(sender._info._user, sender)
--                            require("ClashUserInfoForm").create(sender._info._user._id):show()
--                    end
--                end
            end
        end)

        local flag = UserWidget.Flag.LEVEL_NAME
        if self._focusTabIndex == _M.Tab.player then
            flag = bor(flag, UserWidget.Flag.REGION)
        end
        local userArea = UserWidget.create(nil, flag, 1.2)
        
        userArea:setScale(0.7)
        lc.addChildToPos(item, userArea, cc.p(lc.w(userArea) / 2, lc.h(item) / 2 + 4))

--        local nameLabel = V.createTTF("", V.FontSize.M1, V.COLOR_TEXT_WHITE)
--        lc.addChildToPos(item, nameLabel, cc.p(userArea:getPosition()))

        local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) require("VisitForm").create(item._info, self._focusTabIndex):show() end, V.CRECT_BUTTON_S, 120)
        lc.addChildToPos(item, btn, cc.p(lc.w(item) - lc.cw(btn) - 30, lc.ch(item)))
        btn:addLabel(Str(STR.DETAIL))

        item.update = function(info)
            if info then
                item._info = info
                local user = ClientData.getAttackUserFromInput(info)
                userArea:setUser(user, true)
                if userArea._regionArea then
                    lc.offset(userArea._regionArea, 20, -100)
                end
--                userArea._regionArea:setPosition(cc.p(lc.right(userArea._frame), 0))
--                if self._focusTabIndex ~= _M.Tab.system and user then
--                    userArea:setUser(user, true)
--                    userArea._regionArea:setPosition(cc.p(lc.right(userArea._frame), 0))
--                else
--                    nameLabel:setString("")
--                end
--                userArea:setVisible(self._focusTabIndex ~= _M.Tab.system)
--                nameLabel:setVisible(self._focusTabIndex == _M.Tab.system)
            end
        end
    end
    item.update(info)
    return item
end

return _M