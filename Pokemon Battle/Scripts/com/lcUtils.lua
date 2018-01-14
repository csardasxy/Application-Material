lc = lc or {}

--[[--
Global type
--]]--
lc.App = cc.Application:getInstance()
lc.Director = cc.Director:getInstance()
lc.Dispatcher = lc.Director:getEventDispatcher()
lc.Scheduler = lc.Director:getScheduler()
lc.TextureCache = lc.Director:getTextureCache()
lc.FrameCache = cc.SpriteFrameCache:getInstance()
lc.File = cc.FileUtils:getInstance()
lc.UserDefault = cc.UserDefault:getInstance()
lc.AppStartTime = os.time()

--[[--
Enums 
--]]--

lc.Dir = 
{
    none                    = 0,
    left                    = 1,
    right                   = 2,
    top                     = 4,
    bottom                  = 8,
    left_top                = 5,
    left_bottom             = 9,
    right_top               = 6,
    right_bottom            = 10,
    horizontal              = 3,
    vertical                = 12,
    clockwise               = 256,
    counter_clockwise       = 512,
}

--[[--
Constants 
--]]--
lc.FPS                      = lc.Director:getAnimationInterval()
lc.PLATFORM                 = lc.App:getTargetPlatform()

--[[--
Color
--]]--
lc.Color3B = 
{
    white = cc.c3b(255, 255, 255),
    yellow = cc.c3b(255, 255, 0),
    green = cc.c3b(0, 255, 0),
    blue = cc.c3b(0, 0, 255),
    red = cc.c3b(255, 0, 0),
    magenta = cc.c3b(255, 0, 255),
    black = cc.c3b(0, 0, 0),
    orange = cc.c3b(255, 127, 0),
    gray = cc.c3b(166, 166, 166),
    dark_gray = cc.c3b(50, 50, 50),
    purple = cc.c3b(139, 0, 255),
    light_blue = cc.c3b(80, 80, 192),
}

lc.Color4B = 
{
    white = cc.c4b(255, 255, 255, 255),
    yellow = cc.c4b(255, 255, 0, 255),
    green = cc.c4b(0, 255, 0, 255),
    blue = cc.c4b(0, 0, 255, 255),
    red = cc.c4b(255, 0, 0, 255),
    magenta = cc.c4b(255, 0, 255, 255),
    black = cc.c4b(0, 0, 0, 255),
    orange = cc.c4b(255, 127, 0, 255),
    gray = cc.c4b(166, 166, 166, 255),  
}

lc.Color4F = 
{
    white = cc.c4f(1, 1, 1, 1),
    yellow = cc.c4f(1, 1, 0, 1),
    green = cc.c4f(0, 1, 0, 1),
    blue = cc.c4f(0, 0, 1, 1),
    red = cc.c4f(1, 0, 0, 1),
    magenta = cc.c4f(1, 0, 1, 1),
    black = cc.c4f(0, 0, 0, 1),
    orange = cc.c4f(1, 0.5, 0, 1),
    gray = cc.c4f(0.65, 0.65, 0.65, 1),      
}

--[[--
Bit operation easier to use
--]]--

bor = bit.bor
bnot = bit.bnot
band = bit.band
bxor = bit.bxor
blsh = bit.lshift
brsh = bit.rshift

--[[--
Utilities methods 
--]]--
function lc.log(...)
    print(string.format(...))
end

function lc.dumpTable(table, depth, prefix)
    if type(prefix) ~= "string" then
        prefix = ""
    end
    if type(table) ~= "table" then
        print(prefix .. tostring(table))
    else
        print(table)
        if depth ~= 0 then
            local prefix_next = prefix .. "    "
            print(prefix .. "{")
            for k, v in pairs(table) do
                print(prefix_next .. k .. " = ")
                if type(v) ~= "table" or (type(depth) == "number" and depth <= 1) then
                    print(v)
                else
                    if depth == nil then
                        lc.dumpTable(v, nil, prefix_next)
                    else
                        lc.dumpTable(v, depth - 1, prefix_next)
                    end
                end
            end
            print(prefix .. "}")
        end
    end
end

function lc.str(id, isMultiLine)
    local str = lc.App:getLanString(id)
    if isMultiLine then
        return string.gsub(str, "\\n", "\n")
    end

    return str
