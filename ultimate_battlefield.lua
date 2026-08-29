-- 欢迎提示（灵动岛风格 + 屏幕泛光）
task.spawn(function()
    local player = game.Players.LocalPlayer
    local playerName = player and player.Name or "玩家"
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WelcomeDynamicIsland"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- 全屏泛光边框
    local glowFrame = Instance.new("Frame")
    glowFrame.Size = UDim2.new(1, 0, 1, 0)
    glowFrame.Position = UDim2.new(0, 0, 0, 0)
    glowFrame.BackgroundTransparency = 1
    glowFrame.Active = false
    glowFrame.ZIndex = -1
    glowFrame.Parent = screenGui

    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = Color3.fromRGB(100, 200, 255)
    glowStroke.Thickness = 6
    glowStroke.Transparency = 1
    glowStroke.Parent = glowFrame

    -- 主提示框
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 40)
    frame.Position = UDim2.new(0.5, -110, 0, -60)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "欢迎 " .. playerName
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.Parent = frame

    local TweenService = game:GetService("TweenService")

    local enterTween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -110, 0, 20)})
    local exitTween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -110, 0, -60)})

    local glowInTween = TweenService:Create(glowStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.2})
    local glowOutTween = TweenService:Create(glowStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1})

    enterTween:Play()
    glowInTween:Play()

    enterTween.Completed:Connect(function()
        task.wait(2)
        exitTween:Play()
        glowOutTween:Play()
        exitTween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
end)

-- ubg/by_bitoon 终极战场多功能脚本
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "ubg/by_bitoon",
    SubTitle = "战斗 / 透视 / 人物 / 锁定 / 娱乐 / 农场",
    Theme = "Dark",
    Size = UDim2.fromOffset(620, 760)
})

-- ==================== 标签页 ====================
local MainTab = Window:Tab({ Title = "战斗", Icon = "rbxassetid://6031068432", Border = true })
local Section = MainTab:Section({ Title = "功能控制" })

local EspTab = Window:Tab({ Title = "透视", Icon = "rbxassetid://6031068432", Border = true })
local EspSection = EspTab:Section({ Title = "透视功能" })

local CharacterTab = Window:Tab({ Title = "人物功能", Icon = "rbxassetid://6031068432", Border = true })
local CharacterSection = CharacterTab:Section({ Title = "加速 / 防御 / 防卡" })

local LockTab = Window:Tab({ Title = "锁定功能", Icon = "rbxassetid://6031068432", Border = true })
local LockSection = LockTab:Section({ Title = "目标锁定 / 带来全部人" })

local FunTab = Window:Tab({ Title = "娱乐", Icon = "rbxassetid://6031068432", Border = true })
local FunSection = FunTab:Section({ Title = "搞怪功能" })

local FarmTab = Window:Tab({ Title = "农场", Icon = "rbxassetid://6031068432", Border = true })
local FarmSection = FarmTab:Section({ Title = "自动杀戮" })

-- 服务
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")

-- 常用引用
local Core = require(ReplicatedStorage:WaitForChild("Core"))
local Data = LocalPlayer:WaitForChild("Data")
local CharValue = Data:WaitForChild("Character")
local AbilityRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Abilities"):WaitForChild("Ability")
local ActionRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Action")
local DashRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("Dash")

-- 全局状态
local KillAuraEnabled = false
local WallComboEnabled = false
local SpamEnabled = false
local AutoRespawnEnabled = false
local RangePersistenceEnabled = false
local KillAuraConn = nil  -- 现在存储线程对象
local WallComboConn = nil
local RangePersistenceConn = nil
local lastDash = 0
local KillAuraRange = 100
local LargeRange = 500

-- 自动复活相关
local AutoRespawnLoop = nil
local lastRespawnTime = 0
local deathPosition = nil
local teleportAttempts = 0
local isTeleporting = false

-- 透视相关
local EspEnabled = false
local EspConn = nil
local EspUpdateConn = nil
local EspDrawings = {}

-- 加速相关
local SpeedEnabled = false
local SpeedMultiplier = 2
local SpeedConn = nil

