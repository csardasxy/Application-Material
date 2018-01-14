local Socket_pb = require "Socket_pb"

local _M = class("RegionScene", require("BaseScene"))

function _M.create()
    return lc.createScene(_M)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.region) then return false end
    
    ClientData.loadLCRes("res/avatar.lcres")
    ClientData.loadLCRes("res/general.lcres")

    lc.FrameCache:addSpriteFrames("res/updater/loading.plist", "res/updater/loading.pvr.ccz")
    
    local isAgree = lc.UserDefault:getBoolForKey(ClientData.ConfigKey.agreement, false)
    if ClientData.isAppStoreReviewing() then
        isAgree = true
    end
    
    --local version = V.createBMFont(V.BMFont.huali_20, Str(STR.VERSION)..ClientData.getDisplayVersion()..(lc.PLATFORM == cc.PLATFORM_OS_ANDROID and ('    '..Str(STR.ISBN)) or ''))
    local version = V.createBMFont(V.BMFont.huali_20, Str(STR.VERSION)..ClientData.getDisplayVersion())
    version:setScale(0.8)
    lc.addChildToPos(self, version, cc.p(V.SCR_CW, 20), 2)

    local bg = V.createLoadingBg()
    bg:setPosition(V.SCR_CW, V.SCR_CH)
    self:addChild(bg)
    --[[
    if ClientData.isAppStoreReviewing() then
        local bg = V.createLoadingBg()
        bg:setPosition(V.SCR_CW, V.SCR_CH)
        self:addChild(bg)
    elseif ClientData.isDJLX() then
        local bg = cc.Sprite:create("res/updater/loading_djlx.jpg")
        bg:setPosition(V.SCR_CW, V.SCR_CH)
        self:addChild(bg)

        local bone = cc.DragonBonesNode:createWithDecrypt("res/effects/loading3.lcres", "loading3", "loading3")
        bone:gotoAndPlay("effect1")
        lc.addChildToPos(self, bone, cc.p(lc.w(self) / 2 + 36, lc.h(self) / 2 - 58))
        self._bone = bone
    else
        local bg = cc.Sprite:create("res/updater/loading.jpg")
        bg:setPosition(V.SCR_CW, V.SCR_CH)
        self:addChild(bg)

        local bone = cc.DragonBonesNode:createWithDecrypt("res/effects/loading.lcres", "loading", "loading")
        bone:gotoAndPlay("effect1")
        lc.addChildToPos(self, bone, cc.p(lc.w(self) / 2 + 36, lc.h(self) / 2 + 122))
        self._bone = bone
    end
    ]]

    local node = lc.createNode(cc.size(lc.w(self), lc.h(self))) 
    lc.addChildToCenter(self, node, 1)
    node:setVisible(false)

    local regionBg = lc.createSprite('load_region_bg')
    regionBg:setScale(8, 1)
    lc.addChildToPos(node, regionBg, cc.p(V.SCR_CW, isAgree and 190 or 200))

    local btnChange = V.createScale9ShaderButton(nil, function(sender)
        
        if not self._changeLabel:isVisible() then return end

        local regionForm = require("SelectRegionForm").create()
        regionForm._callback = function(regionId)
            ClientData._userRegion._id = regionId
            self:updateSelectedRegion()
        end
        regionForm:show()
        
    end, cc.rect(1, 1, 1, 1), 460, 62)
    btnChange:setColor(cc.c3b(12, 15, 30))
    btnChange:setTouchEnabled(false)
    btnChange:setContentSize(hintBgSize)
    lc.addChildToPos(node, btnChange, cc.p(lc.w(self) / 2, lc.y(regionBg)))
    self._btnChange = btnChange

    local loadingText = cc.Label:createWithTTF(Str(STR.REGION_LOADING), V.TTF_FONT, V.FontSize.M2)
    lc.addChildToCenter(btnChange, loadingText, 2)
    self._loadingText = loadingText

    local regionText = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.M2)
    regionText:setAnchorPoint(0, 0.5)
    regionText:setVisible(false)
    lc.addChildToPos(btnChange, regionText, cc.p(16, lc.h(btnChange) / 2), 2)
    self._regionText = regionText
    
    lc.offset(regionText, 100, 0)
    
    local label = cc.Label:createWithTTF(Str(STR.REGION_CHANGE), V.TTF_FONT, V.FontSize.M2)
    label:setAnchorPoint(1, 0.5)
    label:setVisible(false)
    label:setColor(lc.Color3B.green)
    lc.addChildToPos(btnChange, label, cc.p(lc.w(btnChange) - 16, lc.h(btnChange) / 2), 2)
    self._changeLabel = label
    

    local btnStart = V.createShaderButton('start_button', function() self:switchScene() end)
    btnStart:setContentSize(280, 110)
    btnStart:setEnabled(false)
    lc.addChildToPos(node, btnStart, cc.p(V.SCR_CW + 10, 94))
    self._btnStart = btnStart
    
    --[[
    local str = "kaishi"
    local bone = cc.DragonBonesNode:createWithDecrypt(string.format("res/effects/%s.lcres", str), str, str)
    bone:gotoAndPlay("effect")
    lc.addChildToCenter(btnStart, bone)
    ]]

    if not isAgree then
        local agreeBg = lc.createSprite('load_region_bg')
        agreeBg:setScale(8, 0.5)
        lc.addChildToPos(node, agreeBg, cc.p(V.SCR_CW, 150), 1)

        local agree = V.createTTF(string.format(Str(STR.CONFIRM_AGREEMENT), ClientData.getAppName()), V.FontSize.S3, lc.Color3B.white)
        lc.addChildToPos(node, agree, cc.p(V.SCR_CW, 150), 1)
    end

    --[[
    local gameAnnounce = V.createTTF(Str(STR.GAME_ANNOUNCE, true), 18)
    gameAnnounce:setColor(cc.c3b(80, 100, 180))
    lc.addChildToPos(self, gameAnnounce, cc.p(V.SCR_CW, V.SCR_H - 28))
    ]]

    if ClientData.isShowAgreement() then
        lc.TextureCache:addImageWithMask("res/jpg/load_btn_agreement.jpg")

        local btnAgreement = V.createShaderButton("res/jpg/load_btn_agreement.jpg", V.openUserProtocol)
        lc.addChildToPos(btnAgreement, V.createBMFont(V.BMFont.huali_26, Str(STR.AGREEMENT)), cc.p(lc.w(btnAgreement) / 2, 20))
        lc.addChildToPos(self, btnAgreement, cc.p(V.SCR_W - 12 - lc.w(btnAgreement) / 2, V.SCR_H - 20 - lc.h(btnAgreement) / 2))
    end

    self._isPacketReceived = false
    self._isGuideOnEnter = false

    node:setVisible(true)
    --[[
    if ClientData.isAppStoreReviewing() then
        node:setVisible(true)
    else
        local duration = self._bone:getAnimationDuration("effect1")
        self:runAction(lc.sequence(duration, function() 
            self._bone:gotoAndPlay('effect2') 

            local particle = Particle.create("zi")
            lc.addChildToPos(self, particle, cc.p(lc.w(self) / 2, lc.h(self) / 2), 1)

            local particle = Particle.create("huo")
            lc.addChildToPos(self, particle, cc.p(lc.w(self) / 2, 50))
        
            node:setVisible(true)
        end))
    end
    ]]
    
    return true
