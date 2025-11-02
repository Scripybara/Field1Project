local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Swiftbara Hub | Version 3.0.0",
   Icon = 98523976445602, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Thank you for using Swiftbara Hub!",
   LoadingSubtitle = "by Scripybara",
   ShowText = "Rayfield", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "AmberGlow", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "SwiftbaraHubConfig"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

--Tabs
local Aimbot = Window:CreateTab("Aimbot", "swords")
local Mobile = Window:CreateTab("Mobile Aimbot", "smartphone")
local Silent = Window:CreateTab("Silent Aim", "crosshair")
local Killall = Window:CreateTab("Kill All", "skull")
local Visuals = Window:CreateTab("Visuals", "eye")
local Gunmod = Window:CreateTab("Gun Mod", "settings-2")
local Misc = Window:CreateTab("Misc", 4483362458) 

---------------------------LOLLLLLLLLLLLLLLLLLLLLLLLLL------------------------

-- Khai báo biến toàn cục trước
if not _G.AimbotData then
    _G.AimbotData = {
        connections = {},
        drawings = {},
        settings = {
            teamCheck = false,
            wallCheck = false,
            fovSize = 100,
            fovColor = Color3.fromRGB(255, 255, 255),
            smoothness = 0.95,
            showCircle = false -- THÊM DÒNG NÀY VÀ ĐẶT THÀNH false
        }
    }
end

--Toggle Aimbot
local Toggle = Aimbot:CreateToggle({
   Name = "Aimbot",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "AimbotToggle",
   Callback = function(Value)
        -- Dọn dẹp khi tắt
        if not Value then
            for _, connection in pairs(_G.AimbotData.connections) do
                connection:Disconnect()
            end
            for _, drawing in pairs(_G.AimbotData.drawings) do
                drawing:Remove()
            end
            _G.AimbotData.connections = {}
            _G.AimbotData.drawings = {}
            return
        end

        -- Aimbot script
        local players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local UserInputService = game:GetService("UserInputService")
        local plr = players.LocalPlayer
        local camera = workspace.CurrentCamera

        -- Aimbot variables
        local aiming = false
        local aimParts = {"Head"}
        local predictionStrength = 0.065

        -- FOV Circle - Đặt ở giữa màn hình
        local fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 2
        fovCircle.Radius = _G.AimbotData.settings.fovSize
        fovCircle.Filled = false
        fovCircle.Color = _G.AimbotData.settings.fovColor
        fovCircle.Visible = _G.AimbotData.settings.showCircle -- SỬA THÀNH BIẾN SETTING
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        table.insert(_G.AimbotData.drawings, fovCircle)

        -- Wall check function
        local function checkWall(targetCharacter)
            if not _G.AimbotData.settings.wallCheck then
                return false
            end
            
            local targetHead = targetCharacter:FindFirstChild("Head")
            if not targetHead then return true end

            local origin = camera.CFrame.Position
            local direction = (targetHead.Position - origin).unit * (targetHead.Position - origin).magnitude
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {plr.Character, targetCharacter}
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

            local raycastResult = workspace:Raycast(origin, direction, raycastParams)
            return raycastResult and raycastResult.Instance ~= nil
        end

        -- Team check function
        local function checkTeam(player)
            if not _G.AimbotData.settings.teamCheck then
                return false
            end
            
            if player.Team == plr.Team then
                return true
            end
            return false
        end

        -- Get target function
        local function getTarget()
            local nearestPlayer = nil
            local closestPart = nil
            local shortestDistance = _G.AimbotData.settings.fovSize

            for _, player in ipairs(players:GetPlayers()) do
                if player ~= plr and player.Character and not checkTeam(player) then
                    for _, partName in ipairs(aimParts) do
                        local part = player.Character:FindFirstChild(partName)
                        if part then
                            local screenPos = camera:WorldToViewportPoint(part.Position)
                            local mousePos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            
                            if distance < shortestDistance and screenPos.Z > 0 then
                                if not checkWall(player.Character) then
                                    shortestDistance = distance
                                    nearestPlayer = player
                                    closestPart = part
                                end
                            end
                        end
                    end
                end
            end

            return nearestPlayer, closestPart
        end

        -- Aim function
        local function aimAt(target, part)
            if target and part then
                local velocity = target.Character.HumanoidRootPart.Velocity
                local predictedPosition = part.Position + (velocity * predictionStrength)
                local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPosition)
                camera.CFrame = camera.CFrame:Lerp(targetCFrame, _G.AimbotData.settings.smoothness)
            end
        end

        -- Mouse events (chỉ dùng MouseButton2)
        local mouseDownConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                aiming = true
            end
        end)

        local mouseUpConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                aiming = false
            end
        end)

        -- Render loop
        local renderConnection = RunService.RenderStepped:Connect(function()
            if Value then
                fovCircle.Radius = _G.AimbotData.settings.fovSize
                fovCircle.Color = _G.AimbotData.settings.fovColor
                fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                fovCircle.Visible = _G.AimbotData.settings.showCircle -- THÊM DÒNG NÀY
                
                if aiming then
                    local target, part = getTarget()
                    if target and part then
                        aimAt(target, part)
                    end
                end
            end
        end)

        -- Thêm connections vào danh sách quản lý
        table.insert(_G.AimbotData.connections, renderConnection)
        table.insert(_G.AimbotData.connections, mouseDownConnection)
        table.insert(_G.AimbotData.connections, mouseUpConnection)
   end,
})

-- Toggle Team Check
local TeamCheckToggle = Aimbot:CreateToggle({
   Name = "Team Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "TeamCheckToggle",
   Callback = function(Value)
        _G.AimbotData.settings.teamCheck = Value
   end,
})

-- Toggle Wall Check
local WallCheckToggle = Aimbot:CreateToggle({
   Name = "Wall Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "WallCheckToggle",
   Callback = function(Value)
        _G.AimbotData.settings.wallCheck = Value
   end,
})

-- Thêm toggle cho circle của aimbot trong tab Aimbot
local CircleToggle = Aimbot:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false, -- ĐẶT THÀNH false
    Flag = "CircleToggle",
    Callback = function(Value)
        -- Lưu setting
        if not _G.AimbotData then
            _G.AimbotData = {
                settings = {
                    showCircle = Value,
                    teamCheck = false,
                    wallCheck = false,
                    fovSize = 100,
                    fovColor = Color3.fromRGB(255, 255, 255),
                    smoothness = 0.95
                }
            }
        else
            _G.AimbotData.settings.showCircle = Value
        end
        
        -- Cập nhật hiển thị circle nếu đang bật aimbot
        if _G.AimbotData and _G.AimbotData.drawings and _G.AimbotData.drawings[1] then
            _G.AimbotData.drawings[1].Visible = Value
        end
    end
})

-- Slider chỉnh độ to của circle
local FovSizeSlider = Aimbot:CreateSlider({
   Name = "FOV Size",
   Range = {10, 500},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 100,
   Flag = "FovSizeSlider",
   Callback = function(Value)
        _G.AimbotData.settings.fovSize = Value
   end,
})

-- Color Picker chỉnh màu circle
local FovColorPicker = Aimbot:CreateColorPicker({
   Name = "FOV Color",
   Color = Color3.fromRGB(255, 255, 255),
   Flag = "FovColorPicker",
   Callback = function(Color)
        _G.AimbotData.settings.fovColor = Color
   end,
})