-- God Mode相关（0.2秒间隔轮流攻击）
local GodModeEnabled = false
local GodModeLoop = nil
local godModeNPCIndex = 1

-- 防卡相关
local AntiLagEnabled = false
local AntiLagLoop = nil

-- 锁定功能相关
local LockTargetName = nil
local LockEnabled = false
local LockLoop = nil
local LockPlayerDropdown = nil
local LockToggleUI = nil

-- 带来全部人相关
local BringAllEnabled = false
local BringAllLoop = nil

-- 娱乐相关状态
local HeadlessEnabled = false
local LeglessEnabled = false
local originalHeadTransparency = nil
local originalRightLegTransparency = nil

-- 农场功能相关
local FarmEnabled = false
local FarmLoop = nil
local FarmOpenedKillAura = false

-- 工具函数
local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getLocalRoot()
    return getRoot(LocalPlayer.Character)
end

-- 冲刺
local function dash()
    local now = tick()
    if now - lastDash < 0.2 then return end
    lastDash = now
    local hrp = getLocalRoot()
    if not hrp then return end
    pcall(function()
        DashRemote:FireServer(hrp.CFrame, "L", hrp.CFrame.LookVector, nil, now)
    end)
end

-- 通用攻击函数
local function sendWallComboAttack(targets)
    if #targets == 0 then return end
    local combo = ReplicatedStorage.Characters[CharValue.Value].WallCombo
    if not combo then return end
    local hitList = {}
    for _, char in ipairs(targets) do
        for i = 1, 20 do table.insert(hitList, char) end
    end
    pcall(function() AbilityRemote:FireServer(combo, 69) end)
    pcall(function()
        ActionRemote:FireServer(combo, "", 4, 69, {
            BestHitCharacter = nil,
            HitCharacters = hitList,
            Ignore = {},
            Actions = {}
        })
    end)
end

-- 获取范围内的玩家目标
local function getTargetsInRange(range)
    local root = getLocalRoot()
    if not root then return {} end
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = getRoot(player.Character)
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if targetRoot and humanoid and humanoid.Health > 0 then
                if (targetRoot.Position - root.Position).Magnitude <= range then
                    if not player.Character:GetAttribute("Invincible") then
                        table.insert(targets, player.Character)
                    end
                end
            end
        end
    end
    return targets
end

-- 获取所有存活 NPC
local function getAllNPCs()
    local npcs = {}
    local npcsFolder = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild("NPCs")
    if not npcsFolder then return npcs end
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(npcs, npc)
            end
        end
    end
    return npcs
end

-- 获取所有其他玩家名字
local function getPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

