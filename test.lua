package.path = package.path .. ";src/?.lua;lib/tui/?/init.lua;lib/tui/?.lua"

local Prompt = require "prompt"

local answer = Prompt {
    prompt = "A simple question\n> ",
    placeholder = "A simple answer"
}:loop()

print("Answer was:")
for i = 1, #answer do
    io.write(answer:sub(i, i):byte() .. " [" .. answer:sub(i, i) .. "] ")
end
print()
