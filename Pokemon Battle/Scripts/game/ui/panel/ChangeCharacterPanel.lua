local _M = class("ChangeCharacterPanel", require("BasePanel"))

local ITEM_W = 360
local ITEM_H = 500

local GAP = 10
local HEAD = 140

local MONSTER_NAMES = {[2] = 'qingyanbailong', [3] = 'heimodao', [5] = 'shijianmoshushi', [12] = 'baiyezhinvwang', [4] = 'qiquanniao', [13] = 'kuileishi', [10] = 'xiaoyilong'}
local OFFSET = {[2] = cc.p(-150, 80), [3] = cc.p(-150, 60), [5] = cc.p(-150, 20), [12] = cc.p(-150, 20), [4] = cc.p(-150, 86), [13] = cc.p(-150, 56), [10] = cc.p(-150, 6)}

function _M.create(isGuide)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(isGuide)
    return panel
end

function _M:init(isGuide)
    _M.super.init(self, not V.isInBattleScene())
    
    self._panelName = "ChangeCharacterPanel"
    self._isGuide = isGuide

    self._bottomH = self._isGuide and 220 or 190 

    if not self._isGuide then
        local area = V.createTitleArea(Str(STR.CHANGE_CHARACTER), function() self:hide() end)
        self:addChild(area, 1)
    end

    local bg = lc.createSprite("res/jpg/change_character_bg.jpg")
    lc.addChildToCenter(self, bg)
    --[[
    local title = lc.createSprite("change_character_title")
    lc.addChildToPos(self, title, cc.p(lc.cw(title), lc.h(self) - V.UI_SCENE_TITLE_HEIGHT - lc.ch(title)))
    self._title = title]]

    local listBg = ccui.Scale9Sprite:createWithSpriteFrameName("img_troop_bg_1", cc.rect(25, 24, 2, 2))
    listBg:setContentSize(cc.size(280, lc.h(self) - V.CRECT_TITLE_AREA_BG.height))
    lc.addChildToPos(self, listBg, cc.p(lc.cw(listBg), lc.ch(listBg) ))
    self._listBg = listBg

    local title = V.createTTFStroke(Str(STR.SELECT_CHARACTER), V.FontSize.M2)
    lc.addChildToPos(listBg, title, cc.p(lc.cw(listBg), lc.h(listBg) - 20 - lc.ch(title)), 2)
    self._title = title

    self._curCharaNode = lc.createNode()
    lc.addChildToPos(self, self._curCharaNode, cc.p(lc.cw(self) + lc.cw(title) - GAP + 40, lc.ch(self)))

    

    if self._isGuide then
        local label = cc.Label:createWithTTF(Str(STR.SELECT_YOUR_CHARACTER), V.TTF_FONT, V.FontSize.S1)
        label:setColor(V.COLOR_TEXT_LIGHT)
        label:setPosition(lc.x(self._curCharaNode), lc.h(self) - 40)
        self:addChild(label)

        label = cc.Label:createWithTTF(Str(STR.INPUT_YOUR_NAME), V.TTF_FONT, V.FontSize.S1)
        label:setColor(V.COLOR_TEXT_LIGHT)
        label:setAnchorPoint(cc.p(0.5, 0.5))
        label:setPosition(lc.x(self._curCharaNode), 192)
        self:addChild(label)
        self._label = label
    
        local size = cc.size(380, 60)
        local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), size, "", true)
        editor:setPosition(lc.x(self._curCharaNode), 142)
        self:addChild(editor)
        self._editor = editor
    
        lc.TextureCache:addImageWithMask("res/jpg/img_icon_dice.jpg")
        local btnRandom = V.createShaderButton("res/jpg/img_icon_dice.jpg", function(sender) self:randomNickname() end)
        btnRandom:setPosition(lc.right(editor) + lc.w(btnRandom) / 2 + 10, lc.y(editor))
        self:addChild(btnRandom)
    end
    
    local btnOk = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onConfirm() end, V.CRECT_BUTTON_1_S, V.PANEL_BTN_WIDTH)
    btnOk:addLabel(Str(STR.OK))
    self:addChild(btnOk)
    self._btnOk = btnOk

    local btnUnlock = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onUnlock(self._selectedId) end, V.CRECT_BUTTON_1_S, V.PANEL_BTN_WIDTH)
    btnUnlock:addLabel(Str(STR.UNLOCK))
    self:addChild(btnUnlock)
    self._btnUnlock = btnUnlock

    local y = lc.h(btnOk) / 2 + (self._isGuide and 20 or 70) - 20
    if isGuide then
        GuideManager.releaseLayer()

        -- Do not close the form, remove old listeners and add a empty listener
        self:addTouchEventListener(function() end)
        --self._btnBack:setVisible(false)

        btnOk:setPosition(lc.x(self._curCharaNode), y)

        -- Random a name for the player
        self:randomNickname()

        self._btnUnlock:setVisible(false)
    else
        btnOk:setPosition(lc.x(self._curCharaNode), y)
        self._btnUnlock:setPosition(lc.x(btnOk), y)
    end

    self._curCharaNode:setPositionY(lc.ch(self) + lc.top(btnOk)/2 + (self._isGuide and 40 or 10))

    self:initCharacterList()