-- 杀戮光环：每0.3秒随机传送并攻击一个目标
local function killAuraTick()
    dash()
    local targets = getTargetsInRange(KillAuraRange)
    if #targets == 0 then return end

    -- 随机选择一个目标
    local target = targets[math.random(1, #targets)]
    local targetRoot = getRoot(target)
    local myRoot = getLocalRoot()
    if targetRoot and myRoot then
        -- 传送到目标背后 3 格
        local behindPos = targetRoot.Position - targetRoot.CFrame.LookVector * 3
        myRoot.CFrame = CFrame.new(behindPos, targetRoot.Position)
    end

    -- 只攻击选中的目标
    sendWallComboAttack({target})
end

-- 范围持续
local function rangePersistenceTick()
    local targets = getTargetsInRange(LargeRange)
    sendWallComboAttack(targets)
    task.wait(0.05)
end

-- 墙打秒杀
local function wallComboTick()
    local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not head then return end
    local hasTarget = false
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = getRoot(player.Character)
            if targetRoot and (targetRoot.Position - head.Position).Magnitude <= 100 then
                hasTarget = true
                break
            end
        end
    end
    if not hasTarget then return end
    local hitResult = Core.Get("Combat", "Hit").Box(nil, LocalPlayer.Character, { Size = Vector3.new(100, 100, 100) })
    if not hitResult then return end
    local ability = ReplicatedStorage.Characters[CharValue.Value].WallCombo
    pcall(function()
        Core.Get("Combat", "Ability").Activate(ability, hitResult, head.Position + Vector3.new(0, 0, 2.5))
    end)
end

-- 自动复活检测（立即触发）
local function autoRespawnTick()
    if tick() - lastRespawnTime < 0.5 then return end
    local char = LocalPlayer.Character
    if not char then
        RespawnAndTeleport()
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if humanoid.Health <= 0 then
        RespawnAndTeleport()
    end
end

-- 记录死亡位置
local function recordDeathPosition()
    local char = LocalPlayer.Character
    if char then
        local root = getRoot(char)
        if root then deathPosition = root.Position end
    end
end

-- 持续传送至死亡位置
local function teleportToDeathPosition()
    if not deathPosition then return end
    isTeleporting = true
    teleportAttempts = 0
    task.spawn(function()
        while isTeleporting and teleportAttempts < 20 do
            local char = LocalPlayer.Character
            if char then
                local root = getRoot(char)
                if root then
                    root.CFrame = CFrame.new(deathPosition)
                    root.Position = deathPosition
                end
            end
            teleportAttempts = teleportAttempts + 1
            task.wait(0.05)
        end
        isTeleporting = false
    end)
end

-- 重生并传送至死亡位置
function RespawnAndTeleport()
    lastRespawnTime = tick()
    recordDeathPosition()
    if not deathPosition then
        local char = LocalPlayer.Character
        if char then
            local root = getRoot(char)
            if root then deathPosition = root.Position end
        end
    end
    local function respawn()
        local respawnSuccess = false
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local characterRemotes = remotes:FindFirstChild("Character")
                if characterRemotes then
                    local respawnRemote = characterRemotes:FindFirstChild("Respawn") or characterRemotes:FindFirstChild("Revive") or characterRemotes:FindFirstChild("Reset")
                    if respawnRemote then
                        respawnRemote:FireServer()
                        respawnSuccess = true
                    end
                end
            end
        end)
        if respawnSuccess then return true end
        local humanoidSuccess = false
        pcall(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
                humanoidSuccess = true
            end
        end)
        if humanoidSuccess then return true end
        pcall(function()
            local VirtualInputManager = game:GetService("VirtualInputManager")
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, nil)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, nil)
        end)
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in ipairs(playerGui:GetDescendants()) do
                    if gui:IsA("TextButton") and (gui.Text:lower():find("重生") or gui.Text:lower():find("respawn")) then
                        local args = {
                            [1] = Vector2.new(gui.AbsolutePosition.X + gui.AbsoluteSize.X/2, gui.AbsolutePosition.Y + gui.AbsoluteSize.Y/2)
                        }
                        local VirtualInputManager = game:GetService("VirtualInputManager")
                        VirtualInputManager:SendMouseButtonEvent(args[1].X, args[1].Y, 0, true, nil, 0)
                        VirtualInputManager:SendMouseButtonEvent(args[1].X, args[1].Y, 0, false, nil, 0)
                        return true
                    end
                end
            end
        end)
        return false
    end
    local success = respawn()
    if deathPosition then
        task.wait(0.05)
        teleportToDeathPosition()
    end
end

-- 监听角色添加（立即传送）
LocalPlayer.CharacterAdded:Connect(function(char)
    if AutoRespawnEnabled and deathPosition then
        task.wait(0.05)
        teleportToDeathPosition()
    end
end)

