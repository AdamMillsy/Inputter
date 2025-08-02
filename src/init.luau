local Signal = require(script.Parent.Signal)
local Serializer = require(script.Serializer)

local Types = require(script.Types)
export type Inputter = Types.Inputter
export type BindingInfo = Types.BindingInfo
export type Signal<T...> = Types.Signal<T...>
export type Trigger = Types.Trigger

-- Version is read off of the wally package folder name
-- If you modify the package structure this may fail, so just manually set the version value below in the format "0.0.0"
-- The version can be found wherever you downloaded the package, check the GitHub release
local Version = script.Parent.Name:match("@(.+)$")
if not Version or not Version:match("^%d+%.%d+%.%d+$") then
	warn("Inputter version did not read correctly, please manually set it. defaulting to '0.0.0'")
	Version = "0.0.0"
end

local Inputter = {}
Inputter.__index = Inputter

Inputter.Trigger = {
	MULTIPLE_PRESS = require(script.Triggers.MULTIPLE_PRESS).new,
	PRESS = require(script.Triggers.PRESS).new,
	HOLD = require(script.Triggers.HOLD).new,
	SHORT_PRESS = require(script.Triggers.SHORT_PRESS).new,
	COMBINATION = require(script.Triggers.COMBINATION).new,
}

--[=[
	@within Inputter
	@function new
	@param name string -- The name of the inputter. Should be unique
	@param triggers {Trigger} -- The triggers that will be used by the inputter. This should be a table of Trigger objects.
	@return Inputter -- The new inputter object

	Creates a new inputter object, ideally there should be one input for each different player action. I.e. an inputter for punch, another inputter for fly, etc.
	```lua
	local punchInput = Inputter.new("PunchInput", {
		Inputter.Trigger.PRESS({
			Input = Enum.KeyCode.ButtonR2,
			IgnoreGameProcessedEvent = true,
		}),
		Inputter.Trigger.MULTIPLE_PRESS({
			Input = Enum.UserInputType.MouseButton1,
			IgnoreGameProcessedEvent = true,
		}, 2, 0.3)
	})
	```

	Creates a combination inputter that listens for the chronilogical order of inputs, i.e. the first input must be pressed before the second input, and so on - last key is the trigger.

	```lua
	local combination = Inputter.Trigger.COMBINATION({
		Input = {
			Enum.KeyCode.A,
			Enum.KeyCode.B,
			Enum.KeyCode.C,
		},
		IgnoreGameProcessedEvent = false,
	})

	-- Connect to the activation event
	combination.OnActivated:Connect(function(input, gameProcessedEvent)
		print("Combination activated!")
		-- Your custom logic here
	end)

	-- Connect to the deactivation event (when any key is released)
	combination.OnDeactivated:Connect(function(input, gameProcessedEvent)
		print("Combination deactivated!")
	end)

	-- Clean up when done
	--combination:Destroy()
	```
]=]

function Inputter.new(name: string, triggers: { Trigger }): Inputter
	local self = setmetatable({}, Inputter)
	if not name or typeof(name) ~= "string" then
		error("Input name must be a string")
	end
	if not triggers or typeof(triggers) ~= "table" then
		error("Input binds must be a table")
	end
	--[=[
		@within Inputter
		@prop Name string
		@readonly
		Name of the inputter. This should be unique for each inputter.
	]=]
	self.Name = name
	--[=[
		@within Inputter
		@prop Active boolean
		@readonly
		Whether the inputter is currently active (i.e. is at least one of the inputs bound triggered). Can be used if the action triggered relies on checking the input is still active.
	]=]
	self.Active = false
	--[=[
		@within Inputter
		@prop Enabled boolean
		@readonly
		Whether the inputter is enabled. If this is false, the inputter will not trigger any events.
	]=]
	self.Enabled = true
	--[=[
		@within Inputter
		@prop OnActivated Signal
		@readonly
		Signal that is fired when the inputter is activated. This will be fired when at least one of the inputs bound to the inputter is triggered.
	]=]
	self.OnActivated = Signal.new()
	--[=[
		@within Inputter
		@prop OnDeactivated Signal
		@readonly
		Signal that is fired when the inputter is deactivated. This will be fired when all of the inputs bound to the inputter are deactivated.
	]=]
	self.OnDeactivated = Signal.new()
	--[=[
		@within Inputter
		@prop Triggers {Trigger}
		@readonly
		The triggers that the inputter is currently listening to.
	]=]
	self.Triggers = {}
	self._activeConnections = {}
	self:_setup(triggers)
	return self
end

--[=[
	@within Inputter
	@private
	@param triggers {Trigger} -- The triggers that will be used by the inputter.
	Initial inputter setup method, used to begin listening to the initially passed triggers. Should only be called internally.
]=]
function Inputter:_setup(triggers: { Trigger })
	for _, Input in pairs(triggers) do
		self:AddTrigger(Input)
	end
end

