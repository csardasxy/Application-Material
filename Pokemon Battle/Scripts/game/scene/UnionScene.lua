local _M = class("UnionScene", BaseUIScene)

local CreateArea = require("UnionCreateArea")
local SearchArea = require("UnionSearchArea")
local UnionArea = require("UnionUnionArea")
local ChatArea = require("UnionChatArea")
local ShopArea = require("UnionShopArea")
local UnionMemberForm = require("UnionMemberForm")

local BG_NAME = "res/jpg/union_bg.jpg"

local CONTENT_ARAE_WIDTH_MAX = 800
local MY_UNION_AREA_H = 80

local TAB = {
    create      = 1,
    my_union    = 2,
    --hire        = 3,
    tech        = 5,
    boss        = 6,
    --blacksmith  = 6,
    search      = 3,
    chat        = 4,
    --battle      = 3,
    shop        =7,
}

function _M.create(tabIndex)
    return lc.createScene(_M, tabIndex)
end

function _M:init(tabIndex)
    if not _M.super.init(self, ClientData.SceneId.union, STR.SID_FIXITY_NAME_1012, BaseUIScene.STYLE_EMPTY, true) then return false end
    
    --[[
    local bg = lc.createSprite(BG_NAME)
    local scaleX = lc.w(self) / lc.w(bg)
    local scaleY = lc.bottom(self._titleArea) / lc.h(bg)
    bg:setScale(scaleX > scaleY and scaleX or scaleY)
    bg:setPosition(lc.w(self) / 2, lc.sh(bg) / 2)
    self:addChild(bg)
    ]]

    self._initTabIndex = tabIndex

    P._playerUnion._hasDetailInfo = nil

    self._titleArea._btnBack._callback = function ()
        if self._myUnionChatArea and self._myUnionChatArea._isBattleWaiting == true then
            return require("Dialog").showDialog(Str(STR.CANCEL_INVITE_1), function() 
                self._myUnionChatArea:onBattleCancel(true)
                self:hide()
            end)
        elseif self._shopArea and self._shopArea._detailPanel then
            self._shopArea:hideCardBox()
        else
            self:hide()
        end
    end
    
    local chatPanelBg = lc.createSprite{_name = "img_com_bg_30", _crect = V.CRECT_COM_BG30, _size = cc.size(580, V.SCR_H - lc.h(self._titleArea))}
    chatPanelBg:setColor(cc.c3b(219, 253, 169))
    local chatPanel = lc.createNode(cc.size(lc.w(chatPanelBg), lc.h(chatPanelBg)))
    lc.addChildToCenter(chatPanel, chatPanelBg, -1)

    local chatArea = ChatArea.create(P._unionId, lc.w(chatPanelBg) - 20, lc.h(chatPanelBg))
    lc.addChildToPos(chatPanelBg, chatArea, cc.p(lc.cw(chatPanelBg) - 8, lc.ch(chatPanelBg)))

    chatPanel._contentBg = chatPanelBg
    chatPanel._isPop = false

    chatPanel.push = function(self)
        if not self._isPop then return end

        self._isPop = false
        self:stopAllActions()
        self:runAction(lc.sequence(lc.ease(lc.moveTo(0.2, cc.p(V.SCR_W, lc.y(self))), "SineI"), function() self._contentBg:setVisible(false) end))
    end

    chatPanel.pop = function(self)
        if self._isPop then return end

        self._isPop = true
        self._contentBg:setVisible(true)
        self:stopAllActions()
        self:runAction(lc.ease(lc.moveTo(0.35, cc.p(V.SCR_W - lc.w(self) + 10, lc.y(self))), "SineO"))
    end

    local chatBtn = V.createShaderButton("img_btn_pop_r", function()
        if chatPanel._isPop then
            chatPanel:push()
        else
            chatPanel:pop()
        end
    end)
    chatBtn:setAnchorPoint(1, 0.5)
    chatPanel:setAnchorPoint(0, 0.5)
    lc.addChildToPos(self, chatPanel, cc.p(lc.w(self), lc.ch(chatPanel)), 3)
    lc.addChildToPos(chatPanel, chatBtn, cc.p(0, lc.ch(chatPanel)))
    self._chatPanel = chatPanel
    return true
end

function _M:syncData()
    _M.super.syncData(self)

    if P:hasUnion() then
        if not P._playerUnion._hasDetailInfo then
            V.getActiveIndicator():show(Str(STR.WAITING))
            ClientData.sendGetMyUnionDetail()
        else
            self:updateTabs()
        end
    else
        self:updateTabs()
    end