-- ==================== 透视功能（美化版） ====================
local function createPlayerEsp(player)
    if player == LocalPlayer then return end
    if EspDrawings[player] then return end

    local Box = Drawing.new("Square")
    Box.Thickness = 2
    Box.Color = Color3.fromRGB(255, 255, 255)
    Box.Filled = false
    Box.Transparency = 1
    Box.Visible = false

    local BoxFill = Drawing.new("Square")
    BoxFill.Thickness = 1
    BoxFill.Color = Color3.fromRGB(0, 0, 0)
    BoxFill.Filled = true
    BoxFill.Transparency = 0.7
    BoxFill.Visible = false

    local Name = Drawing.new("Text")
    Name.Size = 13
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Center = true
    Name.Outline = true
    Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    Name.Transparency = 1
    Name.Visible = false

    local HealthBg = Drawing.new("Square")
    HealthBg.Thickness = 1
    HealthBg.Color = Color3.fromRGB(0, 0, 0)
    HealthBg.Filled = true
    HealthBg.Transparency = 0.5
    HealthBg.Visible = false

    local HealthBar = Drawing.new("Square")
    HealthBar.Thickness = 1
    HealthBar.Color = Color3.fromRGB(0, 255, 0)
    HealthBar.Filled = true
    HealthBar.Transparency = 1
    HealthBar.Visible = false

    EspDrawings[player] = {
        Box = Box,
        BoxFill = BoxFill,
        Name = Name,
        HealthBg = HealthBg,
        HealthBar = HealthBar
    }
end

local function getCharacterScreenBounds(character)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyVisible = false
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            local position, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                anyVisible = true
                minX = math.min(minX, position.X)
                minY = math.min(minY, position.Y)
                maxX = math.max(maxX, position.X)
                maxY = math.max(maxY, position.Y)
            end
        end
    end
    if not anyVisible then return nil end
    return {
        MinX = minX, MinY = minY, MaxX = maxX, MaxY = maxY,
        Width = maxX - minX, Height = maxY - minY,
        CenterX = (minX + maxX) / 2, CenterY = (minY + maxY) / 2
    }
end

local function updateEsp()
    local camera = workspace.CurrentCamera
    if not camera then return end
    for player, d in pairs(EspDrawings) do
        if player and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root then
                local bounds = getCharacterScreenBounds(char)
                if bounds and bounds.Width > 0 and bounds.Height > 0 then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local color
                    if healthPercent > 0.5 then color = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 0.25 then color = Color3.fromRGB(255, 255, 0)
                    else color = Color3.fromRGB(255, 0, 0) end

                    d.Box.Position = Vector2.new(bounds.MinX, bounds.MinY)
                    d.Box.Size = Vector2.new(bounds.Width, bounds.Height)
                    d.Box.Color = color
                    d.Box.Visible = true

                    d.BoxFill.Position = Vector2.new(bounds.MinX + 1, bounds.MinY + 1)
                    d.BoxFill.Size = Vector2.new(bounds.Width - 2, bounds.Height - 2)
                    d.BoxFill.Visible = true

                    d.Name.Text = player.Name .. " [" .. math.floor(healthPercent * 100) .. "%]"
                    d.Name.Position = Vector2.new(bounds.CenterX, bounds.MinY - 12)
                    d.Name.Visible = true

                    local barWidth = bounds.Width
                    local barHeight = 3
                    d.HealthBg.Position = Vector2.new(bounds.MinX, bounds.MaxY + 4)
                    d.HealthBg.Size = Vector2.new(barWidth, barHeight)
                    d.HealthBg.Visible = true

                    d.HealthBar.Position = Vector2.new(bounds.MinX, bounds.MaxY + 4)
                    d.HealthBar.Size = Vector2.new(barWidth * healthPercent, barHeight)
                    d.HealthBar.Color = color
                    d.HealthBar.Visible = true
                else
                    d.Box.Visible = false; d.BoxFill.Visible = false; d.Name.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false
                end
            else
                d.Box.Visible = false; d.BoxFill.Visible = false; d.Name.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false
            end
        else
            d.Box.Visible = false; d.BoxFill.Visible = false; d.Name.Visible = false; d.HealthBg.Visible = false; d.HealthBar.Visible = false
        end
    end
end

local function clearEsp()
    for player, d in pairs(EspDrawings) do
        for _, drawing in pairs(d) do drawing:Remove() end
    end
    EspDrawings = {}
end

local function startEsp()
    EspEnabled = true
    for _, player in ipairs(Players:GetPlayers()) do createPlayerEsp(player) end
    EspConn = Players.PlayerAdded:Connect(function(player) task.wait(1) createPlayerEsp(player) end)
    EspUpdateConn = RunService.RenderStepped:Connect(updateEsp)
