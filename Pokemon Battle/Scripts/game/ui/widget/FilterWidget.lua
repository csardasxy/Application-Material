local _M = class("FilterWidget", lc.ExtendUIWidget)

_M.ModeType = 
{
    monster = 1,
    magic = 2,
    trap = 3,
    rare = 4,
    hire = 5,
    skin = 10,
    
    illustration = 100,
}

_M.SortType = 
{
    quality = 1,
    life = 2,
    cost = 3,
}

_M.SortFunc = 
{
    P.sortByQuality,
    P.sortCardsByHP,
    P.sortCardsByNum,
}

_M.SortStr = 
{
    Str(STR.QUALITY),
    Str(STR.LIFE),
    Str(STR.AMOUNT),
}

_M.FilterNature = 
{
    all = 1,
    light = 2,
    dark = 3,
    earth = 4,
    fire = 5,
    water = 6,    
    wind = 7,
    god = 8,
}

_M.FilterNatureKeyword = 
{
    -1,
    Data.CardNature.grass,
    Data.CardNature.fire,
    Data.CardNature.water,
    Data.CardNature.thunder,
    Data.CardNature.psycho,
    Data.CardNature.might,
    Data.CardNature.dark,
    Data.CardNature.steel,
    Data.CardNature.god,
    Data.CardNature.dragon,
    Data.CardNature.common,
}

_M.FilterNatureStr = 
{
    Str(STR.ALL)..Str(STR.ATTRIBUTE),
    Str(STR.NATURE_GRASS),
    Str(STR.NATURE_FIRE),
    Str(STR.NATURE_WATER),
    Str(STR.NATURE_THUNDER),  
    Str(STR.NATURE_PSYCHO),  
    Str(STR.NATURE_MIGHT),  
    Str(STR.NATURE_DARK),
    Str(STR.NATURE_STEEL),
    Str(STR.NATURE_GOD),
    Str(STR.NATURE_DRAGON),
    Str(STR.NATURE_COMMON),
}

_M.FilterQuality = 
{
    all = 1,
    normal = 2,
    good = 3,
    rare = 4,
    legend = 5,
    saga = 6,    
}

_M.FilterQualityKeyword = 
{
    -1,
    Data.CardQuality.C,
    Data.CardQuality.U,
    Data.CardQuality.R,
    Data.CardQuality.RR,
    Data.CardQuality.SR,
    Data.CardQuality.HR,
    Data.CardQuality.UR,
}

_M.FilterQualityStr = 
{
    Str(STR.ALL)..Str(STR.QUALITY),
    'C',
    'U',
    'R',
    'RR',
    'SR',
    'HR',
    'UR',
}

_M.FilterLevel = 
{ 
    all = 1,
    i = 2,
    ii = 3,
    iii = 4,
}

_M.FilterLevelKeyword = 
{
    -1,
    1,
    2,
    3,
}

_M.FilterLevelStr = 
{
    Str(STR.ALL)..Str(STR.CARD_LEVEL),
    '1',
    '2',
    '3',
}

_M.FilterCategory = 
{
    all = 1,
    magician = 2,
    dragon = 3,
    machinery = 4,
    devil = 5,
    beast = 6,
    warrior = 7,
    rock = 8,
    water = 9,
    sea_dragon = 10,
    worm = 11,
    beast_warrior = 12,
    dinosaur = 13,
    bird_beast = 14,
    angle = 15,
    insect = 16,
    fish = 17,
    undead = 18,
    plant = 19,
    fire = 20,
    imagery_god = 21,
    thund = 22,
}

_M.FilterCategoryKeyword = 
{
    -1,
    Data.CardCategory.magician,
    Data.CardCategory.dragon,
    Data.CardCategory.machinery,
    Data.CardCategory.devil,
    Data.CardCategory.beast,
    Data.CardCategory.warrior,
    Data.CardCategory.rock,
    Data.CardCategory.water,
    Data.CardCategory.sea_dragon,
    Data.CardCategory.worm,
    Data.CardCategory.beast_warrior,
    Data.CardCategory.dinosaur,
    Data.CardCategory.bird_beast,
    Data.CardCategory.angle,
    Data.CardCategory.insect,
    Data.CardCategory.fish,
    Data.CardCategory.undead,
    Data.CardCategory.plant,
    Data.CardCategory.fire,
    Data.CardCategory.imagery_god,
    Data.CardCategory.thund,
}

