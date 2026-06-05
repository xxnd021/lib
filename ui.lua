-- Sintonia Roleplay Script
-- Aguarda o jogo carregar completamente
if not game:IsLoaded() then game.Loaded:Wait() end

-- Serviços
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace       = game:GetService("Workspace")
local CoreGui         = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local Lighting        = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Guard: só roda no Sintonia Roleplay
local CidadeSintonia = Workspace:FindFirstChild("CidadeSintonia")
if getgenv().SintoniaScriptRunning or not CidadeSintonia then return end
getgenv().SintoniaScriptRunning = true
pcall(function()
	script.Destroying:Connect(function()
		getgenv().SintoniaScriptRunning = false
	end)
end)

-- Estados
local S = {
	SpeedHack        = false,
	JumpHack         = false,
	NoClip           = false,
	AntiStaff        = false,
	AutoTrash        = false,
	AutoLockPick     = true,
	BypassLow        = true,
	BypassAC         = true,
	Desync           = false,
	EspPlayers       = false,
	EspTeams         = false,
	EspTools         = true,
	EspFriends       = true,
	AimbotEnabled    = false,
	AimbotFovDisplay = false,
	AimbotTarget     = "Head",
	AimbotFOV        = 197.5,
	AimbotSmooth     = 0,
	AutoFish         = false,
	AutoSamu         = false,
	AutoEssence      = false,
	AutoPeca         = false,
	AutoCollect      = false,
	AutoCLRejoin     = false,
	Flying           = false,
	IgnoreProtected  = true,
	IgnoreFriends    = true,
	SelectedLocation = "",
	SelectedVehicleLoc = "",
	SelectedPlayer   = "",
	SelectedCar      = "",
	SelectedItem     = "",
	PullCarLock      = false,
	PullNearLock     = false,
	AutoTrashStamp   = 0,
	AutoFishStamp    = 0,
	AutoPecaStamp    = 0,
}

local AimbotTarget    = nil
local AimbotBodyPart  = nil
local PrevHumStates   = {}
local AutoCollectOrigin = nil
local SamuTarget      = nil
local SamuOrigin      = nil

-- Carrega WindUI
local libraryUrl = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
local ok, result = pcall(function() return loadstring(game:HttpGet(libraryUrl))() end)
if not ok or not result then
	warn("[Sintonia] Falha ao carregar WindUI: " .. tostring(result))
	getgenv().SintoniaScriptRunning = false
	return
end
local WindUI = result

-- Janela principal
local Window = WindUI:CreateWindow({
	Title = "SINTONIA ROLEPLAY",
	Icon = "swords",
	Theme = "Dark",
	Folder = "sintoniaroleplay",
	Resizable = false,
	Transparent = false,
	Size = UDim2.fromOffset(548, 340),
	HideSearchBar = false,
	OpenButton = { Enabled = false },
	Topbar = { Height = 45, ButtonsType = "Default" }
})
Window:Tag({ Title = "V1.0.3", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })
Window:Tag({ Title = "Discord", Icon = "globe", Color = Color3.fromHex("#5865F2"), Border = true })
Window:DisableTopbarButtons({ "Close", "Minimize", "Fullscreen" })

-- FOV Circle
local FovGui   = Instance.new("ScreenGui")
local FovFrame = Instance.new("Frame")
local FovCorner= Instance.new("UICorner")
local FovStroke= Instance.new("UIStroke")
FovGui.Name = HttpService:GenerateGUID(false)
FovGui.Parent = (gethui and gethui()) or CoreGui
FovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FovGui.IgnoreGuiInset = true
if syn and syn.protect_gui then syn.protect_gui(FovGui) end
FovFrame.Parent = FovGui
FovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FovFrame.Size = UDim2.new(0, 395, 0, 395)
FovFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FovFrame.BackgroundTransparency = 1
FovFrame.Visible = false
FovCorner.CornerRadius = UDim.new(1, 0)
FovCorner.Parent = FovFrame
FovStroke.Color = Color3.fromRGB(255, 255, 255)
FovStroke.Thickness = 2
FovStroke.Transparency = 0
FovStroke.Parent = FovFrame

-- Botão mobile
local MobileGui = Instance.new("ScreenGui")
MobileGui.Parent = CoreGui
MobileGui.ResetOnSpawn = false
MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local MobileBtn = Instance.new("ImageButton")
MobileBtn.Parent = MobileGui
MobileBtn.BackgroundTransparency = 1
MobileBtn.Position = UDim2.new(0.85, 0, 0.18, 0)
MobileBtn.Size = UDim2.new(0, 70, 0, 70)
MobileBtn.Image = "rbxassetid://123515164771676"
MobileBtn.Draggable = true
MobileBtn.Active = true
local MobileDragStart = nil
MobileBtn.MouseButton1Down:Connect(function() MobileDragStart = MobileBtn.AbsolutePosition end)
MobileBtn.DragStopped:Connect(function()
	if not MobileDragStart then return end
	local cur = MobileBtn.AbsolutePosition
	local sz  = MobileBtn.AbsoluteSize
	local par = MobileGui.AbsoluteSize
	if (cur - MobileDragStart).Magnitude <= 2 then
		Window:Toggle()
	else
		local cx = math.clamp(cur.X, 0, par.X - sz.X)
		local cy = math.clamp(cur.Y + 75, 0, par.Y - sz.Y)
		MobileBtn.Position = UDim2.new(0, cx, 0, cy)
	end
	MobileDragStart = nil
end)

-- ===================== TABS =====================

-- === WORLD ===
local WorldTab = Window:Tab({ Title = "World", Icon = "earth", Border = true })
WorldTab:Select()

local LocDropdown = WorldTab:Dropdown({
	Title = "Teleports",
	Values = (function()
		local t = {}
		pcall(function()
			if Workspace:FindFirstChild("GPS") and Workspace.GPS:FindFirstChild("Locais") then
				for _, v in pairs(Workspace.GPS.Locais:GetChildren()) do
					if v:IsA("BasePart") then table.insert(t, v.Name) end
				end
			end
		end)
		return t
	end)(),
	Value = "", Multi = false,
	Callback = function(v) S.SelectedLocation = v end
})

