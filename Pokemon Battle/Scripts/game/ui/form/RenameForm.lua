local _M = class("RenameForm", BaseForm)

local FORM_SIZE = cc.size(640, 360)

function _M.create(isGuide)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(isGuide)
    
    return panel    
end

function _M:init(isGuide)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    self._isGuide = isGuide

    local label = cc.Label:createWithTTF(Str(STR.INPUT_YOUR_NAME)..":", V.TTF_FONT, V.FontSize.S1)
    label:setColor(V.COLOR_TEXT_LIGHT)
    label:setPosition(_M.LEFT_MARGIN + lc.w(label) / 2 + 60, lc.h(self._form) - _M.TOP_MARGIN - 70)
    self._form:addChild(label)
    self._label = label
    
    local size = cc.size(380, 60)
    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), size, "", true)
    editor:setPosition(lc.left(label) + size.width / 2, lc.bottom(label) - size.height / 2 - 20)
    self._form:addChild(editor)
    self._editor = editor
    
    lc.TextureCache:addImageWithMask("res/jpg/img_icon_dice.jpg")
    local btnRandom = V.createShaderButton("res/jpg/img_icon_dice.jpg", function(sender) self:randomNickname() end)
    btnRandom:setPosition(lc.right(editor) + lc.w(btnRandom) / 2 + 10, lc.y(editor))
    self._form:addChild(btnRandom)
    
    local btnOk = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onChangeName() end, V.CRECT_BUTTON_1_S, V.PANEL_BTN_WIDTH)
    btnOk:addLabel(Str(STR.OK))
    self._form:addChild(btnOk)
    self._btnOk = btnOk

    local y = _M.BOTTOM_MARGIN + lc.h(btnOk) / 2 + 10
    if isGuide then
        GuideManager.releaseLayer()

        -- Do not close the form, remove old listeners and add a empty listener
        self:addTouchEventListener(function() end)
        self._btnBack:setVisible(false)

        btnOk:setPosition(lc.w(self._form) / 2, y)

        -- Random a name for the player
        self:randomNickname()
    else
        btnOk:setPosition(lc.w(self._form) / 2 + lc.w(btnOk) / 2 + 15, y)

        local btnCancel = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:hide() end, V.CRECT_BUTTON_1_S, V.PANEL_BTN_WIDTH)
        btnCancel:addLabel(Str(STR.CANCEL))
        btnCancel:setPosition(lc.w(self._form) / 2 - lc.w(btnCancel) / 2 - 15, y)
        self._form:addChild(btnCancel)

        self:refreshChangeNameLabel()
    end
end

function _M:refreshChangeNameLabel()
    if self._labelChangeName ~= nil then
        self._labelChangeName:removeFromParent()
    end

    local labelChangeName = self._labelChangeName
    if P._changeNameCount == 0 then
        labelChangeName = cc.Label:createWithTTF(Str(STR.FIRST_CHANGE_FREE), V.TTF_FONT, V.FontSize.S1)
        labelChangeName:setColor(V.COLOR_TEXT_LIGHT)
        labelChangeName:setPosition(lc.x(self._btnOk), lc.y(self._btnOk) + 65)
    else
        labelChangeName = ccui.RichTextEx:create()
        labelChangeName:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, string.format("%d", Data._globalInfo._editNameIngot), V.TTF_FONT, V.FontSize.S1))
        labelChangeName:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, cc.Sprite:createWithSpriteFrameName(string.format("img_icon_res%d_s", Data.ResType.ingot))))  
        labelChangeName:formatText()
        labelChangeName:setPosition(lc.x(self._btnOk), lc.y(self._btnOk) + 65)
    end
    self._form:addChild(labelChangeName)    
    self._labelChangeName = labelChangeName
end

function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
    self._listener = lc.addEventListener(Data.Event.change_name_dirty, function(event) 
        self:refreshChangeNameLabel()
    end)
end

function _M:onExit()
    _M.super.onExit(self)

    lc.Dispatcher:removeEventListener(self._listener)
    ClientData.removeMsgListener(self)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_icon_dice.jpg"))
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_USER_SET_NAME or msgType == SglMsgType_pb.PB_TYPE_USER_SET_NAME_GUIDE then
        V.getActiveIndicator():hide()
        local name = string.trim(self._editor:getText())
        P:changeName(name)
        
        if not self._isGuide then
            if P._changeNameCount > 0 then
                P:changeResource(Data.ResType.ingot, -Data._globalInfo._editNameIngot)
            end
            P._changeNameCount = P._changeNameCount + 1
        end
        
        local eventCustom = cc.EventCustom:new(Data.Event.change_name_dirty)
        lc.Dispatcher:dispatchEvent(eventCustom)
        
        self:hide()
    
        return true
    end
    
    return false
end

function _M:onChangeName()
    if not self._editor:isValidName() then
        ToastManager.push(Str(STR.INPUT_NAME_INVALID))
    
    else
        local name = string.trim(self._editor:getText())
        if not self._isGuide then
            if P._changeNameCount > 0 then
                if not V.checkIngot(Data._globalInfo._editNameIngot) then
                    return
                end
            end

            V.getActiveIndicator():show(Str(STR.WAITING))
            ClientData.sendChangeName(name)
        else
            V.getActiveIndicator():show(Str(STR.WAITING))
            ClientData.sendChangeNameGuide(name)
        end
    end       
end

function _M:randomNickname()
    require("NameSample")

    local familyname, secondname
    while (familyname == nil and secondname == nil) or (familyname == secondname) do    
        familyname = FAMILY_NAMES[math.random(#FAMILY_NAMES)]
        secondname = math.random() > 0.5 and MALE1_NAMES[math.random(#MALE1_NAMES)] or FEMALE1_NAMES[math.random(#FEMALE1_NAMES)]
    end
    self._editor:setText(familyname..secondname)
end

return _M