_M.FilterCategoryStr = 
{
    Str(STR.ALL)..Str(STR.CARD_CATEGORY),
    Str(STR.CARD_CATEGORY_MAGICIAN),
    Str(STR.CARD_CATEGORY_DRAGON),
    Str(STR.CARD_CATEGORY_MACHINERY),
    Str(STR.CARD_CATEGORY_DEVEL),
    Str(STR.CARD_CATEGORY_BEAST),
    Str(STR.CARD_CATEGORY_WARRIOR),
    Str(STR.CARD_CATEGORY_ROCK),
    Str(STR.CARD_CATEGORY_WATER),
    Str(STR.CARD_CATEGORY_SEA_DRAGON),
    Str(STR.CARD_CATEGORY_WORM),
    Str(STR.CARD_CATEGORY_BEAST_WARRIOR),
    Str(STR.CARD_CATEGORY_DINOSAUR),
    Str(STR.CARD_CATEGORY_BIRD_BEAST),
    Str(STR.CARD_CATEGORY_ANGLE),
    Str(STR.CARD_CATEGORY_INSECT),
    Str(STR.CARD_CATEGORY_FISH),
    Str(STR.CARD_CATEGORY_UNDEAD),
    Str(STR.CARD_CATEGORY_PLANT),
    Str(STR.CARD_CATEGORY_FIRE),
    Str(STR.CARD_CATEGORY_IMAGERY_GOD),
    Str(STR.CARD_CATEGORY_THUND),
}

_M.UpdateFlag = {
    sort = 1,
    filter_nature = 2,
    filter_equip = 3,
    filter_quality = 4,
    filter_status = 5,
    filter_category = 6,
    filter_level = 6,
    search = 7
}

local WIDGET_MAX_SIZE = cc.size(V.AREA_MAX_WIDTH, 46)

local SORT_BTN_WIDTH = 140
local FILTER_BTN_WIDTH = 120
local SEARCH_INPUT_WIDTH = 90

local FILTER_BTN_HEIGHT = 54

local POP_PANEL_SIZE = cc.size(140, 350)
local FILTER_PANEL_SIZE = cc.size(700, 630)

function _M.create(mode, height)
    local widget = _M.new(lc.EXTEND_LAYOUT)
    widget:setAnchorPoint(0.5, 0.5)
    widget:setContentSize(FILTER_BTN_WIDTH, height)
    widget:init(mode)

    return widget
end

function _M.create2(mode, width)
    local widget = _M.new(lc.EXTEND_LAYOUT)
    widget:setAnchorPoint(0.5, 0.5)
    widget:setContentSize(width, FILTER_BTN_HEIGHT)
    widget:init2(mode)

    return widget
end


function _M:init(mode)
    if mode > _M.ModeType.illustration then
        mode = mode - _M.ModeType.illustration
        self._isIllustration = true
    end

    self._mode = mode
    
    local top = lc.h(self)
    local x = lc.w(self) / 2
    
    if not self._isIllustration and self._mode ~= _M.ModeType.skin then
        self._btnSort = self:createSortButton()
        lc.addChildToPos(self, self._btnSort, cc.p(x, top - lc.h(self._btnSort) / 2))
        top = top - lc.h(self._btnSort) - 20
    end
    
    self._btnFilter = self:createFilterButton()
    if self._btnFilter then
        self._btnFilter._label:setString(Str(STR.FILTER))
        lc.addChildToPos(self, self._btnFilter, cc.p(x, top - lc.h(self._btnFilter) / 2))
        top = top - lc.h(self._btnFilter) - 20
    end 

    if not self._isIllustration then
        self._searchArea = self:createSearchArea()
        lc.addChildToPos(self, self._searchArea, cc.p(x, top - lc.h(self._searchArea) / 2))
    else 
        self._searchArea = self:createSearchArea2()
        lc.addChildToCenter(self, self._searchArea)
        self._searchArea:setVisible(false)
    end
