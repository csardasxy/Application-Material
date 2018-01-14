local _M = class("BattleCardSelectForm", BaseForm)

local CardInfoPanel = require("CardInfoPanel")

local MARGIN_H = 30
local TITLE_CARD_FLAG = 100
local ICON_D = 100
local ICON_GAP = 26
local SEARCH_AREA_H = 120

local SEARCH_MARGIN_LEFT = 60
local SEARCH_MARGIN_RIGHT = 60
local SEARCH_MARGIN_TOP = 40

local MAX_COLUMNS = 8

local RANDOM_BTN_WIDTH = 150

local SPACING_FRAME_TO_LIST = 130

local KEY = {
    _A           = 124,
    _B           = 125,
    _C           = 126,
    _D           = 127,
    _E           = 128,
    _F           = 129,
    _G           = 130,
    _H           = 131,
    _I           = 132,
    _J           = 133,
    _K           = 134,
    _L           = 135,
    _M           = 136,
    _N           = 137,
    _O           = 138,
    _P           = 139, 
    _Q           = 140,
    _R           = 141,
    _S           = 142,  
    _T           = 143,
    _U           = 144,
    _V           = 145,
    _W           = 146,
    _X           = 147,
    _Y           = 148,
    _Z           = 149,
    _ENTER       = 35, -- to confirm searching
    _BACKSPACE   = 7,
    _DELETE      = 23, -- to clear searching content
    _SPACE       = 59, -- to confirm selecting a card
    _LEFT        = 26,
    _RIGHT       = 27,
    _UP          = 28,
    _DOWN        = 29,
    _0           = 76,
    _1           = 77,
    _2           = 78,
    _3           = 79,
    _4           = 80,
    _5           = 81,
    _6           = 82,
    _7           = 83,
    _8           = 84,
    _9           = 85,
    _ESC         = 6,

}

local SEARCH_TYPE = {
    _CARD_MONSTER_ID     = 1,
    _CARD_MAGIC_ID     = 2,
    _CARD_TRAP_ID     = 3,
    _CARD_RARE_ID     = 4,
    _SKILL_ID    = 5,
    _ATK         = 6,
    _DEFEND      = 7,
    _PINYIN      = 8,
    _NATURE      = 9,
    _CATEGORY    = 10,
    _KEYWORD     = 11,
}

function _M.create(selectTypes, callback, hideSomeSkill)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(selectTypes, callback, hideSomeSkill)
    return panel
end

function _M:init(selectTypes, callback, hideSomeSkill)
    local visibleSize = lc.Director:getVisibleSize()
     _M.super.init(self, cc.size(visibleSize.width - (16 + V.FRAME_TAB_WIDTH) * 2, 680), Str(STR.BATTLE_TEST_SELECT_CARD), bor(0))

     self._hideBg = true
     self._callback = callback
     self._searchContent = ""

     self:resetIcons()
     self._form:setTouchEnabled(false)
     self:createSearchArea()
     self:createCardArea(selectTypes, hideSomeSkill)
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    
    self:resetIcons()    
    CardInfoPanel._operateType = CardInfoPanel.OperateType.na
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    self._keyListener = lc.addEventListener(Data.Event.unitest, function(event) 
        self:onKeyEvent(event)
    end)
end

function _M:onExit()
    _M.super.onExit(self)

    lc.Dispatcher:removeEventListener(self._keyListener)
end