-- Slider chỉnh độ smooth của aimbot
local SmoothSlider = Aimbot:CreateSlider({
   Name = "Smoothness",
   Range = {1, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 5,
   Flag = "SmoothSlider",
   Callback = function(Value)
        _G.AimbotData.settings.smoothness = 1 - (Value / 100)
   end,
})

---------------------------------------------ESPPP--------------------------------------------
-- ESP Chams Script
local ESP = {
    Enabled = false, -- ĐẶT THÀNH false
    Highlighters = {},
    TeamCheck = false,  -- ĐẶT THÀNH false
    ShowDistance = true,
    ShowHealth = true,
    ChamColor = Color3.fromRGB(255, 165, 0),
    TextColor = Color3.fromRGB(255, 0, 0),
    MaxDistance = 500
}

-- Tạo ESP Chams cho player
function ESP:CreateESP(player)
    if player == game.Players.LocalPlayer then return end
    
    -- Đợi character xuất hiện
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
        wait(1)
    end
    
    if not character then return end
    
    -- Kiểm tra nếu đã có ESP cho player này
    if self.Highlighters[player] then
        self:RemoveESP(player)
    end
    
    -- Tạo Highlighter cho Chams
    local highlighter = Instance.new("Highlight")
    highlighter.Name = "ESPChams"
    highlighter.Enabled = false
    highlighter.Adornee = character
    highlighter.FillColor = self.ChamColor
    highlighter.FillTransparency = 0.5
    highlighter.OutlineColor = self.ChamColor
    highlighter.OutlineTransparency = 0
    highlighter.Parent = character
    
    -- Tạo text (tên)
    local nameBillboard = Instance.new("BillboardGui")
    local nameText = Instance.new("TextLabel")
    
    nameBillboard.Name = "ESPName"
    nameBillboard.Adornee = character:WaitForChild("Head")
    nameBillboard.Size = UDim2.new(0, 200, 0, 50)
    nameBillboard.StudsOffset = Vector3.new(0, 3, 0)
    nameBillboard.AlwaysOnTop = true
    nameBillboard.Enabled = false
    
    nameText.Name = "NameText"
    nameText.BackgroundTransparency = 1
    nameText.Text = player.Name
    nameText.TextColor3 = self.TextColor
    nameText.TextSize = 14
    nameText.TextStrokeTransparency = 0
    nameText.Font = Enum.Font.GothamBold
    nameText.Size = UDim2.new(1, 0, 1, 0)
    nameText.Parent = nameBillboard
    
    nameBillboard.Parent = character
    
    -- Tạo text (info)
    local infoBillboard = Instance.new("BillboardGui")
    local infoText = Instance.new("TextLabel")
    
    infoBillboard.Name = "ESPInfo"
    infoBillboard.Adornee = character:WaitForChild("Head")
    infoBillboard.Size = UDim2.new(0, 200, 0, 50)
    infoBillboard.StudsOffset = Vector3.new(0, 2, 0)
    infoBillboard.AlwaysOnTop = true
    infoBillboard.Enabled = false
    
    infoText.Name = "InfoText"
    infoText.BackgroundTransparency = 1
    infoText.Text = ""
    infoText.TextColor3 = self.TextColor
    infoText.TextSize = 12
    infoText.TextStrokeTransparency = 0
    infoText.Font = Enum.Font.Gotham
    infoText.Size = UDim2.new(1, 0, 1, 0)
    infoText.Parent = infoBillboard
    
    infoBillboard.Parent = character
    
    self.Highlighters[player] = {
        highlighter = highlighter,
        nameBillboard = nameBillboard,
        infoBillboard = infoBillboard,
        character = character
    }
    
    -- Kết nối sự kiện character thay đổi (respawn)
    local characterConnection
    characterConnection = player.CharacterAdded:Connect(function(newChar)
        if characterConnection then
            characterConnection:Disconnect()
        end
        
        wait(1)
        self:RemoveESP(player)
        self:CreateESP(player)
    end)
end

-- Xóa ESP
function ESP:RemoveESP(player)
    if self.Highlighters[player] then
        if self.Highlighters[player].highlighter and self.Highlighters[player].highlighter.Parent then
            self.Highlighters[player].highlighter:Destroy()
        end
        if self.Highlighters[player].nameBillboard and self.Highlighters[player].nameBillboard.Parent then
            self.Highlighters[player].nameBillboard:Destroy()
        end
        if self.Highlighters[player].infoBillboard and self.Highlighters[player].infoBillboard.Parent then
            self.Highlighters[player].infoBillboard:Destroy()
        end
        self.Highlighters[player] = nil
    end
end

-- Kiểm tra player còn sống
function ESP:IsPlayerAlive(player)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    return humanoid.Health > 0
end

-- Cập nhật ESP
function ESP:UpdateESP()
    for player, espData in pairs(self.Highlighters) do
        local character = player.Character
        
        -- Kiểm tra nếu character đã thay đổi (respawn)
        if character ~= espData.character then
            self:RemoveESP(player)
            self:CreateESP(player)
            continue
        end
        
        if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("Head") then
            local humanoid = character.Humanoid
            local head = character.Head
            
            -- Kiểm tra player còn sống
            local isAlive = self:IsPlayerAlive(player)
            
            -- Kiểm tra khoảng cách
            local distance = (head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
            local withinDistance = distance <= self.MaxDistance
            
            -- KIỂM TRA TEAM - QUAN TRỌNG
            local isEnemyTeam = true
            if self.TeamCheck then
                -- Nếu bật Team Check, chỉ hiển thị enemy
                if player.Team and game.Players.LocalPlayer.Team then
                    isEnemyTeam = (player.Team ~= game.Players.LocalPlayer.Team)
                else
                    isEnemyTeam = true -- Nếu không có team, hiển thị tất cả
                end
            else
                -- Nếu tắt Team Check, hiển thị tất cả player
                isEnemyTeam = true
            end
            
            -- Quyết định hiển thị ESP
            local shouldShow = isAlive and withinDistance and isEnemyTeam
            
            -- Cập nhật trạng thái hiển thị
            if espData.highlighter then
                espData.highlighter.Enabled = shouldShow
            end
            if espData.nameBillboard then
                espData.nameBillboard.Enabled = shouldShow
            end
            if espData.infoBillboard then
                espData.infoBillboard.Enabled = shouldShow
            end
            
            if shouldShow then
                -- Cập nhật màu
                if espData.highlighter then
                    espData.highlighter.FillColor = self.ChamColor
                    espData.highlighter.OutlineColor = self.ChamColor
                end
                
                -- Cập nhật text màu
                if espData.nameBillboard then
                    espData.nameBillboard.NameText.TextColor3 = self.TextColor
                end
                if espData.infoBillboard then
                    espData.infoBillboard.InfoText.TextColor3 = self.TextColor
                end
                
                -- Cập nhật thông tin
                local info = ""
                
                if self.ShowDistance then
                    info = string.format("[%d]", math.floor(distance))
                end
                
                if self.ShowHealth then
                    local health = math.floor(humanoid.Health)
                    local maxHealth = math.floor(humanoid.MaxHealth)
                    if self.ShowDistance then
                        info = info .. string.format(" %d/%d", health, maxHealth)
                    else
                        info = string.format("%d/%d", health, maxHealth)
                    end
                end
                
                if espData.infoBillboard then
                    espData.infoBillboard.InfoText.Text = info
                end
            end
            
        else
            -- Character không tồn tại, xóa ESP
            self:RemoveESP(player)
        end
    end
end

-- Bật/tắt ESP
function ESP:ToggleESP(value)
    self.Enabled = value
    
    if value then
        -- Tạo ESP cho tất cả players hiện có
        for _, player in pairs(game.Players:GetPlayers()) do
            spawn(function()
                self:CreateESP(player)
            end)
        end
        
        -- Kết nối sự kiện player mới
        game.Players.PlayerAdded:Connect(function(player)
            spawn(function()
                wait(2)
                self:CreateESP(player)
            end)
        end)
        
        -- Kết nối sự kiện player rời
        game.Players.PlayerRemoving:Connect(function(player)
            self:RemoveESP(player)
        end)
        
        -- Chạy update loop
        local renderConnection
        renderConnection = game:GetService("RunService").RenderStepped:Connect(function()
            if not self.Enabled then
                renderConnection:Disconnect()
                return
            end
            self:UpdateESP()
        end)
        
    else
        -- Xóa tất cả ESP
        for player, _ in pairs(self.Highlighters) do
            self:RemoveESP(player)
        end
        self.Highlighters = {}
    end
end

-- Toggle ESP
local ESPToggle = Visuals:CreateToggle({
    Name = "Chams",
    CurrentValue = false, -- ĐẶT THÀNH false
    Flag = "ESPToggle",
    Callback = function(Value)
        ESP:ToggleESP(Value)
    end
})

-- Toggle Team Check - ĐÃ CÓ SẴN NHƯNG TÔI THÊM MÔ TẢ RÕ HƠN
local ESPTeamCheck = Visuals:CreateToggle({
    Name = "Team Check",
    CurrentValue = false, -- ĐẶT THÀNH false
    Flag = "ESPTeamCheck",
    Callback = function(Value)
        ESP.TeamCheck = Value
        -- Cập nhật ngay lập tức khi thay đổi
        if ESP.Enabled then
            ESP:UpdateESP()
        end
    end
})

-- Toggle Show Distance
local ESPDistance = Visuals:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(Value)
        ESP.ShowDistance = Value
    end
})

