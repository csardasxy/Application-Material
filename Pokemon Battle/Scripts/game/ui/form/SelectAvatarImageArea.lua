local _M = class("SelectAvatarImageArea", lc.ExtendCCNode)


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
    
    local list = lc.List.createH(cc.size(lc.w(self), lc.h(self)), 0, -50)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self, list)
    self._list = list

    local avatarBaseId = P:getCharacterId() * 100
    local images = {}
    for i = 1, 2 do
        local avatarId = avatarBaseId + i
        table.insert(images, avatarId)
    end
    self._images = images
    
    self:updateList()
end

function _M:updateList()
    local list, images = self._list, self._images
    list:removeAllItems()
    for _, data in ipairs(images) do
        local item = self:setOrCreateItem(nil, data)
        list:pushBackCustomItem(item)
    end

    list:jumpToTop()
end

function _M:setOrCreateItem(item, data)
    

    if item == nil then
        item = ccui.Widget:create()
        local imgFrame = lc.createSprite("res/jpg/CharacterImageFrame.png")
        item:setContentSize(lc.w(imgFrame), lc.h(imgFrame))
        lc.addChildToCenter(item, imgFrame)

        local bgPanel3 = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(imgFrame) + 4, lc.h(imgFrame) + 4)})
        lc.addChildToCenter(imgFrame, bgPanel3, -2)
        
        local image = lc.createSprite(string.format("res/jpg/avatar_image_%04d.jpg", data))
        lc.addChildToCenter(imgFrame, image, -1)
        --image:setPressedShader(nil)
        --image:setZoomScale(0)
        item:setScale(0.76)

        --local name = V.createTTFStroke("0", V.FontSize.S1, V.COLOR_TEXT_LIGHT)
        --name:setAnchorPoint(0, 0.5)

        local btnSelect = V.createScale9ShaderButton("img_btn_1_s", nil, V.CRECT_BUTTON_1_S, 150)
        btnSelect:addLabel(Str(STR.SELECT))

       
--        lc.addChildToPos(item, name, cc.p(lc.cw(item), lc.h(item) - 20 - lc.ch(name)))
        lc.addChildToPos(item, btnSelect, cc.p(lc.cw(item), lc.ch(btnSelect) + 20))

        item._image = image
        --item._name = name
        item._btnSelect = btnSelect
    end

    item._image:removeAllChildren()
    --item._image:loadTextureNormal(ClientData.getAvatarFrameName(data._id), ccui.TextureResType.plistType)
    item._image._callback = function()
        --require("DescForm").create({_infoId = data._id}):show()
    end

    --local baseId, id = P._propBag:validPropId(data._id, true)

    item._btnSelect._callback = function()
    
        if P:changeAvatarImage(data) then
            ClientData.sendSetAvatarImage(data)
        end
        self:getParent():getParent():getParent():getParent():hide()
    end

    return item
end

return _M