local _M = ClientView


function _M.createBattleSkillItem(player, skill, pos)
    -- dialog frame
    local size = cc.size(350, 180)

    local dialog = ccui.Layout:create()
    dialog:setContentSize(size)
    dialog:setAnchorPoint(0.5, 0.5)
    dialog:setPosition(pos)
    dialog:setCascadeOpacityEnabled(true)
    dialog:setTouchEnabled(true)
    
    local bg = lc.createSprite({_name = "card_dialog_1", _crect = cc.rect(14, 0, 1, 180), _size = size})
    dialog._bg = bg
    lc.addChildToCenter(dialog, bg)
    
    
    local center = cc.p(dialog:getContentSize().width / 2, dialog:getContentSize().height / 2)
    
    -- skill type
    local skillType = Data.getSkillType(skill._id)
    local typeSpr = cc.Sprite:createWithSpriteFrameName("img_icon_skill_"..skillType)
    typeSpr:setPosition(center.x - 128, center.y + 46)
    dialog:addChild(typeSpr)
    
    -- skill title
    local skillVal = Data._skillInfo[skill._id]._val[math.min(skill._level, #Data._skillInfo[skill._id]._val)]
    local color3b = cc.c3b(255, 0, 0)
    
    local str = Str(Data._skillInfo[skill._id]._nameSid)
    --[[
    if skill._level > 0 and skillVal ~= nil and skillVal ~= 0 then 
        str = str.." "..skill._level 
        if skill._levelUp ~= nil and skill._levelUp > 0 then str = str.."(+"..skill._levelUp..")" end
    end
    ]]
    local label = cc.Label:createWithTTF(str, V.TTF_FONT, 26)
    label:setColor(color3b)
    label:setAnchorPoint(0, 0)
    label:setPosition(center.x - 94, center.y + 36)
    dialog:addChild(label)
    
    -- skill text
    local color3b = skill._isLocked and cc.c3b(80, 49, 49) or V.COLOR_TEXT_DARK
    local str = Str(Data._skillInfo[skill._id]._descSid)
    if skill._level > 0 then
        local pos1, pos2, curVal = string.find(str, "%[(.-)%]")
        if pos1 ~= nil and pos2 ~= nil and curVal ~= nil then 
            str = string.gsub(str, "%["..curVal.."%]", skillVal)
        end
    end
    
    local label = cc.Label:createWithTTF(str, V.TTF_FONT, 26, cc.size(312, 0), cc.TEXT_ALIGNMENT_LEFT)
    label:setAnchorPoint(0, 1)
    label:setScale(0.8)
    label:setColor(color3b)
    label:setPosition(18, lc.bottom(typeSpr) - 2)
    dialog:addChild(label)

    return dialog
end


function _M.createUnionMemberItem(mem, w, isOperateMember)
    local item = ccui.Widget:create()
    item:setContentSize(w, 120)

    item:setTouchEnabled(true)
    item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    item:addTouchEventListener(function(sender, evt)
        if evt == ccui.TouchEventType.ended then
            if item._member._id ~= P._id then
                if isOperateMember then
                    _M.operateMember(item._member, item)
                else
                    _M.operateUser(item._member, item)
                end
            end
        end
    end)

    local bg = lc.createSprite{_name = "img_troop_bg_6", _crect = V.CRECT_TROOP_BG, _size = cc.size(w - 6, 120)}
    lc.addChildToPos(item, bg, cc.p(lc.cw(item) + 3, lc.ch(item)), -1)
    item._bg = bg

    local userArea = UserWidget.create(mem, UserWidget.Flag.LEVEL_NAME)
    userArea:setScale(1.1)
    lc.addChildToPos(item, userArea, cc.p(lc.w(userArea) / 2 + 20, lc.h(item) / 2))
    item._userArea = userArea

    --lc.offset(userArea._nameArea, 0, 20)
    
    local lastLogin = _M.createKeyValueLabel(Str(STR.LAST_LOGIN_TIME), "", 20, false)
    lastLogin:addToParent(userArea, cc.p(lc.cw(lastLogin) + 134, lc.y(userArea) - 30))
    item._lastLogin = lastLogin

    local starArea = V.createIconLabelArea('img_icon_res6_s', mem._trophy, 140)
    lc.addChildToPos(item, starArea, cc.p(lc.w(item) - 24 - lc.w(starArea) / 2, lc.ch(item)))
    item._starArea = starArea

    local job = lc.createSprite('img_union_leader')
    job:setAnchorPoint(0, 0.5)
    lc.addChildToPos(userArea, job, cc.p(lc.right(userArea._nameArea) + 2, lc.y(userArea._nameArea)))
    item._job = job

    item.update = function(self, mem)
        item._member = mem
        --item._bg:setColor(mem._id == P._id and _M.COLOR_TEXT_GREEN or lc.Color3B.white)

        item._userArea:setUser(mem)

        if mem._unionJob == Data.UnionJob.leader or mem._unionJob == Data.UnionJob.elder then
            item._job:setVisible(true)
            item._job:setSpriteFrame(mem._unionJob == Data.UnionJob.leader and 'img_union_leader' or 'img_union_elder') 
        else
            item._job:setVisible(false)
        end
        
        item._lastLogin._value:setString(ClientData.getTimeAgo(mem._lastLogin, 7))
        item._starArea._label:setString(mem._trophy)
    end

    return item
end

function _M.createUnionGroupMemItem(groupId, mem, showBtn, showDetail)
    if showBtn == nil then showBtn = true end
    if showDetail == nil then showDetail = true end

    local item = ccui.Widget:create()
    item:setContentSize(100, showDetail and 160 or 120)

    item:setTouchEnabled(true)
    item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    item:addTouchEventListener(function(sender, evt)
        if evt == ccui.TouchEventType.ended then
            if item._member and (item._member._id ~= P._id) then
                _M.operateGroupMember(item)
            end
        end
    end)

    local bg = lc.createSprite("group_mem_bg")
    lc.addChildToPos(item, bg, cc.p(lc.cw(item), lc.h(item) - lc.ch(bg)))

    local user = UserWidget.create(mem, 0.5)
    lc.addChildToCenter(bg, user)

    local addBtn = V.createShaderButton(nil, function(sender)
        if item._addFunc then
            item:_addFunc(item)
        end
    end)
    local addSpr = lc.createSprite("img_icon_add_big")
    addSpr:setScale(0.4)
    addBtn:setContentSize(bg:getContentSize())
    lc.addChildToCenter(addBtn, addSpr)
    lc.addChildToCenter(bg, addBtn)

    local nameLabel = V.createTTF("", V.FontSize.S3)
    lc.addChildToPos(item, nameLabel, cc.p(lc.cw(item), lc.bottom(bg) - 20))
    item._nameLabel = nameLabel

    local valueArea = V.createIconLabelArea("img_icon_res15_s", "", 150)
    valueArea:setScale(0.6)
    valueArea:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(item, valueArea, cc.p(lc.cw(item), lc.bottom(bg) - 50))

    item.update = function(self, groupId, member, showBtn, showDetail)
        self._member = member
        self._groupId = groupId
        nameLabel:setVisible(true)
        if member then
            user:setVisible(true)
            user:setUser(member)
            addBtn:setVisible(false)
            nameLabel:setString(member._name)
            valueArea._label:setString(member._massWarScore or "0")
            valueArea:setVisible(showDetail == true)
        else
            nameLabel:setString(Str(STR.CAN_S)..Str(STR.JOIN))
            if not showBtn then
                nameLabel:setVisible(false)
            end
            user:setVisible(false)
            addBtn:setVisible(true)
            valueArea:setVisible(false)
        end

        if not showBtn then
            addBtn:setVisible(false)
        end
    end

    item:update(groupId, mem, showBtn, showDetail)

    return item
end