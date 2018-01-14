local _M = class("UserWidget", lc.ExtendCCNode)

_M.FRAME_SIZE = 114
_M.NAME_WIDTH   = 164
_M.TROPHY_WIDTH = 140
_M.AVATAR_GAP   = -10

_M.Flag = {
    TROPHY      = 0x00000001,
    LEVEL_NAME  = 0x00000002,
    UNION       = 0x00000004,
    REGION      = 0x00000008,
    VIP         = 0x00000010,

    CLICKABLE   = 0x00010000,
}

_M.Flag.NAME_UNION = bor(_M.Flag.LEVEL_NAME, _M.Flag.UNION)
_M.Flag.NAME_UNION_VIP = bor(_M.Flag.LEVEL_NAME, _M.Flag.UNION, _M.Flag.VIP)
_M.Flag.REGION_NAME_UNION = bor(_M.Flag.LEVEL_NAME, _M.Flag.UNION, _M.Flag.REGION)
_M.Flag.ALL = bor(_M.Flag.LEVEL_NAME, _M.Flag.TROPHY, _M.Flag.UNION, _M.Flag.REGION)

local TAG_FRAME_EXTRA = 1000

function _M.create(user, flag, avatarScale, isFlipX)
    local widget = _M.new(lc.EXTEND_NODE)
    widget:setAnchorPoint(0.5, 0.5)
    widget:init(user, flag, avatarScale, isFlipX)
    return widget
end

function _M:init(user, flag, avatarScale, isFlipX)
    self._user = user
    self._flag = flag or 0
	self._isFlipX = isFlipX or false

    -- Avater frame
    local frameName, frame = "avatar_frame_001"
    if band(self._flag, _M.Flag.CLICKABLE) ~= 0 then
        frame = V.createShaderButton(frameName, function() require("LordForm").create():show() end)
    else
        frame = lc.createSprite(frameName)
    end

    if avatarScale then frame:setScale(avatarScale) end
    self._frameSize = lc.makeEven(_M.FRAME_SIZE * frame:getScale())
    self._frame = frame

    local selfW, selfH = self._frameSize, self._frameSize    
    self:setContentSize(selfW, selfH)

    lc.addChildToPos(self, frame, cc.p(selfW / 2, selfH / 2))
        
    -- Avatar image
    local avatarBg = lc.createSprite("img_card_ico_bg")
    lc.addChildToCenter(frame, avatarBg, -1)

    local avatar = lc.createSprite("card_icon_unknow")
    lc.addChildToCenter(frame, avatar, -1)
    self._avatar = avatar
    
    -- Add other components
	if band(self._flag, _M.Flag.LEVEL_NAME) ~= 0 then
		selfW = selfW + _M.AVATAR_GAP + _M.NAME_WIDTH
        self:setContentSize(selfW, selfH)

        local area = V.createLevelNameArea(0, '', self._isFlipX)
        self:addChild(area, -1)
        --area._level:setVisible(false)
        self._nameArea = area

        if band(self._flag, _M.Flag.REGION) ~= 0 then
            local region = V.createTTF("0", V.FontSize.S3)
            region:setAnchorPoint(0, 0)
            self:addChild(region)
            self._regionArea = region
        end
    end

    if band(self._flag, _M.Flag.UNION) ~= 0 then
        if selfW == 0 then
            selfW = selfW + _M.AVATAR_GAP + _M.NAME_WIDTH
            self:setContentSize(selfW, selfH)
        end

        local area = V.createUnionInfoArea(user, self._isFlipX)
        self:addChild(area)
        self._unionArea = area
    end

	if user then 
		self:setUser(user, true)
	end 
end

function _M:setUser(user, updatePos)
    self._user = user

    -- Set avatar and frame
    self:setAvatar(user)
        
    -- Set other components
    self:setLevel(user._level)
    self:setRegion(user._regionId)
    self:setName(user._name)
    if band(self._flag, _M.Flag.VIP) ~= 0 then
        self:setVip(user._vip)
    end

    if user._unionId and user._unionId > 0 then
        if self._unionArea then
            self._unionArea:setVisible(true)
            self:setUnion(user._unionBadge, user._unionWord, user._unionName)
        end
    else
        if self._unionArea then
            self._unionArea:setVisible(false)
        end
    end

    -- Place components according to the user information
    if updatePos then
        if self._nameArea then
			local topY = self._frameSize - math.floor(lc.h(self._nameArea) / 2) - 10
            if not self._isFlipX then
				self._frame:setPosition(self._frameSize / 2, self._frameSize / 2)
				local left = self._frameSize + _M.AVATAR_GAP
                self._nameArea:setPosition(left, topY)
                
				if self._unionArea and self._unionArea:isVisible() then
					self._unionArea:setPosition(left + lc.w(self._unionArea) / 2 + 72, topY - 54)
				end

                if self._regionArea and self._regionArea:isVisible() then
                    self._regionArea:setPosition(lc.left(self._nameArea), lc.top(self._nameArea))
                end
			else
				self._frame:setPosition(lc.w(self) - self._frameSize / 2, self._frameSize / 2)
				local right = lc.left(self._frame) - _M.AVATAR_GAP
				self._nameArea:setPosition(right, topY)

				if self._unionArea and self._unionArea:isVisible() then
					self._unionArea:setPosition(right - lc.w(self._unionArea) / 2 - 72, topY - 54)
				end

                if self._regionArea and self._regionArea:isVisible() then
                    self._regionArea:setPosition(right - lc.w(self._regionArea), lc.top(self._nameArea))
                end
			end
        end
    end
end

