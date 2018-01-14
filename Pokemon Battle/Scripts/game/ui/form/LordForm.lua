local _M = class("LordForm", BaseForm)

local FORM_SIZE = cc.size(900, 662)

local H_MARGIN = _M.LEFT_MARGIN
local V_MARGIN = _M.TOP_MARGIN + 20

local BIG_BTN_W = 128
local SMALL_BTN_W = 80

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local infoNode = lc.createNode(cc.size(lc.w(self._form) - 300, lc.h(self._form)))
    lc.addChildToPos(self._form, infoNode, cc.p(lc.w(self._form) - lc.cw(infoNode), lc.ch(self._form)))
    self._infoNode = infoNode

    local imgFrame = lc.createSprite("res/jpg/CharacterImageFrame.png")
    lc.addChildToPos(self._form, imgFrame, cc.p(20 + lc.cw(imgFrame), lc.ch(self._form)))
    self._imgFrame = imgFrame
    --
    local characterImg = lc.createSprite(P._avatarImage > 100 and string.format("res/jpg/avatar_image_%04d.jpg", P._avatarImage) or string.format("res/jpg/avatar_image_%02d01.jpg", P:getCharacterId()))
    lc.addChildToCenter(self._imgFrame, characterImg, -1)
    characterImg.setAvatarImage = function(self, user)
        self:setTexture(user._avatarImage and string.format("res/jpg/avatar_image_%04d.jpg", user._avatarImage) or "res/jpg/avatar_image_0201.jpg")
    end
    self._characterImg = characterImg

    local bgPanel = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._infoNode) - 60, 155)})
    bgPanel:setOpacity(127)
    lc.addChildToPos(self._infoNode, bgPanel, cc.p(lc.cw(self._infoNode), lc.ch(bgPanel) + 40), -1)
    local bgPanel2 = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._infoNode) - 60, 170)})
    bgPanel2:setOpacity(127)
    lc.addChildToPos(self._infoNode, bgPanel2, cc.p(lc.cw(self._infoNode), lc.top(bgPanel) + lc.ch(bgPanel2) + 20), -1)
    local bgPanel3 = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(imgFrame) + 4, lc.h(imgFrame) + 4)})
    lc.addChildToCenter(imgFrame, bgPanel3, -2)
    -- Avatar
    local avatar = UserWidget.create(P, UserWidget.Flag.NAME_UNION_VIP)
    --avatar._unionArea._name:setColor(V.COLOR_TEXT_ORANGE)
    --avatar._nameArea._level:setVisible(false)
    lc.addChildToPos(self._infoNode, avatar, cc.p(H_MARGIN + lc.w(avatar) / 2 + 10, lc.h(self._infoNode) - 32 - lc.h(avatar) / 2))
    self._userAvatar = avatar

    -- Information
    local idIcon = lc.createSprite("img_icon_id")
    lc.addChildToPos(self._infoNode, idIcon, cc.p(384, lc.top(avatar) - lc.ch(idIcon) - 16))

    local id = V.createBMFont(V.BMFont.num_24, ClientData.convertId(P._id))
    lc.addChildToPos(self._infoNode, id, cc.p(lc.right(idIcon) + 6 + lc.w(id) / 2, lc.y(idIcon)))

    self:updateLevelExpBar()

    --[[
    if avatar._unionArea and avatar._unionArea:isVisible() then
        avatar._unionArea:setPosition(lc.left(bg) + lc.w(avatar._unionArea) / 2 + 4, lc.bottom(levelExpBar) - 24)
    else
        local notJoin = V.createTTF(string.format("(%s%s)", Str(STR.NOT_JOIN), Str(STR.UNION)), nil, V.COLOR_TEXT_LIGHT)
        lc.addChildToPos(avatar, notJoin, cc.p(lc.left(bg) + lc.w(notJoin) / 2 + 4, lc.bottom(levelExpBar) - 24))
    end
    ]]

    -- Modify character
    local btnCharacter = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onChangeCharacter() end, V.CRECT_BUTTON_S, BIG_BTN_W)
    btnCharacter:addLabel(Str(STR.CHANGE_CHARACTER))
    lc.addChildToPos(self._infoNode, btnCharacter, cc.p(lc.w(self._infoNode) - H_MARGIN - lc.w(btnCharacter) / 2, lc.y(self._levelExpBar)))
    btnCharacter:setVisible(false)
    
    local gap = 30

    -- Modify name button
    local btnChangeName = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onChangeName() end, V.CRECT_BUTTON_S, BIG_BTN_W)
    btnChangeName:addLabel(Str(STR.CHANGE_NAME))
    lc.addChildToPos(self._infoNode, btnChangeName, cc.p(lc.left(self._userAvatar) + lc.w(btnChangeName) / 2 - 10, lc.bottom(self._userAvatar) - 96)) 
    btnChangeName:setScale(0.8)

    -- Modify avatar button
    local btnChangeAvatar = V.createScale9ShaderButton("img_btn_1_s",  function(sender) self:onChangeAvatar() end, V.CRECT_BUTTON_S, BIG_BTN_W)
    btnChangeAvatar:addLabel(Str(STR.CHANGE_OUTLOOK))
    lc.addChildToPos(self._infoNode, btnChangeAvatar, cc.p(lc.right(btnChangeName) + lc.w(btnChangeAvatar) / 2 + gap, lc.y(btnChangeName))) 
    btnChangeAvatar:setScale(0.8)

    -- Modify avatar frame button
    --[[ local btnChangeAvatarFrame = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onChangeAvatarFrame() end, V.CRECT_BUTTON_S, BIG_BTN_W)
    btnChangeAvatarFrame:addLabel(Str(STR.CHANGE_RECT))
    lc.addChildToPos(self._infoNode, btnChangeAvatarFrame, cc.p(lc.right(btnChangeAvatar) + lc.w(btnChangeAvatarFrame) / 2 + gap, lc.y(btnChangeAvatar)))
    ]]
    -- Modify card back button
    local btnChangeCardBack = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onChangeCardBack() end, V.CRECT_BUTTON_S, BIG_BTN_W)
    btnChangeCardBack:addLabel(Str(STR.CHANGE_CARD_BACK))
    lc.addChildToPos(self._infoNode, btnChangeCardBack, cc.p(lc.right(btnChangeAvatar) + lc.w(btnChangeCardBack) / 2 + gap, lc.y(btnChangeAvatar)))
    btnChangeCardBack:setScale(0.8)
    -- help
    local btnHelp = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onHelp() end, V.CRECT_BUTTON_S, BIG_BTN_W - 30 - 3)
    btnHelp:addLabel(Str(STR.HELP))
    lc.addChildToPos(self._infoNode, btnHelp, cc.p(lc.right(btnChangeCardBack) + lc.w(btnHelp) / 2 + gap, lc.y(btnChangeCardBack)))
    btnHelp:setScale(0.8)

    --TODO
    btnHelp:setDisabledShader(V.SHADER_DISABLE)
    btnHelp:setEnabled(false)

    if not ClientData.isAppStoreReviewing() then
        -- VIP button
        local btnVIP = V.createShaderButton("img_btn_vip", function(sender) self:onShowVIP() end)
        btnVIP:addLabel("VIP "..Str(STR.PRIVILEGE))
        btnVIP._label:setColor(V.COLOR_TEXT_INGOT)
        lc.addChildToPos(self._infoNode, btnVIP, cc.p(lc.w(self._infoNode) - H_MARGIN - lc.w(btnVIP) / 2, lc.top(self._userAvatar) - lc.h(btnVIP) / 2 + 10 - 66))
        btnVIP:setVisible(not ClientData.isHideCharge())

        -- Exchange code button
        local btnCode = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onShowExchangeCode() end, V.CRECT_BUTTON_S, BIG_BTN_W)
        btnCode:addLabel(Str(STR.EXCHANGE_CODE))
        --btnCode._label:setColor(V.COLOR_TEXT_INGOT)
        lc.addChildToPos(self._infoNode, btnCode, cc.p(lc.x(btnVIP), 110))--lc.bottom(btnVIP) - lc.h(btnCode) / 2 - 10))

        --TODO
        btnCode:setDisabledShader(V.SHADER_DISABLE)
        btnCode:setEnabled(false)
    end

    -- Dividing line
    --local dividingLine = V.createDividingLine(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, V.COLOR_DIVIDING_LINE_LIGHT)
    --lc.addChildToPos(self._infoNode, dividingLine, cc.p(lc.w(self._infoNode) / 2, lc.bottom(btnChangeName) - 20))

    -- Music switch
    local btnMusic = V.createShaderButton(ClientData._isMusicOn and "img_btn_on" or "img_btn_off", function(sender) self:onSwitchMusic(sender) end)
    btnMusic:setPressedShader(nil)
    btnMusic:setZoomScale(0)
    lc.addChildToPos(self._infoNode, btnMusic, cc.p(2 * lc.w(self._infoNode) / 7 - 4, lc.bottom(btnChangeName) - 20 - lc.h(btnMusic) / 2 - 20))

    local labelMusic = V.createTTFStroke(Str(STR.AUDIO_MUSIC), V.FontSize.S2)
    --labelMusic:setColor(V.COLOR_LABEL_LIGHT)
    lc.addChildToPos(self._infoNode, labelMusic, cc.p(lc.left(btnMusic) - lc.w(labelMusic) / 2 - 10, lc.y(btnMusic)))
    
    -- Effect switch
    local btnEffect = V.createShaderButton(ClientData._isEffectOn and "img_btn_on" or "img_btn_off", function(sender) self:onSwitchEffect(sender) end)
    btnEffect:setPressedShader(nil)
    btnEffect:setZoomScale(0)
    lc.addChildToPos(self._infoNode, btnEffect, cc.p(6 * lc.w(self._infoNode) / 7 - 15, lc.y(btnMusic)))

    local labelEffect = V.createTTFStroke(Str(STR.AUDIO_EFFECT), V.FontSize.S2)
    lc.addChildToPos(self._infoNode, labelEffect, cc.p(lc.left(btnEffect) - lc.w(labelEffect) / 2 - 10, lc.y(btnEffect)))

    -- Illusion button
    --local btnIllustration = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onShowIllustration() end, V.CRECT_BUTTON_S, BIG_BTN_W)
    --btnIllustration:addLabel(Str(STR.ILLUSTRATION))
    --lc.addChildToPos(self._infoNode, btnIllustration, cc.p(lc.w(self._infoNode) - H_MARGIN - lc.w(btnIllustration) / 2, lc.y(btnEffect)))

    -- Change server button
    local btnRegion = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onChangeRegion() end, V.CRECT_BUTTON_S, BIG_BTN_W + 40)
    btnRegion:addLabel(Str(STR.CHANGE_REGION))
    btnRegion:setScale(0.8)
    lc.addChildToPos(self._infoNode, btnRegion, cc.p(lc.x(btnChangeAvatar) + 95, lc.bottom(btnMusic) - lc.h(btnRegion) / 2 - 20))
    --[[
    local regionBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(240, 40)}
    regionBg:setColor(lc.Color3B.black)
    regionBg:setOpacity(150)
    lc.addChildToPos(self._infoNode, regionBg, cc.p(lc.left(labelMusic) + lc.w(regionBg) / 2 - 10, lc.y(btnRegion)), -1)
    ]]
    local region = ClientData._userRegion
    local labelRegion = V.createTTFStroke(ClientData.genFullRegionName(region._id, region._name, true), V.FontSize.S1)
    labelRegion:setScale(0.8)    
    lc.addChildToPos(self._infoNode, labelRegion, cc.p(lc.left(labelMusic) + lc.sw(labelRegion) / 2, lc.y(btnRegion)))

    -- Change account button
    local channelName = lc.App:getChannelName()
    if channelName ~= 'ASDK' and channelName ~= 'KPZS' and channelName ~= 'YIXIN' and (not ClientData.isAppStoreReviewing()) then
        local btnUser = V.createScale9ShaderButton("img_btn_1_s",  function(sender) self:onChangeUser() end, V.CRECT_BUTTON_S, BIG_BTN_W)
        btnUser:addLabel(Str(STR.CHANGE_USER))
        btnUser:setScale(0.8)
        lc.addChildToPos(self._infoNode, btnUser, cc.p(lc.w(self._infoNode) - H_MARGIN - lc.w(btnUser) / 2, lc.y(btnRegion)))
    end
    
    -- Notice button
    --[[
    local btnNotice = V.createScale9ShaderButton("img_btn_1", function(sender) self:onPushNotice() end, V.CRECT_BUTTON, BIG_BTN_W)
    btnNotice:addLabel(Str(STR.PUSH_NOTICE))    
    lc.addChildToPos(self._infoNode, btnNotice, cc.p(lc.x(btnIllustration), lc.y(btnRegion)))
    ]]

    -- bind button
    if channelName == 'FACEBOOK' then
        local btnBind = V.createScale9ShaderButton(P._canBind and "img_btn_2_s" or "img_btn_1_s",  function(sender) self:onBindUser() end, V.CRECT_BUTTON_S, BIG_BTN_W)
        btnBind:addLabel(Str(P._canBind and STR.BIND_GCID or STR.BIND_GCID_BOUND))
        lc.addChildToPos(self._infoNode, btnBind, cc.p(btnNotice:getPosition()))
        if lc.FrameCache:getSpriteFrame("img_facebook") then
            local icon = lc.createSprite("img_facebook")
            lc.addChildToPos(btnBind, icon, cc.p(28, lc.h(btnBind) / 2 + 1))
            btnBind._label:setPositionX(lc.x(btnBind._label) + 16)
        end
        self._btnBind = btnBind

        btnNotice:setPosition(cc.p(lc.x(btnChangeAvatarFrame), lc.y(btnIllustration)))
    end

    -- Dividing line
    --dividingLine = V.createDividingLine(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, V.COLOR_DIVIDING_LINE_LIGHT)
    --lc.addChildToPos(self._infoNode, dividingLine, cc.p(lc.w(self._infoNode) / 2, lc.bottom(btnRegion) - 20))
    
    if true then
        local marginTop = lc.bottom(btnRegion) - 90
        local marginLeft = V_MARGIN 
        local aboutInfos = {}
        for k, v in pairs(Data._aboutInfo) do
            if not ClientData.isAppStoreReviewing() and (lc.PLATFORM ~= cc.PLATFORM_OS_ANDROID or ClientData.isYYB()) then
                table.insert(aboutInfos, v)
            end
        end    
        table.sort(aboutInfos, function(a, b) return a._id < b._id end)
        for i = 1, #aboutInfos do
            local content = Str(aboutInfos[i]._descSid)
            if i == 2 and ClientData.isYYB() then content = '368241725' end
            local keyLabel, valueLabel = V.createKeyValueLabel(Str(aboutInfos[i]._nameSid), content, V.FontSize.S1)
            keyLabel:setScale(0.7)
            valueLabel:setScale(0.7)
            keyLabel:addToParent(self._infoNode, cc.p(marginLeft, marginTop))

            --marginLeft = marginLeft + 360
            marginTop = marginTop - 34
        end
    
        -- About button
        local btnAbout = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onAbout() end, V.CRECT_BUTTON_S, BIG_BTN_W)
        btnAbout:addLabel(Str(STR.ABOUT))
        --lc.addChildToPos(self._infoNode, btnAbout, cc.p(lc.x(btnIllustration), marginTop))
        lc.addChildToPos(self._infoNode, btnAbout, cc.p(lc.w(self._infoNode) - H_MARGIN - lc.w(btnAbout) / 2, lc.y(btnRegion)))
    
        btnAbout:setVisible(false)
    end
    
    if ClientData.isRateValid() then
        local btnRate = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onRate() end, V.CRECT_BUTTON_S, BIG_BTN_W)
        btnRate:addLabel(Str(STR.RATE))
        lc.addChildToPos(self._infoNode, btnRate, cc.p(lc.left(btnAbout) - 10 - lc.w(btnRate) / 2, marginTop))
    end

    self._isShowResourceUI = true

    local version = V.createBMFont(V.BMFont.huali_20, Str(STR.VERSION)..ClientData.getDisplayVersion())
    version:setScale(0.8)
    lc.addChildToPos(self, version, cc.p(lc.w(self) / 2, 30))
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    self._listeners = {}
    
    local listener = lc.addEventListener(Data.Event.name_dirty, function(event) self._userAvatar:setName(P._name) end)
    table.insert(self._listeners, listener)
    
    listener = lc.addEventListener(Data.Event.icon_dirty, function(event) self._userAvatar:setAvatar(P) end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.avatar_image_dirty, function(event) self._characterImg:setAvatarImage(P) end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.avatar_frame_dirty, function(event) self._userAvatar:setAvatar(P) self._userAvatar:setVip(P._vip) end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.vip_dirty, function(event) self._userAvatar:setVip(P._vip) end)
    table.insert(self._listeners, listener)

    local listener = lc.addEventListener(Data.Event.character_dirty, function(event) self._userAvatar:setAvatar(P) self:updateLevelExpBar() end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.bind_gcid_dirty, function(event) self:updateBindBtn() end)
    table.insert(self._listeners, listener)

    if GuideManager.getCurStepName() == "enter setting" then
        GuideManager.finishStepLater()
    end
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    self._listeners = {}
end