end

-- this is used in HeroCenterScene & illustration panel
function _M:init2(mode)
    if mode > _M.ModeType.illustration then
        mode = mode - _M.ModeType.illustration
        self._isIllustration = true
    end

    self._mode = mode
    
    local right = lc.w(self)
    local y = lc.h(self) / 2
    
    if not self._isIllustration then
        self._btnFilter = self:createFilterButton()
    else 
        self._btnFilter = self:createFilterButton2()
    end
    if self._btnFilter then
        self._btnFilter._label:setString(Str(STR.FILTER))
        lc.addChildToPos(self, self._btnFilter, cc.p(right + lc.w(self._btnFilter) / 2,y))
        right = right + lc.w(self._btnFilter) + 12
    end 

    if not self._isIllustration and self._mode ~= _M.ModeType.skin then
        self._btnSort = self:createSortButton()
        lc.addChildToPos(self, self._btnSort, cc.p(right + lc.w(self._btnSort) / 2,y))
        right = right + lc.w(self._btnSort) + 12
    end
    if not self._isIllustration then
        self._searchArea = self:createSearchArea()
        lc.addChildToPos(self, self._searchArea, cc.p(right + lc.w(self._searchArea) / 2,y))
    else 
        self._searchArea = self:createSearchArea2()
        lc.addChildToCenter(self, self._searchArea)
        self._searchArea:setVisible(false)
    end
end


function _M:createButton(callback)
    local button = V.createScale9ShaderButton("img_btn_2_s", callback, V.CRECT_BUTTON_S, 120, FILTER_BTN_HEIGHT)
    button:setZoomScale(0)

    local label = V.createTTFBold("", V.FontSize.S1)
    label:enableOutline(lc.Color4B.black, 2)
    --lc.addChildToPos(button, label, cc.p(math.floor((lc.left(arrow) - 6) / 2 + 12), lc.h(button) / 2))
    lc.addChildToPos(button, label, cc.p(lc.w(button) / 2 - 1, lc.h(button) / 2 + 1))
    button._label = label
    
    return button
end

function _M:createButton2(callback)
    local button = V.createScale9ShaderButton("img_blank", callback, cc.rect(0, 0, 2, 2), 122, 71)
    button:setZoomScale(0)

    --local label = V.createTTFBold("", V.FontSize.M2, V.COLOR_TEXT_WHITE)
    local label = V.createTTFBold("", V.FontSize.S1)
    label:enableOutline(lc.Color4B.black, 2)

    --lc.addChildToPos(button, label, cc.p(math.floor((lc.left(arrow) - 6) / 2 + 12), lc.h(button) / 2))
    lc.addChildToPos(button, label, cc.p(lc.w(button) / 2 - 1, lc.h(button) / 2 + 1))
    button._label = label
    
    return button
end

function _M:createSortButton()
    self._sortTypes = {}
    for i = 1, #_M.SortStr do
        if i == _M.SortType.cost then
            table.insert(self._sortTypes, i)
        elseif i == _M.SortType.quality then
            table.insert(self._sortTypes, i)
        elseif i == _M.SortType.life then
            if self._mode == _M.ModeType.monster then
                table.insert(self._sortTypes, i)
            end
        end
    end

    local btn = self:createButton(function(sender) self:showSortTypes() end)
    local label = btn._label
    lc.offset(label, -10)
    
    local orderArrow = lc.createSprite("img_arrow_down_1")
    orderArrow:setColor(label:getColor())
    btn:addChild(orderArrow)
    btn._orderArrow = orderArrow

    return btn
end