end

function lc.hex(s)
    s = string.gsub(s, ".", function(c) return string.format("%02X", string.byte(c)) end)
    return s
end

function lc.conv(s, from, to)
    local cd = iconv_open(to, from)
    return cd:iconv(s)
end

function lc.round(x)
    return math.floor(x + 0.5)
end

function lc.createNode(size, pos, anchorPos)
    local node = cc.Node:create()
    if size then node:setContentSize(size) end
    if pos then node:setPosition(pos) end
    node:setAnchorPoint(anchorPos or cc.p(0.5, 0.5))
    return node
end

function lc.createSprite(name, pos, anchorPos)
    local sprite
    if type(name) == "table" then
        local crect = name._crect
        local size = name._size
        name = name._name

        local isFile = string.find(name, "%.")
        sprite = (isFile and ccui.Scale9Sprite:create(crect, name) or ccui.Scale9Sprite:createWithSpriteFrameName(name, crect))
        if size then sprite:setContentSize(size) end
    else
        local isFile = string.find(name, "%.")
        sprite = (isFile and cc.Sprite:create(name) or cc.Sprite:createWithSpriteFrameName(name))
    end

    if pos then sprite:setPosition(pos) end
    if anchorPos then sprite:setAnchorPoint(anchorPos) end
    return sprite
end

function lc.createSpriteWithMask(name, pos, anchorPos)
    lc.TextureCache:addImageWithMask(name)
    return lc.createSprite(name, pos, anchorPos)
end

function lc.createImageView(name, pos, anchorPos)
    local img, crect, size
    if type(name) == "table" then
        crect = name._crect
        size = name._size
        name = name._name
    end

    local isFile = string.find(name, "%.")
    img = ccui.ImageView:create(name, isFile and ccui.TextureResType.localType or ccui.TextureResType.plistType)
    img:setTouchEnabled(true)
    if size then img:setContentSize(size) end

    if crect then
        img:setScale9Enabled(true)
        img:setCapInsets(crect)
        if size then img:setContentSize(size) end
    end

    img.setSpriteFrame = function(img, name)
        local isFile = string.find(name, "%.")
        img:loadTexture(name, isFile and ccui.TextureResType.localType or ccui.TextureResType.plistType)
    end

    return img
end

function lc.createScene(cls, ...)
    local layer = cls.new(lc.EXTEND_LAYER)
    local scene = cc.Scene:create()
    layer._scene = scene

    if layer:init(...) then
        scene:registerScriptHandler(function(evtName)
            if (evtName == "enter")  then
                if (layer.onEnter) then layer:onEnter() end
            elseif (evtName == "exit") then
                if (layer.onExit) then layer:onExit() end
            elseif (evtName == "cleanup") then
                if (layer.onCleanup) then layer:onCleanup() end
            elseif (evtName == "enterTransitionFinish") then
                if (layer.onEnterTransitionFinish) then layer:onEnterTransitionFinish() end
            elseif (evtName == "exitTransitionStart") then
                if (layer.onExitTransitionStart) then layer:onExitTransitionStart() end
            end
        end)    
            
        scene:addChild(layer)
        scene._layer = layer        
        
        return scene
    end
end

function lc.pushScene(scene)
    if scene then
        lc.Director:pushScene(scene)
    end
end

function lc.replaceScene(scene)
    if scene then
        lc.Director:replaceScene(scene)
    end
end

function lc.addEventListener(name, handler, priority)
    local listener = cc.EventListenerCustom:create(name, handler)
    lc.Dispatcher:addEventListenerWithFixedPriority(listener, priority or -1)
    return listener
end

function lc.addGestureEventListener(name, handler, node)
    assert(node, "The node can't be nil when add gesture event listener!")
    local listener = cc.EventListenerCustom:create(name, handler)
    lc.Dispatcher:addEventListenerWithSceneGraphPriority(listener, node)
    return listener
end

function lc.calcDistance(p1, p2)
    return math.sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2)
end

function lc.httpRequest(url, method, callback)
    local http = cc.XMLHttpRequest:new()
    if callback then
        http:registerScriptHandler(callback)
    end

    http:open(method, url)
    http:send()

    return http
end

