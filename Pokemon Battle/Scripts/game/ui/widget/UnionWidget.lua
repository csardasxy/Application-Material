local _M = class("UnionWidget", lc.ExtendCCNode)

_M.SIZE = cc.size(400, 96)

function _M.create(union, needGlow, isInUnion)
    local widget = _M.new(lc.EXTEND_NODE)
    widget:setAnchorPoint(0.5, 0.5)
    widget:setContentSize(_M.SIZE)
    if isInUnion then
        widget:init2(union, needGlow)
    else
        widget:init(union, needGlow)
    end
    return widget
end

function _M:init(union, needGlow)
    local badge = V.createBadge(1, "")
    badge:setScale(0.8)
    lc.addChildToPos(self, badge, cc.p(math.floor(lc.sw(badge) / 2), lc.h(self) / 2))
    self._badge = badge

    if needGlow then
        local glow = lc.createSprite("img_glow")
        glow:setScale(0.5)
        lc.addChildToPos(self, glow, cc.p(badge:getPosition()), -1)
    end
    
    local nameBg = lc.createSprite({_name = "img_com_bg_58", _crect = cc.rect(57, 14, 2, 2), _size = cc.size(208, 40)})
    local w, h = lc.w(nameBg), lc.h(nameBg)
    local nameArea = lc.createNode(cc.size(w, h), nil, cc.p(0, 0.5))
    lc.addChildToCenter(nameArea, nameBg)
    nameArea._bg = nameBg
    local name = V.createTTFStroke("",V.FontSize.M2)
    name:setAnchorPoint(0, 0.5)
    lc.addChildToPos(nameArea, name, cc.p(16,lc.ch(nameArea)))
    nameArea._name = name
    nameArea.setName = function(nameArea, name)
        nameArea._name:setString(name)
        nameArea._name:setScale(math.min(172 / lc.w(nameArea._name), 0.8))
    end
    
    --local nameArea = V.createLevelNameArea(1, "")
    lc.addChildToPos(self, nameArea, cc.p(lc.right(badge) + 13, lc.y(badge) + lc.h(nameArea) / 2 + 20), -1)
    self._nameArea = nameArea
    
    local levelArea = V.createTTFStroke("", V.FontSize.M2)
    lc.addChildToPos(badge, levelArea, cc.p(lc.cw(badge), lc.ch(badge) - 61))
    --lc.addChildToPos(nameArea, levelArea, cc.p((w - 84), lc.y(name) - 20))
    nameArea._level = levelArea
    
    --TODO
--    nameArea._level:setVisible(false)

    self._id = V.addIconValue(self, "img_icon_id", 0, lc.left(nameArea) + 15, lc.bottom(nameArea) - 26)
    self._member = V.addIconValue(self, "img_icon_troop", 0, lc.left(nameArea) + 15, lc.bottom(self._id) - 26)

    if union then
        self:setUnion(union)
    end
end

function _M:init2(union, needGlow)
    local isSelfUnion = (union._unionId == P._unionId)
    local badge = V.createBadge(1, "")
    lc.addChildToPos(self, badge, cc.p(math.floor(lc.sw(badge) / 2), lc.h(self) / 2))
    self._badge = badge

    if needGlow then
        local glow = lc.createSprite("img_glow")
        glow:setScale(0.5)
        lc.addChildToPos(self, glow, cc.p(badge:getPosition()), -1)
    end
    
    local nameBg = lc.createSprite({_name = "img_com_bg_58", _crect = cc.rect(57, 14, 2, 2), _size = cc.size(208, 40)})
    local w, h = lc.w(nameBg), lc.h(nameBg)
    local nameArea = lc.createNode(cc.size(w, h), nil, cc.p(0, 0.5))
    lc.addChildToCenter(nameArea, nameBg)
    nameArea._bg = nameBg
    local name = V.createTTFStroke("",V.FontSize.M2)
    name:setAnchorPoint(0, 0.5)
    lc.addChildToPos(nameArea, name, cc.p(16,lc.ch(nameArea)))
    nameArea._name = name
    nameArea.setName = function(nameArea, name)
        nameArea._name:setString(name)
        nameArea._name:setScale(math.min(172 / lc.w(nameArea._name), 0.8))
    end
    
    --local nameArea = V.createLevelNameArea(1, "")
    lc.addChildToPos(self, nameArea, cc.p(lc.right(badge) + 13, lc.y(badge) + lc.h(nameArea) / 2 + 40), -1)
    self._nameArea = nameArea
    
    local levelArea = V.createTTFStroke("", V.FontSize.M2)
    lc.addChildToPos(badge, levelArea, cc.p(lc.cw(badge), lc.ch(badge) - 61))
    --lc.addChildToPos(nameArea, levelArea, cc.p((w - 84), lc.y(name) - 20))
    nameArea._level = levelArea
    
    --TODO
--    nameArea._level:setVisible(false)

    self._id = V.addIconValue(self, "img_icon_id", 0, lc.left(nameArea) + 15, lc.bottom(nameArea) - 26)
    self._member = V.addIconValue(self, "img_icon_troop", 0, lc.left(nameArea) + 15, lc.bottom(self._id) - 26)
    
    if isSelfUnion then
        local expBtn = V.createShaderButton(nil, function(sender)
                require("DescForm").create({_infoId = Data.ResType.union_act}):show() end)
        expBtn:setContentSize(cc.size(220, 50))
        lc.addChildToPos(self, expBtn, cc.p(lc.left(nameArea) + 125, lc.bottom(self._member) - 26))

        self._expBar = V.addUnionPersonalPowerBar(expBtn, Data.ResType.union_act, 0 , 50, 220)
    end
    --[[
    if union then
        self:setUnion(union)
    end]]
end

function _M:setUnion(union)
    self._union = union

    self._badge:update(union._badge, union._word)
    self._nameArea._level:setString(union._level)
    self._nameArea:setName(union._name)

    self._id:setString(ClientData.convertId(union._id))
    self._member:setString(string.format("%d/%d", union:getMembersNum(), union._memberCapacity))
end

return _M