end

function _M:updateTabs()
    local tabArea, focusedIndex = self._tabArea
    if tabArea then
        focusedIndex = tabArea._focusedTab._index
    else
        focusedIndex = self._initTabIndex
        self._initTabIndex = nil
    end

    local hasUnion = P:hasUnion()
    if self._hasUnion ~= hasUnion then
        local tabDefs
        if hasUnion then
            tabDefs = {
                --{_index = TAB.chat, _str = Str(STR.UNION_CHAT)},
                {_index = TAB.my_union, _str = Str(STR.UNION_MY)},
                --{_index = TAB.hire, _str = Str(STR.UNION_HIRE)},
--                {_index = TAB.tech, _str = Str(STR.UNION_TECH)},
--                {_index = TAB.boss, _str = Str(STR.UNION_CHALLENGE)},
                --{_index = TAB.blacksmith, _str = Str(STR.UNION_BLACKSMITH)},
                --{_index = TAB.shop, _str = Str(STR.UNION_SHOP)},
                {_index = TAB.search, _str = Str(STR.SEARCH_UNION)}
            }
            self._chatPanel:setVisible(true)
        else
            tabDefs = {
                {_index = TAB.create, _str = Str(STR.CREATE_UNION)},
                {_index = TAB.search, _str = Str(STR.SEARCH_UNION)}
            }
            self._chatPanel:setVisible(false)
        end

        if tabArea then
            tabArea:removeFromParent()
        end

        if self._hasUnion ~= nil then focusedIndex = nil end
        self._hasUnion = hasUnion

        tabArea = V.createHorizontalTabListArea(lc.bottom(self._titleArea), tabDefs, function(tab, isSameTab, isUserBehavior)
            if not isSameTab or isUserBehavior then
                if isUserBehavior then
                --[[
                    if self._myUnionChatArea and self._myUnionChatArea._isBattleWaiting == true then
                        local dialog = require("Dialog").showDialog(Str(STR.CANCEL_INVITE_2), function() 
                            self._myUnionChatArea:onBattleCancel(true)
                            self:showTab(tab)
                        end)
                        dialog._btnCancel._callback = function() 
                            dialog:close()
                            tabArea:showTab(TAB.chat, false)
                        end
                    else
                        self:showTab(tab)
                    end]]

                    self:showTab(tab)
                else
                    self:showTab(tab)
                end
            end
        end)
        lc.addChildToPos(self, tabArea, cc.p(lc.w(tabArea) / 2 - 4, lc.bottom(self._titleArea) - 2 - lc.ch(tabArea)), 1)
        local tabBgPanel = lc.createSprite({_name = 'img_troop_bg_1', _crect = cc.rect(25, 25, 2, 2), _size = cc.size(V.SCR_W, lc.bottom(tabArea) + 11)})
        lc.addChildToPos(self, tabBgPanel, cc.p(lc.cw(self), lc.ch(tabBgPanel)))
        self._tabArea = tabArea
        self._tabBgPanel = tabBgPanel
    end

    if focusedIndex == nil then
        focusedIndex = (hasUnion and TAB.my_union or TAB.create)
    end

    if hasUnion and (focusedIndex == TAB.my_union or focusedIndex == TAB.boss) then
        V.getResourceUI():setMode(Data.PropsId.yubi)
    else
        V.getResourceUI():setMode(Data.ResType.gold)
    end

    tabArea:showTab(focusedIndex, true)
end

