-- =====================================================================================
-- PROJECT DELTA / EMERGENCY EMDEN: OMNI-FRAMEWORK v16.0 (MOUSE & CAMERA DUAL-AIM)
-- =====================================================================================

local _G_ENV = getgenv and getgenv() or _G
if _G_ENV.EmergencyEmdenLoaded and not _G_ENV.ForceReload then
    warn("[SWILL]: Framework already active. Set _G.ForceReload = true to re-initialize.")
    return
end
_G_ENV.EmergencyEmdenLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    Aimbot = {
        Enabled = true,
        Key = Enum.UserInputType.MouseButton2, -- Зажми правую кнопку мыши
        AimMode = "Mouse", -- "Mouse" (надежный обход) или "Camera"
        Smoothness = 1, -- 1 = мгновенно в голову
        FOV = 300,
        ShowFOV = true,
        WallCheck = true,
        SelectedHitbox = "Head",
        TeamCheck = false
    },
    Visuals = {
        ESPEnabled = true,
        Boxes = true,
        Names = true,
        Health = true,
        Tracers = true,
        Skeleton = true,
        TeamCheck = false,
        MaxDist = 10000
    },
    Exploits = {
        NoRecoil = true,
        FullBright = true
    }
}

-- Создание круга FOV
local FOVDrawing = Drawing.new("Circle")
FOVDrawing.Visible = Config.Aimbot.ShowFOV
FOVDrawing.Radius = Config.Aimbot.FOV
FOVDrawing.Color = Color3.fromRGB(0, 255, 180)
FOVDrawing.Thickness = 1.5
FOVDrawing.Filled = false
FOVDrawing.Transparency = 0.85
FOVDrawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- Проверка стен (Raycast)
local function IsVisible(targetPart, character)
    if not Config.Aimbot.WallCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = RaycastParams.FilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    rayParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    if result then
        return result.Instance:IsDescendantOf(character)
    end
    return true
end

-- Поиск цели в радиусе FOV
local function GetClosestTarget()
    local bestTarget = nil
    local shortestDist = Config.Aimbot.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local targetPart = char:FindFirstChild(Config.Aimbot.SelectedHitbox) or char:FindFirstChild("Head")
            
            if hum and hum.Health > 0 and targetPart then
                if not Config.Aimbot.TeamCheck or player.Team ~= LocalPlayer.Team then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if mouseDist < shortestDist then
                            if IsVisible(targetPart, char) then
                                shortestDist = mouseDist
                                bestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Система ESP
local ESPRepository = {}

local function CreateESP(player)
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Skeleton = {}
    }

    esp.Box.Visible = false
    esp.Box.Thickness = 1
    esp.Box.Color = Color3.fromRGB(0, 255, 128)
    esp.Box.Filled = false

    esp.Name.Visible = false
    esp.Name.Size = 13
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Center = true
    esp.Name.Outline = true

    esp.Tracer.Visible = false
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = Color3.fromRGB(0, 255, 128)

    for i = 1, 10 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        table.insert(esp.Skeleton, line)
    end

    ESPRepository[player] = esp
end

local function RemoveESP(player)
    if ESPRepository[player] then
        for _, obj in pairs(ESPRepository[player]) do
            if type(obj) == "table" then
                for _, sub in ipairs(obj) do if typeof(sub) == "Drawing" then sub:Remove() end end
            elseif typeof(obj) == "Drawing" then
                obj:Remove()
            end
        end
        ESPRepository[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

local isAiming = false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Config.Aimbot.Key then isAiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.Aimbot.Key then isAiming = false end
end)

