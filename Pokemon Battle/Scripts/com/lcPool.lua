lc = lc or {}

local Pool = lc.Pool or {}

function Pool.new(name, size)
    Pool.extend(name, size)
end

function Pool.clear(name)
    if Pool[name] == nil then return end

    local pool = Pool[name]
    for _, obj in ipairs(pool) do
        if obj.poolClear then
            obj:poolClear()
        end
    end

    Pool[name] = nil
end

function Pool.extend(name, size)
    local pool = Pool[name]
    if pool then
        size = size or pool.extSize
    else
        pool = {}
        Pool[name] = pool
        pool.extSize = size
    end

    local curSize = #pool
    local cls = _G[name]
    for i = 1, size do
        local obj = cls.poolCreate()
        --obj._poolIndex = #pool
        table.insert(pool, obj)
    end

    pool.size = curSize + size
    lc.log("Pool size of '%s' is extend to %d", name, pool.size)
end

function Pool.get(name, ...)
    local pool = Pool[name]
    if pool == nil then return nil end

    local obj
    for _, o in ipairs(pool) do
        if not o._isUsingInPool then
            obj = o
            break
        end
    end

    if obj == nil then
        Pool.extend(name)
        obj = pool[#pool]
    end

    if obj.poolGet then
        obj:poolGet(...)
    end

    --lc.log("Pool get obj index = %d", obj._poolIndex)

    obj._isUsingInPool = true
    return obj
end

function Pool.free(obj, ...)
    if not obj._isUsingInPool then return end

    if obj.poolFree then
        obj:poolFree(...)
    end

    obj._isUsingInPool = nil
    --lc.log("Pool free obj index = %d", obj._poolIndex)
end

lc.Pool = Pool
return Pool