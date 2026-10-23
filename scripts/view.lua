local UI = require("urhox-libs/UI")
local Game = require("game")
local Content = require("content")

local View = {}

local C = {
    paper = { 246, 244, 237, 255 },
    surface = { 255, 253, 247, 255 },
    ink = { 38, 55, 51, 255 },
    muted = { 104, 119, 112, 255 },
    line = { 219, 226, 215, 255 },
    green = { 37, 91, 77, 255 },
    greenHover = { 49, 112, 96, 255 },
    greenPressed = { 28, 70, 60, 255 },
    mint = { 231, 240, 230, 255 },
    disabled = { 224, 229, 220, 255 },
    gold = { 157, 115, 53, 255 },
    warm = { 248, 239, 219, 255 },
    red = { 145, 72, 58, 255 },
    white = { 255, 254, 247, 255 },
}

local ITEM_ORDER = { "umbrella", "cart" }

local function Text(value, size, color, bold, options)
    ---@type LabelProps
    local props = {
        text = tostring(value or ""),
        width = "100%",
        fontSize = size or 15,
        fontColor = color or C.ink,
        fontWeight = bold and "bold" or "normal",
        whiteSpace = "normal",
        wordBreak = "break-word",
        lineHeight = 1.45,
        verticalAlign = "top",
        flexShrink = 0,
    }
    for key, optionValue in pairs(options or {}) do
        props[key] = optionValue
    end
    if props.width == "auto" then
        props.width = nil
        props.whiteSpace = "nowrap"
        props.flexShrink = 1
    end
    return UI.Label(props)
end

---@param children Widget[]
local function Row(children, options)
    local props = {
        width = "100%",
        flexDirection = "row",
        alignItems = "center",
        gap = 12,
        children = children,
    }
    for key, value in pairs(options or {}) do
        props[key] = value
    end
    return UI.Panel(props)
end

---@param children Widget[]
local function Card(children, options)
    local props = {
        width = "100%",
        backgroundColor = C.surface,
        borderColor = C.line,
        borderWidth = 1,
        borderRadius = 18,
        padding = 20,
        gap = 12,
        flexShrink = 0,
        children = children,
    }
    for key, value in pairs(options or {}) do
        props[key] = value
    end
    return UI.Panel(props)
end

local function Button(text, onClick, secondary, disabled, options)
    ---@type ButtonProps
    local props = {
        text = text,
        width = "100%",
        height = 54,
        minWidth = 0,
        borderRadius = 12,
        fontSize = 14,
        fontWeight = "bold",
        paddingHorizontal = 14,
        backgroundColor = secondary and C.mint or C.green,
        hoverBackgroundColor = secondary and C.line or C.greenHover,
        pressedBackgroundColor = secondary and C.disabled or C.greenPressed,
        disabledBackgroundColor = C.disabled,
        textColor = secondary and C.green or C.white,
        disabledTextColor = C.muted,
        borderWidth = 0,
        boxShadow = false,
        hoverBoxShadow = false,
        pressedBoxShadow = false,
        disabledBoxShadow = false,
        disabled = disabled or false,
        onClick = function()
            if not disabled then
                onClick()
            end
        end,
    }
    for key, value in pairs(options or {}) do
        props[key] = value
    end
    if props.width == "auto" then
        props.width = nil
    end
    return UI.Button(props)
end

local function SmallButton(text, onClick)
    return Button(text, onClick, true, false, {
        width = "auto",
        height = 42,
        fontSize = 12,
        flexShrink = 1,
    })
end

local function Tag(text, dark)
    return UI.Panel {
        alignSelf = "flex-start",
        paddingHorizontal = 10,
        paddingVertical = 5,
        borderRadius = 8,
        backgroundColor = dark and { 27, 55, 47, 200 } or C.mint,
        children = {
            UI.Label {
                text = text,
                fontSize = 11,
                fontWeight = "bold",
                fontColor = dark and C.white or C.green,
            },
        },
    }
end