WorldTab:Button({
	Title = "Teleport Player To Location",
	Callback = function()
		pcall(function()
			if S.Desync then WindUI:Notify({ Title = "TP Location", Content = "Desync ativo!", Duration = 3, Icon = "alert-triangle" }) return end
			if S.SelectedLocation == "" then return end
			local char = LocalPlayer.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then return end
			local hum = char:FindFirstChild("Humanoid")
			if not hum or hum.Health <= 0 or hum.Sit then return end
			local part = Workspace:FindFirstChild("GPS") and Workspace.GPS:FindFirstChild("Locais") and Workspace.GPS.Locais:FindFirstChild(S.SelectedLocation)
			if part and part:IsA("BasePart") then
				char.HumanoidRootPart.CFrame = CFrame.new(part.Position + Vector3.new(0, 25, 0))
			end
		end)
	end
})

WorldTab:Space()
local ToggleTrash   = WorldTab:Toggle({ Title = "Auto Farm Trash",   Value = false, Callback = function(v) S.AutoTrash   = v end })
local ToggleFish    = WorldTab:Toggle({ Title = "Auto Farm Fish",    Value = false, Callback = function(v) S.AutoFish    = v end })
local ToggleSamu    = WorldTab:Toggle({ Title = "Auto Farm Samu",    Value = false, Callback = function(v) S.AutoSamu    = v end })
local TogglePeca    = WorldTab:Toggle({ Title = "Auto Farm Peça",    Value = false, Callback = function(v) S.AutoPeca    = v end })
local ToggleEssence = WorldTab:Toggle({ Title = "Auto Farm Essence", Value = false, Callback = function(v) S.AutoEssence = v end })

-- === PLAYER ===
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user", Border = true })

local PlayerDropdown = PlayerTab:Dropdown({
	Title = "Players", Values = (function()
		local t = {}
		pcall(function()
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					table.insert(t, p.Name)
				end
			end
		end)
		return t
	end)(),
	Value = "", Multi = false,
	Callback = function(v) S.SelectedPlayer = v end
})