function _M:showTab(tab)

    -- check inside content tabs
    if self._myUnionArea then
        self._myUnionArea:setVisible(false)
    end
    --[[
    if self._myUnionChatArea then
        self._myUnionChatArea:setVisible(false)
    end]]
    if self._shopArea then
        self._shopArea:hideCardBox()
        self._shopArea:setVisible(false)
    end

    local contentArea = self._contentArea
    if contentArea and contentArea ~= self._myUnionArea and --[[contentArea ~= self._myUnionChatArea and ]]contentArea ~= self._shopArea then
        if contentArea._linkObjs then
            for _, obj in ipairs(contentArea._linkObjs) do
                obj:removeFromParent()
            end
        end

        contentArea:removeFromParent()
        self._contentArea = nil
    end

    local areaW, areaH, area, areaY = lc.w(self._tabBgPanel), lc.h(self._tabBgPanel)
    if tab._index == TAB.my_union then
        if self._myUnionArea == nil then
            area = UnionArea.create(P._unionId, areaW, areaH)
            areaY = areaH - lc.h(area) / 2
            self._myUnionArea = area
            self:addMyUnionButtonArea(V.UNION_BUTTON_AREA_SIZE.width)
        else
            self._myUnionArea:setVisible(true)
        end

        V.getResourceUI():setMode(Data.PropsId.yubi)

    elseif tab._index == TAB.hire then
        area = HireArea.create(areaW + 10, areaH)
        V.getResourceUI():setMode(Data.PropsId.yubi)

    elseif tab._index == TAB.tech then
        area = TechArea.create(areaW + 10, areaH)
        V.getResourceUI():setMode(Data.PropsId.yubi)

    elseif tab._index == TAB.create then
        area = CreateArea.create(CreateArea.Mode.create, areaW)
        V.getResourceUI():setMode(Data.ResType.gold)

    elseif tab._index == TAB.search then
        area = SearchArea.create(areaW, areaH)
        V.getResourceUI():setMode(Data.ResType.gold)

    elseif tab._index == TAB.shop then
        if not self._shopArea then
            area = ShopArea.create(areaW, areaH)
            self._shopArea = area
        else
            self._shopArea:setVisible(true)
        end
        V.getResourceUI():setMode(Data.PropsId.yubi)
--[[
    elseif tab._index == TAB.chat then
        if not self._myUnionChatArea then
            area = ChatArea.create(P._unionId, areaW, areaH)
            V.getResourceUI():setMode(Data.PropsId.yubi)
            self._myUnionChatArea = area
        else
            self._myUnionChatArea:setVisible(true)
        end]]
    end

    if area then
        lc.addChildToPos(self, area, cc.p(lc.w(self)/ 2, areaY or lc.h(area) / 2))
        self._contentArea = area
    end
end

function _M:addMyUnionButtonArea(w)
    local unionArea = self._myUnionArea

    local btnArea = lc.createNode(cc.size(w, V.UNION_BUTTON_AREA_SIZE.height))
    lc.addChildToPos(unionArea, btnArea, cc.p(lc.w(btnArea) / 2 + 10, lc.h(btnArea) / 2 + 10))    
    --[[
    local bottomArea = V.createLineSprite("img_bottom_bg", w + 10)
    bottomArea:setAnchorPoint(0, 0)
    lc.addChildToPos(btnArea, bottomArea, cc.p(0, 0))
    self._bottomArea = bottomArea
    ]]

    -- Add buttons
    local btnDistance = 65
    local btnQuit = V.createScale9ShaderButton("img_btn_2_s", function() self:quitUnion() end, V.CRECT_BUTTON_S, 200)
    btnQuit:addLabel(Str(STR.EXIT)..Str(STR.UNION))
    lc.addChildToPos(btnArea, btnQuit, cc.p(lc.cw(btnArea), P._unionJob ~= Data.UnionJob.rookie and 65 or 105))

    local btnContributeLog = V.createScale9ShaderButton("img_btn_1_s", function() UnionMemberForm.createContribute():show() end, V.CRECT_BUTTON_S, 200)
    btnContributeLog:addLabel(Str(STR.VIP)..Str(STR.CONTRIBUTE))
    lc.addChildToPos(btnArea, btnContributeLog, cc.p(lc.x(btnQuit), lc.y(btnQuit) + btnDistance))

    local btnLog = V.createScale9ShaderButton("img_btn_1_s", function() require("UnionLogForm").create():show() end, V.CRECT_BUTTON_S, 200)
    btnLog:addLabel(Str(STR.UNION)..Str(STR.UNION_LOG))
    lc.addChildToPos(btnArea, btnLog, cc.p(lc.x(btnQuit), lc.y(btnContributeLog) + btnDistance))

    local btnContribute = V.createScale9ShaderButton("img_btn_1_s", function()
        require("UnionContributeForm").create(Data.ResType.union_gold):show()
    end, V.CRECT_BUTTON_S, 200)
    btnContribute:addLabel(Str(STR.UNION)..Str(STR.CONTRIBUTE))
    lc.addChildToPos(btnArea, btnContribute, cc.p(lc.x(btnQuit), lc.y(btnLog) + btnDistance))

     if P._unionJob ~= Data.UnionJob.rookie then
        local btnManage = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:popManageItems(sender) end, V.CRECT_BUTTON_S, 200)
        btnManage:addLabel(Str(STR.MANAGE)..Str(STR.UNION))
        btnManage._label:setColor(V.COLOR_TEXT_ORANGE)
        lc.addChildToPos(btnArea, btnManage, cc.p(lc.x(btnQuit), lc.y(btnContribute) + btnDistance))
    end