function _M:onChangeCharacter()
    require("ChangeCharacterPanel").create(false):show()
end

function _M:onShowVIP()
    require("VIPInfoForm").create():show()
    --lc.pushScene(require("RechargeScene").create())
end

function _M:onShowExchangeCode()
    require("ExchangeCodeForm").create():show()  
end

function _M:onChangeAvatar()
    require("SelectOutlookForm").create():show()
end

function _M:onChangeName()
    require("RenameForm").create():show()
end

function _M:onChangeAvatarFrame()
    require("SelectAvatarFrameForm").create():show()
end

function _M:onChangeCardBack()
    require("SelectCardBackForm").create():show()
end

function _M:onHelp()
    require("BattleHelpForm").create():show()
end

function _M:onChangeRegion()
    ClientData.switchToRegionScene()
end

function _M:onChangeUser()
    if lc.App:getChannelName() == 'APPSTORE' then
        require("Dialog").showDialog(Str(STR.CHANGE_USER_IN_GAMECENTER), function() end)
    else
        ClientData._regions = {}
        ClientData.saveUserRegion()
        lc.App:userLogout()
    
        V.getActiveIndicator():show(Str(STR.WAITING))
    end
end

function _M:onBindUser()
    if P._canBind then
        if lc.App.facebookLogin ~= nil then
            lc.App:facebookLogin()
            V.getActiveIndicator():show(Str(STR.WAITING))
        end
    else
        ToastManager.push(Str(STR.BIND_GCID_BOUND_LONG)) 
    end
