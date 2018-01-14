local _M = class("RewardCardPanel", require("BasePanel"))

local CardThumbnail = require("CardThumbnail")
local CardInfoPanel = require("CardInfoPanel")

local PARTICLE_TAG = 0xff

function _M.create(titleStr, cards, recruitInfo, troopIndex)
    local form = _M.new(lc.EXTEND_LAYOUT_MASK) 
    form:init(titleStr, cards, recruitInfo, troopIndex)

    return form   
end

function _M:init(titleStr, cards, recruitInfo, troopIndex)
    _M.super.init(self, true)
    --[[
    local spine = V.createSpine("lingjiangchenggong")
    lc.addChildToCenter(self, spine)
    self._spine = spine    
    self:runAction(
        lc.sequence(
            function()
                spine:setAnimation(0, "animation", false)
            end, 0.2,
            function()
                spine:setAnimation(0, "animation2", true)
            end
        )
    )
    ]]
    local curStep = GuideManager.getCurStepName()
    if curStep == "evolve card" then
        GuideManager.startStepLater(0.3)
    end

    local thumbnails = {}

    if #cards >= 8 then
        local list = lc.List.createH(cc.size(lc.w(self), 400), 10, 10)
        list:setAnchorPoint(0.5, 0.5)
        lc.addChildToPos(self, list, cc.p(lc.cw(self), lc.ch(self) + 60))
        self._list = list
        
        for i = 1, #cards do
            local item = CardThumbnail.createFromPool(cards[i]._infoId, 0.5)
            item._thumbnail:setTouchEnabled(true)
            item._thumbnail:addTouchEventListener(function(sender, evt) 
                if evt == ccui.TouchEventType.ended then
                    CardInfoPanel.create(item._thumbnail._infoId, nil, CardInfoPanel.OperateType.na):show()
                end
            end)     
            table.insert(thumbnails, item._thumbnail)

            local layout = ccui.Layout:create()
            layout:setContentSize(V.CARD_SIZE)
            lc.addChildToCenter(layout, item)

            list:pushBackCustomItem(layout)
        end

        local btnBack = self:createBackButton(180)
        lc.addChildToPos(self, btnBack, cc.p(lc.w(self) / 2, 50 + lc.h(btnBack) / 2))
        
    else
        local gap, cardWidth = 40, V.CARD_SIZE.width
        local row, col = 1, #cards
        if #cards > 5 then row = 2 col = math.ceil(#cards / 2) end
        local gridWidth = math.min((1024 - col * gap) / #cards, cardWidth)
        local totalWidth = (gridWidth + gap) * col

        local y = lc.h(self) / 2 + 70
        if row == 2 then y = lc.h(self) / 2 + 170 end
        local pos = cc.p((lc.w(self) - totalWidth + gridWidth + gap) / 2, y)

        for _, card in ipairs(cards) do
            local item = CardThumbnail.createFromPool(card._infoId, gridWidth / cardWidth)
            lc.offset(item._countArea, 0, -80)
            --item._countArea:update(false)
            lc.addChildToPos(self, item, pos, 1)
            table.insert(thumbnails, item._thumbnail)

            pos.x = pos.x + gridWidth + gap

            if #thumbnails == col then 
                pos.x = (lc.w(self) - totalWidth + gridWidth + gap) / 2 
                pos.y = pos.y - (V.CARD_SIZE.height * gridWidth / cardWidth) - gap + 20
            end

            item._thumbnail:setTouchEnabled(true)
            item._thumbnail:addTouchEventListener(function(sender, touch) 
                if touch == ccui.TouchEventType.ended then
                    for i = 1,  #lc._runningScene._scene:getChildren() do
                        local child = lc._runningScene._scene:getChildren()[i]
                        if child._panelName == "CardInfoPanel" then return end
                    end

                    if GuideManager.isGuideEnabled() then
                        GuideManager.pauseGuide()
                    end

                    local type = Data.getType(item._thumbnail._infoId)
                    if type == Data.CardType.common_fragment then
                        require("DescForm").create(item._thumbnail._infoId):show()                        
                    else
                        CardInfoPanel.create(item._thumbnail._infoId, nil, CardInfoPanel.OperateType.na):show()
                    end
                end
            end)
        end

--        if lc._runningScene._sceneId == ClientData.SceneId.tavern then
--            self:addRecruitButtons(recruitInfo, true)
--        else
            local btnBack = self:createBackButton(180)
            lc.addChildToPos(self, btnBack, cc.p(lc.w(self) / 2, 20 + lc.h(btnBack) / 2))
--        end
    end

    if titleStr then
        local titleBg = lc.createSprite("img_title_bg")
        titleBg:setScale(600 / lc.w(titleBg), 1)
        lc.addChildToPos(self, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - 50))

        local title = V.createTTF(titleStr, V.FontSize.S1, lc.Color3B.yellow)
        lc.addChildToPos(self, title, cc.p(lc.x(titleBg), lc.y(titleBg)))
    end

    self._thumbnails = thumbnails
    
    lc.Audio.playAudio(AUDIO.E_CARD_GET)    
