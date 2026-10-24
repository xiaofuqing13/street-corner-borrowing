---@class BorrowItem
---@field name string
---@field capacity integer
---@field image string

---@class BorrowPerson
---@field name string
---@field role string
---@field initial string
---@field description string
---@field portrait string

---@class BorrowObjective
---@field id string
---@field type 'completed'|'neighbors'|'request'
---@field title string
---@field description string
---@field target integer
---@field requestId? string

---@class BorrowRequest
---@field id string
---@field slot integer
---@field item string
---@field person string
---@field returnSlot integer
---@field reason string
---@field acceptText string
---@field declineText string
---@field returnText string

---@class BorrowScenario
---@field id string
---@field title string
---@field subtitle string
---@field intro string
---@field maximum integer
---@field requests BorrowRequest[]
---@field image string
---@field objectives BorrowObjective[]

local Content = {}

---@type table<string, BorrowItem>
Content.items = {
    umbrella = { name = "雨伞", capacity = 2, image = "image/v2/item-umbrella.png" },
    cart = { name = "手推车", capacity = 1, image = "image/v2/item-cart.png" },
}

---@type table<string, BorrowPerson>
Content.people = {
    amei = { name = "阿梅", role = "点心铺店主", initial = "梅", portrait = "image/v2/portrait-amei.png",
        description = "点心铺在巷口，送点心和收蒸笼常常挤在同一下午。" },
    laozhou = { name = "老周", role = "社区志愿者", initial = "周", portrait = "image/v2/portrait-laozhou.png",
        description = "活动室的椅子、签到表和晚间通知，老周都记在小本子上。" },
    xiaolin = { name = "小林", role = "图书室管理员", initial = "林", portrait = "image/v2/portrait-xiaolin.png",
        description = "新书要入架，旧书要归位，小林习惯先把书袋扣紧再出门。" },
    chenshu = { name = "陈叔", role = "维修师傅", initial = "陈", portrait = "image/v2/portrait-chenshu.png",
        description = "修理铺里有工具和待取的小电器，陈叔送完东西会把车板擦干净。" },
    xiaotang = { name = "小唐", role = "花店店员", initial = "唐", portrait = "image/v2/portrait-xiaotang.png",
        description = "小唐常带着花纸和送单，收摊前还要把门外的盆栽搬进屋。" },
    zhaoyi = { name = "赵姨", role = "老街坊", initial = "赵", portrait = "image/v2/portrait-zhaoyi.png",
        description = "赵姨熟悉这条街，取床单、办小事，也会到公交站接晚归的家人。" },
}

Content.peopleOrder = { "amei", "laozhou", "xiaolin", "chenshu", "xiaotang", "zhaoyi" }

