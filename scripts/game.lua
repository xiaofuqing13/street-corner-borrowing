local Content = require("content")

local Game = {}
local ITEM_IDS = { "umbrella", "cart" }
local TIMES = { "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00" }
local REQUEST_COUNT = 12
local SAVE_VERSION = 2

---@class BorrowDecision
---@field requestId string
---@field lent boolean

---@class BorrowLoan
---@field requestId string
---@field item string
---@field person string
---@field slot number
---@field returnSlot number
---@field returned boolean

---@class BorrowGameState
---@field scenarioId string
---@field round number
---@field cursor number
---@field stock table<string, number>
---@field loans BorrowLoan[]
---@field decisions BorrowDecision[]
---@field stats table<string, number>
---@field history table[]
---@field finished boolean
---@field awaitingAdvance boolean
---@field status string
---@field statusKind string
---@field freeReplans integer
---@field rewardReplans integer

---@class BorrowObjectiveProgress
---@field id string
---@field type string
---@field title string
---@field description string
---@field current number
---@field target integer
---@field complete boolean

---@class BorrowCompletedEntry
---@field id string
---@field text string

---@class BorrowNeighborRecord
---@field personId string
---@field count number
---@field requestIds string[]
---@field entries BorrowCompletedEntry[]

---@class BorrowResult
---@field completed number
---@field declined number
---@field neighbors number
---@field maximum number
---@field stars number
---@field title string
---@field message string
---@field objectives BorrowObjectiveProgress[]
---@field neighborRecords BorrowNeighborRecord[]

local function IsInteger(value, minimum, maximum)
    return type(value) == "number" and value % 1 == 0
        and value >= minimum and value <= maximum
end

local function ArrayLength(value, maximum)
    if type(value) ~= "table" then return nil end
    local count = 0
    for key in pairs(value) do
        if not IsInteger(key, 1, maximum) then return nil end
        count = count + 1
    end
    for index = 1, count do
        if value[index] == nil then return nil end
    end
    return count
end

-- 只与有限、无环的规范状态比较，不遍历存档中多余的嵌套数据。
local function SameValue(actual, expected)
    if type(actual) ~= type(expected) then return false end
    if type(expected) ~= "table" then return actual == expected end
    for key, value in pairs(expected) do
        if not SameValue(actual[key], value) then return false end
    end
    for key in pairs(actual) do
        if expected[key] == nil then return false end
    end
    return true
end

function Game.Time(slot)
    return TIMES[slot] or "--:--"
end

local function CheckScenario(scenario)
    if type(scenario) ~= "table" or type(scenario.id) ~= "string" then
        return false, "找不到这份排班。"
    end
    if ArrayLength(scenario.requests, REQUEST_COUNT) ~= REQUEST_COUNT then
        return false, "排班必须包含十二条请求。"
    end
    if not IsInteger(scenario.maximum, 1, REQUEST_COUNT) then
        return false, "排班缺少有效的最佳周转次数。"
    end
    for _, itemId in ipairs(ITEM_IDS) do
        local item = Content.items[itemId]
        if type(item) ~= "table" or not IsInteger(item.capacity, 1, REQUEST_COUNT) then
            return false, "物品总量配置不正确。"
        end
    end
    local seen = {}
    for index, request in ipairs(scenario.requests) do
        if type(request) ~= "table" or type(request.id) ~= "string"
            or request.id == "" or seen[request.id]
            or request.slot ~= math.ceil(index / 2)
            or not IsInteger(request.returnSlot, request.slot + 1, 7)
            or type(request.person) ~= "string" or request.person == ""
            or (request.item ~= "umbrella" and request.item ~= "cart") then
            return false, "请求编号、顺序或借还时刻不正确。"
        end
        seen[request.id] = true
    end
    return true
end

---@return BorrowGameState?, string?
function Game.New(scenarioId)
    if type(scenarioId) ~= "string" then return nil, "请选择一份排班。" end
    local scenario = Content.GetScenario(scenarioId)
    if not scenario then return nil, "找不到这份排班。" end
    local ok, message = CheckScenario(scenario)
    if not ok then return nil, message end
    return {
        scenarioId = scenario.id,
        round = 1,
        cursor = 1,
        stock = {
            umbrella = Content.items.umbrella.capacity,
            cart = Content.items.cart.capacity,
        },
        loans = {},
        decisions = {},
        stats = { lent = 0, returned = 0, declined = 0, neighbors = 0 },
        history = {},
        finished = false,
        awaitingAdvance = false,
        status = scenario.intro or "到访预告已经贴好，可以开始值班了。",
        statusKind = "info",
        freeReplans = 0,
        rewardReplans = 0,
    }
