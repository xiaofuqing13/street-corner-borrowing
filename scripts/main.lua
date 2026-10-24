-- 基于官方 templates/scaffold-2d.lua：纯 UI、无物理、无现实倒计时。
local UI = require("urhox-libs/UI")
local Content = require("content")
local Game = require("game")
local View = require("view")
local Ads = require("ads")

---@class LendingProfile
---@field records table
---@field completed integer
---@field sound boolean
---@field objectives table
---@field neighbors table
---@field tutorialSeen boolean
---@field lastRewardAt integer

---@class LendingAdView
---@field busy boolean
---@field available boolean
---@field cooldown number
---@field reason string

---@class LendingModel
---@field screen string
---@field profile LendingProfile
---@field state BorrowGameState?
---@field notice string
---@field saveWarning string
---@field soundWarning string
---@field ad LendingAdView

-- 当前SDK文档已公开此方法；旧版类型库尚未收录广告字段。
---@class SDK
---@field ShowRewardVideoAd fun(self:SDK, callback:fun(result:table)):boolean

-- 内容为JSON；无扩展名的隔离存档槽位不是构建资产路径。
local SAVE_FILES = { "street_lending_slot_a", "street_lending_slot_b" }
local CLOUD_KEY = "street_lending_v1"
---@type LendingModel
local model_
local actions_ = {}
---@type {model:table, actions:table}?
LendingApp = nil

local dirty_ = true
local sequence_ = 0
local runId_ = 0
local recordedRun_ = 0
---@type boolean
local stopped_ = false
-- 异步回调执行时重新读取生命周期，不沿用发起请求时的判断。
local function IsRunning()
    return not stopped_
end
local cloudReady_ = false
local cloudBusy_ = false
local cloudLoading_ = false
---@type number
local cloudElapsed_ = 0
local cloudGeneration_ = 0
---@type number
local retryElapsed_ = 0
local cloudQueue_ = ""
---@type table?
local confirmation_ = nil
---@type Scene?
local audioScene_ = nil
---@type SoundSource?
local soundSource_ = nil
---@type table<string, Sound?>
local sounds_ = {}
---@type table?
local ads_ = nil
---@type fun()
local Render

local function Integer(value, low, high)
    return type(value) == "number" and value % 1 == 0 and value >= low and value <= high
end

---@return LendingProfile
local function DefaultProfile()
    return {
        records = {}, completed = 0, sound = true, objectives = {}, neighbors = {},
        tutorialSeen = false, lastRewardAt = 0,
    }
end

model_ = {
    screen = "home", profile = DefaultProfile(),
    notice = "", saveWarning = "", soundWarning = "",
    ad = { busy = false, available = false, cooldown = 0, reason = "" },
}

local function CurrentState()
    return model_.state
end