-- Основной цикл рендеринга и аима
RunService.RenderStepped:Connect(function()
    FOVDrawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVDrawing.Radius = Config.Aimbot.FOV
    FOVDrawing.Visible = Config.Aimbot.ShowFOV and Config.Aimbot.Enabled

    if Config.Aimbot.Enabled and isAiming then
        local target = GetClosestTarget()
        if target then
            local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
            if onScreen then
                if Config.Aimbot.AimMode == "Mouse" and mousemoverel then
                    -- Эмуляция движения мыши (обходит блокировки камеры в играх)
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local moveX = (screenPos.X - screenCenter.X) / Config.Aimbot.Smoothness
                    local moveY = (screenPos.Y - screenCenter.Y) / Config.Aimbot.Smoothness
                    mousemoverel(moveX, moveY)
                else
                    -- Классический метод через камеру
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                    if Config.Aimbot.Smoothness <= 1 then
                        Camera.CFrame = targetCFrame
                    else
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / Config.Aimbot.Smoothness)
                    end
                end
            end
        end
    end

    -- Рендеринг ESP для всех
    for player, esp in pairs(ESPRepository) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        local show = false
        if Config.Visuals.ESPEnabled and char and root and hum and hum.Health > 0 then
            if not Config.Visuals.TeamCheck or player.Team ~= LocalPlayer.Team then
                if (Camera.CFrame.Position - root.Position).Magnitude <= Config.Visuals.MaxDist then
                    show = true
                end
            end
        end

        if show then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local head = char:FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or pos
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2

                if Config.Visuals.Boxes then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(pos.X - width / 2, headPos.Y)
                    esp.Box.Visible = true
                else
                    esp.Box.Visible = false
                end

                if Config.Visuals.Names then
                    local hpText = Config.Visuals.Health and (" [" .. math.floor(hum.Health) .. "HP]") or ""
                    esp.Name.Text = player.Name .. hpText
                    esp.Name.Position = Vector2.new(pos.X, headPos.Y - 18)
                    esp.Name.Visible = true
                else
                    esp.Name.Visible = false
                end

                if Config.Visuals.Tracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(pos.X, legPos.Y)
                    esp.Tracer.Visible = true
                else
                    esp.Tracer.Visible = false
                end

                if Config.Visuals.Skeleton and char:FindFirstChild("UpperTorso") and head then
                    local joints = {
                        {"Head", "UpperTorso"},
                        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
                        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
                        {"UpperTorso", "LowerTorso"},
                        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
                        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}
                    }
                    for i, pair in ipairs(joints) do
                        local p1 = char:FindFirstChild(pair[1])
                        local p2 = char:FindFirstChild(pair[2])
                        local line = esp.Skeleton[i]
                        if p1 and p2 and line then
                            local s1, v1 = Camera:WorldToViewportPoint(p1.Position)
                            local s2, v2 = Camera:WorldToViewportPoint(p2.Position)
                            if v1 and v2 then
                                line.From = Vector2.new(s1.X, s1.Y)
                                line.To = Vector2.new(s2.X, s2.Y)
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        elseif line then line.Visible = false end
                    end
                else
                    for _, line in ipairs(esp.Skeleton) do line.Visible = false end
                end
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Tracer.Visible = false
                for _, line in ipairs(esp.Skeleton) do line.Visible = false end
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            for _, line in ipairs(esp.Skeleton) do line.Visible = false end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.Exploits.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
    if Config.Exploits.NoRecoil and LocalPlayer.Character then
        local shaker = LocalPlayer.Character:FindFirstChild("CameraShaker")
        if shaker then shaker:Destroy() end
    end
end)

-- =====================================================================================
-- ПОЛЬЗОВАТЕЛЬСКОЕ МЕНЮ С СИСТЕМОЙ ЧЕЛОВЕЧКА (ГОЛОВА) И КНОПКОЙ ЗАКРЫТИЯ/ОТКРЫТИЯ
-- =====================================================================================

for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui.Name == "SwillExecutiveFramework" then gui:Destroy() end
end

local SwillUI = Instance.new("ScreenGui")
SwillUI.Name = "SwillExecutiveFramework"
SwillUI.Parent = CoreGui
SwillUI.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = SwillUI
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 440, 0, 420)
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
TopBar.Size = UDim2.new(1, 0, 0, 35)

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 350, 1, 0)
Title.Font = Enum.Font.Code
Title.Text = "[SWILL]: HEAD-AIM & FIX (INSERT TO OPEN/CLOSE)"
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.TextSize = 10
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Position = UDim2.new(1, -30, 0, 7)
CloseBtn.Size = UDim2.new(0, 21, 0, 21)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Иконка человека (Меню выбора точки хитбокса)
local ManikinFrame = Instance.new("Frame")
ManikinFrame.Parent = MainFrame
ManikinFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
ManikinFrame.Position = UDim2.new(0, 20, 0, 45)
ManikinFrame.Size = UDim2.new(0, 140, 0, 160)

local ManikinCorner = Instance.new("UICorner")
ManikinCorner.CornerRadius = UDim.new(0, 6)
ManikinCorner.Parent = ManikinFrame