-- Toggle Show Health
local ESPHealth = Visuals:CreateToggle({
    Name = "Show Health",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(Value)
        ESP.ShowHealth = Value
    end
})

-- Slider khoảng cách tối đa
local ESPDistanceSlider = Visuals:CreateSlider({
    Name = "Max Distance",
    Range = {50, 1000},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 500,
    Flag = "ESPDistanceSlider",
    Callback = function(Value)
        ESP.MaxDistance = Value
    end
})

-- Color Picker Chams Color
local ESPChamColor = Visuals:CreateColorPicker({
    Name = "Chams Color",
    Color = Color3.fromRGB(255, 165, 0),
    Flag = "ESPChamColor",
    Callback = function(Color)
        ESP.ChamColor = Color
    end
})

-- Color Picker Text Color
local ESPTextColor = Visuals:CreateColorPicker({
    Name = "Text Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPTextColor",
    Callback = function(Color)
        ESP.TextColor = Color
    end
})

---------------------------------------------------------GUN MOD-----------------------------------
-- Biến toàn cục để lưu trữ trạng thái và giá trị gốc
getgenv().WeaponMod = {
    InfAmmo = false, -- ĐẶT THÀNH false
    FireRate = false, -- ĐẶT THÀNH false
    NoRecoil = false, -- ĐẶT THÀNH false
    NoSpread = false, -- ĐẶT THÀNH false
    HighDamage = false, -- ĐẶT THÀNH false
    FastReload = false, -- ĐẶT THÀNH false
    OriginalAttributes = {},
    Connections = {}
}

-- Hàm áp dụng các chỉnh sửa vũ khí
local function applyWeaponModifications(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Lưu giá trị gốc nếu chưa có
    if not getgenv().WeaponMod.OriginalAttributes[tool] then
        getgenv().WeaponMod.OriginalAttributes[tool] = {}
        local attributes = {
            "_ammo", "rateOfFire", "recoilMax", "recoilMin", "spread", 
            "reloadTime", "magazineSize", "damage", "spreadADS"
        }
        
        for _, attr in pairs(attributes) do
            local value = tool:GetAttribute(attr)
            if value ~= nil then
                getgenv().WeaponMod.OriginalAttributes[tool][attr] = value
            end
        end
    end
    
    -- Áp dụng các chỉnh sửa
    local mods = getgenv().WeaponMod
    
    -- Vô hạn đạn
    if mods.InfAmmo then
        pcall(function() tool:SetAttribute("_ammo", 999999) end)
        pcall(function() tool:SetAttribute("magazineSize", 999999) end)
    else
        local original = getgenv().WeaponMod.OriginalAttributes[tool]
        if original and original["_ammo"] then
            pcall(function() tool:SetAttribute("_ammo", original["_ammo"]) end)
        end
        if original and original["magazineSize"] then
            pcall(function() tool:SetAttribute("magazineSize", original["magazineSize"]) end)
        end
    end
    
    -- Tốc độ bắn
    if mods.FireRate then
        pcall(function() tool:SetAttribute("rateOfFire", 999999) end)
    else
        local original = getgenv().WeaponMod.OriginalAttributes[tool]
        if original and original["rateOfFire"] then
            pcall(function() tool:SetAttribute("rateOfFire", original["rateOfFire"]) end)
        end
    end
    
    -- Không giật
    if mods.NoRecoil then
        pcall(function() tool:SetAttribute("recoilMax", Vector2.new(0, 0)) end)
        pcall(function() tool:SetAttribute("recoilMin", Vector2.new(0, 0)) end)
    else
        local original = getgenv().WeaponMod.OriginalAttributes[tool]
        if original and original["recoilMax"] then
            pcall(function() tool:SetAttribute("recoilMax", original["recoilMax"]) end)
        end
        if original and original["recoilMin"] then
            pcall(function() tool:SetAttribute("recoilMin", original["recoilMin"]) end)
        end
    end
    
    -- Không spread
    if mods.NoSpread then
        pcall(function() tool:SetAttribute("spread", 0) end)
        pcall(function() tool:SetAttribute("spreadADS", 0) end)
    else
        local original = getgenv().WeaponMod.OriginalAttributes[tool]
        if original and original["spread"] then
            pcall(function() tool:SetAttribute("spread", original["spread"]) end)
        end
        if original and original["spreadADS"] then
            pcall(function() tool:SetAttribute("spreadADS", original["spreadADS"]) end)
        end
    end
    
    -- Sát thương cao
    if mods.HighDamage then
        pcall(function() tool:SetAttribute("damage", 999999) end)
    else
        local original = getgenv().WeaponMod.OriginalAttributes[tool]
        if original and original["damage"] then
            pcall(function() tool:SetAttribute("damage", original["damage"]) end)
        end
    end
    
    -- Reload nhanh
    if mods.FastReload then
        pcall(function() tool:SetAttribute("reloadTime", 0) end)
    else
        local original = getgenv().WeaponMod.OriginalAttributes[tool]
        if original and original["reloadTime"] then
            pcall(function() tool:SetAttribute("reloadTime", original["reloadTime"]) end)
        end
    end
end

-- Hàm kiểm tra và áp dụng mod khi có vũ khí mới
local function setupWeaponMonitoring()
    local player = game.Players.LocalPlayer
    
    -- Kết nối sự kiện khi character thay đổi
    local charConnection = player.CharacterAdded:Connect(function(character)
        -- Kết nối sự kiện khi tool được thêm vào character
        local toolConnection = character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.5) -- Chờ tool được setup
                applyWeaponModifications(child)
            end
        end)
        
        table.insert(getgenv().WeaponMod.Connections, toolConnection)
        
        -- Kiểm tra tool hiện tại nếu có
        task.wait(1)
        local tool = character:FindFirstChildWhichIsA("Tool")
        if tool then
            applyWeaponModifications(tool)
        end
    end)
    
    table.insert(getgenv().WeaponMod.Connections, charConnection)
    
    -- Áp dụng ngay nếu đã có character
    if player.Character then
        local tool = player.Character:FindFirstChildWhichIsA("Tool")
        if tool then
            task.wait(1)
            applyWeaponModifications(tool)
        end
    end
