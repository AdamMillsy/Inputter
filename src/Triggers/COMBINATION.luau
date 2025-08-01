--[[
    A combination trigger that fires when multiple keys are pressed in combination respectively.
    The last key in the combination acts as the trigger, while all other keys must be held down.
    Author: process77
]]
local UserInputService = game:GetService("UserInputService")
local AbstractTrigger = require(script.Parent.AbstractTrigger)
local Types = require(script.Parent.Parent.Types)

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

	self.Keys = BindingInfo.Input
	self.TriggerKey = self.Keys[#self.Keys] -- Last key is the trigger
	self.CombinationKeys = {} -- All keys except the last one
	for i = 1, #self.Keys - 1 do
		table.insert(self.CombinationKeys, self.Keys[i])
	end

	self.IgnoreGameProcessedEvent = BindingInfo.IgnoreGameProcessedEvent or false
	self._active = false
	self:_setup()
	return self
end

-- Initialise the connections for the object.
function COMBINATION:_setup()
	self._connection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		-- Check if we should ignore game processed events
		if not self.IgnoreGameProcessedEvent and gameProcessedEvent then
			return
		end

		-- Check if the pressed key is our trigger key
		if input.KeyCode and input.KeyCode == self.TriggerKey then
			-- Check if all combination keys are currently held down
			local allCombinationKeysHeld = true
			for _, combinationKey in pairs(self.CombinationKeys) do
				if not UserInputService:IsKeyDown(combinationKey) then
					allCombinationKeysHeld = false
					break
				end
			end

			-- If all combination keys are held and we're not already active, trigger
			if allCombinationKeysHeld and not self._active then
				self._active = true
				self:_activated(input, gameProcessedEvent)
			end
		end
	end)

	-- Listen for key releases to deactivate
	self._connectionRelease = UserInputService.InputEnded:Connect(
		function(input: InputObject, gameProcessedEvent: boolean)
			if not self.IgnoreGameProcessedEvent and gameProcessedEvent then
				return
			end

			-- If any of our keys is released and we're active, deactivate
			if input.KeyCode and self._active then
				for _, key in pairs(self.Keys) do
					if input.KeyCode == key then
						self._active = false
						self:_deactivated(input, gameProcessedEvent)
						break
					end
				end
			end
		end
	)
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
end

return COMBINATION :: COMBINATION