end

function _M:onSwitchMusic(sender)
    ClientData.toggleAudio(lc.Audio.Behavior.music, not ClientData._isMusicOn)
    sender:loadTextureNormal(ClientData._isMusicOn and "img_btn_on" or "img_btn_off", ccui.TextureResType.plistType)
    --sender:setContentSize(cc.size(SMALL_BTN_W, V.CRECT_BUTTON_S.height))
end

function _M:onSwitchEffect(sender)
    ClientData.toggleAudio(lc.Audio.Behavior.effect, not ClientData._isEffectOn)    
    sender:loadTextureNormal(ClientData._isEffectOn and "img_btn_on" or "img_btn_off", ccui.TextureResType.plistType)
    --sender:setContentSize(cc.size(SMALL_BTN_W, V.CRECT_BUTTON_S.height))
end

function _M:onShowIllustration()
    require("IllustrationForm").create():show()
end

function _M:onPushNotice()
    require("PushNoticeForm").create():show()
end

function _M:onAbout()
    require("AboutForm").create():show()
end

function _M:onRate()
    require("RateForm").create():show()
end

function _M:onShowActionFinished()
    self:onGuide(nil)
end

function _M:onHideActionFinished()
    if GuideManager.getCurStepName() == "leave setting" then
        GuideManager.finishStep()
    end
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "leave setting" then
        GuideManager.setOperateLayer(self._btnBack)
    else
        return
    end
    
    if event then
        event:stopPropagation()
    end