function _M:setAvatar(user)
    local frame = self._frame
    frame:removeChildrenByTag(TAG_FRAME_EXTRA)

    -- In region scene, history user has no valid user id
    local isSelf = (user._id and user._id == P._id)

    local frameId = P._propBag:validPropId(user._avatarFrameId, isSelf)
    local frameName = ClientData.getAvatarFrameName(frameId or Data.PropsId.avatar_frame, user._vip)
    if frame.loadTextureNormal then
        frame:loadTextureNormal(frameName, ccui.TextureResType.plistType)
    else
        frame:setSpriteFrame(frameName)
    end

    --[[
    if user._id then
        local _, extra = V.getPropExtra(user._avatarFrameId, frame, user._id == P._id)
        if extra then
            frame:addChild(extra, 0, TAG_FRAME_EXTRA)
        end
    end
    ]]

    if frameId ~= nil and frameId >= 7513 and frameId <= 7515 then
        local frameCount = user._avatarFrameCount or P._propBag._props[frameId]._num or 0
        if frameCount > 0 and frameCount <= 9 then
            local starCount = frameCount % 3
            if starCount == 0 then starCount = 3 end
            local frames = {'avatar_star', 'avatar_moon', 'avatar_sun'}
            local starFrame = frames[math.floor((frameCount - 1) / 3) + 1]
            for i = 1, starCount do
                local star = lc.createSprite(starFrame)
                lc.addChildToPos(frame, star, cc.p(lc.cw(frame) + 6, 16), 0, TAG_FRAME_EXTRA)
                if i == 1 and starCount == 2 then lc.offset(star, 8)
                elseif i == 2 then lc.offset(star, starCount == 2 and -8 or -15)
                elseif i == 3 then lc.offset(star, 15)
                end
            end
        elseif frameCount > 9 then
            local starFrame = 'avatar_crown'
            local star = lc.createSprite(starFrame)
            lc.addChildToPos(frame, star, cc.p(lc.cw(frame) + 6, 20), 0, TAG_FRAME_EXTRA)
        end
    end

    local avatar, avatarName = user._avatar
    if user._id == 0 then
        avatarName = "avatar_00"
    else
        if avatar then
            avatarName = string.format(string.format("avatar_%04d", avatar))
            if lc.FrameCache:getSpriteFrame(avatarName) == nil then avatarName = string.format("avatar_%02d", avatar) end
            if lc.FrameCache:getSpriteFrame(avatarName) == nil then avatarName = "avatar_00" end
        else
            avatarName = "avatar_00"
        end
    end
    if ClientData.isAppStoreReviewing() then avatarName = "avatar_9999" end

    self._avatar:setSpriteFrame(avatarName)
    self._avatar:setPosition(lc.w(frame) / 2, lc.h(frame) / 2)

    if user._crown == nil or self._crown == nil or user._crown._infoId ~= self._crown._infoId or user._crown._num ~= self._crown._num then
        self:setCrown(user._crown and user._crown._infoId or nil, user._crown and user._crown._num or 0)
    end
end

function _M:setVip(vip)
    if vip <= 0 then
        if self._vip then
            self._vip:setVisible(false)
        end

        return
    end

    if self._vip == nil and (not ClientData.isAppStoreReviewing()) then
        local vipBg = lc.createSprite("avatar_vip_bg")
        lc.addChildToCenter(self._frame, vipBg)
        self._vip = vipBg

        local vipStr = V.createTTF("", V.FontSize.S2)
        lc.addChildToPos(vipBg, vipStr, cc.p(92, 20))
        vipBg._value = vipStr
    end

    if self._vip then
        self._vip:setVisible(true)
        self._vip._value:setString((vip > 0) and string.format("V%d", vip) or "")
    end
end

function _M:setLevel(level)
    if self._nameArea then
        self._nameArea._level:setString(string.format("Lv.%d", level))
    end
end

function _M:setRegion(regionId)    
    if self._regionArea then
        if regionId and regionId > 0 then
            self._regionArea:setVisible(true)
            self._regionArea:setString(ClientData.genChannelRegionName(regionId))
        else
            self._regionArea:setVisible(false)
        end
    end
end

function _M:setName(name)
    if self._nameArea then
		self._nameArea:setName(name)
    end
end

function _M:setUnion(badge, word, name)
    if self._unionArea then
        if badge and badge > 0 then self._unionArea._badge:setSpriteFrame(string.format("avatar_badge_s_%d", badge)) end
        if word then self._unionArea._word:setString(word) end
        if name then self._unionArea:setName(name) end
    end
end

function _M:setCrown(infoId, num)
    if self._crown then self._crown:removeFromParent() end
    self._crown = nil

    if infoId == nil then return end

    local names = {'jin', 'yin', 'tong', 'jin', 'yin', 'tong'}
    local name = names[infoId - 7200]
        
    if infoId == 7204 and num > 9 then
        name = 'zs'
    end

    local crown = V.createSpine(infoId - 7200 > 3 and 'jiangbei' or 'huanguan')
    crown:runAction(
        lc.sequence(
            function()
                crown:setAnimation(0, name, true)
            end
        )
    )
    lc.addChildToPos(self._frame, crown, cc.p(0, 0))
    crown._infoId = infoId
    crown._num = num

    if infoId == 7204 and num > 9 then
        if num > 10 then
            local label = cc.Label:createWithBMFont(V.BMFont.num_24, num - 10)
            lc.addChildToPos(crown, label, cc.p(lc.cw(crown) + 1, lc.ch(crown)))
            lc.offset(label, 16, 13)
            crown._label = label
        end
    else
        local label = cc.Label:createWithBMFont(V.BMFont.num_24, num)
        lc.addChildToPos(crown, label, cc.p(lc.cw(crown) - 1, lc.ch(crown)))
        lc.offset(label, 16, 13)
        crown._label = label
    end
    self._crown = crown
end

UserWidget = _M
return _M