-- 比较已规范化的值，新增进度字段也参与云端冲突判断。
local function SameValue(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not SameValue(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function DecodeEnvelope(value)
    if type(value) == "string" then
        local ok, decoded = pcall(cjson.decode, value)
        if not ok then return nil end
        value = decoded
    end
    if type(value) ~= "table" or (value.version ~= 1 and value.version ~= 2)
        or not Integer(value.sequence, 0, 2147483646)
        or not Integer(value.runId, 0, 2147483646)
        or not Integer(value.recordedRun, 0, value.runId)
        or type(value.profile) ~= "table" then return nil end
    local source = value.profile
    if type(source.records) ~= "table" or type(source.sound) ~= "boolean"
        or not Integer(source.completed, 0, 1000000) then return nil end
    local profile = DefaultProfile()
    profile.sound, profile.completed = source.sound, source.completed
    if value.version == 1 then
        profile.tutorialSeen = value.runId > 0 or source.completed > 0
    else
        if type(source.objectives) ~= "table" or type(source.neighbors) ~= "table"
            or type(source.tutorialSeen) ~= "boolean"
            or not Integer(source.lastRewardAt, 0, 4102444800) then return nil end
        profile.tutorialSeen, profile.lastRewardAt = source.tutorialSeen, source.lastRewardAt
    end
    local requests = {}
    for _, scenario in ipairs(Content.scenarios) do
        for _, request in ipairs(scenario.requests) do requests[request.id] = request end
        local record = source.records[scenario.id]
        if record ~= nil then
            if type(record) ~= "table" or not Integer(record.best, 0, scenario.maximum)
                or not Integer(record.stars, 0, 3) or not Integer(record.attempts, 1, 1000000) then
                return nil
            end
            profile.records[scenario.id] = {
                best = record.best, stars = record.stars, attempts = record.attempts,
            }
        end
        local goals = value.version == 2 and source.objectives[scenario.id] or nil
        if goals ~= nil then
            if type(goals) ~= "table" then return nil end
            local clean = {}
            for _, objective in ipairs(scenario.objectives) do
                if goals[objective.id] ~= nil and type(goals[objective.id]) ~= "boolean" then return nil end
                if goals[objective.id] then clean[objective.id] = true end
            end
            if next(clean) then profile.objectives[scenario.id] = clean end
        end
    end
    if value.version == 2 then
        for _, personId in ipairs(Content.peopleOrder) do
            local record = source.neighbors[personId]
            if record ~= nil then
                if type(record) ~= "table" or not Integer(record.completed, 1, 12000000)
                    or type(record.items) ~= "table" then return nil end
                local clean, count = { completed = record.completed, items = {} }, 0
                for requestId, complete in pairs(record.items) do
                    local request = requests[requestId]
                    if complete ~= true or not request or request.person ~= personId then return nil end
                    clean.items[requestId] = true
                    count = count + 1
                end
                if count > record.completed then return nil end
                profile.neighbors[personId] = clean
            end
        end
    end
    local state
    if value.game ~= nil and value.game ~= cjson.null then
        state = Game.Restore(value.game)
        if not state then return nil end
    end
    return {
        version = 2, sequence = value.sequence, runId = value.runId,
        recordedRun = value.recordedRun, profile = profile, state = state,
    }
end

local function ApplyEnvelope(envelope)
    sequence_, runId_, recordedRun_ = envelope.sequence, envelope.runId, envelope.recordedRun
    model_.profile, model_.state = envelope.profile, envelope.state
    dirty_ = true
end

-- 只比较经校验后的存档内容，不依赖 JSON 对象的键顺序。
local function SameProgress(remote)
    if runId_ ~= remote.runId or recordedRun_ ~= remote.recordedRun
        or not SameValue(model_.profile, remote.profile) then return false end
    local currentState = model_.state
    local remoteState = remote.state
    if not currentState or not remoteState then return currentState == remoteState end
    local current = Game.Snapshot(currentState)
    local received = Game.Snapshot(remoteState)
    return current ~= nil and received ~= nil and SameValue(current, received)
end

local function ReadLocal(path)
    if not fileSystem:FileExists(path) then return nil end
    local file = File(path, FILE_READ)
    if not file:IsOpen() then return nil end
    if file:GetSize() > 131072 then file:Close(); return nil end
    local text = file:ReadString()
    file:Close()
    return DecodeEnvelope(text)
end

local function LoadLocal()
    local found = false
    ---@type table?
    local best = nil
    for _, path in ipairs(SAVE_FILES) do
        if fileSystem:FileExists(path) then found = true end
        local ok, candidate = pcall(ReadLocal, path)
        if ok and candidate and (not best or candidate.sequence > best.sequence) then best = candidate end
    end
    if best then
        ApplyEnvelope(best)
    elseif found then
        model_.saveWarning = "原进度暂时无法读取，已保留原文件。开始新班次前可先检查存档。"
    end
end

local function HasCloudUser()
    return clientCloud ~= nil and type(clientCloud.userId) == "string" and clientCloud.userId ~= ""
end

---@type fun()
local PumpCloud

local function Save()
    local snapshot
    if model_.state then
        snapshot = Game.Snapshot(model_.state)
        if not snapshot then
            model_.saveWarning = "当前借还记录未通过校验，暂未覆盖存档。"
            dirty_ = true
            return false
        end
    end
    sequence_ = sequence_ + 1
    local envelope = {
        version = 2, sequence = sequence_, runId = runId_, recordedRun = recordedRun_,
        profile = model_.profile, game = snapshot,
    }
    local encodedOk, encoded = pcall(cjson.encode, envelope)
    if not encodedOk or type(encoded) ~= "string" then
        model_.saveWarning = "本局调整已生效，但进度暂未保存，请先不要退出。"
        dirty_ = true
        return false
    end
    local target = SAVE_FILES[sequence_ % 2 + 1]
    if not target then return false end
    local localOk = pcall(function()
        local file = File(target, FILE_WRITE)
        if not file:IsOpen() then error("存档文件无法写入") end
        local written = file:WriteString(encoded)
        file:Flush()
        file:Close()
        if written == false then error("存档写入未完成") end
        local check = ReadLocal(target)
        if not check or check.sequence ~= sequence_ then error("存档回读校验失败") end
    end)
    if not localOk then model_.saveWarning = "本地保存暂未完成，请先不要退出。" end
    if HasCloudUser() then
        cloudQueue_ = encoded
        if cloudReady_ then PumpCloud() end
    elseif localOk then
        model_.saveWarning = ""
    end
    dirty_ = true
    return localOk
end

PumpCloud = function()
    if stopped_ or not cloudReady_ or cloudBusy_ or cloudQueue_ == "" then return end
    local payload = cloudQueue_
    cloudQueue_ = ""
    cloudBusy_ = true
    local accepted = pcall(function()
        clientCloud:Set(CLOUD_KEY, payload, {
            ok = function()
                cloudBusy_ = false
                if not IsRunning() then return end
                model_.saveWarning = cloudQueue_ == "" and "" or "正在同步最新进度。"
                dirty_ = true
                PumpCloud()
            end,
            error = function()
                cloudBusy_ = false
                if cloudQueue_ == "" then cloudQueue_ = payload end
                if not IsRunning() then return end
                model_.saveWarning = "云端同步暂未完成，请在网络恢复后稍候。"
                retryElapsed_ = 0
                dirty_ = true
            end,
        })
    end)
    if not accepted then
        cloudBusy_ = false
        if cloudQueue_ == "" then cloudQueue_ = payload end
        model_.saveWarning = "云端同步暂不可用，进度仍在等待同步。"
        dirty_ = true
    end
end

local function LoadCloud()
    if not HasCloudUser() then return end
    cloudGeneration_ = cloudGeneration_ + 1
    local generation = cloudGeneration_
    cloudLoading_, cloudElapsed_ = true, 0
    model_.notice = "正在读取值班记录，马上就好。"
    local ok = pcall(function()
        clientCloud:Get(CLOUD_KEY, {
            ok = function(values)
                if stopped_ or generation ~= cloudGeneration_ or not cloudLoading_ then return end
                local remote = type(values) == "table" and DecodeEnvelope(values[CLOUD_KEY]) or nil
                cloudLoading_ = false
                local equalSequenceConflict = remote and remote.sequence == sequence_ and not SameProgress(remote)
                if remote and (remote.sequence > sequence_ or equalSequenceConflict) then
                    if sequence_ > 0 or equalSequenceConflict then
                        confirmation_ = { kind = "cloud", envelope = remote }
                        model_.notice = "发现另一份云端记录，请选择保留哪一份。"
                        dirty_ = true
                        return
                    end
                    ApplyEnvelope(remote)
                    cloudQueue_ = ""
                    cloudReady_ = true
                    model_.notice, model_.saveWarning = "", ""
                    Save()
                else
                    cloudReady_ = true
                    model_.notice, model_.saveWarning = "", ""
                    if sequence_ > 0 and (not remote or sequence_ > remote.sequence) then Save() end
                end
                dirty_ = true
            end,
            error = function()
                if stopped_ or generation ~= cloudGeneration_ or not cloudLoading_ then return end
                cloudLoading_ = false
                model_.notice = ""
                model_.saveWarning = "暂未读到云端记录。当前仅使用本地进度，请保持网络后重试。"
                dirty_ = true
            end,
        })
    end)
    if not ok then
        cloudLoading_ = false
        model_.notice = ""
        model_.saveWarning = "云端记录暂不可用，当前仅使用本地进度。"
    end
end

local function PlaySound(name)
    local source, sound = soundSource_, sounds_[name]
    if model_.profile.sound and source and sound then
        local played = pcall(function() source:Play(sound, 0, 0.28) end)
        model_.soundWarning = played and "" or "音效暂不可用，借还记录仍会正常保存。"
        if not played then dirty_ = true end
    end
end

local function UpdateAdState()
    local busy = ads_ ~= nil and ads_:IsBusy()
    local remaining = math.max(0, math.min(90, 90 - (os.time() - model_.profile.lastRewardAt)))
    if model_.profile.lastRewardAt == 0 then remaining = 0 end
    if ads_ then remaining = math.max(remaining, ads_:RemainingCooldown()) end
    remaining = math.ceil(remaining)
    ---@type boolean, string?
    local available, reason = false, "先完成一班，再使用激励重排。"
    local state = CurrentState()
    if model_.profile.completed > 0 and state then
        available, reason = Game.CanReplan(state, true)
    end
    if available and remaining > 0 then
        available, reason = false, "稍等 " .. remaining .. " 秒后可再次观看。"
    end
    if busy then available, reason = false, "正在播放，完整看完后重新安排本时段。" end
    if model_.ad.busy ~= busy or model_.ad.available ~= available
        or model_.ad.cooldown ~= remaining or model_.ad.reason ~= (reason or "") then
        model_.ad.busy, model_.ad.available = busy, available
        model_.ad.cooldown, model_.ad.reason = remaining, reason or ""
        dirty_ = true
    end
end

local function CancelAd()
    if ads_ then ads_:Cancel("本次奖励已取消，当前借还记录没有变化。") end
end

local function RecordResult()
    if not model_.state or not model_.state.finished or recordedRun_ == runId_ then return end
    local result = Game.Result(model_.state)
    local key = model_.state.scenarioId
    local old = model_.profile.records[key] or { best = 0, stars = 0, attempts = 0 }
    model_.profile.records[key] = {
        best = math.max(old.best, result.completed), stars = math.max(old.stars, result.stars),
        attempts = old.attempts + 1,
    }
    local goals = model_.profile.objectives[key] or {}
    for _, objective in ipairs(result.objectives) do
        if objective.complete then goals[objective.id] = true end
    end
    if next(goals) then model_.profile.objectives[key] = goals end
    for _, neighbor in ipairs(result.neighborRecords) do
        local record = model_.profile.neighbors[neighbor.personId] or { completed = 0, items = {} }
        record.completed = record.completed + neighbor.count
        for _, requestId in ipairs(neighbor.requestIds) do record.items[requestId] = true end
        model_.profile.neighbors[neighbor.personId] = record
    end
    model_.profile.completed = model_.profile.completed + 1
    recordedRun_ = runId_
end

local function StartShift(id)
    local state, message = Game.New(id)
    if not state then model_.notice = message or "这个班次暂不可用。"; dirty_ = true; return end
    CancelAd()
    runId_ = runId_ + 1
    model_.state = state
    model_.screen = model_.profile.tutorialSeen and "game" or "tutorial"
    model_.notice = state.status
    confirmation_ = nil
    PlaySound("page")
    Save()
end

function actions_.start(id)
    if stopped_ or cloudLoading_ or confirmation_ or (ads_ and ads_:IsBusy()) then return end
    if model_.state and not model_.state.finished then
        confirmation_ = { kind = "new", scenarioId = id }
        dirty_ = true
    else
        StartShift(id)
    end
end

function actions_.continueGame()
    if stopped_ then return end
    CancelAd()
    model_.screen = model_.state and (model_.state.finished and "result" or "game") or "home"
    if model_.state and not model_.state.finished and not model_.profile.tutorialSeen then
        model_.screen = "tutorial"
    end
    model_.notice = ""
    dirty_ = true
end

function actions_.home()
    if stopped_ then return end
    CancelAd()
    model_.screen, model_.notice = "home", ""
    dirty_ = true
end

function actions_.show(screen)
    if stopped_ then return end
    if screen == "rules" or screen == "schedule" or screen == "settings" or screen == "result"
        or screen == "neighbors" or screen == "records" or screen == "history" or screen == "tutorial" then
        CancelAd()
        model_.screen, model_.notice = screen, ""
        dirty_ = true
    end
end

local function Decide(lend, requestId)
    if stopped_ or cloudLoading_ or confirmation_ or not model_.state
        or (ads_ and ads_:IsBusy()) then return end
    local ok, message = Game.Decide(model_.state, lend, requestId)
    model_.notice = message or ""
    if ok then PlaySound(lend and "lend" or "page"); Save() end
    dirty_ = true
end

function actions_.lend(requestId) Decide(true, requestId) end
function actions_.decline(requestId) Decide(false, requestId) end

function actions_.nextRound()
    if stopped_ or cloudLoading_ or confirmation_ or not model_.state
        or (ads_ and ads_:IsBusy()) then return end
    local ok, message = Game.NextRound(model_.state)
    model_.notice = message or ""
    if ok then
        if model_.state.finished then
            RecordResult()
            model_.screen = "result"
            PlaySound("finish")
        else
            PlaySound("page")
        end
        Save()
    end
    dirty_ = true
end

function actions_.finishTutorial()
    if stopped_ or cloudLoading_ or confirmation_ then return end
    model_.profile.tutorialSeen = true
    model_.screen = model_.state and (model_.state.finished and "result" or "game") or "home"
    model_.notice = ""
    PlaySound("page")
    Save()
end

function actions_.replan()
    if stopped_ or cloudLoading_ or confirmation_ or not model_.state
        or (ads_ and ads_:IsBusy()) then return end
    local ok, message = Game.Replan(model_.state, false)
    model_.notice = message or ""
    if ok then PlaySound("page"); Save() end
    dirty_ = true
end

function actions_.rewardReplan()
    if stopped_ or cloudLoading_ or confirmation_ or not model_.state or not ads_ then return end
    UpdateAdState()
    if not model_.ad.available then model_.notice = model_.ad.reason; dirty_ = true; return end
    local state, run = model_.state, runId_
    local snapshot = Game.Snapshot(state)
    if not snapshot then return end
    -- 先绘制等待状态，再由SDK在该根上展示广告；播放期间不替换UI根。
    model_.ad.busy = true
    Render()
    local requested, message = ads_:Request({
        isValid = function()
            return IsRunning() and CurrentState() == state and runId_ == run
                and model_.screen == "game" and SameValue(Game.Snapshot(state), snapshot)
                and Game.CanReplan(state, true)
        end,
        grantReward = function()
            local ok, rewardMessage = Game.Replan(state, true)
            if not ok then return false end
            model_.profile.lastRewardAt = os.time()
            model_.notice = rewardMessage or "本时段已重新安排。"
            PlaySound("page")
            Save()
            return true
        end,
        onSuccess = function() dirty_ = true end,
        onFailure = function(reason)
            if not IsRunning() then return end
            model_.notice = reason
            dirty_ = true
        end,
        onBusyChanged = function(busy)
            if not IsRunning() then return end
            model_.ad.busy = busy
            dirty_ = true
        end,
    })
    if not requested then model_.notice = message or "广告暂不可用，请稍后重试。" end
    UpdateAdState()
    dirty_ = true
end

function actions_.toggleSound()
    if stopped_ or cloudLoading_ or confirmation_ or (ads_ and ads_:IsBusy()) then return end
    model_.profile.sound = not model_.profile.sound
    Save()
    if model_.profile.sound then PlaySound("page") end
end

function actions_.resetProgress()
    if stopped_ or cloudLoading_ or confirmation_ or (ads_ and ads_:IsBusy()) then return end
    confirmation_ = { kind = "reset" }
    dirty_ = true
end

local function ConfirmOverlay()
    local resetting = confirmation_ and confirmation_.kind == "reset"
    local cloudConflict = confirmation_ and confirmation_.kind == "cloud"
    local function Cancel()
        if cloudConflict and confirmation_ then
            sequence_ = math.max(sequence_, confirmation_.envelope.sequence)
            cloudQueue_, cloudReady_ = "", true
            confirmation_ = nil
            Save()
        else
            confirmation_ = nil
        end
        dirty_ = true
    end
    local function Confirm()
        if not confirmation_ then return end
        local pending = confirmation_
        confirmation_ = nil
        if pending.kind == "new" then
            StartShift(pending.scenarioId)
        elseif pending.kind == "cloud" then
            CancelAd()
            ApplyEnvelope(pending.envelope)
            cloudQueue_, cloudReady_ = "", true
            model_.screen, model_.notice = "home", "已恢复云端值班记录。"
            Save()
        else
            CancelAd()
            model_.state, model_.profile = nil, DefaultProfile()
            recordedRun_ = runId_
            model_.screen, model_.notice = "home", "已清除本游戏的值班记录。"
            Save()
        end
    end
    return UI.Panel {
        position = "absolute", left = 0, top = 0, right = 0, bottom = 0,
        backgroundColor = { 17, 34, 29, 190 }, pointerEvents = "auto",
        justifyContent = "center", alignItems = "center", padding = 28,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 380, padding = 24, gap = 18,
                backgroundColor = { 255, 253, 247, 255 }, borderRadius = 18,
                children = {
                    UI.Label { text = cloudConflict and "选择要保留的记录" or (resetting and "确认清除记录？" or "重新开始这个班次？"),
                        fontSize = 21, fontColor = { 38, 55, 51, 255 }, whiteSpace = "normal" },
                    UI.Label { text = cloudConflict and "当前值班与云端记录不同，暂不能自动合并。选择一份继续，随后同步这份记录。"
                        or (resetting and "进行中的值班和个人纪录会被清除。"
                        or "进行中的班次会被替换，已完成的个人纪录会保留。"),
                        fontSize = 15, whiteSpace = "normal", fontColor = { 91, 110, 102, 255 } },
                    UI.Button { text = cloudConflict and "保留本次值班并同步" or "保留当前进度", height = 48, onClick = Cancel },
                    UI.Button { text = cloudConflict and "恢复云端记录" or (resetting and "确认清除" or "确认重新开始"),
                        height = 48, onClick = Confirm },
                },
            },
        },
    }