end

function _M:show(zorder)
    _M.super.show(self, zorder)

    if #self._thumbnails < 8 then
        for _, thumbnail in ipairs(self._thumbnails) do
        
            thumbnail:setScaleFactor(0.5)
            self:showEffect(thumbnail)
        end    
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)
end

function _M:onExit()
    _M.super.onExit(self)
    --self._spine:removeFromParent()
    lc.Dispatcher:removeEventListener(self._listener)
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    for _, thumbnail in ipairs(self._thumbnails) do
        CardThumbnail.releaseToPool(thumbnail._item)
    end
end

function _M:createBackButton(w)
    -- Create back button
    local btnBack = V.createScale9ShaderButton("img_btn_2_s", function(sender)
        self:hide()

        GuideManager.finishStep()
    end, V.CRECT_BUTTON_1_S, w)
    btnBack:addLabel(Str(STR.BACK))
    self._btnBack = btnBack

    return btnBack
end

function _M:showEffect(thumbnail, delay)
    local d = delay
    if d == nil then d = 0 end
    
    local pos = self:convertToNodeSpace(thumbnail:convertToWorldSpace(cc.p(lc.w(thumbnail) / 2, lc.h(thumbnail) / 2)))

    local particle1, particle2, particle3
    local info = Data.getInfo(thumbnail._infoId)
    --if info._quality >= Data.CardQuality.R then
        thumbnail:setVisible(false)
        
        
        particle1 = Particle.create("par_reward1")
        particle2 = Particle.create("par_reward2")
        particle1:setTag(PARTICLE_TAG)
        particle2:setTag(PARTICLE_TAG)
        particle1:setPosition(pos)
        particle2:setPosition(pos)    
        particle1:setScale(thumbnail._scale * 1.3)
        particle2:setScale(thumbnail._scale * 1.3)
        self:addChild(particle1, 2)
        self:addChild(particle2, 2)
        particle1:stopSystem()
        particle2:stopSystem()

        if info._quality == Data.CardQuality.UR then
            particle3 = Particle.create("par_hk")
        elseif info._quality == Data.CardQuality.SR then
            particle3 = Particle.create("par_zk")
        end
        if particle3 then
            particle3:setTag(PARTICLE_TAG)
            particle3:setPosition(pos)
            particle3:setScale(thumbnail._scale * 1.3)
            self:addChild(particle3)
            particle3:stopSystem()
        end
            
        self:runAction(cc.Sequence:create(cc.DelayTime:create(d + 0.1),
        cc.CallFunc:create(
            function()
                if particle1 then
                    particle1:resetSystem() 
                    particle1:runAction(cc.Sequence:create(cc.DelayTime:create(particle1:getDuration()), 
                    cc.CallFunc:create(function() particle2:resetSystem() end), cc.DelayTime:create(particle2:getDuration())))
                end
            end),
        cc.DelayTime:create(0.1), cc.CallFunc:create(function() 
            thumbnail:setVisible(true)
            if particle3 then particle3:resetSystem() end
        end)))
        --[[
    else
        thumbnail:setVisible(true)
    end]]
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "show card info" then
        GuideManager.setOperateLayer(self._thumbnails[1])
    elseif curStep == "leave card reward" then
        GuideManager.setOperateLayer(self._btnBack, nil, {self._list})
    elseif curStep == "show tap card tip" then
        local bg = lc.createImageView{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = cc.size(600, 66)}
        --lc.addChildToPos(self, bg, cc.p(lc.w(self) / 2, lc.bottom(self._thumbnails[1]) - 40 - lc.h(bg) / 2))
        lc.addChildToPos(self, bg, cc.p(lc.w(self) / 2, 180))

        local tip = V.createBoldRichText(Str(STR.TAP_CARD_TIP), V.RICHTEXT_PARAM_LIGHT_S1)
        lc.addChildToPos(bg, tip, cc.p(lc.w(bg) / 2, lc.h(bg) / 2 + 2))

        GuideManager.finishStepLater()
    elseif curStep == "leave claim 1" then
        GuideManager.setOperateLayer(self._btnBack, nil, {self})

    else
        return
    end
    
    event:stopPropagation()    
end

return _M