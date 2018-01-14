local _M = class("UnionCreateArea", lc.ExtendCCNode)

local AREA_HEIGHT_CREATE = 624
local AREA_HEIGHT_EDIT = 564
local POP_PANEL_SIZE = cc.size(250, 250)

_M.Mode = {
    create      = 1,
    edit        = 2
}

function _M.create(mode, width)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(cc.size(width, mode == _M.Mode.create and AREA_HEIGHT_CREATE or AREA_HEIGHT_EDIT))
    area:init(mode)
    return area
end

function _M:init(mode)
    self._mode = mode

    local addLabelInput = function(labelStr, x, y, holderStr, w, h)
        local label = V.createTTFStroke(labelStr..":", V.FontSize.S2)
        label:setAnchorPoint(1, 0.5)
        

        local input = V.createEditBox("input_box_bg", V.CRECT_INPUT_BOX_BG, cc.size(w or 222, h or 34), holderStr or "", true)

        lc.addChildToPos(self, label, cc.p(x or 340, y - lc.h(input) / 2))
        lc.addChildToPos(self, input, cc.p(lc.right(label) + lc.w(input) / 2 + 12, lc.y(label)))
        return input, y - lc.h(input) - 9
    end
    local leftWidth = 587
    local y = lc.h(self) - 58 + 16
    self._iptName, y = addLabelInput(Str(STR.UNION_NAME), nil, y)
    --self._iptDesc, y = addLabelInput(Str(STR.UNION_SUMMARY), nil, y, nil, V.SCR_W - lc.right(self._iptName) - 20, 250)

    local descLabel = V.createTTFStroke(Str(STR.UNION_SUMMARY), V.FontSize.S3, V.COLOR_TEXT_ORANGE)
    self._iptDesc = V.createEditBox("img_troop_bg_2", cc.rect(20, 15, 1, 1), cc.size(lc.w(self) - leftWidth - 20, 156), nil, true)
    self._iptDesc:setOpacity(127)
    lc.addChildToPos(self, descLabel, cc.p(leftWidth + lc.cw(self._iptDesc), lc.h(self) - 26))
    lc.addChildToPos(self, self._iptDesc, cc.p(leftWidth + lc.cw(self._iptDesc), lc.bottom(descLabel) - lc.ch(self._iptDesc) - 2))

    local addLabelSelect = function(labelStr, y)
        local label = V.createTTFStroke(labelStr..":", V.FontSize.S2)
        label:setAnchorPoint(1, 0.5)

        local button = V.createScale9ShaderButton("input_box_bg", nil, V.CRECT_INPUT_BOX_BG, 222, 34)
        local btnIcon = lc.createSprite("img_triangle")
        btnIcon:setScale(0.9)
        local btnLabel = V.createTTF("", V.FontSize.S2)
        btnLabel:setAnchorPoint(0, 0.5)
        btnLabel:setColor(V.COLOR_TEXT_WHITE)
        lc.addChildToPos(button, btnLabel, cc.p(12, lc.h(button) / 2 + 1))
        lc.addChildToPos(button, btnIcon, cc.p(lc.w(button) - lc.cw(btnIcon) - 2, lc.ch(button)))
        button._label = btnLabel

        lc.addChildToPos(self, label, cc.p(340, y - lc.h(button) / 2))
        lc.addChildToPos(self, button, cc.p(lc.right(label) + lc.w(button) / 2 + 12, lc.y(label)))
        return button, y - lc.h(button) - 7
    end

    local btnLevelRequire, y = addLabelSelect(Str(STR.UNION_LEVEL_REQUIRE), y)

    btnLevelRequire._callback = function()
        local createDef = function(btn, str, level)
            return {_str = str, _handler = function()
                btn._level = level
                btn._label:setString(str)
            end}
        end

        local unlockLevel = P._playerCity:getUnionUnlockLevel()
        local buttonDefs = {createDef(btnLevelRequire, Str(STR.NO_REQUIREMENT), unlockLevel)}
        for i = unlockLevel + 10, 100, 10 do
            local name = string.format("%s %d", Str(STR.LORD_LEVEL), i)
            table.insert(buttonDefs, createDef(btnLevelRequire, name, i))
        end
        self:popSelectPanel(btnLevelRequire, buttonDefs)
    end
    self._btnLevelRequire = btnLevelRequire

    local btnJoinType, y = addLabelSelect(Str(STR.UNION_TYPE), y)
    btnJoinType._type = Data.UnionJoinType.any
    btnJoinType._label:setString(Str(STR.UNION_TYPE_ANY))
    btnJoinType._callback = function()
        local createDef = function(btn, str, joinType)
            return {_str = str, _handler = function()
                btn._type = joinType
                btn._label:setString(str)
            end}
        end

        local buttonDefs = {}
        for i = 0, 2 do
            table.insert(buttonDefs, createDef(btnJoinType, Str(STR.UNION_TYPE_ANY + i), Data.UnionJoinType.any + i))
        end
        self:popSelectPanel(btnJoinType, buttonDefs)
    end
    self._btnJoinType = btnJoinType

    self._iptWord = addLabelInput(Str(STR.UNION_WORD), nil, y, Str(STR.UNION_WORD_TIP))
    self._iptWord:registerScriptEditBoxHandler(function(evtType)
        if evtType == "changed" then
            self:updateFlagPreview()
        end
    end)

    -- Add flag preview glow
    --[[
    local glow = lc.createSprite("img_glow")
    lc.addChildToPos(self, glow, cc.p(lc.left(self._iptName) - 270, lc.h(self) - 116))
    ]]

    local flagIcon = V.createBadge(1, "")
    lc.addChildToPos(self, flagIcon, cc.p(lc.left(self._iptName) - 240, lc.h(self) - 116))
    self._flagIcon = flagIcon

    local line = lc.createSprite("img_divide_line_11")
    line:setScaleX((lc.w(self) - 19) / lc.w(line))
    lc.addChildToPos(self, line, cc.p(lc.cw(self), lc.bottom(self._iptWord) - 32))

    -- Choose flag area
    local flagBgPanel = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self) - 20, lc.bottom(self._iptWord) - 66)})
    lc.addChildToPos(self, flagBgPanel, cc.p(lc.cw(self), lc.ch(flagBgPanel) + 20))
    local labelBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(flagBgPanel, labelBg, cc.p(lc.cw(flagBgPanel), lc.h(flagBgPanel) - lc.ch(labelBg)))
    local flagLabel = V.createTTFStroke(Str(STR.SELECT_UNION_BADGE), V.FontSize.S2)
    lc.addChildToCenter(labelBg, flagLabel)

    local flagMaxW = 975
    local flagList = lc.List.createH(cc.size(lc.w(flagBgPanel) - 10, 215), 35, 55)
    flagList:setAnchorPoint(0.5, 0.5)
    if lc.w(flagList) >= flagMaxW then flagList:setBounceEnabled(false) end
    lc.addChildToPos(flagBgPanel, flagList, cc.p(lc.w(flagBgPanel) / 2, lc.bottom(labelBg) - 20 - lc.h(flagList) / 2))

    for i = 1, 3 do
        local btnFlag = V.createShaderButton(nil, function()
            self._flag = i
            self:updateFlagPreview()
        end)
        local flag = V.createBadge(i)
        btnFlag:setContentSize(flag:getContentSize())
        lc.addChildToCenter(btnFlag, flag)
        flagList:pushBackCustomItem(btnFlag)
    end
    self._flag = 1

    -- Create button
    local setRequriedLevel = function(level)
        local btn = self._btnLevelRequire
        btn._level = level
        if level <= P._playerCity:getUnionUnlockLevel() then
            btn._label:setString(Str(STR.NO_REQUIREMENT))
        else
            btn._label:setString(string.format("%s %d", Str(STR.LORD_LEVEL), level))
        end
    end

    local setJoinType = function(type)
        local btn = self._btnJoinType
        btn._type = type
        btn._label:setString(Str(STR.UNION_TYPE_ANY + type - Data.UnionJoinType.any))
    end

    if mode == _M.Mode.create then
        local btnArea
        if P:getItemCount(Data.PropsId.union_create) > 0 then
            btnArea = V.createResConsumeButtonArea({110, 280}, "img_icon_props_s7038", V.COLOR_RES_LABEL_BG_LIGHT, 1, Str(STR.CREATE_UNION))
        else
            btnArea = V.createResConsumeButtonArea({110, 280}, "img_icon_res3_s", V.COLOR_RES_LABEL_BG_LIGHT, tostring(Data._globalInfo._createUnionIngot), Str(STR.CREATE_UNION))
        end
        btnArea._btn._callback = function() self:createUnion() end
        lc.addChildToPos(flagBgPanel, btnArea, cc.p(lc.w(flagBgPanel) / 2, 20 + lc.h(btnArea) / 2))

        setRequriedLevel(P._playerCity:getUnionUnlockLevel())
        setJoinType(Data.UnionJoinType.any)
    else
        local btnArea = V.createScale9ShaderButton("img_btn_1_s", function() self:changeInfo(true) end, V.CRECT_BUTTON_1_S, 160)
        btnArea:addLabel(Str(STR.CHANGE)..Str(STR.INFO))
        lc.addChildToPos(flagBgPanel, btnArea, cc.p(lc.w(flagBgPanel) / 2, -20 - lc.h(btnArea) / 2))

        -- Fill current union info
        local union = P._playerUnion:getMyUnion()
        self._iptName:setText(union._name)
        self._iptDesc:setText(union._announce)
        self._iptWord:setText(union._word)
        self._flag = union._badge

        setRequriedLevel(union._reqLevel)
        setJoinType(union._joinType)
    end

    self:updateFlagPreview()