end

function _M:updateBindBtn()
    if self._btnBind ~= nil then
        self._btnBind._label:setString(Str(P._canBind and STR.BIND_GCID or STR.BIND_GCID_BOUND))
        self._btnBind:loadTextureNormal(P._canBind and "img_btn_2" or "img_btn_1", ccui.TextureResType.plistType)
    end
end

function _M:updateLevelExpBar()
    if self._levelExpBar ~= nil then self._levelExpBar:removeFromParent() end

    local character = P._characters[P:getCharacterId()]
    local levelExpBar = V.createLevelExpBar(character._level, character._exp, P:getLevelupExp(character._level), 512)
    if character._level >= P:getMaxLevel() then levelExpBar._label:setString(Str(STR.MAX_LEVEL)) end
    lc.addChildToPos(self._infoNode, levelExpBar, cc.p(lc.left(self._userAvatar) + lc.cw(levelExpBar) + 12, lc.bottom(self._userAvatar) - 36))
    self._levelExpBar = levelExpBar

    local name = V.createBMFont(V.BMFont.huali_26, Str(Data._characterInfo[character._id]._nameSid))
    name:setAnchorPoint(0, 0.5)
    lc.addChildToPos(levelExpBar, name, cc.p(-180, lc.ch(levelExpBar)))
end

return _M