end

-- Hàm ngắt tất cả kết nối
local function disconnectAll()
    for _, connection in ipairs(getgenv().WeaponMod.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    getgenv().WeaponMod.Connections = {}
end

local InfAmmoToggle = Gunmod:CreateToggle({
   Name = "Inf Ammo",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "InfAmmoToggle",
   Callback = function(Value)
      getgenv().WeaponMod.InfAmmo = Value
      local tool = game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
      if tool then
          applyWeaponModifications(tool)
      end
   end,
})

-- Toggle Tốc Độ Bắn
local FireRateToggle = Gunmod:CreateToggle({
   Name = "Inf Fire Rate",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "FireRateToggle",
   Callback = function(Value)
      getgenv().WeaponMod.FireRate = Value
      local tool = game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
      if tool then
          applyWeaponModifications(tool)
      end
   end,
})

-- Toggle Không Giật
local NoRecoilToggle = Gunmod:CreateToggle({
   Name = "No Recoil",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "NoRecoilToggle",
   Callback = function(Value)
      getgenv().WeaponMod.NoRecoil = Value
      local tool = game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
      if tool then
          applyWeaponModifications(tool)
      end
   end,
})

-- Toggle Không Spread
local NoSpreadToggle = Gunmod:CreateToggle({
   Name = "No Spread",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "NoSpreadToggle",
   Callback = function(Value)
      getgenv().WeaponMod.NoSpread = Value
      local tool = game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
      if tool then
          applyWeaponModifications(tool)
      end
   end,
})

-- Toggle Sát Thương Cao
local HighDamageToggle = Gunmod:CreateToggle({
   Name = "High Damage",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "HighDamageToggle",
   Callback = function(Value)
      getgenv().WeaponMod.HighDamage = Value
      local tool = game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
      if tool then
          applyWeaponModifications(tool)
      end
   end,
})

-- Toggle Reload Nhanh
local FastReloadToggle = Gunmod:CreateToggle({
   Name = "Fast Reload",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "FastReloadToggle",
   Callback = function(Value)
      getgenv().WeaponMod.FastReload = Value
      local tool = game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
      if tool then
          applyWeaponModifications(tool)
      end
   end,
})

-- Toggle tổng để bật/tắt tất cả
local AllModsToggle = Gunmod:CreateToggle({
   Name = "All Weapon Mods",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "AllModsToggle",
   Callback = function(Value)
      if Value then
         -- Bật tất cả
         getgenv().WeaponMod.InfAmmo = true
         getgenv().WeaponMod.FireRate = true
         getgenv().WeaponMod.NoRecoil = true
         getgenv().WeaponMod.NoSpread = true
         getgenv().WeaponMod.HighDamage = true
         getgenv().WeaponMod.FastReload = true
         
         -- Cập nhật UI
         InfAmmoToggle:Set(true)
         FireRateToggle:Set(true)
         NoRecoilToggle:Set(true)
         NoSpreadToggle:Set(true)
         HighDamageToggle:Set(true)
         FastReloadToggle:Set(true)
         
         -- Thiết lập monitoring
         disconnectAll()
         setupWeaponMonitoring()
      else
         -- Tắt tất cả
         getgenv().WeaponMod.InfAmmo = false
         getgenv().WeaponMod.FireRate = false
         getgenv().WeaponMod.NoRecoil = false
         getgenv().WeaponMod.NoSpread = false
         getgenv().WeaponMod.HighDamage = false
         getgenv().WeaponMod.FastReload = false
         
         -- Cập nhật UI
         InfAmmoToggle:Set(false)
         FireRateToggle:Set(false)
         NoRecoilToggle:Set(false)
         NoSpreadToggle:Set(false)
         HighDamageToggle:Set(false)
         FastReloadToggle:Set(false)
         
         -- Khôi phục vũ khí hiện tại về mặc định
         local player = game.Players.LocalPlayer
         if player.Character then
             local tool = player.Character:FindFirstChildWhichIsA("Tool")
             if tool and getgenv().WeaponMod.OriginalAttributes[tool] then
                 for attr, value in pairs(getgenv().WeaponMod.OriginalAttributes[tool]) do
                     pcall(function() tool:SetAttribute(attr, value) end)
                 end
             end
         end
         
         -- Ngắt kết nối
         disconnectAll()
      end
   end,
})

-- Tự động thiết lập monitoring khi script chạy
task.wait(1)
setupWeaponMonitoring()

----------------------------------Silent aim-----------------------------------------
-- SILENT AIM WITH UI INTEGRATION
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Tìm ShootEvent
local ShootEvent
local function findShootEvent()
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if eventsFolder then
        ShootEvent = eventsFolder:FindFirstChild("Shoot")
    end
    return ShootEvent ~= nil
end

-- Đợi game load
repeat
    wait(1)
until findShootEvent()

-- Biến cấu hình
local SilentAim = {
    Enabled = false, -- Mặc định tắt
    FOV = 100,
    Target = nil,
    ShowFOV = false, -- ĐẶT THÀNH false
    ShowTracer = false, -- ĐẶT THÀNH false
    TeamCheck = false, -- ĐẶT THÀNH false
    VisibleCheck = false
}

-- Tạo FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = SilentAim.ShowFOV
FOVCircle.Radius = SilentAim.FOV
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 1
FOVCircle.Filled = false

-- Tạo Tracer Line
local TracerLine = Drawing.new("Line")
TracerLine.Visible = false
TracerLine.Color = Color3.fromRGB(0, 255, 0)
TracerLine.Thickness = 2
TracerLine.Transparency = 1

-- Tạo Target Text
local TargetText = Drawing.new("Text")
TargetText.Visible = false
TargetText.Color = Color3.fromRGB(255, 255, 0)
TargetText.Size = 16
TargetText.Center = true
TargetText.Outline = true
TargetText.Font = 2

-- Kiểm tra enemy
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not SilentAim.TeamCheck then return true end
    if not LocalPlayer.Team then return true end
    if not player.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

-- Tìm target gần nhất
local function getClosestTarget()
    local closest = nil
    local closestDist = SilentAim.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                local head = char:FindFirstChild("Head")
                local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
                
                local targetPart = head or humanoidRootPart
                
                if humanoid and targetPart and humanoid.Health > 0 then
                    local success, screenPos, onScreen = pcall(function()
                        return Camera:WorldToViewportPoint(targetPart.Position)
                    end)
                    
                    if success and onScreen then
                        local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                        local dist = (mousePos - targetPos).Magnitude
                        
                        if dist < closestDist then
                            closestDist = dist
                            closest = {
                                Player = player,
                                Character = char,
                                Humanoid = humanoid,
                                Head = head,
                                HumanoidRootPart = humanoidRootPart,
                                Position = targetPart.Position,
                                ScreenPos = targetPos,
                                Distance = dist
                            }
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- Cập nhật tracer
local function updateTracer()
    if not SilentAim.Target or not SilentAim.ShowTracer then
        TracerLine.Visible = false
        TargetText.Visible = false
        return
    end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Cập nhật tracer line
    TracerLine.From = screenCenter
    TracerLine.To = SilentAim.Target.ScreenPos
    TracerLine.Visible = true
    
    -- Cập nhật target text
    TargetText.Text = SilentAim.Target.Player.Name .. " (" .. math.floor(SilentAim.Target.Distance) .. ")"
    TargetText.Position = SilentAim.Target.ScreenPos + Vector2.new(0, -35)
    TargetText.Visible = true
    
    -- Đổi màu theo trạng thái
    if mouseDown then
        TracerLine.Color = Color3.fromRGB(255, 0, 0)
        TargetText.Color = Color3.fromRGB(255, 0, 0)
    else
        TracerLine.Color = Color3.fromRGB(0, 255, 0)
        TargetText.Color = Color3.fromRGB(255, 255, 0)
    end
end

-- Bắn vào target
local function shootAtTarget(target)
    if not target then return end
    
    local localChar = LocalPlayer.Character
    if not localChar then return end
    
    local tool = localChar:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    -- Tính hướng bắn
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin).Unit
    local cf = CFrame.new(origin, origin + direction)
    
    -- Tạo arguments
    local args = {
        os.clock(),
        tool,
        cf,
        true,
        {
            ["1"] = {
                target.Humanoid,
                false,
                true,
                100
            }
        }
    }
    
    -- Bắn
    local success, err = pcall(function()
        ShootEvent:FireServer(unpack(args))
    end)
    
    if success then
    else
    end
