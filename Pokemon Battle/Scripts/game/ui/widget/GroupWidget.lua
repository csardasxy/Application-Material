local _M = class("GroupWidget", lc.ExtendCCNode)
_M.Flag = {
    NAME      = 0x00000001,
    REGION  = 0x00000002,
    UNION       = 0x00000004,
    CLICKABLE   = 0x00010000,
}

function _M.create(group, flag, avatarScale)
    local widget = _M.new(lc.EXTEND_NODE)
    widget:setAnchorPoint(0.5, 0.5)
    widget:init(group, flag, avatarScale)
    return widget
end



function _M:init(group, flag, avatarScale)
    self._group = group
    self._flag = flag or 0
    avatarScale = avatarScale or 0.6

    self._avatar = V.createGroupAvatar()
    self._avatar:setScale(avatarScale)

    local groupNameBg = lc.createSprite("group_name_bg")
--    lc.addChildToPos(self, groupNameBg, cc.p(lc.x(self._avatar), lc.bottom(self._avatar) - 20))

    self:setContentSize(cc.size(lc.w(self._avatar) * avatarScale + lc.w(groupNameBg), lc.h(self._avatar) * avatarScale))

    lc.addChildToPos(self, self._avatar, cc.p(lc.cw(self._avatar), lc.ch(self)), 1)
    lc.addChildToPos(self, groupNameBg, cc.p(lc.right(self._avatar) + lc.cw(groupNameBg) - 20, lc.h(self) - lc.ch(groupNameBg) - 30 * avatarScale))

    local nameLabel = V.createTTF("", V.FontSize.S3)
    lc.addChildToCenter(groupNameBg, nameLabel)
    self._nameLabel = nameLabel

    groupNameBg:setVisible(band(self._flag, _M.Flag.NAME) ~= 0)

    local regionLabel = V.createTTF("", V.FontSize.S3)
    regionLabel:setAnchorPoint(0, 0.5)
--    regionLabel:setScale(0.8)
    lc.addChildToPos(self, regionLabel, cc.p(lc.right(self._avatar), 40 * avatarScale))
    regionLabel:setVisible(band(self._flag, _M.Flag.REGION) ~= 0)
    self._regionLabel = regionLabel

    if group then
        self:setGroup(group)
    end
end

function _M:setAvatar(avatar)
    if self._avatar then
		self._avatar.update(avatar)
    end
end

function _M:setGroup(group)
    self._group = group
    self:setAvatar(group._avatar)
    self:setName(group._name)
    self:setRegion(group._members[1]._regionId)
end

function _M:setName(name)
    if self._nameLabel then
		self._nameLabel:setString(name)
    end
end

function _M:setRegion(region)
    if self._regionLabel then
        self._regionLabel:setString(ClientData.genChannelRegionName(region))
    end
end

return _M