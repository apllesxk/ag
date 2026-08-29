-- 终极战场多功能脚本（最终整合版）
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "终极战场 | 多功能脚本",
    SubTitle = "战斗 / 透视 / 人物 / 锁定 / 娱乐",
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
local KillAuraConn = nil
local WallComboConn = nil
local RangePersistenceConn = nil
local lastDash = 0
local KillAuraRange = 100
local LargeRange = 500

-- 自动复活
local AutoRespawnLoop = nil
local lastRespawnTime = 0
local deathPosition = nil
local teleportAttempts = 0
local isTeleporting = false

-- 透视
local EspEnabled = false
local EspConn = nil
local EspUpdateConn = nil
local EspDrawings = {}

-- 加速
local SpeedEnabled = false
local SpeedMultiplier = 2
local SpeedConn = nil

-- God Mode
local GodModeEnabled = false
local GodModeHeartbeat = nil

-- 防卡
local AntiLagEnabled = false
local AntiLagLoop = nil

-- 锁定
local LockTargetName = nil
local LockEnabled = false
local LockLoop = nil
local LockPlayerDropdown = nil
local LockToggleUI = nil

-- 带来全部人
local BringAllEnabled = false
local BringAllLoop = nil

-- 娱乐状态
local HeadlessEnabled = false
local LeglessEnabled = false
local originalHeadTransparency = nil
local originalLegTransparency = nil

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

-- 获取所有 NPC
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

-- 杀戮光环
local function killAuraTick()
    dash()
    local targets = getTargetsInRange(KillAuraRange)
    sendWallComboAttack(targets)
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

-- 自动复活
local function autoRespawnTick()
    if tick() - lastRespawnTime < 3 then return end
    local char = LocalPlayer.Character
    if not char then RespawnAndTeleport(); return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    if humanoid.Health <= 0 or healthPercent < 0.1 then
        RespawnAndTeleport()
    end
end

local function recordDeathPosition()
    local char = LocalPlayer.Character
    if char then
        local root = getRoot(char)
        if root then deathPosition = root.Position end
    end
end

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
            task.wait(0.1)
        end
        isTeleporting = false
    end)
end

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
        task.wait(0.3)
        teleportToDeathPosition()
    end
end

-- 监听角色添加
LocalPlayer.CharacterAdded:Connect(function(char)
    if AutoRespawnEnabled and deathPosition then
        task.wait(0.1)
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
        if not AutoRespawnLoop then AutoRespawnLoop = task.spawn(function() while AutoRespawnEnabled do autoRespawnTick() task.wait(0.2) end end) end
    else
        if AutoRespawnLoop then task.cancel(AutoRespawnLoop); AutoRespawnLoop = nil end
    end
end

local function setKillAura(state)
    KillAuraEnabled = state
    if state then
        if not KillAuraConn then KillAuraConn = RunService.Heartbeat:Connect(killAuraTick) end
    else
        if KillAuraConn then KillAuraConn:Disconnect(); KillAuraConn = nil end
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

local function setGodMode(state)
    GodModeEnabled = state
    if state then
        if not GodModeHeartbeat then GodModeHeartbeat = RunService.Heartbeat:Connect(function()
            if not GodModeEnabled then return end
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.Health = humanoid.MaxHealth end
            end
            local npcs = getAllNPCs()
            local ability = ReplicatedStorage.Characters[CharValue.Value].WallCombo
            if ability then
                for _, npc in ipairs(npcs) do
                    pcall(function()
                        local hitResult = Core.Get("Combat", "Hit").Box(nil, LocalPlayer.Character, { Size = Vector3.new(1000, 1000, 1000) })
                        if hitResult then Core.Get("Combat", "Ability").Activate(ability, hitResult, LocalPlayer.Character.Head.Position + Vector3.new(0, 0, 2.5)) end
                        AbilityRemote:FireServer(ability, 69)
                        ActionRemote:FireServer(ability, "", 4, 69, { BestHitCharacter = npc, HitCharacters = {npc}, Ignore = {}, Actions = {} })
                    end)
                end
            end
        end) end
    else
        if GodModeHeartbeat then GodModeHeartbeat:Disconnect(); GodModeHeartbeat = nil end
    end
end

-- ==================== 娱乐功能：无头/断腿 ====================
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
    local legs = { "Left Leg", "Right Leg", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg" }
    for _, legName in ipairs(legs) do
        local leg = char:FindFirstChild(legName)
        if leg then
            if enabled then
                originalLegTransparency = leg.Transparency
                leg.Transparency = 1
            else
                leg.Transparency = originalLegTransparency or 0
            end
        end
    end
end

-- ==================== UI 元素 ====================
-- 战斗标签页
Section:Toggle({ Title = "杀戮光环 (Kill Aura)", Value = false, Callback = function(state) setKillAura(state) end })
Section:Toggle({ Title = "墙打秒杀 (Wall Combo)", Value = false, Callback = function(state) setWallCombo(state) end })
Section:Toggle({ Title = "Spam (极速模式)", Value = false, Callback = function(state) SpamEnabled = state end })
Section:Toggle({ Title = "范围持续", Value = false, Callback = function(state) setRangePersistence(state) end })
Section:Toggle({ Title = "自动复活", Value = false, Callback = function(state) setAutoRespawn(state) end })

-- 透视标签页
EspSection:Toggle({ Title = "玩家透视", Value = false, Callback = function(state) if state then startEsp() else stopEsp() end end })

-- 人物功能标签页
CharacterSection:Toggle({ Title = "移动加速", Value = false, Callback = function(state) setSpeed(state, SpeedMultiplier) end })
CharacterSection:Slider({ Title = "加速倍率", Value = { Min = 1, Max = 10, Default = 2 }, Callback = function(v) SpeedMultiplier = v; if SpeedEnabled then setSpeed(true, v) end end })
CharacterSection:Toggle({ Title = "God Mode (最强无敌)", Value = false, Callback = function(state) setGodMode(state) end })
CharacterSection:Toggle({ Title = "防卡 (抗卡顿)", Value = false, Callback = function(state) setAntiLag(state) end })

-- 锁定功能标签页
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

LockSection:Toggle({ Title = "带来全部人", Value = false, Callback = function(state)
    BringAllEnabled = state
    if state then
        if not BringAllLoop then BringAllLoop = task.spawn(function()
            while BringAllEnabled do
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                            if targetRoot then
                                pcall(function()
                                    targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                                    player.Character:SetPrimaryPartCFrame(myRoot.CFrame * CFrame.new(0, 0, -3))
                                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                                    if humanoid then humanoid:MoveTo(myRoot.Position + Vector3.new(0, 0, -3)) end
                                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                    if remotes then
                                        local charRemotes = remotes:FindFirstChild("Character")
                                        if charRemotes then
                                            local teleportRemote = charRemotes:FindFirstChild("Teleport") or charRemotes:FindFirstChild("Move") or charRemotes:FindFirstChild("SetPosition")
                                            if teleportRemote then teleportRemote:FireServer(player, myRoot.Position) end
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
                task.wait(0.01)
            end
            BringAllLoop = nil
        end) end
    else
        if BringAllLoop then task.cancel(BringAllLoop); BringAllLoop = nil end
    end
end })

-- 娱乐标签页
FunSection:Toggle({ Title = "无头模式", Desc = "隐藏头部", Value = false, Callback = function(state) setHeadless(state) end })
FunSection:Toggle({ Title = "断腿模式", Desc = "隐藏腿部", Value = false, Callback = function(state) setLegless(state) end })

print("终极战场脚本加载完毕（最终整合版）")