local function Hero(home)
    return UI.Panel {
        width = "100%",
        aspectRatio = home and 2.15 or 3.25,
        minHeight = home and 190 or 132,
        backgroundImage = "image/station.png",
        backgroundFit = "cover",
        backgroundColor = C.green,
        borderRadius = 20,
        overflow = "hidden",
        flexShrink = 0,
        children = {
            UI.Panel {
                width = "100%",
                height = "100%",
                padding = 22,
                justifyContent = "space-between",
                backgroundGradient = {
                    direction = "to-bottom",
                    from = { 18, 45, 37, 10 },
                    to = { 18, 45, 37, 175 },
                },
                children = {
                    Tag(home and "雨天值班 · 16:00—19:00" or "借一点方便，留一点余地", true),
                    Text(home and "街角借物所" or "雨还没停，邻里正好路过。",
                        home and 29 or 17, C.white, true),
                },
            },
        },
    }
end

local function PersonName(personId)
    return Content.people[personId].name
end

local function ItemName(itemId)
    return Content.items[itemId].name
end

local function ReturnAction(model, actions)
    return function()
        if model.state then
            if model.state.finished then
                actions.show("result")
            else
                actions.continueGame()
            end
        else
            actions.home()
        end
    end
end

local function PageHeading(title, subtitle, back)
    return UI.Panel {
        width = "100%",
        gap = 10,
        children = {
            SmallButton("‹ 返回", back),
            Text(title, 24, C.ink, true),
            Text(subtitle, 14, C.muted),
        },
    }
end