end

-- Input handling
local mouseDown = false

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = false
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    -- Update FOV position
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Find target (chỉ khi silent aim enabled)
    if SilentAim.Enabled then
        SilentAim.Target = getClosestTarget()
        
        -- Update tracer
        updateTracer()
        
        -- Update FOV color
        if SilentAim.Target then
            FOVCircle.Color = Color3.fromRGB(0, 255, 0)
        else
            FOVCircle.Color = Color3.fromRGB(255, 0, 0)
        end
        
        -- Shoot if mouse down and target exists
        if mouseDown and SilentAim.Target then
            shootAtTarget(SilentAim.Target)
        end
    else
        -- Tắt visual khi silent aim disabled
        SilentAim.Target = nil
        TracerLine.Visible = false
        TargetText.Visible = false
        FOVCircle.Color = Color3.fromRGB(255, 0, 0)
    end
end)



-- Toggle cho Silent Aim
local Toggle = Silent:CreateToggle({
   Name = "Silent Aim",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "SilentAimToggle",
   Callback = function(Value)
        SilentAim.Enabled = Value
        FOVCircle.Visible = Value and SilentAim.ShowFOV
        if not Value then
            TracerLine.Visible = false
            TargetText.Visible = false
        end
   end,
})

-- Slider cho kích thước FOV Circle
local Slider = Silent:CreateSlider({
   Name = "Silent Aim FOV",
   Range = {50, 300},
   Increment = 10,
   Suffix = "Radius",
   CurrentValue = SilentAim.FOV,
   Flag = "SilentAimFOV",
   Callback = function(Value)
        SilentAim.FOV = Value
        FOVCircle.Radius = Value
   end,
})

-- Toggle cho Tracer Line
local TracerToggle = Silent:CreateToggle({
   Name = "Show Tracer Line",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "TracerToggle",
   Callback = function(Value)
        SilentAim.ShowTracer = Value
        TracerLine.Visible = Value and SilentAim.Target ~= nil and SilentAim.Enabled
        TargetText.Visible = Value and SilentAim.Target ~= nil and SilentAim.Enabled
   end,
})

-- Toggle cho FOV Circle
local FOVToggle = Silent:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "FOVToggle",
   Callback = function(Value)
        SilentAim.ShowFOV = Value
        FOVCircle.Visible = Value and SilentAim.Enabled
   end,
})

-- Toggle cho Team Check
local TeamCheckToggle = Silent:CreateToggle({
   Name = "Team Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "TeamCheckToggle",
   Callback = function(Value)
        SilentAim.TeamCheck = Value
   end,
})

---------------------------------------------------------------------KILL ALLLLLLLLLL----------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AutoFarmKill = {
    Enabled = false, -- ĐẶT THÀNH false
    TeamCheck = false, -- ĐẶT THÀNH false
    FollowDistance = 10,
    MovementSpeed = 2,
    CheckForcefield = false -- ĐẶT THÀNH false
}

-- Hàm kiểm tra team
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not AutoFarmKill.TeamCheck then return true end
    if not LocalPlayer.Team then return true end
    if not player.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

-- Hàm kiểm tra player có an toàn để điều khiển không
local function isSafeToControl(player)
    if not player then return false end
    if not player.Character then return false end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then return false end
    if humanoid.Health <= 0 then return false end
    
    -- KIỂM TRA FORCEFIELD
    if AutoFarmKill.CheckForcefield then
        local forcefield = character:FindFirstChildOfClass("ForceField")
        if forcefield then
            return false -- Có forcefield, không teleport
        end
    end
    
    return true
end

-- Hàm tính vị trí theo hướng aim
local function getAimPosition()
    if not LocalPlayer.Character then return nil end
    
    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    
    -- Lấy hướng nhìn từ camera (aim direction)
    local cameraCFrame = Camera.CFrame
    local aimDirection = cameraCFrame.LookVector
    
    -- Tính vị trí trước mặt theo hướng aim
    local aimPosition = cameraCFrame.Position + (aimDirection * AutoFarmKill.FollowDistance)
    
    return aimPosition
end

-- Hàm teleport enemy tới vị trí aim (KHÔNG GIỚI HẠN KHOẢNG CÁCH)
local function teleportEnemyToAim(player)
    if not AutoFarmKill.Enabled then return end
    if not isEnemy(player) then return end
    if not isSafeToControl(player) then return end
    if not LocalPlayer.Character then return end
    
    local aimPosition = getAimPosition()
    if not aimPosition then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- TELEPORT TỪ BẤT KỲ ĐÂU TRÊN MAP (không check distance)
    pcall(function()
        humanoidRootPart.CFrame = CFrame.new(aimPosition)
    end)
end

-- Hàm teleport TOÀN BỘ ENEMY TRÊN MAP
local function teleportAllEnemiesFromMap()
    if not AutoFarmKill.Enabled then return end
    
    local aimPosition = getAimPosition()
    if not aimPosition then return end
    
    local teleportedCount = 0
    local blockedCount = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) then
            if isSafeToControl(player) then
                local humanoidRootPart = player.Character.HumanoidRootPart
                
                pcall(function()
                    humanoidRootPart.CFrame = CFrame.new(aimPosition)
                    teleportedCount = teleportedCount + 1
                end)
            else
                blockedCount = blockedCount + 1
            end
        end
    end
    
    if teleportedCount > 0 then
    end
    if blockedCount > 0 then
    end
end

