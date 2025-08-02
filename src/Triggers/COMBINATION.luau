--[[
    A combination trigger that fires when multiple keys are pressed in combination respectively.
    The last key in the combination acts as the trigger, while all other keys must be held down.
    Author: process77
]]
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local AbstractTrigger = require(script.Parent.AbstractTrigger)
local Types = require(script.Parent.Parent.Types)
local Binding = require(script.Parent.Parent.Binding)

type COMBINATION = Types.COMBINATION
type BindingInfo = Types.BindingInfo

--[=[
	@class COMBINATION
	A type of trigger that fires when a combination of inputs are pressed in combination respectively.
	The Input should be a table of Enum.KeyCode values, where the last key acts as the trigger
	and all previous keys must be held down.
]=]
local COMBINATION = setmetatable({}, AbstractTrigger)
COMBINATION.__index = COMBINATION

--[=[
	@param BindingInfo BindingInfo -- The binding information for the input respectively. The Input must be a table of Enum.KeyCode values.
	@return COMBINATION -- The new COMBINATION object.
]=]
function COMBINATION.new(BindingInfo: BindingInfo): COMBINATION
	local self = setmetatable(AbstractTrigger.new(script.Name, BindingInfo), COMBINATION)

	-- Validate input is a table of keys
	if typeof(BindingInfo.Input) ~= "table" or #BindingInfo.Input < 2 then
		error("COMBINATION trigger requires an array of at least 2 Enum.KeyCode values")
	end

	-- Create a binding for the first key in the combination
	local firstKeyBindingInfo = {
		Input = BindingInfo.Input[1],
		IgnoreGameProcessedEvent = BindingInfo.IgnoreGameProcessedEvent,
	}

	self.Binding = Binding.new(firstKeyBindingInfo)
	self.Keys = BindingInfo.Input
	self.IgnoreGameProcessedEvent = BindingInfo.IgnoreGameProcessedEvent or false
	self._active = false
	self._heartbeatConnection = nil
	self._activationSequence = {} -- Track keys as they are activated in order
	self:_setup()
	return self
end

-- Initialise the connections for the object.
function COMBINATION:_setup()
	-- Connect to the first key's activation to start monitoring the combination
	self._connection = self.Binding.OnActivated:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		-- Reset and start tracking the activation sequence
		self._activationSequence = { input.KeyCode }

		-- Start heartbeat monitoring when the first key is pressed
		if not self._heartbeatConnection then
			self._heartbeatConnection = RunService.Heartbeat:Connect(function()
				self:_checkCombination()
			end)
		end
	end)

	-- Connect to the first key's deactivation to stop monitoring
	self._connectionRelease = self.Binding.OnDeactivated:Connect(
		function(input: InputObject, gameProcessedEvent: boolean)
			-- Stop heartbeat monitoring and deactivate if active
			if self._heartbeatConnection then
				self._heartbeatConnection:Disconnect()
				self._heartbeatConnection = nil
			end

			-- Clear the activation sequence
			self._activationSequence = {}

			if self._active then
				self._active = false
				self:_deactivated(input, gameProcessedEvent)
			end
		end
	)

	-- Listen for additional key presses to build the sequence
	self._sequenceConnection = UserInputService.InputBegan:Connect(
		function(input: InputObject, gameProcessedEvent: boolean)
			if not self.IgnoreGameProcessedEvent and gameProcessedEvent then
				return
			end

			-- Only track if we're currently monitoring (heartbeat is active)
			if self._heartbeatConnection and input.KeyCode then
				-- Check if this key is the next expected key in the sequence
				local expectedIndex = #self._activationSequence + 1
				if expectedIndex <= #self.Keys and input.KeyCode == self.Keys[expectedIndex] then
					table.insert(self._activationSequence, input.KeyCode)
				end
			end
		end
	)
end

-- Check if the full combination is being held in chronological order
function COMBINATION:_checkCombination()
	-- Check if we have the complete sequence activated in the correct order
	local sequenceComplete = #self._activationSequence == #self.Keys

	if sequenceComplete then
		-- Verify all keys in the sequence are still held down
		local allKeysStillHeld = true
		for i, key in ipairs(self._activationSequence) do
			if not UserInputService:IsKeyDown(key) then
				allKeysStillHeld = false
				break
			end
		end

		-- If sequence is complete, all keys are held, and we're not already active, activate
		if allKeysStillHeld and not self._active then
			self._active = true
			self:_activated()
		elseif not allKeysStillHeld and self._active then
			-- If any key in the sequence is released and we're active, deactivate
			self._active = false
			self:_deactivated()
		end
	else
		-- If we're active but the sequence is incomplete, deactivate
		if self._active then
			self._active = false
			self:_deactivated()
		end
	end
end

-- Destroy the input handler
function COMBINATION:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	if self._connectionRelease then
		self._connectionRelease:Disconnect()
		self._connectionRelease = nil
	end
	if self._sequenceConnection then
		self._sequenceConnection:Disconnect()
		self._sequenceConnection = nil
	end
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
	if self.Binding then
		self.Binding:Destroy()
		self.Binding = nil
	end
end

return COMBINATION :: COMBINATION
