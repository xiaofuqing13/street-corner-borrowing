---@class LendingAdOptions
---@field show fun(callback: fun(result: any)): boolean
---@field now fun(): number
---@field cooldown? number
---@field timeout? number

---@class LendingAdRequest
---@field isValid fun(): boolean
---@field grantReward fun(): boolean
---@field onSuccess? fun()
---@field onFailure? fun(message: string)
---@field onBusyChanged? fun(busy: boolean)

---@class LendingAdPending
---@field options LendingAdRequest
---@field deadline number
---@field completed boolean

---@class LendingAdController
---@field show fun(callback: fun(result: any)): boolean
---@field now fun(): number
---@field cooldown number
---@field timeout number
---@field cooldownUntil number
---@field active LendingAdPending?
---@field stopped boolean
local Controller = {}
Controller.__index = Controller

local Ads = {}

---@param controller LendingAdController
local function IsStopped(controller)
    return controller.stopped
end

---@param options LendingAdOptions
function Controller:Init(options)
    self.show = options.show
    self.now = options.now
    self.cooldown = options.cooldown or 90
    self.timeout = options.timeout or 180
    self.cooldownUntil = 0
    self.active = nil
    self.stopped = false
end

---@param options LendingAdOptions
---@return LendingAdController
function Ads.New(options)
    assert(type(options) == "table" and type(options.show) == "function", "缺少广告展示方法")
    assert(type(options.now) == "function", "缺少广告计时方法")
    local cooldown = options.cooldown or 90
    local timeout = options.timeout or 180
    assert(type(cooldown) == "number" and cooldown >= 0 and cooldown < math.huge, "广告间隔必须为有限非负秒数")
    assert(type(timeout) == "number" and timeout > 0 and timeout < math.huge, "广告超时必须为有限正秒数")
    local instance = setmetatable({}, Controller)
    instance:Init(options)
    return instance
end

---@return boolean
function Controller:IsBusy()
    return self.active ~= nil
end

---@return number
function Controller:RemainingCooldown()
    return math.max(0, self.cooldownUntil - self.now())
end

---@param request LendingAdPending
---@param result any
function Controller:Finish(request, result)
    if self.stopped or self.active ~= request or request.completed then return end
    -- 先封闭本次结果；发奖期间仍保持锁，奖励回调不能重入发起下一条请求。
    request.completed = true
    local granted = false
    local message = "广告暂未完成，请稍后重试。"
    local currentTime = self.now()
    if currentTime >= request.deadline then
        message = "广告响应超时，请稍后重试。"
    elseif type(result) == "table" and result.success == true then
        -- 完整观看的频控独立于奖励是否仍可应用，跨班次保留在此实例中。
        self.cooldownUntil = currentTime + self.cooldown
        local validOk, valid = pcall(request.options.isValid)
        if not validOk or valid ~= true then
            message = "当前奖励条件已变化，未发放奖励。"
        elseif not self.stopped and self.active == request then
            local rewardOk, rewarded = pcall(request.options.grantReward)
            granted = rewardOk and rewarded == true
            if not granted then
                message = "广告已完成，但奖励未能应用，请检查当前进度。"
            end
        end
    elseif type(result) == "table" then
        if result.msg == "embed manual close" or result.msg == "用户跳过广告" then
            message = "视频未完整观看，本次未获得奖励。"
        elseif type(result.msg) == "string" and result.msg ~= "" then
            -- 内部取消／超时提示由本模块生成；SDK 失败保持简短，不堆技术原文。
            if result.localFailure == true then message = result.msg end
        end
    end

    if self.stopped or self.active ~= request then return end
    self.active = nil
    local options = request.options
    if options.onBusyChanged then options.onBusyChanged(false) end
    -- 等待状态通知允许同步 Stop，必须重新读取生命周期状态。
    if IsStopped(self) then return end
    if granted then
        if options.onSuccess then options.onSuccess() end
    elseif options.onFailure then
        options.onFailure(message)
    end
end

---@param options LendingAdRequest
---@return boolean started, string? message
function Controller:Request(options)
    if self.stopped then return false, "广告入口已关闭。" end
    if self.active then return false, "广告正在处理中，请稍候。" end
    if self:RemainingCooldown() > 0 then return false, "请稍后再观看广告。" end
    if type(options) ~= "table" or type(options.isValid) ~= "function" or type(options.grantReward) ~= "function" then
        return false, "当前奖励暂不可用。"
    end
    local validOk, valid = pcall(options.isValid)
    if not validOk or valid ~= true then return false, "当前没有可用的广告奖励。" end
    ---@type LendingAdPending
    local request = { options = options, deadline = self.now() + self.timeout, completed = false }
    self.active = request
    if options.onBusyChanged then
        local notified, notificationError = pcall(options.onBusyChanged, true)
        if not notified then
            request.completed = true
            if self.active == request then self.active = nil end
            error(notificationError, 0)
        end
    end
    if self.stopped or self.active ~= request or request.completed then
        return false, "本次广告请求已取消。"
    end

    local calling = true
    local callbackError = ""
    local callOk, accepted = pcall(self.show, function(result)
        local callbackOk, failure = pcall(self.Finish, self, request, result)
        if not callbackOk then
            request.completed = true
            if self.active == request then self.active = nil end
            -- UI 编程错误不能被展示 SDK 的 pcall 吞掉；先清锁，再交给正常错误链。
            if calling then callbackError = tostring(failure) else error(failure, 0) end
        end
    end)
    calling = false
    if callbackError ~= "" then error(callbackError, 0) end
    if not callOk or accepted ~= true then
        self:Finish(request, { success = false, msg = "广告暂不可用，请稍后重试。", localFailure = true })
    end
    -- 表示已经尝试调用 SDK，不表示受理、播放成功或奖励已经到账。
    return true
end

function Controller:Tick()
    local request = self.active
    if request and not request.completed and self.now() >= request.deadline then
        self:Finish(request, { success = false })
    end
end

---@param message? string
---@return boolean
function Controller:Cancel(message)
    local request = self.active
    if not request or request.completed then return false end
    self:Finish(request, { success = false, msg = message or "本次广告请求已取消。", localFailure = true })
    return true
end

function Controller:Stop()
    self.stopped = true
    if self.active then self.active.completed = true end
    self.active = nil
end

return Ads