end

function _M:onEnter()
    _M.super.onEnter(self)

    GuideManager.releaseLayer()

    self._loadingTick = 0
    self._loadingSchedulerID = lc.Scheduler:scheduleScriptFunc(function(dt)
        self:updateLoading(dt)
    end, 0.2, false)

    ClientData.reconnectRegionServer()
    
    lc.Audio.playAudio(AUDIO.M_LOADING)
end

function _M:onExit()
    _M.super.onExit(self)

    self:unscheduleLoading()

    lc.Dispatcher:removeEventListener(self._listener)
end

function _M:onCleanup()  
    _M.super.onCleanup(self)
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status
    
    if msgType == SglMsgType_pb.PB_TYPE_REGION_LIST then
        local resp = msg.Extensions[Region_pb.SglRegionMsg.region_list_resp]
        ClientData._regions = {}
        for i = 1, #resp.region do
            local region = self:newRegion(resp.region[i])
            if ClientData.isDJLX() then
                if region._id > Data.DJLX_REGION_ID_BASE then
                    ClientData._regions[region._id] = region
                end
            else
                ClientData._regions[region._id] = region
            end
        end                         
        ClientData._regionCount = #resp.region
        if ClientData.isDJLX() then
            ClientData._regionCount = ClientData._regionCount - Data.DJLX_REGION_ID_BASE
        end
        
        ClientData._historyRegion = {}
        local lastLogin = resp.last_login
        for i = 1, #lastLogin do
            local history = self:newHistory(lastLogin[i])
            if ClientData._regions[history._rid] then
                table.insert(ClientData._historyRegion, history)
            end
        end
        
        if #ClientData._historyRegion > 0 then
            ClientData._userRegion._id = ClientData._historyRegion[1]._rid
        else
            local lastRecommend, lastNew, lastNomal = nil, nil, nil
            for _, v in pairs(ClientData._regions) do
                lastNormal = v._id
                if v._isRecommend then lastRecommend = v._id end
                if v._isNew then lastNew = v._id end
            end
            ClientData._userRegion._id = lastRecommend or lastNew or lastNormal
        end
        self._isPacketReceived = true
        self:tryUnscheduleLoading() 
    end
    
    if _M.super.onMsg(self, msg) then return true end
    
    return false