function _M:createFilterButton()
    if self._mode == _M.ModeType.monster or self._mode == _M.ModeType.rare or self._mode == _M.ModeType.hire or self._mode == _M.ModeType.skin then 
        self._filterNatureTypes = {}
        for i = 1, #_M.FilterNatureStr do
            table.insert(self._filterNatureTypes, i)
        end

        --[[
        self._filterCategoryTypes = {}
        for i = 1, #_M.FilterCategoryStr do
            table.insert(self._filterCategoryTypes, i)
        end
        ]]

        self._filterLevelTypes = {}
        for i = 1, #_M.FilterLevelStr do
            table.insert(self._filterLevelTypes, i)
        end
    end

    if not self._isIllustration then 
        self._filterQualityTypes = {}
        for i = 1, #_M.FilterQualityStr do
            table.insert(self._filterQualityTypes, i)
        end
    end
    
    if self._filterNatureTypes or self._filterCategoryTypes or self._filterQualityTypes then
        if not self._isIllustration then
            return self:createButton(function(sender) self:showFilterTypes() end)  
        else
            return self:createButton2(function(sender) self:showFilterTypes() self._searchArea:setVisible(false) end)  
        end
    end

    return nil
end

function _M:createSearchArea()
    local area = lc.createSprite({_name = "img_btn_2_s", _crect = V.CRECT_BUTTON_S, _size = cc.size(200, FILTER_BTN_HEIGHT)})
    --local area = V.createScale9ShaderButton("img_btn_2_s", function(sender) end, V.CRECT_BUTTON_S, 170, 55)
    local editBox = V.createEditBox("input_box_bg", cc.rect(35, 0, 1, 27), cc.size(123, FILTER_BTN_HEIGHT - 14), "", true, 10)
    editBox:setFontColor(lc.Color4B.white)
    lc.addChildToPos(area, editBox, cc.p(lc.w(area) / 2 - 20, lc.h(area) / 2))
    area._editBox = editBox
    
    local button = V.createShaderButton("img_icon_search_2", function(sender) self:onSearch() end)
    lc.addChildToPos(area, button, cc.p(lc.right(editBox) + lc.w(button) / 2 + 4, lc.h(area) / 2))
    area._button = button

    self._searchText = ""
    
    return area
end

function _M:createSearchArea2()
    local area = lc.createSprite({_name = "img_com_bg_30", _crect = V.CRECT_COM_BG30, _size = cc.size(500, 74)})
    --local area = V.createScale9ShaderButton("img_btn_2_s", function(sender) end, V.CRECT_BUTTON_S, 170, 55)
    local editBox = V.createEditBox("img_com_bg_26", V.CRECT_COM_BG26, cc.size(400, 46), "", true, 10)
    editBox:setFontColor(lc.Color4B.white)

    lc.addChildToPos(area, editBox, cc.p(lc.cw(area) - 20, lc.h(area) / 2))
    area._editBox = editBox
    
    local button = V.createShaderButton("img_icon_search", function(sender) self:onSearch() end)
    button:setScale(0.8)
    lc.addChildToPos(area, button, cc.p(lc.right(editBox) + lc.w(button) / 2 + 7, lc.h(area) / 2))
    area._button = button

    self._searchText = ""
    
    return area
end

function _M:setSort(type, isAscending)
    if self._btnSort == nil then return end
    if self._sort == type and self._isAscending == isAscending then return end
    
    local label = self._btnSort._label
    label:setString(_M.SortStr[type])
    
    local orderArrow = self._btnSort._orderArrow
    orderArrow:setSpriteFrame(isAscending and "img_arrow_up_1" or "img_arrow_down_1")
    orderArrow:setPosition(lc.right(label) + 6 + lc.w(orderArrow) / 2, lc.y(label))
    
    self._sort = type
    self._isAscending = isAscending  
    
    if self._sortFilterHandler then self._sortFilterHandler(_M.UpdateFlag.sort) end      
end

function _M:getSortFunc()
    if self._sort ~= nil then
        return _M.SortFunc[self._sort], self._isAscending
    end
end

function _M:setFilterNature(type)
    if self._filterNature == type then return end
    
    self._filterNature = type
    
    if self._sortFilterHandler then self._sortFilterHandler(_M.UpdateFlag.filter_nature) end
end

function _M:getFilterNatureFunc()
    if self._filterNature ~= nil then
        local keyword = _M.FilterNatureKeyword[self._filterNature]
        if keyword >= 0 then
            return P.filterByNature, keyword
        end
    end