function _M:onKeyEvent(event)
    local key = tonumber(event._key)
    
    if key == KEY._LEFT then
        if #self._icons > 1 and self._selected > 1 then
            self._selected = self._selected - 1
            self:updateView()
        end
    elseif key == KEY._RIGHT then 
        if #self._icons > 1 and self._selected < #self._icons then
            self._selected = self._selected + 1
            self:updateView()
        end
    elseif key == KEY._UP then
        if #self._icons > 9 and self._selected > MAX_COLUMNS then
            self._selected = self._selected - MAX_COLUMNS
            self:updateView()
        end
    elseif key == KEY._DOWN then
        if #self._icons > 9 and self._selected + MAX_COLUMNS <= #self._icons then
            self._selected = self._selected + MAX_COLUMNS
            self:updateView()
        end
    elseif key == KEY._ENTER then
        if #self._icons > 0 then
            self:hide() 
            if self._callback and #self._icons > 0 then 
                local icon = self._icons[self._selected]
                self._callback(icon._data._infoId, false) 
            end 
        end
    elseif key == KEY._ESC then
        self:hide() 
    elseif key == KEY._BACKSPACE then
        if self._searchContent ~= "" then
            self._searchContent = string.sub(self._searchContent, 1, #self._searchContent - 1)
        end
        self._editor:setText(self._searchContent)
        self:search()
    else 
        self._searchContent = self._searchContent .. self:parseKey(key)
        self._editor:setText(self._searchContent)
        self:search()
    end
    print("[UNITTEST] searching: ", self._searchContent)
end

function _M:search()
--    if self._searchContent ~= "" then
        self._selected = nil
        self:resetIcons()
        self:filter(self._searchContent)
        self:insertCards()
        self:updateView()
--    end
end

function _M:parseKey(key)
    if key == KEY._0 then
        return "0"
    elseif key == KEY._1 then
        return "1"
    elseif key == KEY._2 then
        return "2"
    elseif key == KEY._3 then
        return "3"
    elseif key == KEY._4 then
        return "4"
    elseif key == KEY._5 then
        return "5"
    elseif key == KEY._6 then
        return "6"
    elseif key == KEY._7 then
        return "7"
    elseif key == KEY._8 then
        return "8"
    elseif key == KEY._9 then
        return "9"
    elseif key == KEY._A then
        return "A"
    elseif key == KEY._B then
        return "B"
    elseif key == KEY._C then
        return "C"
    elseif key == KEY._D then
        return "D"
    elseif key == KEY._E then
        return "E"
    elseif key == KEY._F then
        return "F"
    elseif key == KEY._G then
        return "G"
    elseif key == KEY._H then
        return "H"
    elseif key == KEY._I then
        return "I"
    elseif key == KEY._J then
        return "J"
    elseif key == KEY._K then
        return "K"
    elseif key == KEY._L then
        return "L"
    elseif key == KEY._M then
        return "M"
    elseif key == KEY._N then
        return "N"
    elseif key == KEY._O then
        return "O"
    elseif key == KEY._P then
        return "P"
    elseif key == KEY._Q then
        return "Q"
    elseif key == KEY._R then
        return "R"
    elseif key == KEY._S then
        return "S"
    elseif key == KEY._T then
        return "T"
    elseif key == KEY._U then
        return "U"
    elseif key == KEY._V then
        return "V"
    elseif key == KEY._W then
        return "W"
    elseif key == KEY._X then
        return "X"
    elseif key == KEY._Y then
        return "Y"
    elseif key == KEY._Z then
        return "Z"
    elseif key == KEY._SPACE then
        return "_"
    end
    
    return ""
end

function _M:createSearchArea(args)
    local EDITOR_W = lc.w(self._frame) - SEARCH_MARGIN_LEFT - SEARCH_MARGIN_RIGHT - RANDOM_BTN_WIDTH * 2
    local EDITOR_H = SEARCH_AREA_H - 45

    local LAYOUT_WIDTH = lc.w(self._frame) - SEARCH_MARGIN_LEFT - SEARCH_MARGIN_RIGHT
    local LAYOUT_HEIGHT = SEARCH_AREA_H

    local layout = ccui.Layout:create()
    layout:setContentSize(LAYOUT_WIDTH, LAYOUT_HEIGHT)
    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(EDITOR_W, EDITOR_H), Str(STR.INPUT_CARDID_SKILLID_ATTACK_DEFEND_PINYIN))
    editor:setAnchorPoint(0, 0.5)
    lc.addChildToPos(layout, editor, cc.p(0, lc.h(layout) / 2), 10)
    self._editor = editor
    self._editor:setTouchEnabled(false)

    local btn2Cards = V.createScale9ShaderButton("img_btn_1", nil, V.CRECT_BUTTON, RANDOM_BTN_WIDTH)
    btn2Cards:addLabel(string.format(Str(STR.GEN_N_CARDS), 2))
    btn2Cards:setAnchorPoint(0, 0)
    btn2Cards._callback = function(sender)
        self:genCards(2)
    end
    lc.addChildToPos(layout, btn2Cards, cc.p(lc.right(self._editor) + 10, V.FRAME_INNER_BOTTOM - 5))
    self._btn2Cards = btn2Cards

    local btn5Cards = V.createScale9ShaderButton("img_btn_1", nil, V.CRECT_BUTTON, RANDOM_BTN_WIDTH)
    btn5Cards:addLabel(string.format(Str(STR.GEN_N_CARDS), 5))
    btn5Cards:setAnchorPoint(0, 0)
    btn5Cards._callback = function(sender)
        self:genCards(5)
    end
    lc.addChildToPos(layout, btn5Cards, cc.p(lc.right(self._btn2Cards) + 10, V.FRAME_INNER_BOTTOM - 5))
    self._bbtn5Cards = btn5Cards