-- slot 1 至 6 为 16:00 至 18:30，returnSlot 7 为 19:00 收班清算。
-- 请求按到访顺序排列，归还时间确定；后一次对话不假定前一次曾获借。
---@type BorrowScenario[]
Content.scenarios = {
    {
        id = "first-rain",
        image = "image/v2/shift-first-rain.png",
        objectives = {
            { id = "first-rain-efficient", type = "completed", title = "高效周转",
                description = "本班完成10次借用。三个目标可以分多局完成。", target = 10 },
            { id = "first-rain-neighbors", type = "neighbors", title = "六位街坊各有安排",
                description = "本班帮助六位不同街坊完成借用。", target = 6 },
            { id = "first-rain-long-loan", type = "request", title = "陈叔的送货",
                description = "接下陈叔16:30到18:00的推车借用。可与高效周转分局完成。", target = 1, requestId = "rain-04" },
        },
        title = "雨里的第一班",
        subtitle = "一把伞，一辆车，接住街坊的小事。",
        intro = "雨刚落下，街角的小站亮起灯。邻居们把今天的借用打算写在到访单上。看看谁先回来，再决定手里的物品借给谁。",
        maximum = 10,
        requests = {
            {
                id = "rain-01", slot = 1, item = "umbrella", person = "amei", returnSlot = 3,
                reason = "我给隔壁巷送两盒点心，纸袋可不能淋湿。",
                acceptText = "阿梅把点心袋护在伞下，朝你点点头。",
                declineText = "阿梅看看雨，先回铺子给纸袋再套一层。",
                returnText = "阿梅把伞放回接水桶，袋里的点心已经送到。",
            },
            {
                id = "rain-02", slot = 1, item = "cart", person = "laozhou", returnSlot = 2,
                reason = "活动室要摆几把折叠椅，借辆车搬一趟。",
                acceptText = "老周试了试车轮，推着空车去了活动室。",
                declineText = "老周把椅子数记下，打算分几趟慢慢搬。",
                returnText = "老周还车时把轮子擦了擦：椅子已经摆好了。",
            },
            {
                id = "rain-03", slot = 2, item = "umbrella", person = "xiaolin", returnSlot = 4,
                reason = "去对街取今天归还的书，想让书封干干爽爽。",
                acceptText = "小林把书袋扣好，撑伞走进雨里。",
                declineText = "小林给对街打了个电话，请他们把书先放屋里。",
                returnText = "小林收起伞，轻轻拍了拍干燥的书袋。",
            },
            {
                id = "rain-04", slot = 2, item = "cart", person = "chenshu", returnSlot = 5,
                reason = "几台修好的小电器要送回去，这趟得多走几户。",
                acceptText = "陈叔把绑带理顺，准备把电器一件件装稳。",
                declineText = "陈叔翻开送货单，重新安排今天的路程。",
                returnText = "陈叔推回空车，最后一台收音机也送到了。",
            },
            {
                id = "rain-05", slot = 3, item = "umbrella", person = "xiaotang", returnSlot = 5,
                reason = "送一束花到前街，花纸碰了雨就不好看了。",
                acceptText = "小唐把花束抱在伞下，走得很小心。",
                declineText = "小唐回店里找了防水套，准备换个送法。",
                returnText = "小唐把伞合好：花送到时，包装还是平整的。",
            },
            {
                id = "rain-06", slot = 3, item = "cart", person = "zhaoyi", returnSlot = 4,
                reason = "去楼下取洗好的床单，一小车正好装下。",
                acceptText = "赵姨扶住车把，念叨着要把床单放稳。",
                declineText = "赵姨说店里能代放，晚一点再去取也行。",
                returnText = "赵姨把车送回门边，床单已经收进柜子。",
            },
            {
                id = "rain-07", slot = 4, item = "cart", person = "amei", returnSlot = 6,
                reason = "铺子要收摊了，几个空蒸笼得送回后院。",
                acceptText = "阿梅比了比蒸笼的大小，推车回铺子装。",
                declineText = "阿梅决定先收小件，蒸笼等会儿再搬。",
                returnText = "阿梅还回推车，围裙上的面粉也拍干净了。",
            },
            {
                id = "rain-08", slot = 4, item = "umbrella", person = "laozhou", returnSlot = 5,
                reason = "把活动室钥匙送给门卫，过条街就回来。",
                acceptText = "老周把钥匙放进口袋，撑伞出门。",
                declineText = "老周给门卫留了话，约好在屋檐下交接。",
                returnText = "老周放好雨伞：钥匙交接清楚了。",
            },
            {
                id = "rain-09", slot = 5, item = "cart", person = "xiaolin", returnSlot = 7,
                reason = "这几箱旧书要挪到里间，我想一车一车分好类。",
                acceptText = "小林把空车推走，准备先从最重的一箱开始。",
                declineText = "小林把箱子靠墙摆好，先整理伸手够得到的书。",
                returnText = "小林在收班前推回空车，书架终于空出了走道。",
            },
            {
                id = "rain-10", slot = 5, item = "umbrella", person = "chenshu", returnSlot = 7,
                reason = "去后街取一袋修理零件，顺路把工具带回店里。",
                acceptText = "陈叔拉好工具袋拉链，把伞举过肩头。",
                declineText = "陈叔联系了零件铺，先把东西留在柜台。",
                returnText = "陈叔还伞时掸去水珠，工具袋安稳地挎在肩上。",
            },
            {
                id = "rain-11", slot = 6, item = "cart", person = "xiaotang", returnSlot = 7,
                reason = "把花店门口的箱子搬进屋，搬完就能关门了。",
                acceptText = "小唐推车回店，先给门口留出一条小路。",
                declineText = "小唐把箱子分成小摞，打算慢慢往屋里搬。",
                returnText = "小唐把空车推回灯下：花店也收好摊啦。",
            },
            {
                id = "rain-12", slot = 6, item = "umbrella", person = "zhaoyi", returnSlot = 7,
                reason = "去公交站接下班的家人，回来正好做晚饭。",
                acceptText = "赵姨看了看站牌方向，把伞握在手里。",
                declineText = "赵姨发了条消息，约家人在站台屋檐下等。",
                returnText = "赵姨把伞送回柜台，窗外有人招呼她回家吃饭。",
            },
        },
    },
    {
        id = "between-showers",
        image = "image/v2/shift-between-showers.png",
        objectives = {
            { id = "between-showers-efficient", type = "completed", title = "高效周转",
                description = "本班完成10次借用。三个目标可以分多局完成。", target = 10 },
            { id = "between-showers-neighbors", type = "neighbors", title = "六位街坊各有安排",
                description = "本班帮助六位不同街坊完成借用。", target = 6 },
            { id = "between-showers-long-loan", type = "request", title = "小林的新书",
                description = "接下小林17:30到18:30的推车借用。可与高效周转分局完成。", target = 1, requestId = "showers-08" },
        },
        title = "雨歇的空当",
        subtitle = "长借与短借之间，留一点周转的余地。",
        intro = "雨势时大时小，街坊的事也各有长短。今天有人要借很久，也有人只走一个来回。到访单已经排好，归还时间都写得清清楚楚。",
        maximum = 10,
        requests = {
            {
                id = "showers-01", slot = 1, item = "umbrella", person = "chenshu", returnSlot = 6,
                reason = "去巷尾查看几扇漏雨的窗，得在外头待一阵。",
                acceptText = "陈叔带上卷尺，撑伞去看今天的活。",
                declineText = "陈叔回店取雨衣，重新理了一遍工具。",
                returnText = "陈叔放回雨伞，量好的尺寸整齐记在本子上。",
            },
            {
                id = "showers-02", slot = 1, item = "umbrella", person = "xiaolin", returnSlot = 5,
                reason = "去街道图书室核对书册，来回加上整理要些时间。",
                acceptText = "小林把书册夹进包里，出门前又核对了地址。",
                declineText = "小林先和图书室通了电话，商量另一种交接办法。",
                returnText = "小林把伞挂回原处，书册的页角没有受潮。",
            },
            {
                id = "showers-03", slot = 2, item = "umbrella", person = "laozhou", returnSlot = 3,
                reason = "把一张临时绕行的通知送给门卫，很快回来。",
                acceptText = "老周把通知夹在文件板上，撑开雨伞。",
                declineText = "老周拍了张通知的照片，先发给门卫看。",
                returnText = "老周放下伞：通知已经贴在大家看得见的地方。",
            },
            {
                id = "showers-04", slot = 2, item = "cart", person = "zhaoyi", returnSlot = 3,
                reason = "小店有一袋米要取，推到楼下就好搬了。",
                acceptText = "赵姨拍拍车板，说这尺寸放一袋米正合适。",
                declineText = "赵姨请小店先替她留着米，回家收拾腾地方。",
                returnText = "赵姨还回推车，车板上的米袋印子已经擦净。",
            },
            {
                id = "showers-05", slot = 3, item = "umbrella", person = "amei", returnSlot = 4,
                reason = "给后街送一盒刚做好的糕点，路不远。",
                acceptText = "阿梅把糕点盒提稳，撑伞绕过门口的水洼。",
                declineText = "阿梅把盒子放回保温袋，和收件人另约了时间。",
                returnText = "阿梅把伞靠好，糕点盒已经交到收件人手中。",
            },
            {
                id = "showers-06", slot = 3, item = "cart", person = "xiaotang", returnSlot = 4,
                reason = "把花店后门的空花筐移进库房，只搬一趟。",
                acceptText = "小唐推着车，先去清出库房门边的空地。",
                declineText = "小唐决定一次提两个筐，边搬边整理。",
                returnText = "小唐推回空车，后门的花筐已经码整齐了。",
            },
            {
                id = "showers-07", slot = 4, item = "cart", person = "chenshu", returnSlot = 5,
                reason = "取一卷防水布送到巷尾，推着比抱着省力。",
                acceptText = "陈叔摸了摸车板，把绑带留在方便拿的位置。",
                declineText = "陈叔给材料店打电话，请他们先放在门内。",
                returnText = "陈叔把车送回，防水布已经放到干燥的地方。",
            },
            {
                id = "showers-08", slot = 4, item = "cart", person = "xiaolin", returnSlot = 6,
                reason = "图书室门口有几箱捐书，要搬进去逐箱摆放。",
                acceptText = "小林看好车轮方向，推着车去接那几箱书。",
                declineText = "小林先把箱子垫高，等腾出手再慢慢搬。",
                returnText = "小林还回空车，说门口现在能顺畅进出了。",
            },
            {
                id = "showers-09", slot = 5, item = "umbrella", person = "laozhou", returnSlot = 6,
                reason = "往公告栏补一张值班表，别让纸在路上淋软了。",
                acceptText = "老周卷好值班表，把它护在雨伞下。",
                declineText = "老周先把电子版发进街坊群，纸表晚些再送。",
                returnText = "老周收伞时笑了笑：明天找谁，大家都看得清。",
            },
            {
                id = "showers-10", slot = 5, item = "cart", person = "zhaoyi", returnSlot = 6,
                reason = "给楼下茶摊送一箱空杯，送到就把车推回来。",
                acceptText = "赵姨在车板上垫了块布，准备把杯箱放稳。",
                declineText = "赵姨和茶摊约好分两趟交接，空杯先不急着搬。",
                returnText = "赵姨还回车，茶摊的空杯已经摆上架子。",
            },
            {
                id = "showers-11", slot = 6, item = "umbrella", person = "amei", returnSlot = 7,
                reason = "去街口取晚饭用的菜，回铺子路上再绕来还。",
                acceptText = "阿梅把菜袋折好放进口袋，撑开伞走了。",
                declineText = "阿梅先在铺子门口等雨小些，顺手理好围裙。",
                returnText = "阿梅提着菜袋来还伞，铺子里的灯也暖暖地亮着。",
            },
            {
                id = "showers-12", slot = 6, item = "cart", person = "xiaotang", returnSlot = 7,
                reason = "把收好的花盆送进侧屋，今晚就能放心关窗。",
                acceptText = "小唐推着车走向侧屋，先把过道里的门撑住。",
                declineText = "小唐给花盆排了个次序，准备一盆盆抱进去。",
                returnText = "小唐把车停回原位，抬头看了看渐渐停下的雨。",
            },
        },
    },
    {
        id = "lamplight",
        image = "image/v2/shift-lamplight.png",
        objectives = {
            { id = "lamplight-efficient", type = "completed", title = "高效周转",
                description = "本班完成10次借用。三个目标可以分多局完成。", target = 10 },
            { id = "lamplight-neighbors", type = "neighbors", title = "六位街坊各有安排",
                description = "本班帮助六位不同街坊完成借用。", target = 6 },
            { id = "lamplight-long-loan", type = "request", title = "赵姨的换季衣物",
                description = "接下赵姨16:00到17:30的推车借用。可与高效周转分局完成。", target = 1, requestId = "light-01" },
        },
        title = "收班前的灯",
        subtitle = "看好后面的到访，让物品多走几个来回。",
        intro = "小站里备好了两把伞和一辆推车。今天的事都不大，却有几趟凑在一起。把归还和下一次到访接上，收班时就能留下更多完成的记录。",
        maximum = 10,
        requests = {
            {
                id = "light-01", slot = 1, item = "cart", person = "zhaoyi", returnSlot = 4,
                reason = "把家里几箱换季衣物送去女儿家，得走一段路。",
                acceptText = "赵姨拿出绑绳，推着车回家装那几箱衣物。",
                declineText = "赵姨先把箱子归拢好，重新约了送过去的时间。",
                returnText = "赵姨还回推车，叠好的衣物已经放进新柜子。",
            },
            {
                id = "light-02", slot = 1, item = "umbrella", person = "xiaotang", returnSlot = 4,
                reason = "去几家店确认明天的花束订单，想顺着街走一圈。",
                acceptText = "小唐把订单本放进防水袋，撑伞出门。",
                declineText = "小唐回到店里，先挨家打电话核对订单。",
                returnText = "小唐合起伞，订单本上多了几行整齐的备注。",
            },
            {
                id = "light-03", slot = 2, item = "cart", person = "amei", returnSlot = 3,
                reason = "把一袋面粉从巷口搬到铺子，过来还车很方便。",
                acceptText = "阿梅按了按车把，盘算着从平整的那边走。",
                declineText = "阿梅请店家把面粉暂存柜台，先回去腾地方。",
                returnText = "阿梅推回车，面粉已经安稳放进铺子。",
            },
            {
                id = "light-04", slot = 2, item = "umbrella", person = "laozhou", returnSlot = 3,
                reason = "去对街送明天活动的签到纸，一个来回就好。",
                acceptText = "老周把纸夹进薄夹板，撑伞走向对街。",
                declineText = "老周先把名单拍给对方，纸张留在干燥处。",
                returnText = "老周把伞撑在桶边沥水，签到纸已交接好了。",
            },
            {
                id = "light-05", slot = 3, item = "cart", person = "xiaolin", returnSlot = 4,
                reason = "把门厅的一摞杂志送进阅览室，搬完便归还。",
                acceptText = "小林推走车，打算先把杂志码得平一些。",
                declineText = "小林分出几摞小份，先抱最上面的一摞进去。",
                returnText = "小林推回空车，杂志已经按月份排在架上。",
            },
            {
                id = "light-06", slot = 3, item = "umbrella", person = "chenshu", returnSlot = 5,
                reason = "去前街送一只修好的台灯，灯罩得避着雨。",
                acceptText = "陈叔抱好包着软布的台灯，把伞撑高了一点。",
                declineText = "陈叔先把台灯放回工作台，等方便时再送。",
                returnText = "陈叔放回雨伞：台灯接上电，亮得很稳。",
            },
            {
                id = "light-07", slot = 4, item = "umbrella", person = "zhaoyi", returnSlot = 7,
                reason = "去菜场再逛一圈，回来时顺路经过小站。",
                acceptText = "赵姨把购物袋揣好，说会按单上的时刻还伞。",
                declineText = "赵姨看看时间，准备先把家里的事收拾妥当。",
                returnText = "赵姨拎着菜来还伞，柜台边多了几句家常话。",
            },
            {
                id = "light-08", slot = 4, item = "cart", person = "xiaotang", returnSlot = 5,
                reason = "给隔壁店送一盆落地绿植，车板比手抱平稳。",
                acceptText = "小唐先把车停稳，准备给花盆垫好底。",
                declineText = "小唐请隔壁店先留好位置，约好晚一点再送。",
                returnText = "小唐推回空车：绿植摆在窗边，正合适。",
            },
            {
                id = "light-09", slot = 5, item = "umbrella", person = "amei", returnSlot = 7,
                reason = "去街尾买些明早用的食材，得把几家小店走完。",
                acceptText = "阿梅叠好采购单，撑伞去赶小店收摊前的空当。",
                declineText = "阿梅翻了翻采购单，先联系熟悉的店家备货。",
                returnText = "阿梅按时还了伞，明早要用的食材也备齐了。",
            },
            {
                id = "light-10", slot = 5, item = "cart", person = "laozhou", returnSlot = 6,
                reason = "把活动室的靠垫送进储物间，推一趟正合适。",
                acceptText = "老周扶着车，回去把靠垫一摞摞码稳。",
                declineText = "老周决定先抱轻的靠垫，储物间的门已经开着。",
                returnText = "老周把车放回门边，活动室也收拾清爽了。",
            },
            {
                id = "light-11", slot = 6, item = "umbrella", person = "xiaolin", returnSlot = 7,
                reason = "把借书登记册送到值班室，纸页不想沾水。",
                acceptText = "小林夹紧登记册，撑伞向值班室走去。",
                declineText = "小林找了个文件袋，把登记册先封好。",
                returnText = "小林送回雨伞，图书室的门口也亮起了灯。",
            },
            {
                id = "light-12", slot = 6, item = "cart", person = "chenshu", returnSlot = 7,
                reason = "把门外的工具箱挪进店里，搬好就来交车。",
                acceptText = "陈叔推车回店，先把路上的小石子踢到一边。",
                declineText = "陈叔扣紧工具箱，准备分两趟提回屋。",
                returnText = "陈叔把车停好。街边的店门收了，小站也该关灯了。",
            },
        },
    },
}