end

local function stopEsp()
    EspEnabled = false
    if EspConn then EspConn:Disconnect(); EspConn = nil end
    if EspUpdateConn then EspUpdateConn:Disconnect(); EspUpdateConn = nil end
    clearEsp()
end

-- ==================== 防卡功能 ====================
local function disableEffects(parent)
    for _, v in ipairs(parent:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Explosion") then v.Enabled = false
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
        elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") then v.Enabled = false end
    end
end

local function enableEffects(parent)
    for _, v in ipairs(parent:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Explosion") then v.Enabled = true
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 0
        elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") then v.Enabled = true end
    end
end

local function antiLagTick()
    disableEffects(workspace)
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""
        sky.SunAngularSize = 0; sky.MoonAngularSize = 0
    end
end

local function setAntiLag(state)
    AntiLagEnabled = state
    if state then
        antiLagTick()
        if not AntiLagLoop then AntiLagLoop = task.spawn(function() while AntiLagEnabled do antiLagTick() task.wait(0.5) end end) end
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "防卡", Text = "已开启", Duration = 2 })
    else
        if AntiLagLoop then task.cancel(AntiLagLoop); AntiLagLoop = nil end
        enableEffects(workspace)
        Lighting.GlobalShadows = true; Lighting.FogEnd = 1000
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "防卡", Text = "已关闭", Duration = 2 })
    end
end

-- ==================== 启动/停止函数 ====================
local function setAutoRespawn(state)
    AutoRespawnEnabled = state
    if state then
        if not AutoRespawnLoop then
            AutoRespawnLoop = task.spawn(function()
                while AutoRespawnEnabled do
                    autoRespawnTick()
                    task.wait(0.05)
                end
            end)
        end
    else
        if AutoRespawnLoop then task.cancel(AutoRespawnLoop); AutoRespawnLoop = nil end
    end
end

local function setKillAura(state)
    KillAuraEnabled = state
    if state then
        if not KillAuraConn then
            KillAuraConn = task.spawn(function()
                while KillAuraEnabled do
                    killAuraTick()
                    task.wait(0.3)
                end
                KillAuraConn = nil
            end)
        end
    else
        if KillAuraConn then
            task.cancel(KillAuraConn)
            KillAuraConn = nil
        end
    end
end

local function setWallCombo(state)
    WallComboEnabled = state
    if state then
        if not WallComboConn then WallComboConn = RunService.Heartbeat:Connect(wallComboTick) end
    else
        if WallComboConn then WallComboConn:Disconnect(); WallComboConn = nil end
    end
end

local function setRangePersistence(state)
    RangePersistenceEnabled = state
    if state then
        if not RangePersistenceConn then RangePersistenceConn = task.spawn(function() while RangePersistenceEnabled do rangePersistenceTick() end end) end
    else
        if RangePersistenceConn then task.cancel(RangePersistenceConn); RangePersistenceConn = nil end
    end
end

local function setSpeed(state, multiplier)
    SpeedEnabled = state
    SpeedMultiplier = multiplier
    if state then
        if not SpeedConn then SpeedConn = RunService.RenderStepped:Connect(function(dt)
            if not SpeedEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                local moveDir = humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    local baseSpeed = 16
                    local extraSpeed = (SpeedMultiplier - 1) * baseSpeed
                    root.CFrame = root.CFrame + moveDir * extraSpeed * dt
                end
            end
        end) end
    else
        if SpeedConn then SpeedConn:Disconnect(); SpeedConn = nil end
    end
end