end

function _M:setFilterLevel(type)
    if self._filterLevel == type then return end
    
    self._filterLevel = type
    
    if self._sortFilterHandler then self._sortFilterHandler(_M.UpdateFlag.filter_level) end
end

function _M:getFilterLevelFunc()
    if self._filterLevel ~= nil then
        local keyword = _M.FilterLevelKeyword[self._filterLevel]
        if keyword >= 0 then
            return P.filterByLevel, keyword
        end
    end
end

function _M:setFilterQuality(type)
    if self._filterQuality == type then return end
    
    self._filterQuality = type
    
    if self._sortFilterHandler then self._sortFilterHandler(_M.UpdateFlag.filter_quality) end
end

function _M:getFilterQualityFunc()
    if self._filterQuality ~= nil then
        local keyword = _M.FilterQualityKeyword[self._filterQuality]
        if keyword >= 0 then
            return P.filterByQuality, keyword
        end
    end
end

function _M:setFilterCategory(type)
    if self._filterCategory == type then return end
    
    self._filterCategory = type
    
    if self._sortFilterHandler then self._sortFilterHandler(_M.UpdateFlag.filter_category) end
end

function _M:getFilterCategoryFunc(type)
    if self._filterCategory ~= nil then
        local keyword = _M.FilterCategoryKeyword[self._filterCategory]
        if keyword >= 0 then
            return P.filterByCategory, keyword
        end
    end
end

function _M:getFilterSearchFunc()
    if self._searchText ~= "" then
        return P.filterBySearch, self._searchText
    end
end

function _M:registerSortFilterHandler(handler)
    self._sortFilterHandler = handler
end

function _M:showSortTypes()
    local createContentArea = function(i, isUp)
        local label = V.createTTF(_M.SortStr[self._sortTypes[i]], V.FontSize.S1)
        local arrow = cc.Sprite:createWithSpriteFrameName(isUp and "img_arrow_up_1" or "img_arrow_down_1")
        local w = lc.w(label) + 6 + lc.w(arrow)
        local h = lc.h(label)
        local area = lc.createNode(cc.size(w, h))
        lc.addChildToPos(area, label, cc.p(lc.w(label) / 2, h / 2))
        lc.addChildToPos(area, arrow, cc.p(w - lc.w(arrow) / 2, h / 2))
        return area
    end

    local buttonDefs = {}
    for i = 1, #self._sortTypes do
        table.insert(buttonDefs, {_area = createContentArea(i, true), _handler = function(tag) self:setSort(self._sortTypes[i], true) end})
        table.insert(buttonDefs, {_area = createContentArea(i, false), _handler = function(tag) self:setSort(self._sortTypes[i], false) end})
    end

    self:showPopPanel(self._btnSort, buttonDefs)
end

function _M:showFilterTypes()
    local allButtonDefs = {}

    if self._filterQualityTypes then
        local buttonDefs = {}
        for i = 1, #self._filterQualityTypes do
            local type = self._filterQualityTypes[i]
            table.insert(buttonDefs, {_str = _M.FilterQualityStr[type], _handler = function(tag) self:setFilterQuality(type) end})
            if type == self._filterQuality then
                buttonDefs._curFilter = i
            end
        end
        buttonDefs._titleStr = Str(STR.QUALITY)
        table.insert(allButtonDefs, buttonDefs)
    end

    if self._filterLevelTypes then
        local buttonDefs = {}
        for i = 1, #self._filterLevelTypes do
            local type = self._filterLevelTypes[i]
            table.insert(buttonDefs, {_str = _M.FilterLevelStr[type], _handler = function(tag) self:setFilterLevel(type) end})
            if type == self._filterLevel then
                buttonDefs._curFilter = i
            end
        end
        buttonDefs._titleStr = Str(STR.CARD_LEVEL)
        table.insert(allButtonDefs, buttonDefs)
    end

    if self._filterNatureTypes then
        local buttonDefs = {}
        for i = 1, #self._filterNatureTypes do
            local type = self._filterNatureTypes[i]
            table.insert(buttonDefs, {_str = _M.FilterNatureStr[type], _handler = function(tag) self:setFilterNature(type) end})
            if type == self._filterNature then
                buttonDefs._curFilter = i
            end
        end
        buttonDefs._titleStr = Str(STR.ATTRIBUTE)
        table.insert(allButtonDefs, buttonDefs)
    end

    --[[
    if self._filterCategoryTypes then
        local buttonDefs = {}
        for i = 1, #self._filterCategoryTypes do
            local type = self._filterCategoryTypes[i]
            table.insert(buttonDefs, {_str = _M.FilterCategoryStr[type], _handler = function(tag) self:setFilterCategory(type) end})
            if type == self._filterCategory then
                buttonDefs._curFilter = i
            end
        end
        buttonDefs._titleStr = Str(STR.CARD_CATEGORY)
        table.insert(allButtonDefs, buttonDefs)
    end
    ]]

    self:showFilterPanel(self._btnFilter, allButtonDefs)