-- Hàm di chuyển enemy theo aim (cho enemy đã được teleport về)
local function moveEnemyWithAim(player)
    if not AutoFarmKill.Enabled then return end
    if not isEnemy(player) then return end
    if not isSafeToControl(player) then return end
    if not LocalPlayer.Character then return end
    
    local aimPosition = getAimPosition()
    if not aimPosition then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Tính hướng di chuyển
    local currentPosition = humanoidRootPart.Position
    local direction = (aimPosition - currentPosition).Unit
    
    -- Di chuyển enemy tới vị trí aim
    local newPosition = currentPosition + (direction * AutoFarmKill.MovementSpeed)
    
    -- Cập nhật vị trí
    pcall(function()
        humanoidRootPart.CFrame = CFrame.new(newPosition)
    end)
end

-- Vòng lặp chính - TP TOÀN BỘ MAP
local MainLoop
local function startAutoFarmKill()
    if MainLoop then
        MainLoop:Disconnect()
        MainLoop = nil
    end
    
    -- Đầu tiên teleport TOÀN BỘ ENEMY từ MAP
    teleportAllEnemiesFromMap()
    
    -- Sau đó giữ chúng ở vị trí aim
    MainLoop = RunService.Heartbeat:Connect(function()
        if not AutoFarmKill.Enabled then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if isEnemy(player) then
                if isSafeToControl(player) then
                    moveEnemyWithAim(player)
                end
            end
        end
    end)
end


-- Toggle chính
local AutoFarmKillToggle = Killall:CreateToggle({
   Name = "Auto Farm Kill",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "AutoFarmKillToggle",
   Callback = function(Value)
        AutoFarmKill.Enabled = Value
        
        if Value then
            startAutoFarmKill()
        else
            if MainLoop then
                MainLoop:Disconnect()
                MainLoop = nil
            end
        end
   end,
})

-- Toggle Team Check
local TeamCheckToggle = Killall:CreateToggle({
   Name = "Team Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "TeamCheckToggle",
   Callback = function(Value)
        AutoFarmKill.TeamCheck = Value
   end,
})

-- Toggle Forcefield Check
local ForcefieldCheckToggle = Killall:CreateToggle({
   Name = "Forcefield Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "ForcefieldCheckToggle",
   Callback = function(Value)
        AutoFarmKill.CheckForcefield = Value
        if Value then
        else
        end
   end,
})

-- Slider khoảng cách
local FollowDistanceSlider = Killall:CreateSlider({
   Name = "Follow Distance",
   Range = {5, 30},
   Increment = 1,
   Suffix = "studs",
   CurrentValue = 10,
   Flag = "FollowDistanceSlider",
   Callback = function(Value)
        AutoFarmKill.FollowDistance = Value
   end,
})

-------------------------------------------------------------------MOBILEEEEE AIMBOTTTTTT----------------------------------------------------
-- MOBILE AIMBOT SCRIPT WITH DEATH CHECK & DISTANCE SORTING
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Biến toàn cục cho aimbot mobile
if not _G.MobileAimbotData then
    _G.MobileAimbotData = {
        connections = {},
        drawings = {},
        settings = {
            enabled = false, -- ĐẶT THÀNH false
            teamCheck = false, -- ĐẶT THÀNH false
            wallCheck = false,
            fovSize = 100,
            fovColor = Color3.fromRGB(255, 255, 255),
            smoothness = 0.95,
            deathCheck = false -- ĐẶT THÀNH false
        }
    }
end

-- Hàm cleanup
local function cleanupMobileAimbot()
    for _, connection in pairs(_G.MobileAimbotData.connections) do
        connection:Disconnect()
    end
    for _, drawing in pairs(_G.MobileAimbotData.drawings) do
        drawing:Remove()
    end
    _G.MobileAimbotData.connections = {}
    _G.MobileAimbotData.drawings = {}
end

-- Hàm kiểm tra player còn sống
local function isPlayerAlive(player)
    if not _G.MobileAimbotData.settings.deathCheck then
        return true -- Nếu tắt death check thì coi như sống
    end
    
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    return humanoid.Health > 0
end

-- Wall check function
local function checkWall(targetCharacter)
    if not _G.MobileAimbotData.settings.wallCheck then
        return false
    end
    
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not targetHead then return true end

    local origin = Camera.CFrame.Position
    local direction = (targetHead.Position - origin).unit * (targetHead.Position - origin).magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return raycastResult and raycastResult.Instance ~= nil
end

-- Team check function
local function checkTeam(player)
    if not _G.MobileAimbotData.settings.teamCheck then
        return false
    end
    
    if player.Team == LocalPlayer.Team then
        return true
    end
    return false
end