local function Notice(model)
    local children = {}
    if model.notice and model.notice ~= "" then
        children[#children + 1] = Text(model.notice, 14, C.green)
    elseif model.state and model.state.status ~= "" then
        children[#children + 1] = Text(model.state.status, 14, C.green)
    end
    if model.saveWarning and model.saveWarning ~= "" then
        children[#children + 1] = Text(model.saveWarning, 13, C.red)
    end
    if #children == 0 then
        return nil
    end
    return UI.Panel { width = "100%", gap = 8, children = children }
end

local function Home(model, actions, body)
    body:AddChild(Hero(true))
    body:AddChild(Text("替邻里安排一把伞、一辆车的去处。\n看看稍后的来访，再决定现在借给谁。", 16))
    if model.state and not model.state.finished then
        local scenario = Content.GetScenario(model.state.scenarioId)
        if scenario then
            body:AddChild(Card({
                Tag("进行中的值班"),
                Text(scenario.title .. " · " .. Game.Time(model.state.round), 17, C.ink, true),
                Button("继续值班", actions.continueGame),
            }, { backgroundColor = C.mint }))
        else
            body:AddChild(Text("进行中的班次暂时无法读取，请重新选择一个班次。", 14, C.red))
        end
    end
    body:AddChild(Row({
        Text("选一个班次", 19, C.ink, true, { width = "auto", flexGrow = 1 }),
        SmallButton("怎么玩", function() actions.show("rules") end),
    }))
    for index, scenario in ipairs(Content.scenarios) do
        local scenarioId = scenario.id
        local record = model.profile.records[scenarioId]
        ---@type Widget[]
        local children = {
            Tag(string.format("%02d  /  %s", index, record and "已有值班记录" or "新的一个下午")),
            Text(scenario.title, 20, C.ink, true),
            Text(scenario.subtitle, 14, C.muted),
        }
        if record then
            local stars = math.floor(record.stars)
            children[#children + 1] = Text(string.rep("★", stars)
                .. string.rep("☆", 3 - stars) .. "  最佳 " .. tostring(record.best) .. " 次借用", 14, C.gold, true)
            children[#children + 1] = Text("已尝试 " .. tostring(record.attempts) .. " 次", 12, C.muted)
        end
        children[#children + 1] = Button(record and "再值一次这个班" or "开始这个班次",
            function() actions.start(scenarioId) end, true)
        body:AddChild(Card(children))
    end
    body:AddChild(Row({
        Text("已完成 " .. tostring(model.profile.completed) .. " 次值班", 12, C.muted,
            false, { width = "auto", flexGrow = 1 }),
        SmallButton("设置", function() actions.show("settings") end),
    }))
end

local function Inventory(state)
    local cards = {}
    for _, itemId in ipairs(ITEM_ORDER) do
        local available = state.stock[itemId]
        cards[#cards + 1] = Card({
            Text(ItemName(itemId), 14, C.muted),
            Text(tostring(available) .. " 件可借", 22, available > 0 and C.green or C.muted, true),
            Text("共 " .. tostring(Content.items[itemId].capacity) .. " 件", 12, C.muted),
        }, { width = 0, flexGrow = 1, flexBasis = 0, padding = 16, gap = 5 })
    end
    return Row(cards, { alignItems = "stretch" })
end

---@param state BorrowGameState
local function UpcomingReturns(state)
    ---@type BorrowLoan[]
    local loans = {}
    for _, loan in ipairs(state.loans) do
        if not loan.returned then
            loans[#loans + 1] = loan
        end
    end
    table.sort(loans, function(a, b)
        if a.returnSlot == b.returnSlot then
            return a.requestId < b.requestId
        end
        return a.returnSlot < b.returnSlot
    end)
    local children = { Text("稍后归还", 15, C.ink, true) }
    if #loans == 0 then
        children[#children + 1] = Text("目前没有借出的物品。", 13, C.muted)
    else
        for index, loan in ipairs(loans) do
            if index > 3 then break end
            children[#children + 1] = Text(Game.Time(loan.returnSlot) .. "  "
                .. PersonName(loan.person) .. "归还" .. ItemName(loan.item), 13, C.muted)
        end
        if #loans > 3 then
            children[#children + 1] = Text("其余归还安排可在完整预告中查看。", 12, C.muted)
        end
    end
    return Card(children)
end

local function Forecast(state, actions)
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then
        return Card({ Text("本班的到访预告暂时无法读取。", 14, C.red) })
    end
    ---@type Widget[]
    local children = {
        Row({
            Text("接下来的来访", 15, C.ink, true, { width = "auto", flexGrow = 1 }),
            SmallButton("完整预告", function() actions.show("schedule") end),
        }),
    }
    local shown = 0
    for _, request in ipairs(scenario.requests) do
        if request.slot > state.round and shown < 2 then
            children[#children + 1] = Text(Game.Time(request.slot) .. "  "
                .. PersonName(request.person) .. "想借" .. ItemName(request.item)
                .. "，" .. Game.Time(request.returnSlot) .. "归还", 13, C.muted)
            shown = shown + 1
        end
    end
    if shown == 0 then
        children[#children + 1] = Text("今天没有更晚的来访，19:00 清点归还。", 13, C.muted)
    end
    return Card(children)
end

local function RequestCard(state, request, actions)
    local person = Content.people[request.person]
    local available = state.stock[request.item]
    local children = {
        Tag("当前来访 · " .. person.role),
        Row({
            UI.Panel {
                width = 48, height = 48, borderRadius = 24,
                backgroundColor = C.mint, alignItems = "center", justifyContent = "center",
                children = { UI.Label { text = person.initial, fontSize = 19,
                    fontWeight = "bold", fontColor = C.green } },
            },
            Text(person.name, 21, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
        }),
        Text(request.reason, 17),
        UI.Panel {
            width = "100%", padding = 14, borderRadius = 10, backgroundColor = C.mint,
            children = { Text("借用" .. ItemName(request.item) .. "  ·  "
                .. Game.Time(request.returnSlot) .. "归还", 14, C.green, true) },
        },
        Row({
            Button("借出" .. ItemName(request.item), function() actions.lend(request.id) end,
                false, available <= 0, { width = 0, flexGrow = 1, flexBasis = 0 }),
            Button("这次不借", function() actions.decline(request.id) end,
                true, false, { width = 0, flexGrow = 1, flexBasis = 0 }),
        }),
    }
    if available <= 0 then
        children[#children + 1] = Text(ItemName(request.item)
            .. "都借出去了，当前无法借出。可以先看看归还和到访预告，再决定这次是否婉拒。", 13, C.red)
    else
        children[#children + 1] = Text("借出会占用一件库存，直到约定时刻归还。", 12, C.muted)
    end
    return Card(children, { borderColor = { 184, 205, 185, 255 }, padding = 22, gap = 16 })
end

local function Play(model, actions, body)
    local state = model.state
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then
        body:AddChild(Card({ Text("这份值班安排暂时无法读取，请回门口重新选择。", 15, C.red),
            Button("回门口", actions.home) }))
        return
    end
    body:AddChild(Row({
        Text(scenario.title, 17, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
        SmallButton("规则", function() actions.show("rules") end),
        SmallButton("门口", actions.home),
    }))
    body:AddChild(Hero(false))
    body:AddChild(Row({
        Text(Game.Time(state.round), 27, C.green, true,
            { width = "auto", flexGrow = 1 }),
        Text("第 " .. tostring(math.min(state.round, 6)) .. " / 6 时刻", 13, C.muted,
            false, { width = "auto" }),
    }))
    local request = Game.Current(state)
    if request then
        body:AddChild(RequestCard(state, request, actions))
    else
        local nextSlot = math.min(state.round + 1, 7)
        body:AddChild(Card({
            Tag("这一时刻已处理完"),
            Text("先看看稍后的安排，再走向下一个时刻。", 16),
            Button(nextSlot == 7 and "19:00 · 清点归还并收班"
                or "前往 " .. Game.Time(nextSlot), actions.nextRound),
        }))
    end
    body:AddChild(Text("手边的物品", 17, C.ink, true))
    body:AddChild(Inventory(state))
    body:AddChild(UpcomingReturns(state))
    body:AddChild(Forecast(state, actions))
    body:AddChild(Text("时间由你推进。读完、想好，再做决定。", 12, C.muted,
        false, { textAlign = "center" }))
end

local function Schedule(model, actions, body)
    body:AddChild(PageHeading("今天的到访预告", "预告帮助安排库存。邻居到访时，再决定是否借出。",
        ReturnAction(model, actions)))
    if not model.state then
        body:AddChild(Card({ Text("先从门口选择一个班次，就能查看这一天的安排。", 16),
            Button("去选班次", actions.home) }))
        return
    end
    local state = model.state
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then
        body:AddChild(Card({ Text("这份到访预告暂时无法读取，请回门口重新选择班次。", 15, C.red),
            Button("回门口", actions.home) }))
        return
    end
    local decisions = {}
    for _, decision in ipairs(state.decisions) do
        decisions[decision.requestId] = decision.lent and "已借出" or "已婉拒"
    end
    for slot = 1, 7 do
        local children = { Text(Game.Time(slot), 19, C.green, true) }
        for _, loan in ipairs(state.loans) do
            if loan.returnSlot == slot then
                children[#children + 1] = Text((loan.returned and "已归还  " or "将归还  ")
                    .. PersonName(loan.person) .. " · " .. ItemName(loan.item), 13, C.green)
            end
        end
        for _, request in ipairs(scenario.requests) do
            if request.slot == slot then
                local status = decisions[request.id]
                children[#children + 1] = Text(PersonName(request.person) .. "想借"
                    .. ItemName(request.item) .. (status and (" · " .. status) or ""), 15, C.ink, true)
                children[#children + 1] = Text(request.reason, 13, C.muted)
                if not status then
                    children[#children + 1] = Text("若借出，" .. Game.Time(request.returnSlot) .. "归还。", 12, C.muted)
                end
            end
        end
        if slot == 7 then
            children[#children + 1] = Text("只清点归还，停止借出，然后为今天做个小结。", 14, C.muted)
        end
        body:AddChild(Card(children, { backgroundColor = slot == state.round and C.mint or C.surface }))
    end
end

local function Rules(model, actions, body)
    body:AddChild(PageHeading("借物所的小约定", "不用赶时间，先看清今天的安排。", ReturnAction(model, actions)))
    local rules = {
        { "01  看见现在，也看看稍后", "雨伞有两把，手推车有一辆。到访预告公开可查，但只是预告；只有你确认借出，才会占用库存。" },
        { "02  只有两种决定", "邻居到访时，选择借出，或这次不借。借出的物品会在约定时刻按时归还，归还后才能再借给别人。" },
        { "03  时刻由你推进", "16:00 到 18:30 共六个时刻。处理完当前来访，点击下一个时刻；同一时刻先归还，再接待来访。阅读和思考不会消耗时间。" },
        { "04  19:00 一起收班", "所有借用都要在 19:00 前或正好 19:00 归还。19:00 只清点归还，不再借出，也不延长营业。" },
        { "05  留一点余地给后来的邻居", "尽量完成更多借用，也可以为稍后的来访保留物品。结束后查看自己的值班记录，再试另一种安排。" },
    }
    for _, rule in ipairs(rules) do
        body:AddChild(Card({ Text(rule[1], 17, C.green, true), Text(rule[2], 15) }))
    end
end

local function Result(model, actions, body)
    if not model.state then
        Home(model, actions, body)
        return
    end
    local scenario = Content.GetScenario(model.state.scenarioId)
    if not scenario then
        body:AddChild(Card({ Text("这份值班小结暂时无法读取，可以回门口开始新的班次。", 15, C.red),
            Button("回门口", actions.home) }))
        return
    end
    local result = Game.Result(model.state)
    local stars = math.floor(result.stars)
    body:AddChild(Hero(false))
    body:AddChild(Tag(scenario.title .. " · 值班小结"))
    body:AddChild(Text(string.rep("★", stars) .. string.rep("☆", 3 - stars),
        30, C.gold, true, { textAlign = "center" }))
    body:AddChild(Text(result.title, 25, C.ink, true, { textAlign = "center" }))
    body:AddChild(Text(result.message, 16, C.muted, false, { textAlign = "center" }))
    body:AddChild(Card({
        Text("今天完成了", 14, C.muted),
        Text(tostring(result.completed) .. " 次借用", 29, C.green, true),
        Text("帮到了 " .. tostring(result.neighbors) .. " 位邻居，婉拒了 "
            .. tostring(result.declined) .. " 次来访。", 14),
        Text("这个班次最多可安排 " .. tostring(result.maximum) .. " 次借用。", 12, C.muted),
    }))
    body:AddChild(Button("再值一次这个班", function() actions.start(scenario.id) end))
    body:AddChild(Button("回门口选班次", actions.home, true))
    body:AddChild(SmallButton("回顾今天的安排", function() actions.show("schedule") end))
end

local function Settings(model, actions, body)
    body:AddChild(PageHeading("借物所设置", "安静一点，或重新开始一段记录。", ReturnAction(model, actions)))
    body:AddChild(Card({
        Text("界面音效", 18, C.ink, true),
        Text("借出、归还与收班时的轻提示。", 14, C.muted),
        Button(model.profile.sound and "音效已开启 · 点击关闭" or "音效已关闭 · 点击开启",
            actions.toggleSound, true),
    }))
    body:AddChild(Card({
        Text("重新整理记录", 18, C.ink, true),
        Text("清除进行中的值班和班次纪录。操作前会再次确认。", 14, C.muted),
        Button("清除进度…", actions.resetProgress, true, false, {
            textColor = C.red,
            backgroundColor = C.warm,
            hoverBackgroundColor = { 241, 226, 202, 255 },
            pressedBackgroundColor = { 232, 215, 191, 255 },
        }),
    }))
end

---@param model table
---@param actions table
---@return Panel
function View.Build(model, actions)
    local body = UI.Panel {
        width = "100%",
        maxWidth = 620,
        alignSelf = "center",
        paddingHorizontal = 22,
        paddingTop = 18,
        paddingBottom = 32,
        gap = 18,
    }
    local notice = Notice(model)
    if notice then
        body:AddChild(notice)
    end
    if model.screen == "game" and model.state then
        if model.state.finished then
            Result(model, actions, body)
        else
            Play(model, actions, body)
        end
    elseif model.screen == "result" then
        Result(model, actions, body)
    elseif model.screen == "schedule" then
        Schedule(model, actions, body)
    elseif model.screen == "rules" then
        Rules(model, actions, body)
    elseif model.screen == "settings" then
        Settings(model, actions, body)
    else
        Home(model, actions, body)
    end
    return UI.Panel {
        width = "100%",
        height = "100%",
        backgroundColor = C.paper,
        children = {
            UI.SafeAreaView {
                width = "100%",
                height = "100%",
                nativeMenuInset = true,
                children = {
                    UI.ScrollView {
                        width = "100%",
                        flexGrow = 1,
                        flexShrink = 1,
                        flexBasis = 0,
                        scrollY = true,
                        scrollX = false,
                        showScrollbar = true,
                        children = { body },
                    },
                },
            },
        },
    }
end

return View