end

function _M:popSelectPanel(parent, buttonDefs)
    local panel = require("TopMostPanel").ButtonList.create(POP_PANEL_SIZE)
    if panel then
        local gPos = lc.convertPos(cc.p(lc.w(parent) / 2, lc.h(parent) / 2), parent)
        panel:setButtonDefs(buttonDefs)
        panel:setPosition(gPos.x, gPos.y - lc.h(panel) / 2 - 24)
        panel:linkNode(parent)
        panel:show()
    end
end

function _M:updateFlagPreview()
    self._flagIcon:update(self._flag, self:getFlagWord())
end

function _M:getFlagWord()
    return lc.getUtf8Char(self._iptWord:getText(), 1)
end

function _M:createUnion()
    if not self._iptName:isValidName() then
        ToastManager.push(Str(STR.INPUT_NAME_INVALID))
        return
    end

    local name = string.trim(self._iptName:getText())
    local desc = self._iptDesc:getText()
    if lc.utf8len(desc) > ClientData.MAX_INPUT_LEN then
        ToastManager.push(Str(STR.UNION_SUMMARY)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))
        return
    end

    local word = self:getFlagWord()
    if word == "" then
        ToastManager.push(Str(STR.INPUT_UNION_WORD))
        return
    end

    if P:getItemCount(Data.PropsId.union_create) <= 0 and not V.checkIngot(Data._globalInfo._createUnionIngot) then
        return
    end
    
    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendCreateUnion(name, desc, self._btnLevelRequire._level, self._btnJoinType._type, self._flag, word)