local ManikinTitle = Instance.new("TextLabel")
ManikinTitle.Parent = ManikinFrame
ManikinTitle.BackgroundTransparency = 1
ManikinTitle.Size = UDim2.new(1, 0, 0, 25)
ManikinTitle.Font = Enum.Font.Code
ManikinTitle.Text = "HITBOX (СИЛУЭТ)"
ManikinTitle.TextColor3 = Color3.fromRGB(150, 150, 170)
ManikinTitle.TextSize = 10

local HeadNodeBtn = Instance.new("TextButton")
HeadNodeBtn.Parent = ManikinFrame
HeadNodeBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 128) -- Подсветка головы
HeadNodeBtn.Position = UDim2.new(0.5, -20, 0, 35)
HeadNodeBtn.Size = UDim2.new(0, 40, 0, 40)
HeadNodeBtn.Font = Enum.Font.Code
HeadNodeBtn.Text = "ГОЛОВА"
HeadNodeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
HeadNodeBtn.TextSize = 8

local HeadCorner = Instance.new("UICorner")
HeadCorner.CornerRadius = UDim.new(0, 20)
HeadCorner.Parent = HeadNodeBtn

local AddPointLabel = Instance.new("TextLabel")
AddPointLabel.Parent = ManikinFrame
AddPointLabel.BackgroundTransparency = 1
AddPointLabel.Position = UDim2.new(0, 0, 0, 85)
AddPointLabel.Size = UDim2.new(1, 0, 0, 40)
AddPointLabel.Font = Enum.Font.Code
AddPointLabel.Text = "Режим наведения:\n[ТОЛЬКО ГОЛОВА]"
AddPointLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
AddPointLabel.TextSize = 9

HeadNodeBtn.MouseButton1Click:Connect(function()
    Config.Aimbot.SelectedHitbox = "Head"
    HeadNodeBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
    AddPointLabel.Text = "Режим наведения:\n[ТОЛЬКО ГОЛОВА]"
end)

local function AddButton(text, posX, posY, sizeX, sizeY, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Position = UDim2.new(0, posX, 0, posY)
    btn.Size = UDim2.new(0, sizeX, 0, sizeY)
    btn.Font = Enum.Font.Code
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

AddButton("Aimbot: ON", 175, 45, 245, 30, function(b)
    Config.Aimbot.Enabled = not Config.Aimbot.Enabled
    b.Text = "Aimbot: " .. (Config.Aimbot.Enabled and "ON" or "OFF")
end)

AddButton("WallCheck (Без стен): ON", 175, 80, 245, 30, function(b)
    Config.Aimbot.WallCheck = not Config.Aimbot.WallCheck
    b.Text = "WallCheck: " .. (Config.Aimbot.WallCheck and "ON" or "OFF")
end)

AddButton("ESP (Все игроки): ON", 175, 115, 245, 30, function(b)
    Config.Visuals.ESPEnabled = not Config.Visuals.ESPEnabled
    b.Text = "ESP (Все игроки): " .. (Config.Visuals.ESPEnabled and "ON" or "OFF")
end)

AddButton("Skeleton ESP: ON", 175, 150, 245, 30, function(b)
    Config.Visuals.Skeleton = not Config.Visuals.Skeleton
    b.Text = "Skeleton ESP: " .. (Config.Visuals.Skeleton and "ON" or "OFF")
end)

AddButton("Метод аима: Mouse (Обход)", 20, 215, 400, 32, function(b)
    if Config.Aimbot.AimMode == "Mouse" then
        Config.Aimbot.AimMode = "Camera"
        b.Text = "Метод аима: Camera (Классика)"
    else
        Config.Aimbot.AimMode = "Mouse"
        b.Text = "Метод аима: Mouse (Обход)"
    end
end)

AddButton("Cycle FOV Radius (Current: 300)", 20, 255, 400, 32, function(b)
    Config.Aimbot.FOV = Config.Aimbot.FOV + 50
    if Config.Aimbot.FOV > 500 then Config.Aimbot.FOV = 150 end
    b.Text = "FOV Radius: " .. Config.Aimbot.FOV
end)

AddButton("Anti-Recoil & FullBright: ON", 20, 295, 400, 32, function(b)
    Config.Exploits.NoRecoil = not Config.Exploits.NoRecoil
    Config.Exploits.FullBright = not Config.Exploits.FullBright
    b.Text = "Anti-Recoil & FullBright: " .. (Config.Exploits.NoRecoil and "ON" or "OFF")
end)

-- Открытие/закрытие меню по клавише Insert
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("[SWILL]: Omni-Framework v16 loaded. Use INSERT to open/close menu.")