end

function _M:initCharacterList()
    self._heads = {}

    local list = lc.List.createV(cc.size(250, lc.h(self._listBg) - 100), GAP, 2*GAP)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._listBg, list, cc.p(lc.cw(self._listBg), lc.ch(list) + 20), 2)

    local listBg2 = lc.createSprite{_name = "img_troop_bg_2", _size = list:getContentSize(), _crect = cc.rect(16, 14, 9, 6)}
    lc.addChildToPos(self._listBg, listBg2, cc.p(lc.cw(self._listBg), lc.ch(listBg2) + 20), 1)
    self._list = list

    local ids = {{2, 3}, {4, -1}, {-1, -1}, {-1, -1}}
    for i = 1, #ids do
        local id = ids[i]
        local info1 = Data._characterInfo[id[1]]
        local info2 = Data._characterInfo[id[2]]
        info1 = info1 or {_id = -1}
        info2 = info2 or {_id = -1}
        local item = self:setOrCreateItem(info1, info2)
        list:pushBackCustomItem(item)
    end

    self:selectCharacter(P:getCharacterId())
end

function _M:setCurrentCharacter(info)
    if info._id == -1 then
        return ToastManager.push(Str(STR.SID_FIXITY_DESC_1013))
    end
    self._selectedId = info._id
    local layout = V.createShaderButton(nil, function(sender) 
        if sender._lock:isVisible() then
            self:onUnlock(info._id)
        end
    end)
    layout._id = info._id
    layout:setContentSize(ITEM_W, lc.h(self) - self._bottomH)

    local nameBg = lc.createSprite({_name = 'img_character_name_bg', _size = cc.size(ITEM_W, V.CRECT_COM_BG43.height), _crect = cc.rect(28, 33, 2, 2)})
    lc.addChildToPos(layout, nameBg, cc.p(lc.cw(layout), lc.ch(nameBg) - 40), 1)
    layout._nameBg = nameBg

    local name = V.createTTFStroke( Str(info._nameSid), V.FontSize.M1)
    lc.addChildToCenter(nameBg, name)
    --[[
    local monsterBones = DragonBones.create(MONSTER_NAMES[info._id])
    monsterBones:gotoAndPlay('effect1')
    monsterBones:setScale(0.8)
    lc.addChildToPos(layout, monsterBones, cc.p(lc.x(nameBg) + OFFSET[info._id].x, lc.top(nameBg) + 120 + OFFSET[info._id].y))
    ]]
    local spine = V.createSpine(string.format("renwu_%02d", info._id))
    spine:setScale(0.7)
    lc.addChildToPos(layout, spine, cc.p(lc.cw(layout), lc.y(nameBg) + lc.ch(spine)))
    self._spine = spine
    self:runAction(
        lc.sequence(
            function()
                spine:setAnimation(0, "animation", true)
            end
        )
    )
    local light = lc.createSprite('img_light')
    light:setScale(5)
    light:runAction(lc.rep(lc.sequence(lc.scaleTo(0.8, 6), lc.scaleTo(0.8, 5))))
    lc.addChildToPos(layout, light, cc.p(lc.x(nameBg), lc.top(nameBg) + 200), -1)
    layout._light = light

    --[[
    local particle = Particle.create('xuanzhong')
    particle:setPositionType(cc.POSITION_TYPE_GROUPED) 
    lc.addChildToPos(layout, particle, cc.p(lc.x(nameBg), lc.top(nameBg) + 20), -1)
    layout._particle = particle
    ]]

    local lock = lc.createSprite('img_lock')
    lc.addChildToPos(layout, lock, cc.p(lc.x(nameBg), lc.top(nameBg) + 64))
    layout._lock = lock

    local tipBg = lc.createSprite({_name = "img_form_title_light_1", _crect = V.CRECT_FORM_TITLE_LIGHT1_CRECT, _size = cc.size(300, V.CRECT_FORM_TITLE_LIGHT1_CRECT.height)})
    lc.addChildToPos(layout, tipBg, cc.p(lc.x(nameBg), lc.top(nameBg) + 12))
    layout._tipBg = tipBg

    local tip = V.createTTF(Str(STR.CAN_S)..Str(STR.UNLOCK)..Str(Data.getRecruiteInfo(info._packageIds[1])._nameSid), V.FontSize.S3)
    tip:setColor(lc.Color3B.yellow)
    lc.addChildToCenter(tipBg, tip)

    if info._id == 2 then lc.offset(bones, 10, 0) end

    self._curCharaNode:removeAllChildren()
    self._curCharaNode:addChild(layout)

    local isLock = not self._isGuide and not P:isCharacterUnlocked(layout._id) or false

    --layout._nameBg:setSpriteFrame(lc.FrameCache:getSpriteFrame(not isLock and 'img_com_bg_44' or 'img_com_bg_43'), V.CRECT_COM_BG43)
    layout._nameBg:setContentSize(ITEM_W, V.CRECT_COM_BG43.height)
    layout._nameBg:setEffect(nil)
    layout._nameBg:setEffect(isLock and V.SHADER_DISABLE or nil)

    layout._light:setVisible(not isLock)
    --layout._particle:setVisible(not isLock)
    layout._lock:setVisible(isLock)
    layout._tipBg:setVisible(isLock or self._isGuide)

    
    self._btnOk:setVisible(not isLock)
    self._btnUnlock:setVisible(isLock)