end

function _M:onIdle() 
    lc.Director:updateTouchTimestamp()
end

function _M:newRegion(pbRegion)
    local region = {}
    region._id = pbRegion.id
    region._host = pbRegion.host
    region._name = pbRegion.name
    region._status = pbRegion.status
    region._isNew = pbRegion.is_new
    region._isRecommend = pbRegion.is_recommend
    return region
end

function _M:newHistory(pbHistory)
    local history = {}
    history._rid = pbHistory.rid
    history._name = pbHistory.name
    history._level = pbHistory.level
    history._avatar = pbHistory.avatar
    history._vip = pbHistory.vip

    history._avatarFrameId = pbHistory.avatar_frame
    if history._avatarFrameId == 0 then
        history._avatarFrameId = nil
    end

    lc.log("rid: %d, timestamp:%f", pbHistory.rid, pbHistory.last_login)

    return history
end

function _M:unscheduleLoading()
    if self._loadingSchedulerID ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._loadingSchedulerID)
        self._loadingSchedulerID = nil
    end
end

function _M:tryUnscheduleLoading()
    if self._isPacketReceived == true then 
        self:unscheduleLoading()
        self:updateSelectedRegion()
    end
end

function _M:updateLoading(dt)
    self._loadingTick = self._loadingTick + 1
    if self._loadingTick == 4 then
        self._loadingTick = 0
    end
    
    local str = Str(STR.REGION_LOADING)
    if self._loadingTick > 0 then
        for i = 1, self._loadingTick do
            str = str.."."
        end
    end 
    self._loadingText:setString(str)
end

function _M:updateSelectedRegion()
    self._loadingText:setVisible(false)

    self._btnChange:setTouchEnabled(true)
    --self._changeLabel:setVisible(true)
    self._btnStart:setEnabled(true)

    local region = ClientData._regions[ClientData._userRegion._id]
    self._regionText:setVisible(true)
    self._regionText:setString(ClientData.genFullRegionName(region._id, region._name))
end

function _M:switchScene()
    ClientData.saveUserRegion()
    ClientData.loadUserRegion()

    lc.replaceScene(require("LoadingScene").create())
end

return _M