-- 后三班沿用同一套借还规则，分别改变长借与短借的冲突位置。
---@type BorrowScenario[]
local additionalScenarios = {
    {
        id = "book-relay",
        image = "image/v2/shift-book-relay.png",
        objectives = {
            { id = "book-relay-efficient", type = "completed", title = "高效周转",
                description = "本班完成11次借用。三个目标可以分多局完成。", target = 11 },
            { id = "book-relay-neighbors", type = "neighbors", title = "六位街坊各有安排",
                description = "本班帮助六位不同街坊完成借用。", target = 6 },
            { id = "book-relay-long-loan", type = "request", title = "书屋的大整理",
                description = "接下小林16:30到18:30的推车借用。可与高效周转分局完成。", target = 1, requestId = "book-03" },
        },
        title = "书屋的接力",
        subtitle = "一趟长搬运，还是接起几趟短差事。",
        intro = "新书送到了街口，图书室也要腾出书架。小林想借车多整理一会儿，其他街坊还有几趟短差事。借还时刻都已写好，看看怎样接起这些来回。",
        maximum = 11,
        requests = {
            {
                id = "book-01", slot = 1, item = "cart", person = "laozhou", returnSlot = 2,
                reason = "活动室借出的几把椅子该送回来了，推车走一趟就够。",
                acceptText = "老周把椅子数记好，推车去活动室。",
                declineText = "老周把椅子收在门边，先搬轻的。",
                returnText = "老周把椅子送回，推车也按时归位。",
            },
            {
                id = "book-02", slot = 1, item = "umbrella", person = "amei", returnSlot = 2,
                reason = "给对街书屋送一袋刚蒸好的点心，怕纸袋沾雨。",
                acceptText = "阿梅把纸袋拢在伞下，穿过街口。",
                declineText = "阿梅回铺子找了个带盖的盒子。",
                returnText = "阿梅还了伞：点心已经送到了。",
            },
            {
                id = "book-03", slot = 2, item = "cart", person = "xiaolin", returnSlot = 6,
                reason = "书屋今天换书架，新书旧书要分几轮搬，得借到18:30。",
                acceptText = "小林先去清出通道，准备把书箱一摞摞搬好。",
                declineText = "小林在排架表上画了几笔，决定今天先整理一部分。",
                returnText = "小林推回空车，新书旧书都放回了合适的位置。",
            },
            {
                id = "book-04", slot = 2, item = "umbrella", person = "chenshu", returnSlot = 4,
                reason = "去取书屋请修的台灯，灯罩上包着纸。",
                acceptText = "陈叔把取件条放进口袋，撑伞出门。",
                declineText = "陈叔给书屋打了电话，请他们先把台灯放屋里。",
                returnText = "陈叔交回雨伞，包台灯的纸没有淋湿。",
            },
            {
                id = "book-05", slot = 3, item = "cart", person = "zhaoyi", returnSlot = 4,
                reason = "捐给书屋的旧杂志扎好了，借车送到门口。",
                acceptText = "赵姨把杂志捆又紧了紧，准备装车。",
                declineText = "赵姨先把杂志收到干处，等方便时再送。",
                returnText = "赵姨把空车推回来，杂志已经送进书屋。",
            },
            {
                id = "book-06", slot = 3, item = "umbrella", person = "xiaotang", returnSlot = 4,
                reason = "去书屋送一小束花，包装纸容易被雨点打花。",
                acceptText = "小唐把花束侧着抱好，撑伞走向书屋。",
                declineText = "小唐给花束多套了一层纸，先放回柜台。",
                returnText = "小唐把伞抖干，花束已放在书屋窗边。",
            },
            {
                id = "book-07", slot = 4, item = "cart", person = "xiaolin", returnSlot = 5,
                reason = "还有一箱待归架的书要送到里间，半小时就能推回来。",
                acceptText = "小林扶好书箱，推车进了书屋。",
                declineText = "小林把箱子拆开，准备分几次抱进里间。",
                returnText = "小林准时还车，那箱书已经归架。",
            },
            {
                id = "book-08", slot = 4, item = "umbrella", person = "xiaotang", returnSlot = 7,
                reason = "去街尾核对晚间送花的地址，几家店要慢慢走完。",
                acceptText = "小唐夹好送单，撑伞去街尾。",
                declineText = "小唐坐回柜台，先逐家核对送单。",
                returnText = "小唐在收班前送回雨伞，晚间地址都核对好了。",
            },
            {
                id = "book-09", slot = 5, item = "cart", person = "amei", returnSlot = 6,
                reason = "书屋下午茶用完的蒸笼要收回来，车上正好装一摞。",
                acceptText = "阿梅带上绑绳，推车去收蒸笼。",
                declineText = "阿梅先打电话，请书屋把蒸笼叠在屋里。",
                returnText = "阿梅还车时，蒸笼已经收进铺子。",
            },
            {
                id = "book-10", slot = 5, item = "umbrella", person = "laozhou", returnSlot = 6,
                reason = "把书屋的活动签到表送去值班室，纸张得护着。",
                acceptText = "老周把签到表夹好，撑伞走向值班室。",
                declineText = "老周找了个文件袋，先把签到表收好。",
                returnText = "老周送回雨伞，签到表已经交到值班室。",
            },
            {
                id = "book-11", slot = 6, item = "cart", person = "chenshu", returnSlot = 7,
                reason = "修好的落地灯该送回书屋了，用车运着更稳。",
                acceptText = "陈叔扶住灯杆，把绑带绕过车板。",
                declineText = "陈叔把灯先靠稳，准备另外安排送货。",
                returnText = "陈叔推回空车，落地灯已经在书屋亮起来了。",
            },
            {
                id = "book-12", slot = 6, item = "umbrella", person = "zhaoyi", returnSlot = 7,
                reason = "去书屋把登记好的借书证领回来，关门前就回。",
                acceptText = "赵姨收好领证条，撑伞往书屋走。",
                declineText = "赵姨给书屋留了话，改天再去领证。",
                returnText = "赵姨带着借书证回来，把伞放回桶里。",
            },
        },
    },
    {
        id = "market-prep",
        image = "image/v2/shift-market-prep.png",
        objectives = {
            { id = "market-prep-efficient", type = "completed", title = "高效周转",
                description = "本班完成10次借用。三个目标可以分多局完成。", target = 10 },
            { id = "market-prep-neighbors", type = "neighbors", title = "六位街坊各有安排",
                description = "本班帮助六位不同街坊完成借用。", target = 6 },
            { id = "market-prep-long-loan", type = "request", title = "小集的摊架",
                description = "接下赵姨16:00到17:30的推车借用。可与高效周转分局完成。", target = 1, requestId = "market-01" },
        },
        title = "小集开张前",
        subtitle = "摆摊和收摊，都要给推车留出空当。",
        intro = "街坊的小集要开张了。前半段有人搬材料，后半段还要收摊；两趟较长的推车借用夹在短差事之间。先看好空当，再决定接下哪一趟。",
        maximum = 10,
        requests = {
            {
                id = "market-01", slot = 1, item = "cart", person = "zhaoyi", returnSlot = 4,
                reason = "小集的摊架和几箱旧物要分开搬，车得用到17:30。",
                acceptText = "赵姨理好摊架，推车去库房。",
                declineText = "赵姨先把小件摆出来，摊架另想办法。",
                returnText = "赵姨按时推回车，摊架和旧物都摆好了。",
            },
            {
                id = "market-02", slot = 1, item = "umbrella", person = "amei", returnSlot = 5,
                reason = "去街口的小集送点心，还要等第一轮客人散了再回。",
                acceptText = "阿梅把点心盒码稳，撑伞出门。",
                declineText = "阿梅先把点心留在铺里，等合适时再送。",
                returnText = "阿梅还了伞，小集那边的点心已经送妥。",
            },
            {
                id = "market-03", slot = 2, item = "cart", person = "chenshu", returnSlot = 3,
                reason = "小集缺一张折叠桌，我去仓库搬来，半小时就还。",
                acceptText = "陈叔去仓库取桌子，车轮轻轻越过门槛。",
                declineText = "陈叔先量了量桌面，打算找人一起抬。",
                returnText = "陈叔送来折叠桌，推车按时归位。",
            },
            {
                id = "market-04", slot = 2, item = "umbrella", person = "xiaotang", returnSlot = 3,
                reason = "去摊位送花纸和小夹子，来回用不了多久。",
                acceptText = "小唐抱好材料盒，撑伞走向摊位。",
                declineText = "小唐把材料盒封好，暂放在店门内。",
                returnText = "小唐送回雨伞，花纸和夹子已经送到。",
            },
            {
                id = "market-05", slot = 3, item = "cart", person = "xiaolin", returnSlot = 4,
                reason = "书屋的小书摊要开了，一箱书送过去就能还车。",
                acceptText = "小林把书箱垫好，推车去书摊。",
                declineText = "小林先拿几本样书过去，整箱书晚些再搬。",
                returnText = "小林按时还车，小书摊已经摆好。",
            },
            {
                id = "market-06", slot = 3, item = "umbrella", person = "laozhou", returnSlot = 4,
                reason = "去逐个核对摊位名单，纸上还缺几处签名。",
                acceptText = "老周撑开伞，把名单夹在硬板上。",
                declineText = "老周先坐在屋里核对已有的登记。",
                returnText = "老周交回雨伞，摊位名单已经核完。",
            },
            {
                id = "market-07", slot = 4, item = "cart", person = "amei", returnSlot = 7,
                reason = "点心铺的摊位要补货，最后还要把蒸笼一起收回。",
                acceptText = "阿梅把补货单折好，推车去忙后半场。",
                declineText = "阿梅看看补货单，决定减少几样现场现蒸的点心。",
                returnText = "阿梅收摊后推回车，蒸笼已经归位。",
            },
            {
                id = "market-08", slot = 4, item = "umbrella", person = "zhaoyi", returnSlot = 5,
                reason = "去对面给摊上的旧物取价签，取完就回。",
                acceptText = "赵姨把价签底稿揣好，撑伞过街。",
                declineText = "赵姨先用铅笔写几张临时价签。",
                returnText = "赵姨还了伞，摊上的价签也换好了。",
            },
            {
                id = "market-09", slot = 5, item = "cart", person = "xiaotang", returnSlot = 6,
                reason = "花摊的空桶得先运回店里，半小时能回来。",
                acceptText = "小唐把空桶套在一起，推车离开摊位。",
                declineText = "小唐把空桶先叠在雨棚下，收摊再处理。",
                returnText = "小唐送回推车，空桶已经放进店里。",
            },
            {
                id = "market-10", slot = 5, item = "umbrella", person = "chenshu", returnSlot = 6,
                reason = "去看看小集那盏接触不良的台灯，很快就回。",
                acceptText = "陈叔收起小螺丝刀，撑伞去摊边。",
                declineText = "陈叔先问清灯的情况，提醒摊主暂时关掉。",
                returnText = "陈叔还了伞，那盏台灯已经接稳了。",
            },
            {
                id = "market-11", slot = 6, item = "cart", person = "laozhou", returnSlot = 7,
                reason = "收摊时的折叠椅要送回活动室，这趟收好就还。",
                acceptText = "老周把椅背扣齐，推车去收椅子。",
                declineText = "老周先把椅子靠到一起，准备多走几趟。",
                returnText = "老周推回空车，活动室的椅子已经清点完。",
            },
            {
                id = "market-12", slot = 6, item = "umbrella", person = "xiaolin", returnSlot = 7,
                reason = "把书摊登记册送回书屋，收好就来还伞。",
                acceptText = "小林把登记册夹在外套里，撑伞回书屋。",
                declineText = "小林先给登记册套上文件袋。",
                returnText = "小林交回雨伞，登记册已放回抽屉。",
            },
        },
    },
    {
        id = "evening-rounds",
        image = "image/v2/shift-evening-rounds.png",
        objectives = {
            { id = "evening-rounds-efficient", type = "completed", title = "高效周转",
                description = "本班完成10次借用。三个目标可以分多局完成。", target = 10 },
            { id = "evening-rounds-neighbors", type = "neighbors", title = "六位街坊各有安排",
                description = "本班帮助六位不同街坊完成借用。", target = 6 },
            { id = "evening-rounds-long-loan", type = "request", title = "晚归志愿者的伞",
                description = "接下老周16:00到19:00的借伞安排。可与高效周转分局完成。", target = 1, requestId = "evening-01" },
        },
        title = "晚归的街坊",
        subtitle = "长借的伞与晚来的需求，得一起看。",
        intro = "晚些时候还有几位街坊来借东西。两趟较早的借伞要占用不少时间，推车也有长短两种用法。别急着只看眼前，完整安排就在柜台边。",
        maximum = 10,
        requests = {
            {
                id = "evening-01", slot = 1, item = "umbrella", person = "laozhou", returnSlot = 7,
                reason = "今天挨家送晚间通知，要在外头走到19:00才回来。",
                acceptText = "老周把通知单收好，撑伞开始挨家走访。",
                declineText = "老周把通知顺序重新排了排，先联系就近的住户。",
                returnText = "老周在收班前送回雨伞，晚间通知已经送完。",
            },
            {
                id = "evening-02", slot = 1, item = "cart", person = "chenshu", returnSlot = 2,
                reason = "把门边几只空工具箱收进铺子，半小时就还。",
                acceptText = "陈叔把工具箱叠稳，推车回铺子。",
                declineText = "陈叔先把小工具箱提回屋里。",
                returnText = "陈叔推回空车，工具箱已经收妥。",
            },
            {
                id = "evening-03", slot = 2, item = "umbrella", person = "zhaoyi", returnSlot = 4,
                reason = "去街口取晒好的床单，再绕去买一点针线。",
                acceptText = "赵姨收好取件条，撑伞去街口。",
                declineText = "赵姨请店家把床单先留在干处。",
                returnText = "赵姨还了伞，床单和针线都取回来了。",
            },
            {
                id = "evening-04", slot = 2, item = "cart", person = "amei", returnSlot = 3,
                reason = "把一摞空点心盘送回后厨，很快就能归还。",
                acceptText = "阿梅垫好盘子，扶着推车慢慢走。",
                declineText = "阿梅先把轻的几只盘子端回后厨。",
                returnText = "阿梅把盘子收好，按时推回车。",
            },
            {
                id = "evening-05", slot = 3, item = "umbrella", person = "xiaotang", returnSlot = 4,
                reason = "去对街送一束预订的花，送到就回来。",
                acceptText = "小唐护好花束，撑伞过街。",
                declineText = "小唐先联系收花的人，约好稍晚送到。",
                returnText = "小唐放回雨伞，那束花已经交到客人手里。",
            },
            {
                id = "evening-06", slot = 3, item = "cart", person = "xiaolin", returnSlot = 4,
                reason = "把门口的还书箱推到书架旁，半小时就够。",
                acceptText = "小林把箱盖扣好，推车回书屋。",
                declineText = "小林先把还书箱挪到门内，再分批归架。",
                returnText = "小林按时还车，还书箱已经清空。",
            },
            {
                id = "evening-07", slot = 4, item = "umbrella", person = "amei", returnSlot = 6,
                reason = "去街尾收几张明早的点心订单，得走上几家。",
                acceptText = "阿梅带上订单本，撑伞去街尾。",
                declineText = "阿梅坐回柜台，先把能联系上的订单记好。",
                returnText = "阿梅收好订单本，把伞放回接水桶。",
            },
            {
                id = "evening-08", slot = 4, item = "cart", person = "zhaoyi", returnSlot = 5,
                reason = "一袋米要从街口推回家，路不远，用完就还。",
                acceptText = "赵姨把米袋放平，扶稳车把。",
                declineText = "赵姨请米店先把米袋收好，晚些再取。",
                returnText = "赵姨推回空车，米袋已经送到家。",
            },
            {
                id = "evening-09", slot = 5, item = "umbrella", person = "chenshu", returnSlot = 6,
                reason = "去送一台修好的小收音机，送到就回。",
                acceptText = "陈叔把收音机包好，撑伞出门。",
                declineText = "陈叔把收音机放回柜台，重新约好取货时间。",
                returnText = "陈叔交回雨伞，收音机已送到主人手中。",
            },
            {
                id = "evening-10", slot = 5, item = "cart", person = "laozhou", returnSlot = 7,
                reason = "活动室今晚要收一批椅子，整理完19:00交车。",
                acceptText = "老周把椅子数好，推车去活动室。",
                declineText = "老周先把椅子收拢，决定分几趟搬。",
                returnText = "老周按时还车，活动室已经收拾好。",
            },
            {
                id = "evening-11", slot = 6, item = "umbrella", person = "xiaolin", returnSlot = 7,
                reason = "把借书登记册交到值班室，赶在收班前回来。",
                acceptText = "小林夹好登记册，撑伞走向值班室。",
                declineText = "小林先把登记册装进防水袋。",
                returnText = "小林送回雨伞，登记册已经交妥。",
            },
            {
                id = "evening-12", slot = 6, item = "cart", person = "xiaotang", returnSlot = 7,
                reason = "门外几盆花该搬进店了，搬完马上推回来。",
                acceptText = "小唐把花盆排好，推车去店门口。",
                declineText = "小唐先把小盆花抱进店里，大盆另想办法。",
                returnText = "小唐推回空车，店门外的花盆都收好了。",
            },
        },
    },
}
for _, scenario in ipairs(additionalScenarios) do
    Content.scenarios[#Content.scenarios + 1] = scenario
end

---@param id string
---@return BorrowScenario?
function Content.GetScenario(id)
    for _, scenario in ipairs(Content.scenarios) do
        if scenario.id == id then
            return scenario
        end
    end
    return nil
end

return Content
