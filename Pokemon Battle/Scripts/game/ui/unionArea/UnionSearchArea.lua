local _M = class("UnionSearchArea", lc.ExtendCCNode)

local AREA_WIDTH_MAX = 800

local FILTER = {
    name        = 1,
    id          = 2,
    level       = 3,
}

function _M.create(w, h)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(math.min(w, AREA_WIDTH_MAX), h)
    area:init()

    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        end
    end)

    return area
end

function _M:init()
    local areaW, areaH = lc.w(self), lc.h(self)
    --[[
    local topBg = lc.createSprite{_name = "img_com_bg_4", _crect = V.CRECT_COM_BG4, _size = cc.size(areaW - 12, 110)}
    lc.addChildToPos(self, topBg, cc.p(areaW / 2 + 4, areaH - lc.h(topBg) / 2 - 8), 1)
    ]]
    local btnSearch = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:searchUnion() end, V.CRECT_BUTTON_S, 150)
    btnSearch:addIcon("img_icon_search_2") 
    btnSearch:addLabel(Str(STR.SEARCH))
    lc.addChildToPos(self, btnSearch, cc.p(lc.w(self) - lc.w(btnSearch) / 2 - 30, areaH - lc.ch(btnSearch) - 30), 1)

    local btnFilter = V.createShaderButton(nil, nil)
    btnFilter:setContentSize(cc.size(150, 36))
    local btnLabel = V.createBMFont(V.BMFont.huali_20, "")
    btnLabel:setColor(V.COLOR_TEXT_ORANGE)
    local btnIcon = lc.createSprite("img_triangle")
    lc.addChildToPos(btnFilter, btnLabel, cc.p(lc.cw(btnFilter) - 2, lc.h(btnFilter) / 2 + 1))
    lc.addChildToPos(btnFilter, btnIcon, cc.p(lc.right(btnLabel) + 49 + lc.cw(btnIcon), lc.h(btnFilter) / 2 + 1))
    lc.addChildToPos(self, btnFilter, cc.p(lc.w(btnFilter) / 2 + 30, lc.y(btnSearch)))

    btnLabel:setString(Str(STR.UNION_NAME))
    btnFilter._label = btnLabel
    btnFilter._filter = FILTER.name
    btnFilter._callback = function()
        local createDef = function(str, filter, isSeparator)
            return {_str = str, _handler = function()
                btnFilter._filter = filter
                btnFilter._label:setString(str)
            end, 
            _isSeparator = isSeparator}
        end

        local buttonDefs = {
            createDef(Str(STR.UNION_NAME), FILTER.name),
            createDef(nil, nil, true),
            createDef(Str(STR.UNION).." ID", FILTER.id),
            --createDef(Str(STR.UNION)..Str(STR.LEVEL), FILTER.level)
        }
        self:popSelectPanel(btnFilter, buttonDefs)
    end
    self._btnFilter = btnFilter

    local input = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(lc.left(btnSearch) - 16 - lc.right(btnFilter), 56), nil, true)
    lc.addChildToPos(self, input, cc.p(lc.right(btnFilter) + lc.w(input) / 2 + 8, lc.y(btnSearch)))
    self._iptSearch = input
    
    local unionBgPanel = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(V.SCR_W - 40, lc.bottom(input) - 30)})
    lc.addChildToPos(self, unionBgPanel, cc.p(lc.cw(self), lc.ch(unionBgPanel) + 20))
    local unionList = lc.List.createV(cc.size(lc.w(unionBgPanel) - 12, lc.h(unionBgPanel) - 20), 10, 16)
    unionList:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(unionBgPanel, unionList)
    self._unionList = unionList
end

function _M:popSelectPanel(parent, buttonDefs)
    local panel = require("TopMostPanel").ButtonList.create(cc.size(170, lc.h(self) - 40))
    if panel then
        local gPos = lc.convertPos(cc.p(lc.w(parent) / 2, lc.h(parent) / 2), parent)
        panel:setButtonDefs(buttonDefs)
        panel:setPosition(gPos.x, gPos.y - lc.h(panel) / 2 - 24)
        panel:linkNode(parent)
        panel:show()
    end
end