-- God Mode（0.2秒间隔轮流攻击NPC）
local function setGodMode(state)
    GodModeEnabled = state
    if state then
        if not GodModeLoop then
            GodModeLoop = task.spawn(function()
                while GodModeEnabled do
                    -- 锁血
                    local character = LocalPlayer.Character
                    if character then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then humanoid.Health = humanoid.MaxHealth end
                    end
                    -- 轮流攻击一个NPC
                    local npcs = getAllNPCs()
                    if #npcs > 0 and character then
                        if godModeNPCIndex > #npcs then godModeNPCIndex = 1 end
                        local npc = npcs[godModeNPCIndex]
                        godModeNPCIndex += 1
                        local head = character:FindFirstChild("Head")
                        if head then
                            local ability = ReplicatedStorage.Characters[CharValue.Value].WallCombo
                            if ability then
                                pcall(function()
                                    local hitResult = Core.Get("Combat", "Hit").Box(nil, character, { Size = Vector3.new(1000, 1000, 1000) })
                                    if hitResult then
                                        Core.Get("Combat", "Ability").Activate(ability, hitResult, head.Position + Vector3.new(0, 0, 2.5))
                                    end
                                    AbilityRemote:FireServer(ability, 69)
                                    ActionRemote:FireServer(ability, "", 4, 69, { BestHitCharacter = npc, HitCharacters = {npc}, Ignore = {}, Actions = {} })
                                end)
                            end
                        end
                    end
                    task.wait(0.2) -- 0.2秒间隔
                end
                GodModeLoop = nil
            end)
        end
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "God Mode", Text = "已开启（0.2秒/次）", Duration = 2 })
    else
        if GodModeLoop then
            task.cancel(GodModeLoop)
            GodModeLoop = nil
        end
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "God Mode", Text = "已关闭", Duration = 2 })
    end
end

-- ==================== 农场功能（修复：死亡自动复活继续） ====================
local function farmLoopFunction()
    while FarmEnabled do
        -- 检查自己是否存活，若死亡则立即复活
        local myChar = LocalPlayer.Character
        local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myChar or not myHumanoid or myHumanoid.Health <= 0 then
            RespawnAndTeleport()
            task.wait(0.5)
            continue
        end

        -- 获取所有存活的其他玩家
        local targets = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root then
                    table.insert(targets, player)
                end
            end
        end

        if #targets > 0 then
            local target = targets[math.random(1, #targets)]
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            if targetRoot and myRoot then
                pcall(function()
                    local behindPos = targetRoot.Position - targetRoot.CFrame.LookVector * 3
                    myRoot.CFrame = CFrame.new(behindPos, targetRoot.Position)
                end)
            end
        end
        task.wait(0.05)
    end
end

local function startFarm()
    if FarmLoop then return end
    -- 如果杀戮光环未开启，则自动开启
    if not KillAuraEnabled then
        setKillAura(true)
        FarmOpenedKillAura = true
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "农场",
            Text = "已自动开启杀戮光环",
            Duration = 2
        })
    end
    FarmLoop = task.spawn(farmLoopFunction)
end

local function stopFarm()
    if FarmLoop then
        task.cancel(FarmLoop)
        FarmLoop = nil
    end
    -- 如果农场开启了杀戮光环，则关闭它
    if FarmOpenedKillAura and KillAuraEnabled then
        setKillAura(false)
        FarmOpenedKillAura = false
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "农场",
            Text = "已关闭自动开启的杀戮光环",
            Duration = 2
        })
    end
end

-- ==================== UI 元素 ====================
Section:Toggle({ Title = "杀戮光环 (Kill Aura)", Value = false, Callback = function(state) setKillAura(state) end })
Section:Toggle({ Title = "墙打秒杀 (Wall Combo)", Value = false, Callback = function(state) setWallCombo(state) end })
Section:Toggle({ Title = "Spam (极速模式)", Value = false, Callback = function(state) SpamEnabled = state end })
Section:Toggle({ Title = "范围持续", Value = false, Callback = function(state) setRangePersistence(state) end })
Section:Toggle({ Title = "自动复活", Value = false, Callback = function(state) setAutoRespawn(state) end })

EspSection:Toggle({ Title = "玩家透视", Value = false, Callback = function(state) if state then startEsp() else stopEsp() end end })

CharacterSection:Toggle({ Title = "移动加速", Value = false, Callback = function(state) setSpeed(state, SpeedMultiplier) end })
CharacterSection:Slider({ Title = "加速倍率", Value = { Min = 1, Max = 10, Default = 2 }, Callback = function(v) SpeedMultiplier = v; if SpeedEnabled then setSpeed(true, v) end end })
CharacterSection:Toggle({ Title = "God Mode (0.2秒间隔)", Value = false, Callback = function(state) setGodMode(state) end })
CharacterSection:Toggle({ Title = "防卡 (抗卡顿)", Value = false, Callback = function(state) setAntiLag(state) end })