--    local btnSearch = V.createScale9ShaderButton("img_btn_1", nil, V.CRECT_BUTTON, 100)
--    btnSearch:addLabel(Str(STR.SEARCH))
--    btnSearch:setAnchorPoint(1, 0)
--    btnSearch._callback = function(sender)
--        local text = editor:getText()
--        self:filter(text)
--        self:insertCards()
--        self:updateView()
--    end
--    lc.addChildToPos(layout, btnSearch, cc.p(lc.w(layout), V.FRAME_INNER_BOTTOM))
--    self._btnSearch = btnSearch

    layout:setAnchorPoint(0, 1)
    lc.addChildToPos(self._frame, layout, cc.p(SEARCH_MARGIN_LEFT, lc.h(self._frame) - SEARCH_MARGIN_TOP), 20)
end

function _M:createCardArea(selectTypes, hideSomeSkill)
    local areaW = lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT
    local areaH = lc.h(self._frame) - V.FRAME_INNER_BOTTOM - V.FRAME_INNER_BOTTOM - SEARCH_AREA_H

    local list = lc.List.createV(cc.size(areaW, areaH), 10, 10)
    list:setAnchorPoint(0.5, 0)
    lc.addChildToPos(self._frame, list, cc.p(lc.w(self._frame) / 2, V.FRAME_INNER_BOTTOM), 10)
    self._list = list

    self._cardCountInRow = math.floor(lc.w(list) / (ICON_D + ICON_GAP))

    -- Prepare card data
    self._data = {{}, {}, {}, {}}

    for i = 1, #selectTypes do
        if selectTypes[i] == _SELECT_CARD_TYPE.MONSTER then
            local monsters = self._data[1]
            for infoId, info in pairs(Data._monsterInfo) do
                if Data.isUserVisible(infoId) then
                    monsters[#monsters + 1] = info
                end
            end
            table.sort(monsters, function(a, b) return a._id < b._id end)

        elseif selectTypes[i] == _SELECT_CARD_TYPE.MAGIC then
            local magics = self._data[2]
            for infoId, info in pairs(Data._magicInfo) do
                if Data.isUserVisible(infoId) then
                    if hideSomeSkill and info._type ~= 11 then
                        magics[#magics + 1] = info
                    elseif hideSomeSkill == nil then
                        magics[#magics + 1] = info
                    end
                end
            end
            table.sort(magics, function(a, b) return a._id < b._id end)

        --[[
        elseif selectTypes[i] == _SELECT_CARD_TYPE.TRAP then
            local traps = self._data[3]
            for infoId, info in pairs(Data._trapInfo) do
                if Data.isUserVisible(infoId) then
                    if hideSomeSkill and info._type ~= 11 then
                        traps[#traps + 1] = info
                   elseif hideSomeSkill == nil then 
                        traps[#traps + 1] = info
                    end
                end
            end
            table.sort(traps, function(a, b) return a._id > b._id end)
        ]]

        end
    end
end

function _M:filter(keyword)
    self._searchKey = nil
    self._searchType = nil
    local kw
    kw = string.lower(keyword)
    kw = string.trim(kw)
    if tonumber(kw) == nil and kw ~= '' then
        local first = string.sub(kw, 1, 1)
        local preTow = string.sub(kw, 1, 2)
        local suffix = string.sub(kw, 3)
        local others = string.sub(kw, 2)
        others = tonumber(others)

        
        self._searchKey = {}
        -- nature
        if preTow == 'n_' then
            lc.log("n empty {" .. suffix)
            if suffix == nil or suffix == "" then
            else
                if string.find('guang', suffix) == 1  then
                    table.insert(self._searchKey, 1)
                    self._searchType = SEARCH_TYPE._NATURE
                end
                if string.find('an', suffix) == 1 then
                    table.insert(self._searchKey, 2)
                    self._searchType = SEARCH_TYPE._NATURE
                end
                if string.find('di', suffix) == 1 then
                    table.insert(self._searchKey, 3)
                    self._searchType = SEARCH_TYPE._NATURE
                end
                if string.find('yan', suffix) == 1 then
                    table.insert(self._searchKey, 4)
                    self._searchType = SEARCH_TYPE._NATURE
                end
                if string.find('shui', suffix) == 1 then
                    table.insert(self._searchKey, 5)
                    self._searchType = SEARCH_TYPE._NATURE
                end
                if string.find('feng', suffix) == 1 then
                    table.insert(self._searchKey, 6)
                    self._searchType = SEARCH_TYPE._NATURE
                end
                if string.find('shen', suffix) == 1 then
                    table.insert(self._searchKey, 7)
                    self._searchType = SEARCH_TYPE._NATURE
                end
            end

        -- category
        elseif preTow == 'c_' then
            lc.log("c empty {" .. suffix)
            if suffix == nil or suffix == "" then
            else
                if string.find('mofashi', suffix) == 1 then
                    table.insert(self._searchKey, 1)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('long', suffix) == 1 then
                    table.insert(self._searchKey, 2)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('jixie', suffix) == 1 then
                    table.insert(self._searchKey, 3)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('emo', suffix) == 1 then
                    table.insert(self._searchKey, 4)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('shou', suffix) == 1 then
                    table.insert(self._searchKey, 5)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('zhanshi', suffix) == 1 then
                    table.insert(self._searchKey, 6)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('yanshi', suffix) == 1 then
                    table.insert(self._searchKey, 7)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('shui', suffix) == 1 then
                    table.insert(self._searchKey, 8)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('hailong', suffix) == 1 then
                    table.insert(self._searchKey, 9)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('pachong', suffix) == 1 then
                    table.insert(self._searchKey, 10)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('shouzhanshi', suffix) == 1 then
                    table.insert(self._searchKey, 11)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('konglong', suffix) == 1 then
                    table.insert(self._searchKey, 12)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('niaoshou', suffix) == 1 then
                    table.insert(self._searchKey, 13)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('tianshi', suffix) == 1 then
                    table.insert(self._searchKey, 14)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('kunchong', suffix) == 1 then
                    table.insert(self._searchKey, 15)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('yu', suffix) == 1 then
                    table.insert(self._searchKey, 16)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('busi', suffix) == 1 then
                    table.insert(self._searchKey, 17)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('zhiwu', suffix) == 1 then
                    table.insert(self._searchKey, 18)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('yan', suffix) == 1 then
                    table.insert(self._searchKey, 19)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
                if string.find('huanshen', suffix) == 1 then
                    table.insert(self._searchKey, 20)
                    self._searchType = SEARCH_TYPE._CATEGORY
                end
            end

        -- keyword
        elseif preTow == 'k_' then
            lc.log("k empty {" .. suffix)
            if suffix == nil or suffix == "" then
            else
                if string.find('heimofashi', suffix) == 1 then
                    table.insert(self._searchKey, 1)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('qingyanbailong', suffix) == 1 then
                    table.insert(self._searchKey, 2)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('emo', suffix) == 1 then
                    table.insert(self._searchKey, 3)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('cishizhanshi', suffix) == 1 then
                    table.insert(self._searchKey, 4)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('liziqiu', suffix) == 1 then
                    table.insert(self._searchKey, 5)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('yamaxun', suffix) == 1 then
                    table.insert(self._searchKey, 6)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('yingshen', suffix) == 1 then
                    table.insert(self._searchKey, 7)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('zhenhongyan', suffix) == 1 then
                    table.insert(self._searchKey, 8)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('jinglingjianshi', suffix) == 1 then
                    table.insert(self._searchKey, 9)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('shengke', suffix) == 1 then
                    table.insert(self._searchKey, 10)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('duotianshi', suffix) == 1 then
                    table.insert(self._searchKey, 11)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('shouhuzhe', suffix) == 1 then
                    table.insert(self._searchKey, 12)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('shengqishi', suffix) == 1 then
                    table.insert(self._searchKey, 13)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                if string.find('yuansuyingxiong', suffix) == 1 then
                    table.insert(self._searchKey, 14)
                    self._searchType = SEARCH_TYPE._KEYWORD
                end
                
            end

        -- pinyin
        elseif others == nil then
            self._searchKey = kw
            self._searchType = SEARCH_TYPE._PINYIN
            lc.log("pinyin -- " .. kw)

        -- attack
        elseif first == 'a' then 
            local atk = string.sub(kw, 2)
            local atkNum = tonumber(atk)
            if atkNum ~= nil then
                lc.log("atk -- " .. atk)
                self._searchKey = atkNum
                self._searchType = SEARCH_TYPE._ATK
            end

        -- defend
        elseif first == 'd' then
            local defend = string.sub(kw, 2)
            local defendNum = tonumber(defend)
            if defendNum ~= nil then
                lc.log("def -- " .. defend)
                self._searchKey = defendNum
                self._searchType = SEARCH_TYPE._DEFEND
            end

        end
    elseif kw ~= '' then
        local id = tonumber(kw)
        -- monster id
        if id > 10000 and id < 30000 then
            self._searchKey = id
            self._searchType = SEARCH_TYPE._CARD_MONSTER_ID
            lc.log("monster id " .. id)

        -- magic id
        elseif id > 30000 and id < 40000 then
            self._searchKey = id
            self._searchType = SEARCH_TYPE._CARD_MAGIC_ID
            lc.log("magic id " .. id)

        -- trap id
        elseif id > 40000 and id < 50000 then
            self._searchKey = id
            self._searchType = SEARCH_TYPE._CARD_TRAP_ID
            lc.log("trap id " .. id)

        -- skill id
        elseif id > 0 and id < 10000 then
            self._searchKey = id
            self._searchType = SEARCH_TYPE._SKILL_ID
            lc.log("skill id " .. id)

        end
    end
    
    self._filterData = {}
    -- no type return
    if self._searchType == nil or self._searchKey == nil then
        return
    end
    -- card id
    if self._searchType <= SEARCH_TYPE._CARD_RARE_ID then
        for _, card in ipairs(self._data[self._searchType]) do
            if self._searchKey == card._id then
                table.insert(self._filterData, card)
                lc.log("add card id -- " .. tostring(card._id))
            end
        end

    -- skill id
    elseif self._searchType == SEARCH_TYPE._SKILL_ID then
        for i = 1, #self._data do
            local cards = self._data[i]
            for _, card in ipairs(cards) do
                local skills = card._skillId
                for _, skillId in ipairs(skills) do
                    if self._searchKey == skillId then
                        table.insert(self._filterData, card)
                        lc.log("add skill id -- " .. tostring(skillId))
                        break
                    end
                end
            end
        end
    -- attack
    elseif self._searchType == SEARCH_TYPE._ATK then
        local cards = self._data[SEARCH_TYPE._CARD_MONSTER_ID]
        for _, card in ipairs(cards) do
            if self._searchKey == card._atk[1] then
                table.insert(self._filterData, card)
                lc.log("add attack -- " .. tostring(card._atk[1]))
            end
        end
        cards = self._data[SEARCH_TYPE._CARD_RARE_ID]
        for _, card in ipairs(cards) do
            if self._searchKey == card._atk[1] then
                table.insert(self._filterData, card)
                lc.log("add attack -- " .. tostring(card._atk[1]))
            end
        end
    -- defend
    elseif self._searchType == SEARCH_TYPE._DEFEND then
        local cards = self._data[SEARCH_TYPE._CARD_MONSTER_ID]
        for _, card in ipairs(cards) do
            if self._searchKey == card._hp[1] then
                table.insert(self._filterData, card)
                lc.log("add defend -- " .. tostring(card._hp[1]))
            end
        end
        cards = self._data[SEARCH_TYPE._CARD_RARE_ID]
        for _, card in ipairs(cards) do
            if self._searchKey == card._hp[1] then
                table.insert(self._filterData, card)
                lc.log("add defend -- " .. tostring(card._hp[1]))
            end
        end
    -- pinyin
    elseif self._searchType == SEARCH_TYPE._PINYIN then
        for i = 1, #self._data do
            local cards = self._data[i]
            for _, card in ipairs(cards) do
                local s, _ = string.find(card._py, self._searchKey)
                if s == 1 then 
                    lc.log(type(result))
                    table.insert(self._filterData, card)
                    lc.log("add pinyin -- " .. card._py)
                end
            end
        end
    -- nature
    elseif self._searchType == SEARCH_TYPE._NATURE then
        for i = 1, #self._data do
            local cards = self._data[i]
            for _, card in ipairs(cards) do
                local nature = card._nature
                for i = 1, #self._searchKey do
                    if nature == self._searchKey[i] then
                        table.insert(self._filterData, card)
                        break
                    end
                end
            end
        end
    -- category
    elseif self._searchType == SEARCH_TYPE._CATEGORY then
        for i = 1, #self._data do
            local cards = self._data[i] 
            for _, card in ipairs(cards) do
                local category = card._category
                for i = 1, #self._searchKey do
                    if category == self._searchKey[i] then
                        table.insert(self._filterData, card)
                        break
                    end
                end
            end
        end
    -- keyword
    elseif self._searchType == SEARCH_TYPE._KEYWORD then
        for i = 1, #self._data do
            local cards = self._data[i] 
            for _, card in ipairs(cards) do
                local keyword = card._keyword
                for i = 1, #self._searchKey do
                    if keyword == self._searchKey[i] then
                        table.insert(self._filterData, card)
                        break
                    end
                end
            end
        end
    end
end

function _M:filterSelectedCard(selectedId)
    lc.log("filterSelectedCard")
    if self._filterData then   
        lc.log("filterdata not null")
        lc.log("filteData type is " .. type(self._filterData))
        lc.dumpTable(self._filterData)
        for _, card in ipairs(self._filterData) do
            lc.log("filter card id is " .. tostring(card._id))
            if card._id == selectedId then
                lc.log("insert " .. selectedId)
                table.insert(self._selectedData, card)
            end
        end
    end
end

function _M:insertCards()
    local listData = self:addCards(self._filterData)
    local list = self._list
    lc.log("list type : " .. type(list))

    self._icons = {}
    if list ~= nil then
        list:removeAllItems()
        if listData then
            list:bindData(listData, function(item, data) self:setOrCreateItem(item, data) end, math.min(8, #listData), 1)

            for i = 1, list._cacheCount do
                local data = listData[i]
                local item = self:setOrCreateItem(nil, data)
                list:pushBackCustomItem(item)
            end

            list:jumpToTop()
        end
    end
end

function _M:genCards(num)
    num = num or 1
    
    local totalIds = {}
    for i = 1, #self._data do
        for j = 1, #self._data[i] do
            local card = self._data[i][j]
            table.insert(totalIds, card._id)
        end
    end
    lc.log("num is " .. num)

    for i = 1, num do
        local random = math.random(#totalIds)
        lc.log("======================genCard" .. totalIds[random])

        self._callback(totalIds[random], true)
    end
    self:hide()
    
--    self:updateView()
end

function _M:getCardId(selected) 
    

end

function _M:addCards(cards)
    if cards == nil or #cards == 0 then
        return nil
    end
    local listData = {}
    local card = cards[1]
--        lc.dumpTable(card)
    local rowData = {}
    for _, info in ipairs(cards) do
        table.insert(rowData, info)
        if #rowData == self._cardCountInRow then
            table.insert(listData, rowData)
            rowData = {}
        end
    end

    if #rowData > 0 then
        table.insert(listData, rowData)
    end

    -- Check whether there are any data in this quality
    if type(listData[#listData]) == "number" then
        table.remove(listData)
    end
    return listData
end

function _M:setOrCreateItem(item, data)
    if item == nil then
        item = ccui.Widget:create()
    end

    item:removeAllChildren()

    if type(data) == "number" then
        
    else
        local width = (ICON_D + ICON_GAP) * self._cardCountInRow - ICON_GAP

        item:setContentSize(width, 130)

        local pos = cc.p(ICON_D / 2, lc.h(item) / 2)
        for _, info in ipairs(data) do
            local icon = IconWidget.create({_infoId = info._id})
            -- add star start--------------------------
--            local starCount = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.M1)
            local starCount = V.createBMFont(V.BMFont.huali_20, "")
            starCount:setScale(0.7)
            lc.addChildToPos(icon._frame, starCount, cc.p(lc.w(icon._frame) - lc.w(starCount) / 2 - 20, lc.h(starCount) / 2 + 25))
            starCount:setString(info._quality)

            local starIcon = lc.createSprite('card_quality')
            starIcon:setScale(0.7)
            lc.addChildToPos(icon._frame, starIcon, cc.p(lc.left(starCount) - lc.w(starIcon) / 2, lc.h(starIcon) / 2 + 10))

            -- add star end----------------------------
            icon._name:setColor(V.COLOR_BMFONT)
            icon._callback = function(icon)
                self:hide() 
                if self._callback then 
                    self._callback(icon._data._infoId, false) 
                end 
            end
            lc.addChildToPos(item, icon, pos)
            table.insert(self._icons, icon)
            pos.x = pos.x + ICON_D + ICON_GAP
        end
    end
    return item
end

function _M:updateView()
    if not self._selected and #self._icons >= 1 then
--        local icon = self._icons[i]
--        if not icon._glow then
--            local bones = DragonBones.create("xuanzhong")
--            bones:gotoAndPlay("effect1")
--            bones:setScale(1.4)
--            lc.addChildToCenter(widget, bones, -1)
--            icon._glow = bones
--        end
        self._selected = 1
    end

    for i = 1, #self._icons do
        local icon = self._icons[i]
        if i == self._selected then
            if not icon._selPanel then
                lc.log("box rect : " .. lc.w(icon) .. "--" .. lc.h(icon))
                local panel = lc.createImageView{_name = "img_com_bg_37", _crect = cc.rect(25, 27, 1, 2)}
                panel:setContentSize(lc.w(icon) + 8, lc.h(icon) + 8) 
                lc.addChildToCenter(icon, panel, -1)
                icon._selPanel = panel
            end
        else 
            if icon._selPanel then
                icon._selPanel:removeFromParent()
                icon._selPanel = null
            end
        end
    end
    
end

function _M:resetIcons()
    if not self._icons then
        self._icons = {}
        return
    end

    for i = #self._icons, 1, -1 do
        local icon = self._icons[i]
        if icon then
            if icon._selPanel then
                icon._selPanel:removeFromParent()
                icon._selPanel = nil
            end
            table.remove(self._icons, i)
        end
    end
end

return _M