function _M:updateUnionList(unions)
    if self._indicator then
        self._indicator:removeFromParent()
        self._indicator = nil
    end

    local list = self._unionList
    list:removeAllItems()

    -- Create items
    list:bindData(unions, function(item, union) self:setOrCreateUnionItem(item, union) end, math.min(6, #unions))

    for i = 1, list._cacheCount do
        local item = self:setOrCreateUnionItem(nil, unions[i])
        list:pushBackCustomItem(item)
    end

    list:checkEmpty(Str(STR.LIST_EMPTY_SEARCH))

    list:refreshView()
    list:gotoTop()
end

function _M:setOrCreateUnionItem(item, union)
    if item == nil then
        item = ccui.Widget:create()
        item:setContentSize(lc.w(self._unionList) - 20, 186)
        item:setTouchEnabled(true)
        item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

        local bg = lc.createSprite{_name = "img_troop_bg_6", _crect = V.CRECT_TROOP_BG, _size = item:getContentSize()}
        lc.addChildToCenter(item, bg, -1)
        item._bg = bg

        local unionWidget = require("UnionWidget").create(nil, true)
        lc.addChildToPos(item, unionWidget, cc.p(lc.w(unionWidget) / 2 + 25, lc.h(item) / 2))
        item._unionWidget = unionWidget

        local joinType = V.createTTFStroke("", V.FontSize.S2, V.COLOR_TEXT_LIGHT)
        joinType:setAnchorPoint(1, 0.5)
        lc.addChildToPos(item, joinType, cc.p(lc.w(item) - 50, lc.h(item) / 2 + 38))
        item._joinType = joinType

    end

    item:addTouchEventListener(function(sender, evt)
        if evt == ccui.TouchEventType.ended then
            require("UnionDetailForm").create(item._union._id):show()
            --[[
            if P:hasUnion() then
                
            else
                V.operateUnion(item._union, item)
            end
            ]]
        end
    end)

    item._union = union

    item._unionWidget:setUnion(union)

    item._joinType:setString(Str(STR.UNION_TYPE_ANY + union._joinType - 1))

    if union._reqLevel > 0 then
        item._level = string.format("Lv%d",  union._reqLevel)
    else
        item._level = ""
    end

    if item._btnJoin ~= nil then
        item._btnJoin:removeFromParent()
    end

    if not P:hasUnion() then
        if item._union._joinType ~= Data.UnionJoinType.close then
            local isAny = item._union._joinType == Data.UnionJoinType.any
            local str = item._level..(isAny and Str(STR.JOIN)..Str(STR.UNION) or Str(STR.APPLY)..Str(STR.JOIN))

            local btnJoin = V.createScale9ShaderButton("img_btn_1_s", function()
                if not isAny then
                    ToastManager.push(Str(STR.UNION_APPLY_SEND))
                end
                ClientData.sendUnionApply(item._union._id, Str(STR.UNION_APPLY_MSG))
            end, V.CRECT_BUTTON_S, 220)
            btnJoin:setAnchorPoint(1, 0.5)
            btnJoin:addLabel(str)
            if P:getMaxCharacterLevel() < P._playerCity:getUnionUnlockLevel() then
                btnJoin:setDisabledShader(V.SHADER_DISABLE)
                btnJoin:setEnabled(false)
            end
            lc.addChildToPos(item, btnJoin, cc.p(lc.x(item._joinType), lc.bottom(item._joinType) - 12 - lc.ch(btnJoin)))
            item._btnJoin = btnJoin
        end
    else
        local level = V.createTTFStroke(item._level, V.FontSize.S3, V.COLOR_TEXT_LIGHT)
        level:setAnchorPoint(1, 0.5)
        level:setColor(V.COLOR_TEXT_GRAY)
        lc.addChildToPos(item, level, cc.p(lc.x(item._joinType), lc.bottom(item._joinType) - 24))
    end

    return item
end

function _M:searchUnion()
    local keyword = self._iptSearch:getText()
    self._iptSearch:setText("")

    if keyword == "" then
        self._indicator = V.showPanelActiveIndicator(self)
        ClientData.sendGetRecommandUnions()
    else
        local searchType = self._btnFilter._filter
        local searchNames = {"name", "id", "level"}
        if searchType == FILTER.id or searchType == FILTER.level then
            keyword = tonumber(keyword)
            if keyword == nil then
                ToastManager.push(Str(STR.INVALID_SEARCH))
                return
            end
        end
        
        self._indicator = V.showPanelActiveIndicator(self)
        ClientData.sendGetSearchUnions(searchNames[searchType], keyword)
    end
end

function _M:onEnter()
    self._listeners = {}
    
    local listener = lc.addEventListener(Data.Event.union_search_dirty, function(event)
        self:updateUnionList(P._playerUnion:getSearchUnions())
    end)
    table.insert(self._listeners, listener)
    
    listener = lc.addEventListener(Data.Event.union_recommand_dirty, function(event)
        self:updateUnionList(P._playerUnion:getRecommandUnions())
    end)
    table.insert(self._listeners, listener)

    -- Send packet
    self._indicator = V.showPanelActiveIndicator(self)
    ClientData.sendGetRecommandUnions()
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

return _M