end

function _M:showPopPanel(refBtn, buttonDefs)
    local panel = require("TopMostPanel").ButtonList.create(POP_PANEL_SIZE)
    if panel then
        local gPos = lc.convertPos(cc.p(0, lc.h(refBtn)), refBtn)
        panel:setButtonDefs(buttonDefs)
        panel:setPosition(gPos.x - 20 + 67 + 8, gPos.y - lc.h(panel) / 2 + 20 - 127 + 30)
        panel:linkNode(refBtn)
        panel:show()

        local arrow = lc.createSprite('img_arrow_right_02')
        arrow:setRotation(90)
        lc.addChildToPos(panel, arrow, cc.p(lc.left(panel) - 304 + 70 + 15 - 91, lc.h(panel) + 21 + 6))
    end
end

-- used in HeroCenterScene
function _M:showFilterPanel(refBtn, allButtonDefs)
    local panel = require("TopMostPanel").FilterList.create(FILTER_PANEL_SIZE)
    if panel then
        panel:setButtonDefs(allButtonDefs)

        local gPos = lc.convertPos(cc.p(0, lc.h(refBtn)), refBtn)
        local margin = 20

        local posY = gPos.y - lc.ch(panel) + margin
        if posY - lc.ch(panel) < 10 then 
            posY = 10 + lc.ch(panel) 
            margin = lc.h(panel) - gPos.y + 10
        elseif  posY + lc.ch(panel) > V.SCR_H - 10 then
            posY = V.SCR_H - 10 - lc.ch(panel)
            margin = V.SCR_H - gPos.y - 10
        end

        if self._isIllustration then
            panel:setPosition(gPos.x + lc.w(panel) / 2 + 43 + 67 - 12, posY + 16)
        else 
            panel:setPosition(gPos.x + lc.w(panel) / 2 + 43 + 67 + 52 - 12 - 161, posY - 26 - 48)
        end
        panel:linkNode(refBtn)
        panel:show()

        local arrow = lc.createSprite('img_arrow_right_02')
        if self._isIllustration then
            lc.addChildToPos(panel, arrow, cc.p(- lc.cw(arrow) + 1, lc.h(panel) - margin - lc.ch(refBtn) ))
        else 
            arrow:setRotation(90)
            lc.addChildToPos(panel, arrow, cc.p(lc.left(panel) - 204 + 70 + 15 - 56, lc.h(panel) + 21 + 6))    
        end
    end
end

function _M:onSearch()
    local text = self._searchArea._editBox:getText()
    --self._searchArea._editBox:setText("")
    
    self._searchText = text
    if self._sortFilterHandler then self._sortFilterHandler(_M.UpdateFlag.search) end
end

function _M:resetAllFilter()
    self:setSort(_M.SortType.quality)
    self:setFilterQuality(_M.FilterQuality.all)

    if self._mode == _M.ModeType.monster or self._mode == _M.ModeType.rare then
        self:setFilterCategory(_M.FilterCategory.all)
        self:setFilterLevel(_M.FilterLevel.all)
        self:setFilterNature(_M.FilterNature.all)
    end
end

return _M