PlayerTab:Button({ Title = "Update Players List", Callback = function()
	pcall(function()
		local t = {}
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(t, p.Name)
			end
		end
		PlayerDropdown:Refresh(#t == 0 and {"None Players"} or t)
		S.SelectedPlayer = ""
		PlayerDropdown:Select("")
	end)
end })

local TpPlayerBtn = PlayerTab:Button({ Title = "Teleport Player To Player", Callback = function()
	pcall(function()
		if S.Desync or S.SelectedPlayer == "" then return end
		local char = LocalPlayer.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local hum = char:FindFirstChild("Humanoid")
		if not hum or hum.Health <= 0 or hum.Sit then return end
		local target = Players:FindFirstChild(S.SelectedPlayer)
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = CFrame.new(target.Character.HumanoidRootPart.Position + Vector3.new(0, 25, 0))
		end
	end)
end })

PlayerTab:Space()
PlayerTab:Toggle({ Title = "Speed Hack",      Value = false, Callback = function(v) S.SpeedHack  = v end })
PlayerTab:Toggle({ Title = "Jump Hack",       Value = false, Callback = function(v) S.JumpHack   = v end })
PlayerTab:Toggle({ Title = "Auto CL",         Value = false, Callback = function(v) S.AutoCLRejoin = v end })
PlayerTab:Toggle({ Title = "No Clip",         Value = false, Callback = function(v) S.NoClip     = v end })
PlayerTab:Toggle({ Title = "Anti-Staff [TP]", Value = false, Callback = function(v) S.AntiStaff  = v end })
PlayerTab:Toggle({ Title = "Flying Mode",     Value = false, Callback = function(v) S.Flying     = v end })

local ToggleDesync = PlayerTab:Toggle({ Title = "Desync Mode", Value = false, Callback = function(v)
	S.Desync = v
	if v then
		ToggleTrash:Set(false);   ToggleTrash:Lock()
		ToggleEssence:Set(false); ToggleEssence:Lock()
		ToggleFish:Set(false);    ToggleFish:Lock()
		ToggleSamu:Set(false);    ToggleSamu:Lock()
		TogglePeca:Set(false);    TogglePeca:Lock()
	else
		ToggleTrash:Unlock(); ToggleEssence:Unlock()
		ToggleFish:Unlock();  ToggleSamu:Unlock()
		TogglePeca:Unlock()
	end
end })

-- === WEAPONS ===
local WeapTab = Window:Tab({ Title = "Weapons", Icon = "swords", Border = true })

WeapTab:Dropdown({ Title = "Aimbot Path", Values = {"Head","Chest"}, Value = "Head", Multi = false,
	Callback = function(v) S.AimbotTarget = v end })

WeapTab:Slider({ Title = "Fov Radius Size", Step = 5, Value = { Min = 80, Max = 500, Default = 395 },
	Callback = function(v)
		S.AimbotFOV = v / 2
		FovFrame.Size = UDim2.new(0, v, 0, v)
	end })

WeapTab:Slider({ Title = "Smoothing Adjust", Step = 0.1, Value = { Min = 0, Max = 0.9, Default = 0 },
	Callback = function(v) S.AimbotSmooth = v end })

WeapTab:Toggle({ Title = "Ignore Friends",   Value = true,  Callback = function(v) S.IgnoreFriends  = v end })
WeapTab:Toggle({ Title = "Ignore Protecteds",Value = true,  Callback = function(v) S.IgnoreProtected = v end })
WeapTab:Toggle({ Title = "Enable Fov Display",Value = false, Callback = function(v) S.AimbotFovDisplay = v end })
WeapTab:Toggle({ Title = "Enable Aimbot",    Value = false, Callback = function(v) S.AimbotEnabled = v end })

WeapTab:Space()
WeapTab:Dropdown({ Title = "Items",
	Values = {"Glock","Balaclava","Micha","Essencia","Tesoura","MiliTec","Dinamite","MichaEletrica","Plastico","Radin"},
	Value = "", Multi = false, Callback = function(v) S.SelectedItem = v end })

local ItemPrices = { Glock=550000, Balaclava=500, Micha=5000, Essencia=1000, Tesoura=400, MiliTec=4000, Dinamite=10000, MichaEletrica=6000, Plastico=400, Radin=1000 }
WeapTab:Button({ Title = "Purchase Selected Item", Callback = function()
	pcall(function()
		if S.SelectedItem ~= "" then
			ReplicatedStorage:WaitForChild("Mercadinho"):WaitForChild("GlobalComprarItem"):FireServer(S.SelectedItem, ItemPrices[S.SelectedItem], 1)
		end
	end)
end })

WeapTab:Button({ Title = "Open Personal Chest", Callback = function()
	pcall(function()
		ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InvRemotes"):WaitForChild("InvRequest"):InvokeServer("SendTransferenciaBauBind","Tira","Essencia",999)
	end)
end })

-- === VISUAL ===
local VisualTab = Window:Tab({ Title = "Visual", Icon = "wallpaper", Border = true })

VisualTab:Space()
VisualTab:Toggle({ Title = "Esp Teams",   Value = false, Callback = function(v) S.EspTeams   = v end })
VisualTab:Toggle({ Title = "Esp Tools",   Value = true,  Callback = function(v) S.EspTools   = v end })
VisualTab:Toggle({ Title = "Esp Friends", Value = true,  Callback = function(v) S.EspFriends = v end })
VisualTab:Toggle({ Title = "Enable Esp",  Value = false, Callback = function(v) S.EspPlayers = v end })

-- === VEHICLES ===
local VehTab = Window:Tab({ Title = "Vehicles", Icon = "car-front", Border = true })

local VehLocDropdown = VehTab:Dropdown({
	Title = "Teleports",
	Values = (function()
		local t = {}
		pcall(function()
			if Workspace:FindFirstChild("GPS") and Workspace.GPS:FindFirstChild("Locais") then
				for _, v in pairs(Workspace.GPS.Locais:GetChildren()) do
					if v:IsA("BasePart") then table.insert(t, v.Name) end
				end
			end
		end)
		return t
	end)(),
	Value = "", Multi = false,
	Callback = function(v) S.SelectedVehicleLoc = v end
})

local TpVehicleBtn = VehTab:Button({ Title = "Teleport Vehicle To Location", Callback = function()
	pcall(function()
		if S.SelectedVehicleLoc == "" then return end
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		if not hum or hum.Health <= 0 then return end
		if not hum.Sit or not hum.SeatPart or not hum.SeatPart:IsA("VehicleSeat") then return end
		local part = Workspace:FindFirstChild("GPS") and Workspace.GPS:FindFirstChild("Locais") and Workspace.GPS.Locais:FindFirstChild(S.SelectedVehicleLoc)
		if not part then return end
		local seat = hum.SeatPart
		local model = seat:FindFirstAncestorOfClass("Model")
		if not model then return end
		local welds = {}
		for _, d in pairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d ~= seat then
				local w = Instance.new("Weld")
				w.Part0 = seat; w.Part1 = d
				w.C0 = seat.CFrame:Inverse() * d.CFrame
				w.Parent = seat
				table.insert(welds, w)
			end
		end
		seat.CFrame = CFrame.new(part.Position + Vector3.new(0, 25, 0)) * (seat.CFrame - seat.Position)
		for _, w in pairs(welds) do w:Destroy() end
	end)
end })

VehTab:Space()
local CarDropdown = VehTab:Dropdown({
	Title = "Cars",
	Values = (function()
		local t = {}
		pcall(function()
			if Workspace:FindFirstChild("CarrosSpawnados") then
				for _, m in pairs(Workspace.CarrosSpawnados:GetChildren()) do
					if m:IsA("Model") then
						local seat = m:FindFirstChildOfClass("VehicleSeat")
						if seat and not seat.Occupant then table.insert(t, m.Name) end
					end
				end
			end
		end)
		return #t == 0 and {"None Cars"} or t
	end)(),
	Value = "", Multi = false,
	Callback = function(v) S.SelectedCar = v end
})

VehTab:Button({ Title = "Update Cars List", Callback = function()
	pcall(function()
		local t = {}
		if Workspace:FindFirstChild("CarrosSpawnados") then
			for _, m in pairs(Workspace.CarrosSpawnados:GetChildren()) do
				if m:IsA("Model") then
					local seat = m:FindFirstChildOfClass("VehicleSeat")
					if seat and not seat.Occupant then table.insert(t, m.Name) end
				end
			end
		end
		CarDropdown:Refresh(#t == 0 and {"None Cars"} or t)
		S.SelectedCar = ""
		CarDropdown:Select("")
	end)
end })

local function BringCar(model)
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum or hum.Health <= 0 or hum.Sit then return end
	local seat = model:FindFirstChildOfClass("VehicleSeat")
	if not seat or seat.Occupant then return end
	local welds = {}
	for _, d in pairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= seat then
			local w = Instance.new("Weld")
			w.Part0 = seat; w.Part1 = d
			w.C0 = seat.CFrame:Inverse() * d.CFrame
			w.Parent = seat
			table.insert(welds, w)
		end
	end
	for i = 0, 1, 0.1 do
		seat.CFrame = (CFrame.new(char.HumanoidRootPart.Position + Vector3.new(0,25,0)) * CFrame.Angles(0,math.rad(seat.Orientation.Y),0)):Lerp(CFrame.new(char.HumanoidRootPart.Position + Vector3.new(0,5,0)), i)
		RunService.Heartbeat:Wait()
	end
	char.HumanoidRootPart.CFrame = seat.CFrame
	for _, w in pairs(welds) do w:Destroy() end
	seat:Sit(hum)
end

local PullSelectedBtn = VehTab:Button({ Title = "Bring Selected Car", Callback = function()
	if S.PullCarLock or S.SelectedCar == "" then return end
	S.PullCarLock = true
	pcall(function()
		local cars = Workspace:FindFirstChild("CarrosSpawnados")
		if cars then
			local m = cars:FindFirstChild(S.SelectedCar)
			if m then BringCar(m) end
		end
	end)
	S.PullCarLock = false
end })

local PullNearBtn = VehTab:Button({ Title = "Bring Nearest Car", Callback = function()
	if S.PullNearLock then return end
	S.PullNearLock = true
	pcall(function()
		local char = LocalPlayer.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then S.PullNearLock = false return end
		local cars = Workspace:FindFirstChild("CarrosSpawnados")
		if not cars then S.PullNearLock = false return end
		local sorted = cars:GetChildren()
		table.sort(sorted, function(a, b)
			local sa = a:FindFirstChildOfClass("VehicleSeat")
			local sb = b:FindFirstChildOfClass("VehicleSeat")
			local da = sa and (char.HumanoidRootPart.Position - sa.Position).Magnitude or math.huge
			local db = sb and (char.HumanoidRootPart.Position - sb.Position).Magnitude or math.huge
			return da < db
		end)
		for _, m in pairs(sorted) do
			if m:IsA("Model") then
				local seat = m:FindFirstChildOfClass("VehicleSeat")
				if seat and not seat.Occupant then BringCar(m) break end
			end
		end
	end)
	S.PullNearLock = false
end })

-- === EXPLOITS ===
local ExploitTab = Window:Tab({ Title = "Exploits", Icon = "bomb", Border = true })
ExploitTab:Toggle({ Title = "Auto LockPick",      Value = true,  Callback = function(v) S.AutoLockPick = v end })
ExploitTab:Toggle({ Title = "Auto Collect [TP]",  Value = false, Callback = function(v) S.AutoCollect  = v end })
ExploitTab:Toggle({ Title = "Bypass Low Level",   Value = true,  Callback = function(v) S.BypassLow    = v end })
ExploitTab:Toggle({ Title = "Bypass Anti-Cheat",  Value = true,  Callback = function(v) S.BypassAC     = v end })

-- ===================== LÓGICA =====================


-- Anti-Cheat Bypass (Indetectável - só remove obstruções)
local function AntiCheatPing()
	if not S.BypassAC then return end
	
	-- Remove apenas objetos físicos do AC sem interagir com remotes
	pcall(function()
		local char = LocalPlayer.Character
		if not char then return end
		
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Remove ClientAC injetado
			local ac = hrp:FindFirstChild("ClientAC")
			if ac then ac:Destroy() end
		end
		
		-- Remove scripts de AC no character
		local antiCheatScript = char:FindFirstChild("AntiCheat")
		if antiCheatScript then antiCheatScript:Destroy() end
		
		-- Remove objetos com nomes suspeitos de AC
		for _, child in pairs(char:GetDescendants()) do
			if child:IsA("LocalScript") or child:IsA("Script") then
				local name = child.Name:lower()
				if string.find(name, "ac") or string.find(name, "anticheat") or string.find(name, "security") then
					child:Destroy()
				end
			end
		end
	end)
	
	-- Intercepta apenas se o servidor enviar sinais (responde naturalmente)
	pcall(function()
		local ping = ReplicatedStorage:FindFirstChild("SignalPing")
		if ping and ping:IsA("RemoteEvent") then
			-- Apenas responde se receber - não dispara
			local conns = getconnections(ping.OnClientEvent)
			if conns and #conns > 0 then
				for _, conn in pairs(conns) do
					if conn then
						conn:Fire()
						task.wait(0.1)
					end
				end
			end
		end
	end)
	
	pcall(function()
		local ack = ReplicatedStorage:FindFirstChild("SignalSendACK")
		if ack and ack:IsA("RemoteEvent") then
			local conns = getconnections(ack.OnClientEvent)
			if conns and #conns > 0 then
				for _, conn in pairs(conns) do
					if conn then
						conn:Fire()
						task.wait(0.1)
					end
				end
			end
		end
	end)
end

-- Bypass low level
local function BypassLow()
	if not S.BypassLow then return end
	if LocalPlayer:GetAttribute("LowLevelPlr") then LocalPlayer:SetAttribute("LowLevelPlr", false) end
end

-- Lockpick / ATM
local function AutoLockpick()
	local gui = LocalPlayer.PlayerGui
	local lp = gui:FindFirstChild("Lockpick")
	if lp and lp.Lockpick.Visible and S.AutoLockPick then
		lp.Lockpick.Btn.Visible = false
		lp.Lockpick.Objetivo.Visible = false
		lp.Lockpick.Bloco.Visible = false
		lp.Lockpick.Objetivo.Position = UDim2.new(0.5,0,0.5,0)
		lp.Lockpick.Bloco.Position = UDim2.new(0.5,0,0.5,0)
		getconnections(lp.Lockpick.Btn.MouseButton1Click)[1]:Fire()
	elseif lp then
		lp.Lockpick.Btn.Visible = true
		lp.Lockpick.Objetivo.Visible = true
		lp.Lockpick.Bloco.Visible = true
	end
	local atm = gui:FindFirstChild("RoubarATM")
	if atm and atm.ATM.Visible and S.AutoLockPick then
		atm.ATM.Btn.Visible = false
		atm.ATM.TextoAviso.Visible = false
		getconnections(atm.ATM.Btn.MouseButton1Click)[1]:Fire()
	elseif atm then
		atm.ATM.Btn.Visible = true
		atm.ATM.TextoAviso.Visible = true
	end
end

-- Speed hack
local function SpeedHack()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 or hum.Sit then return end
	if LocalPlayer:GetAttribute("FazendoAlgo") then return end
	if S.SpeedHack then
		hum.WalkSpeed = 26
		if hum.MoveDirection.Magnitude > 0 then
			hrp.CFrame = hrp.CFrame + (hum.MoveDirection * 0.99)
		end
	end
end

-- Jump hack
local function JumpHack()
	if not S.JumpHack then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 or hum.Sit then return end
	if LocalPlayer:GetAttribute("FazendoAlgo") then return end
	if hum:GetState() == Enum.HumanoidStateType.Jumping then
		for i = 1, 30 do
			local rp = RaycastParams.new()
			rp.FilterDescendantsInstances = {char}
			rp.FilterType = Enum.RaycastFilterType.Exclude
			if Workspace:Raycast(hrp.Position + Vector3.new(0,3,0), Vector3.new(0,5,0), rp) then break end
			hrp.CFrame = hrp.CFrame + Vector3.new(0, 2.5, 0)
			RunService.Heartbeat:Wait()
		end
	end
end

-- No clip
local function NoClip()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("Torso")
	if not S.NoClip or not hum or hum.Health <= 0 or hum.Sit or hum.PlatformStand then
		if head then head.CanCollide = true end
		if torso then torso.CanCollide = true end
		return
	end
	if head then head.CanCollide = false end
	if torso then torso.CanCollide = false end
end

-- Anti staff
local function AntiStaff()
	if not S.AntiStaff or S.Desync then return end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Team and p.Team.Name == "STAFF" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			if (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude <= 200 then
				pcall(function()
					if Workspace:FindFirstChild("GPS") and Workspace.GPS:FindFirstChild("Locais") then
						local locs = {}
						for _, v in pairs(Workspace.GPS.Locais:GetChildren()) do
							if v:IsA("BasePart") and (char.HumanoidRootPart.Position - v.Position).Magnitude >= 800 then
								table.insert(locs, v)
							end
						end
						table.sort(locs, function() return math.random() > 0.5 end)
						if locs[1] then
							char.HumanoidRootPart.CFrame = CFrame.new(locs[1].Position + Vector3.new(0,25,0))
							WindUI:Notify({ Title = "Anti Staff", Content = "Teleportado para " .. locs[1].Name, Duration = 3, Icon = "box" })
						end
					end
				end)
				return
			end
		end
	end
end


-- ESP
local function UpdateESP()
	for _, p in pairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		local char = p.Character
		if not char then continue end
		local head = char:FindFirstChild("Head")
		if not head then continue end
		if not S.EspPlayers then
			local gui = head:FindFirstChild("EspBillboardGui")
			if gui then gui:Destroy() end
			continue
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end
		local isFriend = LocalPlayer:IsFriendsWith(p.UserId)
		local h = S.EspFriends and isFriend and 42 or 28
		if not head:FindFirstChild("EspBillboardGui") then
			local bg = Instance.new("BillboardGui")
			bg.Name = "EspBillboardGui"
			bg.Parent = head
			bg.Size = UDim2.new(0,200,0,h)
			bg.StudsOffset = Vector3.new(0,3,0)
			bg.AlwaysOnTop = true
			bg.ResetOnSpawn = false
			local nl = Instance.new("TextLabel", bg)
			nl.Name = "NameLabel"
			nl.BackgroundTransparency = 1
			nl.Size = UDim2.new(1,0,0.33,0)
			nl.Position = UDim2.new(0,0,0,0)
			nl.Font = Enum.Font.GothamBold
			nl.TextSize = 14
			nl.TextColor3 = Color3.fromRGB(255,255,255)
			nl.TextStrokeTransparency = 0.5
			local fl = Instance.new("TextLabel", bg)
			fl.Name = "FriendLabel"
			fl.BackgroundTransparency = 1
			fl.Size = UDim2.new(1,0,0.33,0)
			fl.Position = UDim2.new(0,0,0.33,0)
			fl.Font = Enum.Font.Gotham
			fl.TextSize = 12
			fl.TextColor3 = Color3.fromRGB(255,255,255)
			fl.TextStrokeTransparency = 0.5
			local il = Instance.new("TextLabel", bg)
			il.Name = "InfoLabel"
			il.BackgroundTransparency = 1
			il.Size = UDim2.new(1,0,0.33,0)
			il.Position = UDim2.new(0,0,0.66,0)
			il.Font = Enum.Font.Gotham
			il.TextSize = 12
			il.TextColor3 = Color3.fromRGB(255,255,255)
			il.TextStrokeTransparency = 0.5
		end
		local bg = head:FindFirstChild("EspBillboardGui")
		if not bg then continue end
		bg.Size = UDim2.new(0,200,0,h)
		local nl = bg:FindFirstChild("NameLabel")
		local fl = bg:FindFirstChild("FriendLabel")
		local il = bg:FindFirstChild("InfoLabel")
		if nl then nl.Text = "[" .. string.sub(p.Name,1,8) .. "]" end
		if fl then fl.Text = (isFriend and S.EspFriends) and "[Roblox Friend]" or "" end
		if il then
			local myChar = LocalPlayer.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
			local parts = {"[" .. dist .. "M]"}
			if S.EspTools then
				local tool = char:FindFirstChildOfClass("Tool")
				table.insert(parts, 1, "[" .. (tool and tool.Name or "None") .. "]")
			end
			if S.EspTeams then
				table.insert(parts, 1, "[" .. (p.Team and p.Team.Name or "None") .. "]")
			end
			il.Text = table.concat(parts, " ")
		end
	end
end

-- Aimbot
local function Aimbot()
	if not S.AimbotEnabled then
		AimbotTarget = nil
		FovStroke.Color = Color3.fromRGB(255,255,255)
		FovFrame.Visible = false
		return
	end
	local char = LocalPlayer.Character
	if not char then AimbotTarget = nil FovFrame.Visible = false return end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool or not tool:FindFirstChild("FireAnim") then
		AimbotTarget = nil FovFrame.Visible = false return
	end
	FovFrame.Visible = S.AimbotFovDisplay
	AimbotTarget = nil
	for _, c in pairs(Workspace:GetChildren()) do
		if not c:IsA("Model") or c == char then continue end
		if S.IgnoreFriends then
			local p = Players:GetPlayerFromCharacter(c)
			if p and LocalPlayer:IsFriendsWith(p.UserId) then continue end
		end
		if S.IgnoreProtected and c:FindFirstChild("AreaSafe", true) then continue end
		local hum = c:FindFirstChild("Humanoid")
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 or hum.Sit then continue end
		local _, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
		if not onScreen then continue end
		local sp = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
		local center = Vector2.new(Workspace.CurrentCamera.ViewportSize.X/2, Workspace.CurrentCamera.ViewportSize.Y/2)
		local mag = (Vector2.new(sp.X, sp.Y) - center).Magnitude
		if mag > S.AimbotFOV then continue end
		if not AimbotTarget then
			AimbotTarget = c
		else
			local sp2 = Workspace.CurrentCamera:WorldToViewportPoint(AimbotTarget:FindFirstChild("HumanoidRootPart").Position)
			local mag2 = (Vector2.new(sp2.X, sp2.Y) - center).Magnitude
			if mag < mag2 then AimbotTarget = c end
		end
	end
	if AimbotTarget then
		local part = S.AimbotTarget == "Head" and (AimbotTarget:FindFirstChild("Head") or AimbotTarget:FindFirstChild("HumanoidRootPart")) or (AimbotTarget:FindFirstChild("HumanoidRootPart") or AimbotTarget:FindFirstChild("Head"))
		if part then
			FovStroke.Color = Color3.fromRGB(255,0,0)
			local cam = Workspace.CurrentCamera
			cam.CFrame = S.AimbotSmooth == 0
				and CFrame.new(cam.CFrame.Position, part.Position)
				or cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, part.Position), S.AimbotSmooth)
		end
	else
		FovStroke.Color = Color3.fromRGB(255,255,255)
	end
end

-- Flying
local function Flying()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or hum.Sit or LocalPlayer:GetAttribute("FazendoAlgo") then
		local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
		if torso then
			local g = torso:FindFirstChild("AutonomousFlightStabilizationGyroscope")
			local v = torso:FindFirstChild("PropulsionBasedAerodynamicVelocityController")
			if g then g:Destroy() end
			if v then v:Destroy() end
			for k, val in next, PrevHumStates do hum:SetStateEnabled(k, val) end
			table.clear(PrevHumStates)
			hum.PlatformStand = false
			char.Animate.Disabled = false
		end
		return
	end
	local torso = hum.RigType == Enum.HumanoidRigType.R6 and char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	if not torso then return end
	if not S.Flying then
		if torso:FindFirstChild("AutonomousFlightStabilizationGyroscope") then
			torso:FindFirstChild("AutonomousFlightStabilizationGyroscope"):Destroy()
			torso:FindFirstChild("PropulsionBasedAerodynamicVelocityController"):Destroy()
			for k, val in next, PrevHumStates do hum:SetStateEnabled(k, val) end
			table.clear(PrevHumStates)
			hum.PlatformStand = false
			char.Animate.Disabled = false
		end
		return
	end
	if not torso:FindFirstChild("AutonomousFlightStabilizationGyroscope") then
		char.Animate.Disabled = true
		for _, t in next, hum:GetPlayingAnimationTracks() do t:AdjustSpeed(0) end
		for _, e in next, Enum.HumanoidStateType:GetEnumItems() do
			PrevHumStates[e] = hum:GetStateEnabled(e)
			hum:SetStateEnabled(e, false)
		end
		hum:ChangeState(Enum.HumanoidStateType.Swimming)
		hum.PlatformStand = true
		local g = Instance.new("BodyGyro", torso)
		g.Name = "AutonomousFlightStabilizationGyroscope"
		g.P = 9e4; g.maxTorque = Vector3.new(9e9,9e9,9e9); g.cframe = torso.CFrame
		local v = Instance.new("BodyVelocity", torso)
		v.Name = "PropulsionBasedAerodynamicVelocityController"
		v.velocity = Vector3.new(0,0.1,0); v.maxForce = Vector3.new(9e9,9e9,9e9)
	end
	local v = torso:FindFirstChild("PropulsionBasedAerodynamicVelocityController")
	local g = torso:FindFirstChild("AutonomousFlightStabilizationGyroscope")
	if v then v.velocity = Vector3.new(0,0,0) end
	if g then g.cframe = Workspace.CurrentCamera.CoordinateFrame end
	if hum.MoveDirection.Magnitude > 0 then char:TranslateBy(hum.MoveDirection * 3.5) end
end

-- Auto Collect
local function AutoCollect()
	if not S.AutoCollect or S.Desync then AutoCollectOrigin = nil return end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum or hum.Sit then return end
	local drops = Workspace:FindFirstChild("DropsWorkspace")
	if not drops then return end
	for _, m in pairs(drops:GetChildren()) do
		if m:IsA("Model") then
			local prompt = m:FindFirstChild("Prompt")
			if prompt and prompt:FindFirstChild("ProximityPrompt") then
				if not AutoCollectOrigin then AutoCollectOrigin = char.HumanoidRootPart.CFrame end
				prompt.ProximityPrompt.RequiresLineOfSight = false
				prompt.ProximityPrompt.MaxActivationDistance = 15
				char.HumanoidRootPart.CFrame = CFrame.new(prompt.Position + Vector3.new(0,5,0))
				fireproximityprompt(prompt.ProximityPrompt)
				return
			end
		end
	end
	if AutoCollectOrigin then
		char.HumanoidRootPart.CFrame = AutoCollectOrigin
		AutoCollectOrigin = nil
	end
end

-- Auto Farm Trash
local function AutoFarmTrash()
	if not S.AutoTrash or S.Desync then return end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	pcall(function()
		local gui = LocalPlayer.PlayerGui
		local lvlui = gui:FindFirstChild("LevelUpUI")
		if lvlui and lvlui:FindFirstChild("LvlFrame") and lvlui.LvlFrame.Visible then
			local btn = lvlui.LvlFrame:FindFirstChild("Content") and lvlui.LvlFrame.Content:FindFirstChild("Body") and lvlui.LvlFrame.Content.Body:FindFirstChild("FecharButton")
			if btn then firesignal(btn.MouseButton1Click) end
		end
	end)
	if LocalPlayer.Team and LocalPlayer.Team.Name == "Lixeiro" then
		local hrp = char.HumanoidRootPart
		if LocalPlayer:GetAttribute("FazendoAlgo") then hrp.CFrame = CFrame.new(-769.371887, 178.907166, 287.941559) return end
		if os.clock() - S.AutoTrashStamp < 0.5 then return end
		local lixeiro = Workspace:FindFirstChild("Lixeiro")
		if lixeiro and #lixeiro:GetChildren() > 0 then
			for _, v in pairs(lixeiro:GetChildren()) do
				if v:IsA("MeshPart") and v.Name == "Lixo" and v:FindFirstChild("PegarLixo") and math.random(1,10) == 1 then
					hrp.CFrame = v.CFrame + Vector3.new(0,5,0)
					fireproximityprompt(v.PegarLixo)
					S.AutoTrashStamp = os.clock()
					return
				end
			end
		end
		hrp.CFrame = CFrame.new(-769.371887, 178.907166, 287.941559)
		return
	end
	char.HumanoidRootPart.CFrame = CFrame.new(-1336.74634, 185.647675, 117.125275)
	ReplicatedStorage:WaitForChild("Mercadinho"):WaitForChild("PrefRemote"):FireServer("Lixeiro", 1, true)
end

-- Auto Farm Fish
local function AutoFarmFish()
	if not S.AutoFish or S.Desync then
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local vc = char.HumanoidRootPart:FindFirstChild("AquaticHarvestVelocityController")
			if vc then vc:Destroy() end
		end
		return
	end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart
	if not hrp:FindFirstChild("AquaticHarvestVelocityController") then
		local bv = Instance.new("BodyVelocity")
		bv.Name = "AquaticHarvestVelocityController"
		bv.Velocity = Vector3.new(0,0,0)
		bv.MaxForce = Vector3.new(9e9,9e9,9e9)
		bv.Parent = hrp
	end
	if LocalPlayer:GetAttribute("FazendoAlgo") then return end
	if not char:FindFirstChild("Vara") and not (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Vara")) then
		ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InvRemotes"):WaitForChild("InvRequest"):InvokeServer("SendSemEspacoBind", "Vara")
	end
	if LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Vara") then
		char.Humanoid:EquipTool(LocalPlayer.Backpack.Vara)
	end
	if Workspace:FindFirstChild("Pescaria") and Workspace.Pescaria:FindFirstChild("Pescadores") then
		if os.clock() - S.AutoFishStamp >= 5 then
			hrp.CFrame = CFrame.new(-32.78, 184.43, 562.41)
			local venda = ReplicatedStorage:WaitForChild("Mercadinho"):WaitForChild("VendaPeixaria")
			venda:FireServer("PeixeNormal", 100)
			venda:FireServer("PeixeGrande", 500)
			venda:FireServer("PeixeDourado", 100000)
			venda:FireServer("PeixeEspada", 1000)
			for _, spot in pairs(Workspace.Pescaria.Pescadores:GetChildren()) do
				if spot:IsA("BasePart") and spot:FindFirstChild("Interagir") then
					fireproximityprompt(spot.Interagir)
					S.AutoFishStamp = os.clock()
					break
				end
			end
		end
	end
end

-- Auto Farm Essence
local function AutoFarmEssence()
	if not S.AutoEssence or S.Desync then return end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	if LocalPlayer:FindFirstChild("Inv") and not LocalPlayer.Inv:FindFirstChild("Tesoura") then
		ReplicatedStorage:WaitForChild("Mercadinho"):WaitForChild("GlobalComprarItem"):FireServer("Tesoura", 400, 1)
		return
	end
	char.HumanoidRootPart.CFrame = CFrame.new(-3675.99683, 154.972382, 64.2251663)
	if LocalPlayer:GetAttribute("FazendoAlgo") then return end
	local farm = Workspace:FindFirstChild("FarmIlegal")
	if farm and farm:FindFirstChild("Essencia") and farm.Essencia:FindFirstChild("Verdin") then
		local pt = farm.Essencia.Verdin:FindFirstChild("PartPromptETexto")
		if pt and pt:FindFirstChild("Interagir") then
			fireproximityprompt(pt.Interagir)
		end
	end
end

-- Auto Farm Peça
local function AutoFarmPeca()
	if not S.AutoPeca or S.Desync then return end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	if LocalPlayer:GetAttribute("FazendoAlgo") then return end
	if os.clock() - S.AutoPecaStamp < 0.5 then return end
	local farm = Workspace:FindFirstChild("FarmPartesDeArma")
	if farm and farm:FindFirstChild("Locais") then
		for _, part in pairs(farm.Locais:GetChildren()) do
			local gui = part:FindFirstChild("GUI")
			if gui and gui:IsA("BillboardGui") and gui.Enabled and part:FindFirstChild("Interagir") then
				char.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,5,0)
				fireproximityprompt(part.Interagir)
				S.AutoPecaStamp = os.clock()
				return
			end
		end
	end
end

-- Auto Farm Samu
local function AutoFarmSamu()
	if not S.AutoSamu then
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local c = char.HumanoidRootPart:FindFirstChild("SamuHarvestPositionalAnchorStabilizationComponent")
			if c then c:Destroy() end
		end
		SamuTarget = nil; SamuOrigin = nil; return
	end
	if not LocalPlayer.Team or LocalPlayer.Team.Name ~= "Médico" then SamuTarget = nil SamuOrigin = nil return end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then SamuTarget = nil SamuOrigin = nil return end
	if char.Humanoid.Health <= 0 or char.Humanoid.Sit then SamuTarget = nil SamuOrigin = nil return end
	local hrp = char.HumanoidRootPart
	if SamuTarget then
		if not SamuTarget.Parent or not SamuTarget:FindFirstChild("Humanoid") or SamuTarget.Humanoid.Health > 0 then
			SamuTarget = nil
			local c = hrp:FindFirstChild("SamuHarvestPositionalAnchorStabilizationComponent")
			if c then c:Destroy() end
			return
		end
		hrp.CFrame = SamuTarget.HumanoidRootPart.CFrame + Vector3.new(0,-5,0)
		local bp = hrp:FindFirstChild("SamuHarvestPositionalAnchorStabilizationComponent")
		if not bp then
			bp = Instance.new("BodyPosition")
			bp.Name = "SamuHarvestPositionalAnchorStabilizationComponent"
			bp.MaxForce = Vector3.new(9e9,9e9,9e9)
			bp.Parent = hrp
		end
		bp.Position = SamuTarget.HumanoidRootPart.Position + Vector3.new(0,-5,0)
		if not LocalPlayer:GetAttribute("FazendoAlgo") then
			ReplicatedStorage:WaitForChild("OrpheusShared"):WaitForChild("Outros"):WaitForChild("Interaction"):FireServer("Reviver")
		end
		return
	end
	for _, c in pairs(Workspace:GetChildren()) do
		if c:IsA("Model") and c ~= char and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart") and c.Humanoid.Health <= 0 then
			if not SamuOrigin then SamuOrigin = hrp.CFrame end
			SamuTarget = c
			hrp.CFrame = c.HumanoidRootPart.CFrame + Vector3.new(0,-5,0)
			if not LocalPlayer:GetAttribute("FazendoAlgo") then
				ReplicatedStorage:WaitForChild("OrpheusShared"):WaitForChild("Outros"):WaitForChild("Interaction"):FireServer("Reviver")
			end
			return
		end
	end
	if SamuOrigin then
		hrp.CFrame = SamuOrigin
		local c = hrp:FindFirstChild("SamuHarvestPositionalAnchorStabilizationComponent")
		if c then c:Destroy() end
		SamuTarget = nil; SamuOrigin = nil
	end
end

-- Auto CL Rejoin
local function AutoCL()
	if S.AutoCLRejoin then
		local gui = LocalPlayer.PlayerGui:FindFirstChild("TelaMorte")
		if gui and gui.Enabled then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end
	end
end

-- Desync mode (Heartbeat)
local function DesyncLoop()
	local char = LocalPlayer.Character
	if not char then return end
	if not S.Desync then
		local hl = char:FindFirstChild("InvisibilityHighlight")
		if hl then hl:Destroy() end
		local op = Workspace:FindFirstChild("CameraOffsetPart")
		if op then op:Destroy() end
		local hum = char:FindFirstChild("Humanoid")
		if Workspace.CurrentCamera.CameraSubject ~= hum then
			Workspace.CurrentCamera.CameraSubject = hum
		end
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not hrp or not hum or hum.Health <= 0 or hum.Sit then return end
	if not char:FindFirstChild("InvisibilityHighlight") then
		local hl = Instance.new("Highlight")
		hl.Name = "InvisibilityHighlight"
		hl.FillColor = Color3.fromRGB(0,0,255)
		hl.OutlineColor = Color3.fromRGB(0,0,255)
		hl.FillTransparency = 0.5
		hl.Parent = char
	end
	if not Workspace:FindFirstChild("CameraOffsetPart") then
		local p = Instance.new("Part")
		p.Name = "CameraOffsetPart"
		p.Size = Vector3.new(1,1,1)
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 1
		p.Parent = Workspace
	end
	if LocalPlayer:GetAttribute("Mirando") or LocalPlayer:GetAttribute("Atirando") or LocalPlayer:GetAttribute("TaEm1Pessoa") then
		hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(Workspace.CurrentCamera.CFrame.LookVector.X, 0, Workspace.CurrentCamera.CFrame.LookVector.Z)) * CFrame.new(0,-300,0)
	else
		hrp.CFrame = hrp.CFrame * CFrame.new(0,-300,0)
	end
	local op = Workspace:FindFirstChild("CameraOffsetPart")
	if op then
		local tool = char:FindFirstChildOfClass("Tool")
		local offset = (tool and tool:FindFirstChild("FireAnim") and not LocalPlayer:GetAttribute("TaEm1Pessoa")) and CFrame.new(2,0,0) or CFrame.new(0,0,0)
		op.CFrame = hrp.CFrame * CFrame.new(0,301.5,0) * offset
		if Workspace.CurrentCamera.CameraSubject ~= op then
			Workspace.CurrentCamera.CameraSubject = op
		end
	end
	RunService.RenderStepped:Wait()
	hrp.CFrame = hrp.CFrame * CFrame.new(0,300,0)
end

-- ===================== LOOPS =====================
RunService.Heartbeat:Connect(function()
	pcall(DesyncLoop)
end)

RunService.RenderStepped:Connect(function()
	pcall(AutoFarmPeca)
	pcall(AutoFarmSamu)
	pcall(AutoCollect)
	pcall(Flying)
	pcall(Aimbot)
	pcall(AutoFarmEssence)
	pcall(AutoCL)
	pcall(UpdateESP)
	pcall(AntiCheatPing)
	pcall(AntiStaff)
	pcall(SpeedHack)
	pcall(NoClip)
	pcall(JumpHack)
	pcall(BypassLow)
	pcall(AutoLockpick)
	pcall(AutoFarmFish)
	pcall(AutoFarmTrash)
end)