-- 锁定功能
local function refreshPlayerDropdown()
    if LockPlayerDropdown then LockPlayerDropdown:Refresh(getPlayerNames()) end
end
LockPlayerDropdown = LockSection:Dropdown({ Title = "选择目标玩家", Values = getPlayerNames(), Value = nil, Callback = function(name) LockTargetName = name end })
LockSection:Button({ Title = "刷新玩家列表", Callback = refreshPlayerDropdown })
LockToggleUI = LockSection:Toggle({ Title = "持续传送到目标后背", Value = false, Callback = function(state)
    LockEnabled = state
    if state then
        if not LockTargetName then LockToggleUI:Set(false); return end
        if not LockLoop then LockLoop = task.spawn(function()
            while LockEnabled do
                local targetPlayer = nil
                for _, p in ipairs(Players:GetPlayers()) do if p.Name == LockTargetName then targetPlayer = p; break end end
                if not targetPlayer then LockEnabled = false; LockToggleUI:Set(false); break end
                if targetPlayer.Character then
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot and myRoot then pcall(function() myRoot.CFrame = CFrame.new(targetRoot.Position - targetRoot.CFrame.LookVector * 3, targetRoot.Position) end) end
                end
                task.wait(0.05)
            end
            LockLoop = nil
        end) end
    else
        if LockLoop then task.cancel(LockLoop); LockLoop = nil end
    end
end })

-- 带来全部人（墙打+传送）
LockSection:Toggle({
    Title = "带来全部人",
    Desc = "将所有人墙打传送到你身边",
    Value = false,
    Callback = function(state)
        BringAllEnabled = state
        if state then
            if not BringAllLoop then
                BringAllLoop = task.spawn(function()
                    while BringAllEnabled do
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            local targets = {}
                            for _, player in ipairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer and player.Character then
                                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                                    if root then
                                        pcall(function()
                                            root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                                            player.Character:SetPrimaryPartCFrame(myRoot.CFrame * CFrame.new(0, 0, -3))
                                        end)
                                        table.insert(targets, player.Character)
                                    end
                                end
                            end
                            sendWallComboAttack(targets)
                        end
                        task.wait(0.05)
                    end
                    BringAllLoop = nil
                end)
            end
        else
            if BringAllLoop then task.cancel(BringAllLoop); BringAllLoop = nil end
        end
    end
})

-- 娱乐功能
local function setHeadless(enabled)
    HeadlessEnabled = enabled
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        if enabled then
            originalHeadTransparency = head.Transparency
            head.Transparency = 1
        else
            head.Transparency = originalHeadTransparency or 0
        end
    end
end

local function setLegless(enabled)
    LeglessEnabled = enabled
    local char = LocalPlayer.Character
    if not char then return end
    local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("RightFoot")
    if rightLeg then
        if enabled then
            originalRightLegTransparency = rightLeg.Transparency
            rightLeg.Transparency = 1
        else
            rightLeg.Transparency = originalRightLegTransparency or 0
        end
    end
end

FunSection:Toggle({ Title = "无头模式", Value = false, Callback = function(state) setHeadless(state) end })
FunSection:Toggle({ Title = "断右腿模式", Value = false, Callback = function(state) setLegless(state) end })

-- 农场标签页按钮
FarmSection:Toggle({
    Title = "自动杀戮（农场）",
    Desc = "持续随机传送到玩家背后并自动攻击",
    Value = false,
    Callback = function(state)
        FarmEnabled = state
        if state then
            startFarm()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "农场",
                Text = "自动杀戮已开启",
                Duration = 2
            })
        else
            stopFarm()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "农场",
                Text = "自动杀戮已关闭",
                Duration = 2
            })
        end
    end
})

print("ubg/by_bitoon 脚本加载完毕")
