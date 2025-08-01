local Signal = require(script.Parent.Parent.Signal)

export type Signal<T...> = Signal.Signal<T...>

--[=[
	@class Inputter
	The inputter class represents each individual action a player can make. It should be used to abstract away from the different input methods ROBLOX provides.
]=]
export type Inputter = {
	Name: string,
	Active: boolean,
	Enabled: boolean,
	ActiveTriggers: { Trigger }, -- The triggers that are currently active. This is used to determine if the inputter is active or not.
	OnActivated: Signal.Signal<() -> ()>, -- The signal that is fired when the inputter is activated.
	OnDeactivated: Signal.Signal<() -> ()>, -- The signal that is fired when the inputter is deactivated.

	new: (name: string, inputs: { Trigger }) -> Inputter,
	AddInput: (self: Inputter, input: Trigger) -> (),
	RemoveInput: (self: Inputter, input: Trigger) -> (),
	GetAllInputs: (self: Inputter) -> { Trigger },
	IsActive: (self: Inputter) -> boolean,
	Enable: (self: Inputter) -> (),
	Disable: (self: Inputter) -> (),
	Destroy: (self: Inputter) -> (),
	Serialize: (self: Inputter) -> string, -- Serializes the inputter to a string.
	Deserialize: (self: Inputter, serialized: string) -> Inputter, -- Rebuilds an inputter from a serialized string.
}

--[=[
	@interface BindingInfo
	.Input Enum.KeyCode | Enum.UserInputType | GuiButton | {Enum.KeyCode | Enum.UserInputType | GuiButton} -- The input that will trigger the binding. Whether this is a table or single input is contextual on the trigger being constructed.
	@within Inputter
	.IgnoreGameProcessedEvent boolean? -- By default this value is false, and inputs already processed by the game (such as when interacting with GUI) are ignored. If this flag is set to true the inputter will be triggered regardless of the context of the input.
]=]
export type BindingInfo = {
	Input: Enum.KeyCode | Enum.UserInputType | GuiButton | { Enum.KeyCode | Enum.UserInputType | GuiButton },
	IgnoreGameProcessedEvent: boolean?,
}

export type Binding = {
	Input: Enum.KeyCode | Enum.UserInputType | GuiButton,
	Pressed: boolean,
	Destroy: (self: Binding) -> (),
	new: (BindingInfo: BindingInfo) -> Binding,
}

export type Trigger = {
	OnActivated: Signal.Signal<() -> ()>,
	OnDeactivated: Signal.Signal<() -> ()>,
	_serialize: (self: Trigger) -> { Type: string, Arguments: { any } },
}
export type MULTIPLE_PRESS = Trigger & {
	new: (BindingInfo: BindingInfo, PressCount: number, TimeFrame: number) -> Trigger,
}
export type PRESS = Trigger & {
	new: (BindingInfo: BindingInfo) -> Trigger,
}
export type HOLD = Trigger & {
	new: (BindingInfo: BindingInfo, HoldTime: number) -> Trigger,
}
export type SHORT_PRESS = Trigger & {
	new: (BindingInfo: BindingInfo, MaxPressTime: number?) -> Trigger,
}

export type COMBINATION = Trigger & {
	new: (BindingInfo: BindingInfo) -> Trigger,
}

return {}
