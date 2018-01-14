local _M = class("CreateGroupForm", BaseForm)

local FORM_SIZE = cc.size(720, 550)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    
    return panel    
end

function _M:init()
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))
    local size = cc.size(400, 60)
    local editor = V.createEditBox("img_com_bg_5", V.CRECT_COM_BG3, size, Str(STR.INPUT_GROUP_NAME), true)
    editor:setFontColor(lc.Color4B.white)
    editor:setPosition(_M.LEFT_MARGIN + 200 + size.width / 2, lc.h(self._form) - _M.TOP_MARGIN - 90)
    self._form:addChild(editor)
    self._editor = editor

    local tipLabel = V.createTTF(Str(STR.SELECT_GROUP_HEAD), V.FontSize.S2)
    lc.addChildToPos(self._form, tipLabel, cc.p(lc.cw(self._form), lc.bottom(editor) - lc.ch(tipLabel) - 30))

    local avatarBg = lc.createSprite("img_glow")
    avatarBg:setScale(0.7)
    avatarBg:runAction(lc.rep(lc.spawn(lc.rotateBy(5, 270), lc.ease(lc.sequence(lc.spawn(lc.scaleTo(2.5, 0.5), lc.fadeOut(2.5)), lc.spawn(lc.scaleTo(2.5, 0.7), lc.fadeIn(2.5))), "SineIO"))))
    lc.addChildToPos(self._form, avatarBg, cc.p(lc.left(editor) / 2, lc.y(editor)))

    self._avatar = 1
    local curAvatar = V.createGroupAvatar(self._avatar)
    lc.addChildToPos(self._form, curAvatar, cc.p(lc.left(editor) / 2, lc.y(editor)))
    self._curAvatar = curAvatar

    local avatarList = lc.List.createH(cc.size(lc.w(self._form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 6, 150), 20, 20)
    avatarList:setAnchorPoint(0.5, 0.5)
    local listBg = lc.createSprite({_name = "group_avatars_bg", _crect = cc.rect(1, 1, 2, 2), _size = avatarList:getContentSize()})
    lc.addChildToPos(self._form, listBg, cc.p(lc.w(self._form) / 2, lc.bottom(tipLabel) - 30 - lc.h(avatarList) / 2))
    lc.addChildToPos(self._form, avatarList, cc.p(lc.w(self._form) / 2, lc.bottom(tipLabel) - 30 - lc.h(avatarList) / 2))

    self._selectedBg = lc.createSprite("res/jpg/group_avatar_selected.jpg")
    self._selectedBg:retain()

    self._avatars = {}
    for i = 1, 10 do
        local btnAvatar = V.createShaderButton(nil, function(sender)
            self._avatar = i
            self:updateAvatarPreview()
        end)
        local avatar = V.createGroupAvatar(i)
        btnAvatar:setContentSize(avatar:getContentSize())
        lc.addChildToCenter(btnAvatar, avatar)
        avatarList:pushBackCustomItem(btnAvatar)
        table.insert(self._avatars, btnAvatar)
    end

    self:updateAvatarPreview()

    local btnOk = V.createScale9ShaderButton("img_btn_1", function(sender) self:onConfirm() end, V.CRECT_BUTTON, V.PANEL_BTN_WIDTH)
    btnOk:addLabel(Str(STR.OK))
    lc.addChildToPos(self._form, btnOk, cc.p(lc.cw(self._form), lc.ch(btnOk) + 50))
    self._btnOk = btnOk

end

function _M:updateAvatarPreview()
    self._curAvatar.update(self._avatar)
    self._selectedBg:removeFromParent()
    lc.addChildToCenter(self._avatars[self._avatar], self._selectedBg, -1)
end

function _M:onConfirm()
--    if self._confirmHandle then
--        local text = self._editor:getText()
--        self._confirmHandle(self, text)
--    end
    if self._editor:isValidName(ClientData.MAX_GROUP_NAME_DISPLAY_LEN) then
        V.getActiveIndicator():show(Str(STR.WAITING))
        local name = self._editor:getText()
        local avatar = self._avatar
        P._playerUnion:createGroup(name, avatar)
        V.getActiveIndicator():show(Str(STR.WAITING))
    else
        ToastManager.push(Str(STR.INPUT_NAME_INVALID))
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.union_group_dirty, function()
            if P._playerUnion:getMyGroup() then
                self:hide()
            end
        end))
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    self._selectedBg:release()
end

return _M