-- Get target function với sắp xếp từ GẦN đến XA
local function getMobileTarget()
    local targets = {} -- Lưu tất cả target hợp lệ
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not checkTeam(player) then
            -- KIỂM TRA PLAYER CÒN SỐNG
            if isPlayerAlive(player) then
                local head = player.Character:FindFirstChild("Head")
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                
                local targetPart = head or humanoidRootPart
                
                if targetPart then
                    local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
                    
                    -- Chỉ xét target trong tầm nhìn
                    if screenPos.Z > 0 then
                        local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        -- Chỉ xét target trong FOV
                        if distance < _G.MobileAimbotData.settings.fovSize then
                            if not checkWall(player.Character) then
                                -- Tính khoảng cách 3D thực tế
                                local realDistance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                                
                                table.insert(targets, {
                                    player = player,
                                    part = targetPart,
                                    screenDistance = distance,
                                    realDistance = realDistance,
                                    screenPos = Vector2.new(screenPos.X, screenPos.Y)
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- SẮP XẾP TARGET TỪ GẦN ĐẾN XA (theo khoảng cách thực)
    table.sort(targets, function(a, b)
        return a.realDistance < b.realDistance
    end)
    
    -- Trả về target gần nhất (nếu có)
    if #targets > 0 then
        return targets[1].player, targets[1].part
    end
    
    return nil, nil
end

-- Get all targets info for debug
local function getAllTargetsInfo()
    local targets = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not checkTeam(player) then
            if isPlayerAlive(player) then
                local head = player.Character:FindFirstChild("Head")
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                
                local targetPart = head or humanoidRootPart
                
                if targetPart then
                    local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
                    
                    if screenPos.Z > 0 then
                        local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        local realDistance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                        
                        if screenDistance < _G.MobileAimbotData.settings.fovSize then
                            if not checkWall(player.Character) then
                                table.insert(targets, {
                                    player = player,
                                    name = player.Name,
                                    realDistance = math.floor(realDistance),
                                    screenDistance = math.floor(screenDistance),
                                    health = player.Character.Humanoid.Health
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sắp xếp theo khoảng cách
    table.sort(targets, function(a, b)
        return a.realDistance < b.realDistance
    end)
    
    return targets
end

-- Aim function
local function mobileAimAt(target, part)
    if target and part then
        local velocity = target.Character.HumanoidRootPart.Velocity
        local predictedPosition = part.Position + (velocity * 0.065)
        local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.MobileAimbotData.settings.smoothness)
    end
end

-- Main mobile aimbot loop
local function startMobileAimbot()
    cleanupMobileAimbot()
    
    -- FOV Circle - Đặt ở giữa màn hình
    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.Radius = _G.MobileAimbotData.settings.fovSize
    fovCircle.Filled = false
    fovCircle.Color = _G.MobileAimbotData.settings.fovColor
    fovCircle.Visible = _G.MobileAimbotData.settings.enabled
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    table.insert(_G.MobileAimbotData.drawings, fovCircle)

    -- Render loop cho mobile (LUÔN AIM KHÔNG CẦN GIỮ)
    local renderConnection = RunService.RenderStepped:Connect(function()
        if not _G.MobileAimbotData.settings.enabled then return end
        
        -- Cập nhật FOV circle
        fovCircle.Radius = _G.MobileAimbotData.settings.fovSize
        fovCircle.Color = _G.MobileAimbotData.settings.fovColor
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Visible = true
        
        -- LUÔN AIM TỰ ĐỘNG vào target GẦN NHẤT
        local target, part = getMobileTarget()
        if target and part then
            mobileAimAt(target, part)
        end
    end)

    table.insert(_G.MobileAimbotData.connections, renderConnection)
end


-- Toggle Mobile Aimbot
local MobileAimbotToggle = Mobile:CreateToggle({
   Name = "Mobile Aimbot",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "MobileAimbotToggle",
   Callback = function(Value)
        _G.MobileAimbotData.settings.enabled = Value
        
        if Value then
            startMobileAimbot()
        else
            cleanupMobileAimbot()
        end
   end,
})

-- Toggle Team Check cho Mobile
local MobileTeamCheck = Mobile:CreateToggle({
   Name = "Team Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "MobileTeamCheck",
   Callback = function(Value)
        _G.MobileAimbotData.settings.teamCheck = Value
   end,
})

-- Toggle Wall Check cho Mobile
local MobileWallCheck = Mobile:CreateToggle({
   Name = "Wall Check",
   CurrentValue = false,
   Flag = "MobileWallCheck",
   Callback = function(Value)
        _G.MobileAimbotData.settings.wallCheck = Value
   end,
})

-- Toggle Death Check cho Mobile
local MobileDeathCheck = Mobile:CreateToggle({
   Name = "Death Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "MobileDeathCheck",
   Callback = function(Value)
        _G.MobileAimbotData.settings.deathCheck = Value
        if Value then
        else
        end
   end,
})

-- Slider độ to của circle cho Mobile
local MobileFovSizeSlider = Mobile:CreateSlider({
   Name = "FOV Size",
   Range = {10, 500},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 100,
   Flag = "MobileFovSizeSlider",
   Callback = function(Value)
        _G.MobileAimbotData.settings.fovSize = Value
   end,
})

-- Color Picker cho Mobile FOV
local MobileFovColorPicker = Mobile:CreateColorPicker({
   Name = "FOV Color",
   Color = Color3.fromRGB(255, 255, 255),
   Flag = "MobileFovColorPicker",
   Callback = function(Color)
        _G.MobileAimbotData.settings.fovColor = Color
   end,
})

-- Slider smoothness cho Mobile
local MobileSmoothSlider = Mobile:CreateSlider({
   Name = "Smoothness",
   Range = {1, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 5,
   Flag = "MobileSmoothSlider",
   Callback = function(Value)
        _G.MobileAimbotData.settings.smoothness = 1 - (Value / 100)
   end,
})

---------------------------------------------------------MISC--------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình hitbox
local HitboxSettings = {
    Enabled = false, -- ĐẶT THÀNH false
    TeamCheck = false, -- ĐẶT THÀNH false
    HeadSize = 5, -- Kích thước head hitbox mặc định
    Transparency = 0.5,
    BodyParts = {"Head"}
}

-- Lưu trữ kích thước gốc
local OriginalSizes = {}

-- Hàm kiểm tra team
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not HitboxSettings.TeamCheck then return true end
    if not LocalPlayer.Team then return true end
    if not player.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

-- Hàm thay đổi kích thước hitbox
local function resizeBodyPart(targetPlayer, partName, size)
    if targetPlayer == LocalPlayer then return end
    if HitboxSettings.TeamCheck and not isEnemy(targetPlayer) then return end
    
    local character = targetPlayer.Character
    if not character then return end

    local part = character:FindFirstChild(partName)
    if not part then return end

    -- Lưu kích thước gốc
    if not OriginalSizes[part] then
        OriginalSizes[part] = part.Size
    end

    if HitboxSettings.Enabled and size > 0 then
        -- Áp dụng hitbox
        local newSize = math.max(size, 0.1)
        part.Size = Vector3.new(newSize, newSize, newSize)
        part.Transparency = HitboxSettings.Transparency
        part.CanCollide = false
        part.Massless = true
    else
        -- Khôi phục kích thước gốc
        if OriginalSizes[part] then
            part.Size = OriginalSizes[part]
            part.Transparency = 0
            part.CanCollide = true
            part.Massless = false
        end
    end
end

-- Hàm cập nhật hitbox cho tất cả players
local function updateAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        for _, partName in ipairs(HitboxSettings.BodyParts) do
            if HitboxSettings.Enabled then
                resizeBodyPart(player, partName, HitboxSettings.HeadSize)
            else
                resizeBodyPart(player, partName, 0) -- Tắt hitbox
            end
        end
    end
end

-- Hàm xử lý khi player mới join
local function setupPlayerHitbox(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Chờ character load
        for _, partName in ipairs(HitboxSettings.BodyParts) do
            if HitboxSettings.Enabled then
                resizeBodyPart(player, partName, HitboxSettings.HeadSize)
            end
        end
    end)
    
    -- Xử lý character hiện tại
    if player.Character then
        for _, partName in ipairs(HitboxSettings.BodyParts) do
            if HitboxSettings.Enabled then
                resizeBodyPart(player, partName, HitboxSettings.HeadSize)
            end
        end
    end
end

-- Vòng lặp cập nhật hitbox
local HitboxLoop
local function startHitboxSystem()
    if HitboxLoop then
        HitboxLoop:Disconnect()
    end
    
    HitboxLoop = RunService.Heartbeat:Connect(function()
        if HitboxSettings.Enabled then
            updateAllHitboxes()
        end
    end)
end

-- Khởi tạo hệ thống hitbox
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayerHitbox(player)
end

Players.PlayerAdded:Connect(setupPlayerHitbox)



-- Toggle Head Hitbox
local HitboxToggle = Misc:CreateToggle({
   Name = "Head Hitbox",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "HitboxToggle",
   Callback = function(Value)
        HitboxSettings.Enabled = Value
        
        if Value then
            startHitboxSystem()
        else
            if HitboxLoop then
                HitboxLoop:Disconnect()
                HitboxLoop = nil
            end
            -- Khôi phục kích thước gốc cho tất cả players
            updateAllHitboxes()
        end
   end,
})

-- Toggle Team Check cho Hitbox
local HitboxTeamCheck = Misc:CreateToggle({
   Name = "Hitbox Team Check",
   CurrentValue = false, -- ĐẶT THÀNH false
   Flag = "HitboxTeamCheck",
   Callback = function(Value)
        HitboxSettings.TeamCheck = Value
        if Value then
        else
        end
        -- Cập nhật lại hitbox khi thay đổi team check
        if HitboxSettings.Enabled then
            updateAllHitboxes()
        end
   end,
})

-- Slider kích thước head hitbox
local HeadSizeSlider = Misc:CreateSlider({
   Name = "Hitbox Size",
   Range = {1, 20},
   Increment = 1,
   Suffix = "size",
   CurrentValue = 5,
   Flag = "HeadSizeSlider",
   Callback = function(Value)
        HitboxSettings.HeadSize = Value
        
        -- Cập nhật ngay lập tức khi thay đổi size
        if HitboxSettings.Enabled then
            updateAllHitboxes()
        end
   end,
})

-- Slider transparency
local HitboxTransparencySlider = Misc:CreateSlider({
   Name = "Hitbox Transparency",
   Range = {0, 100},
   Increment = 5,
   Suffix = "%",
   CurrentValue = 50,
   Flag = "HitboxTransparencySlider",
   Callback = function(Value)
        HitboxSettings.Transparency = Value / 100
        
        -- Cập nhật ngay lập tức
        if HitboxSettings.Enabled then
            updateAllHitboxes()
        end
   end,
})

local Button = Misc:CreateButton({
   Name = "Better Crosshair",
   Callback = function()
      local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        local Center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local CrosshairLines, LineCount, Radius, LineLength, LineColor = {}, 4, 7, 15, Color3.fromRGB(255,0,0)

        for i = 1, LineCount do
            local line = Drawing.new("Line")
            line.Color = LineColor
            line.Thickness = 2
            line.Visible = true
            table.insert(CrosshairLines, line)
        end

        local Dot = Drawing.new("Circle")
        Dot.Radius = 2
        Dot.Position = Center
        Dot.Color = LineColor
        Dot.Filled = true
        Dot.Visible = true

        local VelocityText = Drawing.new("Text")
        VelocityText.Text = "Scripybara"
        VelocityText.Position = Vector2.new(Center.X - 20, Center.Y + 20)
        VelocityText.Size = 16
        VelocityText.Center = true
        VelocityText.Outline = true
        VelocityText.Color = Color3.new(1,1,1)
        VelocityText.Visible = true
        VelocityText.Font = 2

        local LOLText = Drawing.new("Text")
        LOLText.Text = ".YT"
        LOLText.Position = Vector2.new(Center.X + 35, Center.Y + 20)
        LOLText.Size = 16
        LOLText.Center = true
        LOLText.Outline = true
        LOLText.Color = Color3.fromRGB(255,0,0)
        LOLText.Visible = true
        LOLText.Font = 2

        local angle = 0
        CrosshairConnection = RunService.RenderStepped:Connect(function()
            Center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            for i, line in ipairs(CrosshairLines) do
                local a = angle + (math.pi*2/LineCount)*(i-1)
                local from = Vector2.new(Center.X + math.cos(a) * Radius, Center.Y + math.sin(a) * Radius)
                local to = Vector2.new(Center.X + math.cos(a) * (Radius + LineLength), Center.Y + math.sin(a) * (Radius + LineLength))
                line.From = from
                line.To = to
            end
            Dot.Position = Center
            VelocityText.Position = Vector2.new(Center.X - 20, Center.Y + 20)
            LOLText.Position = Vector2.new(Center.X + 35, Center.Y + 20)
            angle = angle + 0.05
        end)

        CrosshairObjects = {Dot, VelocityText, LOLText}
        for _, line in ipairs(CrosshairLines) do
            table.insert(CrosshairObjects, line)
        end
   end,
})


local Button = Misc:CreateButton({
   Name = "Fix Lag",
   Callback = function()
local function permanentEffectRemoval()
    local removedCount = 0
    local preventedCount = 0
    
    -- CHỈ xóa các effect trong workspace và lighting
    local safeLocations = {workspace, game:GetService("Lighting")}
    
    -- CHỈ xóa các class effect vật lý
    local targetClasses = {
        "ParticleEmitter", "Smoke", "Fire", "Sparkles", 
        "Explosion", "PointLight", "SpotLight"
    }
    
    -- TUYỆT ĐỐI KHÔNG đụng vào các service UI
    local uiServices = {
        game:GetService("StarterGui"),
        game:GetService("StarterPack"), 
        game:GetService("StarterPlayer"),
        game:GetService("CoreGui")
    }
    
    -- Danh sách để theo dõi các instance đã xóa
    local removedInstances = {}
    
    -- Hàm kiểm tra an toàn
    local function isSafeToRemove(object)
        -- Không xóa nếu object trong UI service
        for _, uiService in ipairs(uiServices) do
            if object:IsDescendantOf(uiService) then
                return false
            end
        end
        
        -- Không xóa nếu là UI class
        if object:IsA("ScreenGui") or object:IsA("Frame") or object:IsA("TextLabel") then
            return false
        end
        
        return true
    end
    
    -- Hàm xóa effect
    local function removeEffect(effect)
        if effect and effect.Parent then
            removedInstances[effect] = true
            effect:Destroy()
            removedCount += 1
        end
    end
    
    -- Quét và xóa effects hiện có
    for _, location in ipairs(safeLocations) do
        local function scanAndRemove(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if isSafeToRemove(child) then
                    for _, className in ipairs(targetClasses) do
                        if child:IsA(className) then
                            removeEffect(child)
                            break
                        end
                    end
                end
                
                -- Tiếp tục đệ quy
                scanAndRemove(child)
            end
        end
        
        scanAndRemove(location)
    end
    
    -- Ngăn chặn effects mới được tạo ra
    for _, location in ipairs(safeLocations) do
        location.ChildAdded:Connect(function(child)
            wait(0.1) -- Chờ một chút để đảm bảo object được tạo hoàn chỉnh
            
            if isSafeToRemove(child) then
                for _, className in ipairs(targetClasses) do
                    if child:IsA(className) and not removedInstances[child] then
                        removeEffect(child)
                        preventedCount += 1
                        break
                    end
                end
            end
        end)
    end
    
    -- Kết nối sự kiện respawn để tiếp tục ngăn chặn effects
    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)        
        -- Quét lại để xóa any effects mới xuất hiện
        task.wait(1) -- Chờ 1 giây để các effects load
        for _, location in ipairs(safeLocations) do
            local function rescan(parent)
                for _, child in ipairs(parent:GetChildren()) do
                    if isSafeToRemove(child) then
                        for _, className in ipairs(targetClasses) do
                            if child:IsA(className) and not removedInstances[child] then
                                removeEffect(child)
                                preventedCount += 1
                                break
                            end
                        end
                    end
                    rescan(child)
                end
            end
            rescan(location)
        end
    end)
end

-- Chạy
permanentEffectRemoval()

local ToDisable = {
	Textures = true,
	VisualEffects = true,
	Parts = true,
	Particles = true,
	Sky = true
}

local ToEnable = {
	FullBright = false
}

local Stuff = {}

for _, v in next, game:GetDescendants() do
	if ToDisable.Parts then
		if v:IsA("Part") or v:IsA("Union") or v:IsA("BasePart") then
			v.Material = Enum.Material.SmoothPlastic
			table.insert(Stuff, 1, v)
		end
	end
	
	if ToDisable.Particles then
		if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
			v.Enabled = false
			table.insert(Stuff, 1, v)
		end
	end
	
	if ToDisable.VisualEffects then
		if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
			v.Enabled = false
			table.insert(Stuff, 1, v)
		end
	end
	
	if ToDisable.Textures then
		if v:IsA("Decal") or v:IsA("Texture") then
			v.Texture = ""
			table.insert(Stuff, 1, v)
		end
	end
	
	if ToDisable.Sky then
		if v:IsA("Sky") then
			v.Parent = nil
			table.insert(Stuff, 1, v)
		end
	end
end

game:GetService("TestService"):Message("Effects Disabler Script : Successfully disabled "..#Stuff.." assets / effects. Settings :")

for i, v in next, ToDisable do
	print(tostring(i)..": "..tostring(v))
end

if ToEnable.FullBright then
    local Lighting = game:GetService("Lighting")
    
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    Lighting.FogEnd = math.huge
    Lighting.FogStart = math.huge
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 5
    Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Outlines = true
end

   end,
})