end


function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
    
    self._invalidInputListener = lc.addEventListener(Data.Event.invalid_input, function(event)
        self._btnOk:setEnabled(true)
    end)
end

function _M:onExit()
    _M.super.onExit(self)

    ClientData.removeMsgListener(self)
    lc.Dispatcher:removeEventListener(self._invalidInputListener)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_icon_dice.jpg"))
end

function _M:onCleanup()
    _M.super.onCleanup(self)
        
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/change_character_bg.jpg"))  
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_USER_SET_NAME or msgType == SglMsgType_pb.PB_TYPE_USER_SET_NAME_GUIDE then
        V.getActiveIndicator():hide()
        local name = string.trim(self._editor:getText())
        P:changeName(name)

        local eventCustom = cc.EventCustom:new(Data.Event.change_name_dirty)
        lc.Dispatcher:dispatchEvent(eventCustom)

        P._characters[self._selectedId]._level = 1
        P:changeCharacter(self._selectedId, true)
        ClientData.sendSetCharacter(self._selectedId, true)

        if lc.App:getChannelName() == 'ASDK' then
            ClientData.submitRoleData('1')
        end

        return true
    elseif msgType == SglMsgType_pb.PB_TYPE_USER_SET_CHARACTER then
        local cards = msg.Extensions[User_pb.SglUserMsg.init_cards_resp]
        for i = 1, #cards do
            local infoId, num = cards[i].info_id, cards[i].num
            local type = Data.getType(infoId)
            P._playerCard:addCard(infoId, num)
            P._playerCard._troops[1][#P._playerCard._troops[1] + 1] = {_infoId = infoId, _num = num}
            P._playerCard._unlocked[infoId] = nil
            
        end
        
        self:hide()
        GuideManager.finishStep()
        return true
    end
    
    return false
end

function _M:onConfirm()
    if not self._isGuide then
        if self._selectedId ~= P:getCharacterId() then
            P:changeCharacter(self._selectedId)
            ClientData.sendSetCharacter(self._selectedId)
            local data = self._selectedId * 100 + 1
            if P:changeAvatarImage(data) then
                ClientData.sendSetAvatarImage(data)
            end
        end
        self:hide()
    else
        if not self._editor:isValidName() then
            ToastManager.push(Str(STR.INPUT_NAME_INVALID))
        else
            local name = string.trim(self._editor:getText())
            V.getActiveIndicator():show(Str(STR.WAITING))
            ClientData.sendChangeNameGuide(name)
            self._btnOk:setEnabled(false)
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

function _M:createHead(info)
    local head = V.createShaderButton(nil)
    head:setDisabledShader(V.SHADER_DISABLE)
    local headSpr = V.createCharacterHeadById(info._id)
    head:setContentSize(headSpr:getContentSize())
    lc.addChildToCenter(head, headSpr)
    head._headSpr = headSpr
    local frame = lc.createSprite("avatar_frame_001")
    lc.addChildToCenter(head, frame, 2)
    function head:select(id)
        if id==-1 then return end
        headSpr:removeAllChildren()
        --[[
        if id==info._id then
            local selectSpr = lc.createSprite("character_selected")
            lc.addChildToCenter(headSpr , selectSpr, -1)
        end]]
    end
    head._callback = function(sender)
        if self._isGuide and info._id ~= 2 and info._id ~= 3 and info._id ~= 5 then
            return ToastManager.push(Str(STR.CANNOT_SELECT_CHARACTR))
        end
        self:setCurrentCharacter(info)
        for k,head in pairs(self._heads) do
            head:select(info._id)
        end
    end
    self._heads[info._id] = head
    if self._isGuide and info._id ~= 2 and info._id ~= 3 and info._id ~= 5 then
        headSpr:setEffect(V.SHADER_DISABLE)
    end

    return head
end


function _M:setOrCreateItem(info1, info2)
    local head1 = self:createHead(info1)
    local head2 = self:createHead(info2)

    local layout = ccui.Widget:create()
    layout:setContentSize(cc.size(lc.w(head1) + lc.w(head2) + 2*GAP , lc.h(head1)))
    lc.addChildToPos(layout, head1, cc.p(lc.cw(head1), lc.ch(layout)))
    lc.addChildToPos(layout, head2, cc.p(lc.w(layout) - lc.cw(head2), lc.ch(layout)))

    return layout
end

function _M:onSelectCharacter(id)
end

function _M:onUnlock(id)
    local propId = Data.PropsId.millennium_block
    if P._propBag:hasProps(propId, 1) then
        require("Dialog").showDialog(string.format(Str(STR.SURE_TO_UNLOCK_CHARACTER_PROP), 1, Str(Data._propsInfo[propId]._nameSid), Str(Data._characterInfo[id]._nameSid)), function() 
            P._propBag:changeProps(propId, -1)
            ClientData.sendUnlockCharacter(id, false)
            self:onUnlocked(id)
        end)
    else
        propId = Data.ResType.ingot
        local ingotNeed = Data._globalInfo._unlockCharIngot
        require("Dialog").showDialog(string.format(Str(STR.SURE_TO_UNLOCK_CHARACTER_INGOT, true), ingotNeed, Str(Data._resInfo[propId]._nameSid), Str(Data._characterInfo[id]._nameSid)), function() 
            if V.checkIngot(ingotNeed) then
                P:changeResource(propId, -ingotNeed)
                ClientData.sendUnlockCharacter(id, true)
                self:onUnlocked(id)
            end
        end)
    end
end

function _M:onUnlocked(id)
    ToastManager.push(string.format(Str(STR.CHARACTER_UNLOCKED), Str(Data._characterInfo[id]._nameSid)))
    P._characters[id]._level = 1
    self:selectCharacter(id)
end

function _M:selectCharacter(id)
    self._heads[id]:_callback()
end

return _M