function lc.readFile(filename, start, len)
    local data
    if lc.PLATFORM == cc.PLATFORM_OS_ANDROID then
        data = lc.File:getDataFromFile(filename, start, len)
    else
        local f = io.open(lc.File:fullPathForFilename(filename), "rb")
        if f == nil then return "" end
        if start ~= nil then f:seek("set", start) end

        if len == nil then
            data = f:read("*all")
        else
            data = f:read(len)
        end
        f:close()    
    end

    --if data ~= nil then lc.log("read file %s (%d + %d)", filename, start or 0, #data) end
    return data
end

function lc.writeFile(filename, str)
    filename = lc.File:fullPathForFilename(filename)
    local f = io.open(filename, "wb")
    if f ~= nil then
        f:write(str)
        f:close()
    end
end

function lc.resetConfigFile(file)
    if lc._configFile == file then return end

    lc._configFile = file
    
    local str = lc.readFile(lc.File:getWritablePath()..lc._configFile)
    if str ~= nil and #str > 0 then 
        lc._configs = json.decode(str)
    else 
        lc._configs = {}
    end 
end

function lc.readConfig(key, defaultValue)
    local v = lc._configs[key]
    if v == nil and defaultValue ~= nil then
        v = defaultValue
        lc.writeConfig(key, v)
    end 
    return v
end

function lc.writeConfig(key, value)
    lc._configs[key] = value
    lc.writeFile(lc.File:getWritablePath()..lc._configFile, json.encode(lc._configs))
end

function lc.getUdid()
    local str = lc.App:getUdid()
    return str
end

function lc.getDeviceInfo()
    if lc.DEVICE_INFO == nil then
        local t = {model = lc.App:getDeviceModel(), memory = lc.App:getSystemMemory(), udid = lc.App:getUdid()}
	    lc.DEVICE_INFO = json.encode(t)
    end
    return lc.DEVICE_INFO
end

function lc.getRunningTime()
    return os.time() - lc.AppStartTime
end

function lc.w(node)
    return node:getContentSize().width
end

function lc.cw(node)
    return node:getContentSize().width / 2
end

function lc.sw(node, isRecurisive)
    local scale = node:getScaleX()
    if isRecurisive then
        local parent = node:getParent()
        while parent do
            scale = scale * parent:getScaleX()
            parent = parent:getParent()
        end
    end

    return node:getContentSize().width * scale
end

function lc.h(node)
    return node:getContentSize().height
end

function lc.ch(node)
    return node:getContentSize().height / 2
end

function lc.sh(node, isRecurisive)
    local scale = node:getScaleY()
    if isRecurisive then
        local parent = node:getParent()
        while parent do
            scale = scale * parent:getScaleY()
            parent = parent:getParent()
        end
    end
    
    return node:getContentSize().height * scale
end

function lc.x(node)
    return node:getPositionX()
end

function lc.ax(node)
    return node:getAnchorPoint().x
end

function lc.y(node)
    return node:getPositionY()
end

function lc.ay(node)
    return node:getAnchorPoint().y
end

function lc.left(node)
    local ax = (node:isIgnoreAnchorPointForPosition() and 0 or lc.ax(node))
    return node:getPositionX() - ax * lc.sw(node)
end

function lc.right(node)
    local ax = (node:isIgnoreAnchorPointForPosition() and 0 or lc.ax(node))
    return node:getPositionX() + (1 - ax) * lc.sw(node)
end

function lc.bottom(node)
    local ay = (node:isIgnoreAnchorPointForPosition() and 0 or lc.ay(node))
    return node:getPositionY() - ay * lc.sh(node)
end

function lc.top(node)
    local ay = (node:isIgnoreAnchorPointForPosition() and 0 or lc.ay(node))
    return node:getPositionY() + (1 - ay) * lc.sh(node)
end

function lc.offset(node, offX, offY)
    local x, y = node:getPosition()
    node:setPosition(x + (offX or 0), y + (offY or 0))
    return node
end

function lc.bound(node)
    return cc.rect(lc.left(node), lc.bottom(node), lc.sw(node), lc.sh(node))
end

function lc.contain(node, globalPos)
    local pos, rect = node:convertToNodeSpace(globalPos)
    if node._touchRect then
        rect = node._touchRect
    else
        rect = cc.rect(0, 0, lc.w(node), lc.h(node))
    end
    return cc.rectContainsPoint(rect, pos)
end

function lc.contain3D(node, globalPos, camera3D)
    local pos = node:convertToNodeSpace3D(globalPos, camera3D)
    return cc.rectContainsPoint(cc.rect(0, 0, lc.w(node), lc.h(node)), pos)
end

function lc.convertPos(pos, node, toNode)
    local globalPos = node:convertToWorldSpace(pos)
    local pos = toNode and toNode:convertToNodeSpace(globalPos) or globalPos
    pos.x = math.floor(pos.x)
    pos.y = math.floor(pos.y)
    return pos
end

function lc.reverseChildrenPos(parent, dir)
    local children = parent:getChildren()
    if dir == lc.Dir.vertical then
        local h = lc.h(parent)
        for _, child in ipairs(children) do
            child:setPositionY(h - lc.y(child))
        end

    else
        local w = lc.w(parent)
        for _, child in ipairs(children) do
            child:setPositionX(w - lc.x(child))
        end
    end
end

function lc.makeEven(num)
    local num = math.floor(num)
    return (num % 2) == 0 and num or num + 1
end

function lc.sendEvent(evt, param)
    local eventCustom = cc.EventCustom:new(evt)
    eventCustom._param = param
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function lc.addChildToCenter(parent, child, zorder, tag)
    local ax = (child:isIgnoreAnchorPointForPosition() and 0 or lc.ax(child))
    local ay = (child:isIgnoreAnchorPointForPosition() and 0 or lc.ay(child))

    local position = cc.p(lc.w(parent) / 2 + (ax - 0.5) * lc.sw(child), lc.h(parent) / 2 + (ay - 0.5) * lc.sh(child))
    return lc.addChildToPos(parent, child, position, zorder, tag)
end

function lc.addChildToPos(parent, child, position, zorder, tag)
    child:setPosition(position)
    parent:addChild(child, zorder or 0, tag or -1)
    return child
end

function lc.addNodesToCenterH(parent, nodes, gaps, y, zorder, tag)
    -- All nodes' anchor point must be (0.5, 0.5)

    local isMultiGap = (type(gaps) == "table")

    local w = 0
    for i = 1, #nodes do
        local node = nodes[i]
        w = w + lc.sw(node)

        if i < #nodes then
            w = w + (isMultiGap and gaps[i] or gaps)
        end
    end

    w = lc.makeEven(w)

    local x = (lc.w(parent) - w) / 2
    y = y or lc.h(parent) / 2
    for i = 1, #nodes do
        local node = nodes[i]
        node:setPosition(math.floor(x + lc.sw(node) / 2), y)
        parent:addChild(node, zorder or 0, tag or -1)

        if i < #nodes then
            x = x + lc.sw(node) + (isMultiGap and gaps[i] or gaps)
        end
    end
end

function lc.addNodesToCenterV(parent, nodes, gaps, x, zorder, tag)
    -- All nodes' anchor point must be (0.5, 0.5)

    local isMultiGap = (type(gaps) == "table")

    local h = 0
    for i = 1, #nodes do
        local node = nodes[i]
        h = h + lc.sh(node)

        if i < #nodes then
            h = h + (isMultiGap and gaps[i] or gaps)
        end
    end

    h = lc.makeEven(h)

    local y = (lc.h(parent) - h) / 2
    x = x or lc.w(parent) / 2
    for i = 1, #nodes do
        local node = nodes[i]
        node:setPosition(x, math.floor(y + lc.sh(node) / 2))
        parent:addChild(node, zorder or 0, tag or -1)

        if i < #nodes then
            y = y + lc.sh(node) + (isMultiGap and gaps[i] or gaps)
        end
    end
end

function lc.removeChildrenByTag(parent, tag)
    local children = parent:getChildren()
    local index = 1

    while (index <= #children) do
        local child = children[index]
        if child:getTag() == tag then
            parent:removeChild(child)
        else
            index = index + 1
        end
    end
end

function lc.changeParent(child, oldParent, newParent, zorder, tag)
    oldParent = oldParent or child:getParent()
    if oldParent then
        child:retain()
        oldParent:removeChild(child, false)
        newParent:addChild(child, zorder or child:getLocalZOrder(), tag or child:getTag())
        child:release()
    else
        newParent:addChild(child, zorder or child:getLocalZOrder(), tag or child:getTag())
    end
end

function lc.frameSize(name)
    local frame = lc.FrameCache:getSpriteFrame(name)
    return frame:getOriginalSize()
end

function lc.createMaskLayer(opacity, color, size)
    local layer = ccui.Layout:create()
    lc.initMaskLayer(layer, opacity, color, size)
    return layer
end

function lc.initMaskLayer(layer, opacity, color, size)
    layer:setContentSize(size or lc.Director:getVisibleSize())
    layer:setTouchEnabled(true)
    layer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    layer:setBackGroundColor(color or lc.Color3B.black)
    layer:setBackGroundColorOpacity(opacity or 200)
end

function lc.splitText(content)
    local strs = {}
    local i = 1
    while i <= string.len(content) do
        local byte = string.byte(content, i)
        if byte < 0x80 then
            table.insert(strs, string.char(byte))
            i = i + 1
        else
            table.insert(strs, string.char(byte, string.byte(content, i + 1), string.byte(content, i + 2)))
            i = i + 3
        end        
    end
    
    return strs
end

function lc.getTableCount(table)
    local index, count = next(table), 0
    while index do
        count = count + 1
        index = next(table, index)
    end
    return count
end

function lc.arrayAt(array, index)
    if index > #array then
        return array[#array]
    elseif index < 0 then
        local index = #array + (index + 1)        
        return index < 1 and array[1] or array[index]
    else
        return array[index]
    end
end

function lc.arrayToTable(array, lineNum, condition)
    local data, line = {}, {}
    for _, v in ipairs(array) do
        if condition == nil or condition(v) then
            if #line < lineNum then
                table.insert(line, v)
            else
                table.insert(data, line)
                line = {v}
            end
        end
    end

    if #line > 0 then
        table.insert(data, line)
    end

    return data
end

function lc.reorderToArray(data, orderFunc)
    local array = {}
    local index, val = next(data)    
    while index do
        table.insert(array, val)
        index, val = next(data, index)
    end

    table.sort(array, orderFunc)
    return array
end

function lc.absTime(time)
    return time * cc.Director:getInstance():getScheduler():getTimeScale()
end

function lc.utf8CharSize(c)
    if not c then
        return 0
    elseif c >= 240 then
        return 4
    elseif c >= 224 then
        return 3
    elseif c >= 192 then
        return 2
    else
        return 1
    end
end

function lc.utf8len(str)
    local len = 0
    local currentIndex = 1
    while currentIndex <= #str do
        local c = string.byte(str, currentIndex)
        currentIndex = currentIndex + lc.utf8CharSize(c)
        len = len + 1
    end
    return len
end

function lc.getUtf8Char(str, index)
    local pos, charPos = 1, 1
    while pos <= #str do
        local c = string.byte(str, pos)
        local size = lc.utf8CharSize(c)
        if charPos == index then
            return string.sub(str, 1, pos + size - 1)    
        end

        pos, charPos = pos + size, charPos + 1
    end
    return ""
end

--[[--
Wrap cocos2dx actions
--]]--

local getVec2 = function(xy)
    if #xy == 1 then
        return xy[1]
    elseif #xy == 2 then
        return {x = xy[1], y = xy[2]}
    end
end

function lc.moveTo(t, ...)
    return cc.MoveTo:create(t, getVec2{...})
end

function lc.moveBy(t, ...)
    return cc.MoveBy:create(t, getVec2{...})
end

function lc.scaleTo(t, ...)
    return cc.ScaleTo:create(t, ...)
end

function lc.scaleBy(t, ...)
    return cc.ScaleBy:create(t, ...)
end

function lc.rotateTo(t, ...)
    local arg = {...}
    if #arg == 3 then
        return cc.RotateTo:create(t, {x = arg[1], y = arg[2], z = arg[3]})
    else
        return cc.RotateTo:create(t, ...)
    end
end

function lc.rotateBy(t, ...)
    local arg = {...}
    if #arg == 3 then
        return cc.RotateBy:create(t, {x = arg[1], y = arg[2], z = arg[3]})
    else
        return cc.RotateBy:create(t, ...)
    end
end

function lc.tintTo(t, ...)
    return cc.TintTo:create(t, ...)
end

function lc.tintBy(t, ...)
    local arg = {...}
    if #arg == 1 then
        return cc.RotateBy:create(t, arg[1].r, arg[1].g, arg[1].b)
    else
        return cc.RotateBy:create(t, ...)
    end
end

function lc.fadeIn(t)
    return cc.FadeIn:create(t)
end

function lc.fadeOut(t)
    return cc.FadeOut:create(t)
end

function lc.fadeTo(t, opacity)
    return cc.FadeTo:create(t, opacity)
end

function lc.delay(t)
	return cc.DelayTime:create(t)
end

function lc.show()
    return cc.Show:create()
end

function lc.hide()
    return cc.Hide:create()
end

function lc.remove(...)
    return cc.RemoveSelf:create(...)
end

function lc.place(...)
    return cc.Place:create(getVec2{...})
end

function lc.call(func)
    return cc.CallFunc:create(func)
end

function lc.ease(action, easeName, param)
    local easeDefs = {
        I = {cc.EaseIn, 2, 1}, O = {cc.EaseOut, 2, 1}, IO = {cc.EaseIn, 2, 1},
        BackI = {cc.EaseBackIn, 1}, BackO = {cc.EaseBackOut, 1}, BackIO = {cc.EaseBackInOut, 1},
        BounceI = {cc.EaseBounceIn, 1}, BounceO = {cc.EaseBounceOut, 1}, BounceIO = {cc.EaseBounceInOut, 1},
        ElasticI = {cc.EaseElasticIn, 2, 0.3}, ElasticO = {cc.EaseElasticOut, 2, 0.3}, ElasticIO = {cc.EaseElasticInOut, 2, 0.3},
        SineI = {cc.EaseSineIn, 1}, SineO = {cc.EaseSineOut, 1}, SineIO = {cc.EaseSineInOut, 1}
    }

    local easing
    if easeDefs[easeName] then
        local cls, count, default = unpack(easeDefs[easeName])
        if count == 2 then
            easing = cls:create(action, param or default)
        else
            easing = cls:create(action)
        end
    end

    return easing
end

function lc.animate(prefix, interval, loops)
    local frames = {}
    local i = 1
    local frame = lc.FrameCache:getSpriteFrame(string.format("%s_%02d", prefix, i))
    while frame do
        table.insert(frames, #frames + 1, frame)
        i = i + 1
        frame = lc.FrameCache:getSpriteFrame(string.format("%s_%02d", prefix, i))
    end
    
    return cc.Animation:createWithSpriteFrames(frames, interval, loops)
end

function lc.sequence(...)
	local arg = {...}
    
    local actions = {}
    for i = 1, #arg do
		local action = arg[i]
		if type(action) == "function" then
			action = lc.call(action)
		elseif type(action) == "number" then
			action = lc.delay(action)
		elseif type(action) == "table" then
			action = lc.spawn(unpack(action))
		end
        table.insert(actions, action)
    end
    return cc.Sequence:create(actions)
end

function lc.spawn(...)
	local arg = {...}
    
    local actions = {}
    for i = 1, #arg do
		local action = arg[i]
		if type(action) == "function" then
			action = lc.call(action)
		elseif type(action) == "number" then
			action = lc.delay(action)
		elseif type(action) == "table" then
			action = lc.sequence(unpack(action))
		end
        table.insert(actions, action)
    end
    return cc.Spawn:create(actions)
end

function lc.rep(action, times)
	if times then
        return cc.Repeat:create(action, times)
	else
		return cc.RepeatForever:create(action)
	end
end

--[[--
Extend more useful usage of existing lua engine 
--]]--

-- Directly get char by pos from string using []
getmetatable("").__index = function(str, i)
  if type(i) == 'number' then
    return string.sub(str, i, i)
  else
    return string[i]
  end
end

-- If sep is a single char, use string.splitByChar which is 8x faster than this function 
string.split = function(str, sep)
    str = str..sep
    return {str:match((str:gsub("[^"..sep.."]*"..sep, "([^"..sep.."]*)"..sep)))}
end

string.trim = function(str)
    local trimed = string.gsub(str, "^%s*(.-)%s*$", "%1")
    return trimed
end