end

function _M:quitUnion(isForce)
    if P._playerUnion._groupId then
        return ToastManager.push(Str(STR.EXIT_GROUP_FIRST))
    end
    if not isForce then
        local tipStr
        if P._unionJob == Data.UnionJob.leader then
            if P._playerUnion:getMyUnion():getMembersNum() == 1 then
                tipStr = Str(STR.SURE_TO_EXIT_UNION_ONLY_LEADER)
            else
                tipStr = Str(STR.SURE_TO_EXIT_UNION_LEADER)
                require("Dialog").showDialog(tipStr, nil, true)
                return
            end
        else
            tipStr = Str(STR.SURE_TO_EXIT_UNION)
        end

        require("Dialog").showDialog(tipStr, function() self:quitUnion(true) end)

        return
    end

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendUnionLeave()
end

function _M:popInfoItems(btnManage)
    local size, btnDefs = cc.size(200, 320), {}
    local playerUnion = P._playerUnion
    local union = playerUnion:getMyUnion()

    table.insert(btnDefs, {_str = Str(STR.UNION)..Str(STR.UNION_LOG), _handler = function()
        require("UnionLogForm").create():show()
    end})

    
    table.insert(btnDefs, {_str = Str(STR.MEMBER_CONTRIBUTE), _handler = function()
        UnionMemberForm.createContribute():show()
    end})
--    table.insert(btnDefs, {_str = Str(STR.MEMBER_ACTIVITY), _handler = function()
--        require("UnionMemberForm").createActivity():show()
--    end})

    local panel = require("TopMostPanel").ButtonList.create(size)
    if panel then
        local gPos = lc.convertPos(cc.p(0, lc.h(btnManage)), btnManage)
        panel:setButtonDefs(btnDefs)
        panel:setPosition(gPos.x + lc.w(panel) / 2, gPos.y + lc.h(panel) / 2 + 6)
        panel:linkNode(btnManage)
        panel:show()
    end
end

function _M:popManageItems(btnManage)
    local size, btnDefs = cc.size(200, 320), {}
    local playerUnion = P._playerUnion
    local union = playerUnion:getMyUnion()

    --[[
    table.insert(btnDefs, {_str = Str(STR.UPGRADE)..Str(STR.UNION), _handler = function()
        if union._level < union:getMaxLevel() then
            require("UnionUpgradeForm").create():show()
        else
            ToastManager.push(string.format(Str(STR.REACH_MAX_LEVEL), Str(STR.UNION)))
        end
    end})
    ]]

    table.insert(btnDefs, {_str = Str(STR.SEND_GROUP)..Str(STR.MAIL), _handler = function()
        require("SendMailForm").create():show()
    end})

    table.insert(btnDefs, {_isSeparator = true}) 

    table.insert(btnDefs, {_str = Str(STR.CHANGE)..Str(STR.INFO), _handler = function()
        require("UnionEditForm").create():show()
    end})

    local panel = require("TopMostPanel").ButtonList.create(size)
    if panel then
        local gPos = lc.convertPos(cc.p(lc.w(btnManage), lc.h(btnManage)), btnManage)
        panel:setButtonDefs(btnDefs)
        panel:setPosition(gPos.x + lc.w(panel) / 2 + 6, gPos.y - lc.h(panel) / 2 + 2)
        panel:linkNode(btnManage)
        panel:show()
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    local listeners = {}
    table.insert(listeners, lc.addEventListener(Data.Event.union_dirty, function()
        V.getActiveIndicator():hide()
        self:updateTabs()
    end))

    table.insert(listeners, lc.addEventListener(Data.Event.union_enter_dirty, function()
        V.getActiveIndicator():hide()
        self:syncData()
    end))
    
    table.insert(listeners, lc.addEventListener(Data.Event.union_exit_dirty, function()
        if self._myUnionArea then
            if self._contentArea == self._myUnionArea then
                self._contentArea = nil
            end
            self._myUnionArea:removeFromParent()
            self._myUnionArea = nil
        end

        self:clearPanels()

        V.getActiveIndicator():hide()
        self:syncData()
    end))

    table.insert(listeners, lc.addEventListener(Data.Event.union_edit_dirty, function()
        V.getActiveIndicator():hide()
        self:syncData()
    end))

    self._listeners = listeners

    self:syncData()
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    V.getResourceUI():setVisible(true)
end

return _M