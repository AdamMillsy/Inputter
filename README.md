# Inputter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://choosealicense.com/licenses/mit/)

**Inputter** is a fully-typed, cross-platform ROBLOX input manager for clean and efficient input handling across PC, mobile, and console devices.

---

## Features

- Cross-platform support (PC, Console, Mobile)  
- Typed input configuration  
- Easy integration with existing systems  
- Supports multiple simultaneous inputs  

---

## Installation

### Using Wally

Add the following line to your `wally.toml` dependencies:

```toml
Inputter = "adammillsy/inputter@1.0.0"
```

Then run:

```sh
wally install
```

### Manual Installation

Download a ZIP file of the module from the [GitHub repository](https://github.com/AdamMillsy/Inputter), and copy the code into your project.

---

## Getting Started

Require the module in your project:

```lua
local Inputter = require(Path.To.Inputter)
```

The following example creates a new inputter that responds to both mouse and gamepad input:

```lua
local exampleInput = Inputter.new("ExampleInput", {
    -- Detects left mouse button press
    Inputter.Input.PRESS({
        Input = Enum.UserInputType.MouseButton1
    }),
    -- Detects R2 trigger on gamepads
    Inputter.Input.PRESS({
        Input = Enum.KeyCode.ButtonR2
    })
})

-- Fires when either input is activated
exampleInput.OnActivated:Connect(function()
    -- Start your desired action
end)

-- Fires when the input is released
exampleInput.OnDeactivated:Connect(function()
    -- Stop the action
end)
```

Inputter automatically handles platform-specific input logic under the hood.

---

## Documentation

To view the documentation, please go to [this page](https://adammillsy.github.io/Inputter/).

## Why Inputter?

`UserInputService` is excellent, however most games focus on one platform before expanding to others. Inputter makes it easy to add and remove input methods, removing the complexity that the default methods provide.

---

## Contributing

Issues and PRs are welcome!

---

## License

This project is licensed under the [MIT License](https://choosealicense.com/licenses/mit/) and maintained by **Adam Mills**.

---