--[=[
	@within Inputter
	@param trigger Trigger -- The trigger to add to the inputter.
	Adds a new trigger to an already existing inputter.
]=]
function Inputter:AddTrigger(trigger: Trigger)
	if not trigger then
		error("Trigger cannot be nil")
	end
	table.insert(self.Triggers, trigger)
	self._activeConnections[trigger] = {}
	table.insert(
		self._activeConnections[trigger],
		trigger.OnActivated:Connect(function(...)
			self:_activate(...)
		end)
	)
	table.insert(
		self._activeConnections[trigger],
		trigger.OnDeactivated:Connect(function(...)
			self:_deactivate(...)
		end)
	)
end

--[=[
	@within Inputter
	@tag Work In Progress
	@param Trigger Trigger -- The trigger to remove from the inputter.
	Removes a trigger from an already existing inputter. This method is a work in progress, in the future it may be expanded to allow removal by keybind or other properties.
]=]
function Inputter:RemoveTrigger(Trigger: Trigger)
	for i, v in pairs(self.Triggers) do
		if v == Trigger then
			table.remove(self.Triggers, i)
			break
		end
	end
	if self._activeConnections[Trigger] then
		for _, connection in pairs(self._activeConnections[Trigger]) do
			connection:Disconnect()
		end
		self._activeConnections[Trigger] = nil
	end
end

--[=[
	@within Inputter
	@return {Input} -- All inputs this input is currently connected to.
	Returns all the inputs currently used by the inputter.
]=]
function Inputter:GetAllTriggers()
	local triggers = {}
	for _, trigger in pairs(self.Triggers) do
		table.insert(triggers, trigger)
	end
	return triggers
end

--[=[
	@within Inputter
	@private
	@param InputObject InputObject -- The input object that triggered the event.
	@param GameProcessedEvent boolean -- Whether the game processed the event or not.
	@param ... any -- Any additional arguments passed to the event.
	Internal method that is called when an input is activated. Should only be called internally.
]=]
function Inputter:_activate(InputObject, GameProcessedEvent, ...)
	if self.Enabled then
		self.Active = true
		self.OnActivated:Fire(InputObject, GameProcessedEvent, ...)
	end
end

--[=[
	@within Inputter
	@private
	@param InputObject InputObject -- The input object that triggered the event.
	@param GameProcessedEvent boolean -- Whether the game processed the event or not.
	@param ... any -- Any additional arguments passed to the event.
	Internal method that is called when an input is deactivated. Should only be called internally.
]=]
function Inputter:_deactivate(InputObject, GameProcessedEvent, ...)
	if self.Active then
		self.Active = false
		if self.Enabled then
			self.OnDeactivated:Fire(InputObject, GameProcessedEvent, ...)
		end
	end
end

--[=[
	@within Inputter
	@return boolean -- Whether the inputter is currently active or not.
	Returns whether the inputter is currently active or not. This will be true if at least one of the inputs bound to the inputter is triggered.
]=]
function Inputter:IsActive()
	return self.Active
end

--[=[
	@within Inputter
	Enables the inputter, meaning it can send activated and deactivated events.
]=]
function Inputter:Enable()
	self.Enabled = true
end

--[=[
	@within Inputter
	Disables the inputter, meaning it will not send activated and deactivated events.
]=]
function Inputter:Disable()
	self.Enabled = false
end

--[=[
	@within Inputter
	Destroys the inputter, meaning it will no longer send activated and deactivated events. This should be called when the inputter is no longer needed.
]=]
function Inputter:Destroy()
	for _, connection in pairs(self._activeConnections) do
		if connection.OnActivated then
			connection.OnActivated:Disconnect()
		end
		if connection.OnDeactivated then
			connection.OnDeactivated:Disconnect()
		end
	end
	self.OnActivated:Destroy()
	self.OnDeactivated:Destroy()
	for i, _ in pairs(self) do
		self[i] = nil
	end
end

--[=[
	@within Inputter
	Converts the inputter to a table representation, for serialization purposes.
	@return  string -- The JSON encoded representation of the inputter.
]=]
function Inputter:Serialize()
	local tbl = {}
	tbl.Version = Version
	tbl.Name = self.Name
	tbl.Triggers = {}
	for _, trigger: Types.Trigger in pairs(self.Triggers) do
		table.insert(tbl.Triggers, trigger:_serialize())
	end
	return Serializer.encode(tbl)
end

--[=[
	@within Inputter
	Rebuilds an inputter from a serialized string.
	@param serialized string -- The serialized string representation of the inputter.
	@return Inputter -- The rebuilt inputter object.
]=]
function Inputter.Deserialize(serialized: string)
	local tbl = Serializer.decode(serialized)
	-- Unfortunately only exact matches of inputter versions are supported.
	-- I will endeavor to keep the serialization similar, so theoretically this may work across minor and patch versions.
	-- But I cannot guarantee that, I would recommend keeping your version of inputter consistent.
	if tbl.Version ~= Version then
		error("Inputter version mismatch. Expected: " .. Version .. ", got: " .. tbl.Version)
	end
	local inputter = Inputter.new(tbl.Name, {})
	for _, triggerData in pairs(tbl.Triggers) do
		local triggerType = Inputter.Trigger[triggerData.Type]
		if not triggerType then
			error("Unknown trigger type: " .. tostring(triggerData.Type))
		end
		local trigger = triggerType(unpack(triggerData.Arguments))
		inputter:AddTrigger(trigger)
	end
	return inputter
end

return Inputter
