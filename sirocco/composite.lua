local Class  = require "hump.class"
local colors = require "term".colors

local Prompt = require "sirocco.prompt"

local Composite = Class {

    __includes = Prompt,

    init = function(self, options)
        self.fields = options.fields or {}
        self.separator = options.separator or " • "

        Prompt.init(self, options)

        for _, field in ipairs(self.fields) do
            field.buffer = ""
        end
    end

}

function Composite:render()
    Prompt.render(self)

    self:setCursor(
        self.promptPosition.x,
        self.promptPosition.y
    )

    local len = #self.fields
    local fieldPosition = 0
    for i, field in ipairs(self.fields) do
        if not field.buffer or utf8.len(field.buffer) == 0 then
            -- Truncate placeholder to field length
            local placeholder = (field.placeholder or ""):sub(1, field.length)
            -- Add padding to match field length
            placeholder = placeholder .. (" "):rep(field.length - utf8.len(placeholder))

            self.output:write(
                colors.bright .. colors.black
                .. placeholder
                .. colors.reset

                .. (i < len and self.separator or "")
            )

            if not field.position then
                field.position = fieldPosition
            end
        else
            local buffer = field.buffer .. (" "):rep(field.length - utf8.len(field.buffer))

            self.output:write(
                buffer
                .. (i < len and self.separator or "")
            )
        end

        fieldPosition = fieldPosition + field.length + (i < len and utf8.len(self.separator) or 0)
    end

    self:setCursor(
        self.promptPosition.x + self.currentPosition.x,
        self.promptPosition.y + self.currentPosition.y
    )
end

function Composite:processInput(input)
    -- Jump cursor to next field if necessary
    local len = #self.fields
    for i, field in ipairs(self.fields) do
        if self.currentPosition.x > field.position + field.length - 1
            and i < len
            and self.currentPosition.x < self.fields[i + 1].position then
            self.currentPosition.x = self.fields[i + 1].position
        end
    end

    -- Get current field
    local currentField
    local i = 1
    repeat
        currentField = self.fields[i]
        i = i + 1
    until (self.currentPosition.x >= currentField.position
        and self.currentPosition.x <= currentField.position + currentField.length)
        or i > len

    -- Filter input
    input = currentField.filter
        and currentField.filter(input)
        or input

    -- Insert in current field
    currentField.buffer =
        currentField.buffer:sub(1, self.currentPosition.x - currentField.position)
        .. input
        .. currentField.buffer:sub(self.currentPosition.x + 1 - currentField.position)

    -- Increment current position
    self.currentPosition.x = self.currentPosition.x + utf8.len(input)

    -- Validation
    if currentField.validator then
        local _, message = currentField.validator(currentField.buffer)
        self.message = message
    end
end

return Composite