local _M = class("SelectAvatarArea", lc.ExtendCCNode)

local AVATAR_COUNT_IN_ROW = 6

local AREA_WIDTH_MAX = 800

function _M.create(w, h)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(math.min(w, AREA_WIDTH_MAX), h)
    area:init()

    return area
end

function _M:init()
    local areaW, areaH = lc.w(self), lc.h(self)
    
    local list = lc.List.createV(cc.size(lc.w(self), lc.h(self)), 20, 20)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self, list)
    self._list = list
    
    -- Sort acquired card and remove repeated avatar
    local avatarBaseId = P:getCharacterId() * 100
    local avatarIds = {}
    for i = 1, 100 do
        local avatarId = avatarBaseId + i
        if lc.FrameCache:getSpriteFrame(string.format('avatar_%04d', avatarId)) == nil then break end
        table.insert(avatarIds, avatarId)
    end
    self._avatarIds = avatarIds

    self:updateList()
end

function _M:updateList()
     local listData, rowData = {}
    
    -- tip
    table.insert(listData, Str(STR.AVATAR_CARD_TIP))

    -- avatars
    for i = 1, #self._avatarIds do
        if rowData == nil or #rowData == AVATAR_COUNT_IN_ROW then
            rowData = {}
            table.insert(listData, rowData)
        end

        table.insert(rowData, self._avatarIds[i])
    end

    local list = self._list
    list:bindData(listData, function(item, data) self:setOrCreateItem(item, data) end, math.min(8, #listData), 1)

    for i = 1, list._cacheCount do
        local data = listData[i]
        local item = self:setOrCreateItem(nil, data)
        list:pushBackCustomItem(item)
    end

    list:jumpToTop()
end

function _M:setOrCreateItem(item, data)
    if item == nil then
        item = ccui.Widget:create()
    end

    item:removeAllChildren()

    if type(data) == "string" then
        local itemH = 66
        item:setContentSize(lc.w(self._list), itemH)
        V.addDecoratedLabel(item, data, cc.p(lc.w(item) / 2, itemH / 2), 26)

    else
        local iconD, iconGap = 104, 20
        local width = (iconD + iconGap) * AVATAR_COUNT_IN_ROW - iconGap

        item:setContentSize(width, 100)

        local pos = cc.p(iconD / 2, lc.h(item) / 2)
        for _, infoId in ipairs(data) do
            local avatarFrame = V.createShaderButton('avatar_frame_001', function() 
                if ClientData._player:changeIcon(infoId) then
                    ClientData.sendSetAvatar(infoId)
                    self:getParent():getParent():getParent():getParent():hide()
                end
            end)
            lc.addChildToPos(item, avatarFrame, pos)

            local avatarBg = lc.createSprite("img_card_ico_bg")
            lc.addChildToCenter(avatarFrame, avatarBg, -1)

            local avatar = lc.createSprite(string.format("avatar_%04d", infoId))
            lc.addChildToCenter(avatarFrame, avatar, -1)

            pos.x = pos.x + lc.w(avatarFrame) + iconGap
        end
    end

    return item
end

return _M