end

function _M:changeInfo(checkIngot)
    local union, needIngot = P._playerUnion:getMyUnion(), 0

    local name = string.trim(self._iptName:getText())
    local isNameChanged = (name ~= union._name)
    if not self._iptName:isValidName() then
        ToastManager.push(Str(STR.INPUT_NAME_INVALID))
        return
    elseif isNameChanged then
        needIngot = needIngot + Data._globalInfo._editUnionNameIngot
    end

    local desc = self._iptDesc:getText()
    if lc.utf8len(desc) > ClientData.MAX_INPUT_LEN then
        ToastManager.push(Str(STR.UNION_SUMMARY)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))
        return
    end

    local word = self:getFlagWord()
    local isFlagChanged = (word ~= union._word or self._flag ~= union._badge)
    if word == "" then
        ToastManager.push(Str(STR.INPUT_UNION_WORD))
        return        
    elseif isFlagChanged then
        needIngot = needIngot + Data._globalInfo._editUnionTagIngot
    end

    if needIngot > 0 and checkIngot then
        require("PromptForm").ConfirmEditUnion.create(isNameChanged, isFlagChanged, function() self:changeInfo() end):show()
        return        
    end

    if not V.checkIngot(needIngot) then
        return
    end

    P:changeResource(Data.ResType.ingot, -needIngot)

    P._playerUnion._hasDetailInfo = false

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendChangeUnion(name, desc, self._btnLevelRequire._level, self._btnJoinType._type, self._flag, word)
end

return _M