end

---@param state BorrowGameState
---@return BorrowRequest?
function Game.Current(state)
    if type(state) ~= "table" or state.finished or state.awaitingAdvance then return nil end
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then return nil end
    local request = scenario.requests[state.cursor]
    if request and request.slot == state.round then return request end
    return nil
end

---@param state BorrowGameState
local function ApplyDecision(state, lent, expectedRequestId)
    local request = Game.Current(state)
    if not request then return false, "当前没有待处理的请求，请先查看交接。" end
    if expectedRequestId ~= nil and request.id ~= expectedRequestId then
        return false, "这条请求已经处理，请查看当前邻居。"
    end
    if type(lent) ~= "boolean" then return false, "请选择借出或婉拒。" end
    if lent and state.stock[request.item] < 1 then
        return false, "这件物品还在借用中，现在没有可用库存。"
    end
    local knownNeighbor = false
    for _, loan in ipairs(state.loans) do
        if loan.person == request.person then
            knownNeighbor = true
            if lent and not loan.returned and loan.item == request.item then
                return false, "这位邻居还有同类物品未归还。"
            end
        end
    end
    local message = request.declineText or "已婉拒，物品留给后续安排。"
    if lent then
        state.stock[request.item] = state.stock[request.item] - 1
        state.loans[#state.loans + 1] = {
            requestId = request.id,
            item = request.item,
            person = request.person,
            slot = request.slot,
            returnSlot = request.returnSlot,
            returned = false,
        }
        state.stats.lent = state.stats.lent + 1
        if not knownNeighbor then state.stats.neighbors = state.stats.neighbors + 1 end
        message = request.acceptText or ("已借出，" .. Game.Time(request.returnSlot) .. " 归还。")
    else
        state.stats.declined = state.stats.declined + 1
    end
    state.decisions[#state.decisions + 1] = { requestId = request.id, lent = lent }
    state.cursor = state.cursor + 1
    state.awaitingAdvance = (state.cursor > state.round * 2)
    state.status = message
    state.statusKind = lent and "lent" or "declined"
    state.history[#state.history + 1] = { time = Game.Time(state.round), text = message }
    return true, message
end

---@param state BorrowGameState
local function Advance(state)
    if state.finished then return false, "已经收班，可以查看结果或再值一班。" end
    if not state.awaitingAdvance then return false, "请先处理本时刻的两条请求。" end
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then return false, "找不到这份排班，未推进时刻。" end
    state.round = state.round + 1
    local messages = {}
    for _, loan in ipairs(state.loans) do
        if not loan.returned and loan.returnSlot == state.round then
            loan.returned = true
            state.stock[loan.item] = state.stock[loan.item] + 1
            state.stats.returned = state.stats.returned + 1
            local text = "物品已按时归还。"
            for _, request in ipairs(scenario.requests) do
                if request.id == loan.requestId then
                    text = request.returnText or text
                    break
                end
            end
            messages[#messages + 1] = text
            state.history[#state.history + 1] = { time = Game.Time(state.round), text = text }
        end
    end
    state.awaitingAdvance = false
    state.finished = (state.round == 7)
    if #messages > 0 then
        state.status = table.concat(messages, "\n")
    elseif state.finished then
        state.status = "19:00，物品已清点完毕，本班结束。"
    else
        state.status = Game.Time(state.round) .. "，可以处理新的到访请求了。"
    end
    state.statusKind = state.finished and "finished" or "info"
    return true, state.status
end

-- 仅重放决策；库存、归还、统计和历史都不从存档直接读入。
function Game.Restore(snapshot)
    if type(snapshot) ~= "table" or (snapshot.version ~= 1 and snapshot.version ~= SAVE_VERSION)
        or type(snapshot.scenarioId) ~= "string" or not IsInteger(snapshot.round, 1, 7) then
        return nil, "存档格式或版本不正确。"
    end
    local freeReplans, rewardReplans = 0, 0
    if snapshot.version == SAVE_VERSION then
        if not IsInteger(snapshot.freeReplans, 0, 1) or not IsInteger(snapshot.rewardReplans, 0, 1)
            or snapshot.rewardReplans > snapshot.freeReplans then
            return nil, "存档的重新安排次数不正确。"
        end
        freeReplans, rewardReplans = snapshot.freeReplans, snapshot.rewardReplans
    end
    local count = ArrayLength(snapshot.decisions, REQUEST_COUNT)
    if count == nil then return nil, "存档的请求记录不完整。" end
    local round = snapshot.round
    if (round == 7 and count ~= REQUEST_COUNT)
        or (round < 7 and (count < (round - 1) * 2 or count > round * 2)) then
        return nil, "存档时刻与已处理请求不一致。"
    end
    local state, message = Game.New(snapshot.scenarioId)
    if not state then return nil, message end
    for _, decision in ipairs(snapshot.decisions) do
        if type(decision) ~= "table" or type(decision.requestId) ~= "string"
            or type(decision.lent) ~= "boolean" then
            return nil, "存档中有无效的借用决定。"
        end
        if state.awaitingAdvance then Advance(state) end
        local ok, errorMessage = ApplyDecision(state, decision.lent, decision.requestId)
        if not ok then return nil, "存档无法恢复：" .. errorMessage end
    end
    while state.round < round do
        local ok, errorMessage = Advance(state)
        if not ok then return nil, "存档无法恢复：" .. errorMessage end
    end
    state.freeReplans, state.rewardReplans = freeReplans, rewardReplans
    return state
end

---@param state BorrowGameState
---@return boolean, string?
function Game.Validate(state)
    if type(state) ~= "table" then return false, "值班状态不存在。" end
    local rebuilt, message = Game.Restore({
        version = SAVE_VERSION,
        scenarioId = state.scenarioId,
        round = state.round,
        decisions = state.decisions,
        freeReplans = state.freeReplans,
        rewardReplans = state.rewardReplans,
    })
    if not rebuilt then return false, message end
    for _, key in ipairs({ "cursor", "stock", "loans", "stats", "history", "finished", "awaitingAdvance" }) do
        if not SameValue(state[key], rebuilt[key]) then
            return false, "值班状态与借还记录不一致：" .. key
        end
    end
    if type(state.status) ~= "string" or type(state.statusKind) ~= "string" then
        return false, "值班反馈状态不完整。"
    end
    return true
end

---@param state BorrowGameState
---@return boolean, string?
function Game.Decide(state, lent, expectedRequestId)
    local ok, message = Game.Validate(state)
    if not ok then return false, message end
    return ApplyDecision(state, lent, expectedRequestId)
end

---@param state BorrowGameState
---@return boolean, string?
function Game.NextRound(state)
    local ok, message = Game.Validate(state)
    if not ok then return false, message end
    return Advance(state)
end

---@param state BorrowGameState
function Game.Snapshot(state)
    local ok, message = Game.Validate(state)
    if not ok then return nil, message end
    local decisions = {}
    for _, decision in ipairs(state.decisions) do
        decisions[#decisions + 1] = { requestId = decision.requestId, lent = decision.lent }
    end
    return {
        version = SAVE_VERSION,
        scenarioId = state.scenarioId,
        round = state.round,
        decisions = decisions,
        freeReplans = state.freeReplans,
        rewardReplans = state.rewardReplans,
    }
end

---@param state BorrowGameState
---@param rewarded? boolean
---@return boolean, string?
function Game.CanReplan(state, rewarded)
    local ok, message = Game.Validate(state)
    if not ok then return false, message end
    if rewarded ~= nil and type(rewarded) ~= "boolean" then
        return false, "重新安排的来源不正确。"
    end
    if state.finished or state.round == 7 then return false, "已经收班，不能重新安排。" end
    if #state.decisions == (state.round - 1) * 2 then
        return false, "先处理本时段的一条请求，才需要重新安排。"
    end
    if rewarded then
        if state.freeReplans == 0 then return false, "请先使用本班的免费重新安排。" end
        if state.rewardReplans > 0 then return false, "本班的额外重新安排已经用过了。" end
    elseif state.freeReplans > 0 then
        return false, "本班的免费重新安排已经用过了。"
    end
    return true
end

-- 只撤回当前时段；重放不回退本班已用次数。
---@param state BorrowGameState
---@param rewarded? boolean
---@return boolean, string?
function Game.Replan(state, rewarded)
    local ok, message = Game.CanReplan(state, rewarded)
    if not ok then return false, message end
    local decisions = {}
    for index = 1, (state.round - 1) * 2 do
        local decision = state.decisions[index]
        if not decision then return false, "此前时段的选择记录不完整。" end
        decisions[index] = { requestId = decision.requestId, lent = decision.lent }
    end
    local rebuilt, errorMessage = Game.Restore({
        version = SAVE_VERSION, scenarioId = state.scenarioId, round = state.round,
        decisions = decisions,
        freeReplans = state.freeReplans + (rewarded and 0 or 1),
        rewardReplans = state.rewardReplans + (rewarded and 1 or 0),
    })
    if not rebuilt then return false, errorMessage end
    for key, value in pairs(rebuilt) do state[key] = value end
    return true, "本时段的选择已撤回，可以从第一位街坊重新安排。"
end

---@param state BorrowGameState
---@return BorrowObjectiveProgress[]
function Game.Objectives(state)
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then return {} end
    local completed, neighbors, requestIds, people = 0, 0, {}, {}
    for _, loan in ipairs(state.loans) do
        if loan.returned then
            completed = completed + 1
            requestIds[loan.requestId] = true
            if not people[loan.person] then
                people[loan.person] = true
                neighbors = neighbors + 1
            end
        end
    end
    local objectives = {}
    for _, objective in ipairs(scenario.objectives) do
        local current = 0
        if objective.type == "completed" then current = completed
        elseif objective.type == "neighbors" then current = neighbors
        elseif objective.requestId and requestIds[objective.requestId] then current = 1 end
        objectives[#objectives + 1] = {
            id = objective.id, type = objective.type, title = objective.title,
            description = objective.description, current = current,
            target = objective.target, complete = current >= objective.target,
        }
    end
    return objectives
end

---@param state BorrowGameState
---@param scenario BorrowScenario
---@return BorrowNeighborRecord[]
local function NeighborRecords(state, scenario)
    local records = {}
    for _, personId in ipairs(Content.peopleOrder) do
        ---@type BorrowNeighborRecord
        local record = { personId = personId, count = 0, requestIds = {}, entries = {} }
        for _, loan in ipairs(state.loans) do
            if loan.returned and loan.person == personId then
                for _, request in ipairs(scenario.requests) do
                    if request.id == loan.requestId then
                        record.count = record.count + 1
                        record.requestIds[#record.requestIds + 1] = request.id
                        record.entries[#record.entries + 1] = { id = request.id, text = request.returnText }
                        break
                    end
                end
            end
        end
        if record.count > 0 then records[#records + 1] = record end
    end
    return records
end

---@param state BorrowGameState
---@return BorrowResult
function Game.Result(state)
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then
        return {
            completed = 0, declined = 0, neighbors = 0, maximum = 0, stars = 0,
            title = "排班暂不可用", message = "无法核对这份排班，请返回首页重新读取记录。",
            objectives = {}, neighborRecords = {},
        }
    end
    local completed = state.stats.returned
    local maximum = scenario.maximum
    local secondStar = math.ceil(maximum * 0.7)
    local stars = 0
    if state.finished and completed > 0 then
        stars = completed >= maximum and 3 or (completed >= secondStar and 2 or 1)
    end
    local title = "本班已完成"
    if not state.finished then title = "值班进行中"
    elseif stars == 3 then title = "物品周转安排得很漂亮"
    elseif stars == 2 then title = "完成了一班踏实的周转" end
    return {
        completed = completed,
        declined = state.stats.declined,
        neighbors = state.stats.neighbors,
        maximum = maximum,
        stars = stars,
        title = title,
        objectives = Game.Objectives(state),
        neighborRecords = NeighborRecords(state, scenario),
        message = "完成借用 " .. completed .. " 次 / 本排班最多 " .. maximum
            .. " 次。完成 1 次得 1 星，完成 " .. secondStar .. " 次得 2 星，完成 "
            .. maximum .. " 次得 3 星。婉拒不扣道德分。",
    }
end

return Game
