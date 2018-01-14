local _M = class("CardFactoryPanel", require("BasePanel"))

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, true)
    
    self._panelName = "CardFactoryPanel"

    self._params = {}

    for i = 1, 4 do
        self:addButton(i)
    end

    local light = lc.createSprite('img_factory_light')
    light:setScale(8)
    lc.addChildToCenter(self, light)
end

function _M:addButton(index)
    local btnNames = {'monster', 'magic', 'trap', 'merge'}
    local btnStrs = {STR.MONSTER, STR.MAGIC, STR.TRAP, STR.RARE}

    local isLeft = index % 2 == 1
    local isTop = index <= 2

    local btn = V.createScale9ShaderButton('img_blank', function(sender) 
        if index == 1 then lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_monster))
        elseif index == 2 then lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_magic))
        elseif index == 3 then lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_trap))
        elseif index == 4 then lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_rare))
        end
    end, cc.rect(0, 0, 2, 2), 369, 297)
    local offsetx = lc.w(btn) / 2
    local offsety = lc.h(btn) / 2
    lc.addChildToPos(self, btn, cc.p(lc.w(self) / 2 + (isLeft and -offsetx or offsetx), lc.h(self) / 2 + (isTop and offsety or -offsety)))

    local image = lc.createSprite('img_factory_'..btnNames[index])
    lc.addChildToCenter(btn, image)

    local frame = lc.createSprite('img_factory_unfocus')
    frame:setFlippedX(isLeft)
    frame:setFlippedY(not isTop)
    lc.addChildToCenter(btn, frame)

    local labelBg = lc.createSprite('img_factory_label_bg')
    lc.addChildToPos(btn, labelBg, cc.p(lc.w(btn) / 2 + (isLeft and -76 or 76), 50))
    labelBg:setFlippedX(isLeft)
    labelBg:setFlippedY(not isTop)

    local label = V.createBMFont(V.BMFont.huali_26, lc.str(btnStrs[index]))
    lc.addChildToCenter(labelBg, label)
    --label:setFlippedX(isLeft)
    --label:setFlippedY(not isTop)
end


return _M