end

Render = function()
    local root = View.Build(model_, actions_)
    if confirmation_ then root:AddChild(ConfirmOverlay()) end
    UI.SetRoot(root, true)
    dirty_ = false
end

function Start()
    graphics.windowTitle = "街角借物所"
    stopped_ = false
    UI.Init({ theme = "default-taptap", scale = UI.Scale.DEFAULT })
    LoadLocal()
    ads_ = Ads.New({
        show = function(callback) return sdk:ShowRewardVideoAd(callback) end,
        now = function() return time.elapsedTime end,
        cooldown = 90, timeout = 180,
    })
    UpdateAdState()
    audioScene_ = Scene()
    soundSource_ = audioScene_:CreateChild("InterfaceSounds"):CreateComponent("SoundSource")
    for _, name in ipairs({ "page", "lend", "finish" }) do
        sounds_[name] = cache:GetResource("Sound", "audio/sfx/" .. name .. ".wav")
    end
    LoadCloud()
    Render()
    SubscribeToEvent("Update", "HandleUpdate")
    LendingApp = { model = model_, actions = actions_ }
end

---@param _eventType string
---@param eventData UpdateEventData
function HandleUpdate(_eventType, eventData)
    if not IsRunning() then return end
    local dt = eventData:GetFloat("TimeStep")
    if ads_ then ads_:Tick() end
    UpdateAdState()
    if cloudLoading_ then
        cloudElapsed_ = cloudElapsed_ + dt
        if cloudElapsed_ > 15 then
            cloudGeneration_ = cloudGeneration_ + 1
            cloudLoading_ = false
            model_.notice = ""
            model_.saveWarning = "云端记录暂未响应，当前仅使用本地进度。"
            dirty_ = true
        end
    elseif HasCloudUser() and not cloudReady_ and not confirmation_ then
        retryElapsed_ = retryElapsed_ + dt
        if retryElapsed_ > 30 then retryElapsed_ = 0; LoadCloud() end
    elseif cloudQueue_ ~= "" and not cloudBusy_ then
        retryElapsed_ = retryElapsed_ + dt
        if retryElapsed_ > 8 then retryElapsed_ = 0; PumpCloud() end
    end
    if dirty_ and not (ads_ and ads_:IsBusy()) then Render() end
end

function Stop()
    stopped_ = true
    if ads_ then ads_:Stop(); ads_ = nil end
    cloudGeneration_ = cloudGeneration_ + 1
    UnsubscribeFromEvent("Update")
    if not cloudLoading_ and not (confirmation_ and confirmation_.kind == "cloud") then Save() end
    UI.Shutdown()
    if audioScene_ then audioScene_:Dispose(); audioScene_ = nil end
    soundSource_ = nil
    LendingApp = nil
end

