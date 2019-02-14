local Class  = require "hump.class"
local colors = require "term".colors

local Prompt = require "prompt"

local List = Class {

    __includes = Prompt,

    init = function(self, options)
        self.items         = options.items or {
            -- {
            --     value = "a",
            --     label = "the first choice"
            -- }
        }

        self.multiple = true
        if options.multiple ~= nil then
            self.multiple = options.multiple
        end

        self.currentChoice = 1
        self.chosen = {}

        Prompt.init(self, options)
    end

}

function List:registerKeybinding()
    self.keybinding = {
        [Prompt.escapeCodes.up] = function()
            self:setCurrentChoice(-1)
        end,

        [Prompt.escapeCodes.down] = function()
            self:setCurrentChoice(1)
        end,

        -- Select an item
        [" "] = function()
            local count = 0
            for _, v in pairs(self.chosen) do
                count = count + (v and 1 or 0)
            end

            self.chosen[self.currentChoice] = not self.chosen[self.currentChoice]

            -- Only one choice allowed ? unselect previous choice
            if self.chosen[self.currentChoice] and not self.multiple and count > 0 then
                self.chosen = {
                    [self.currentChoice] = true
                }
            end
        end,
    }
end

function List:setCurrentChoice(newChoice)
    self.currentChoice = math.max(1, math.min(#self.items, self.currentChoice + newChoice))
end

function List:render()
    Prompt.render(self)

    -- List must begin under prompt
    if not self.prompt:match("\n$") then
        self.output:write("\n")
    end

    for i, item in ipairs(self.items) do
        local chosen = self.chosen[i]

        self.output:write(
            " "
            .. (i == self.currentChoice and "❱ " or "  ")

            .. colors.magenta
            .. (self.multiple and "[" or "(")
            .. (
                self.multiple
                and (chosen and "✔" or " ")
                or (chosen and "●" or " ")
            )
            .. (self.multiple and "]" or ")")
            .. colors.reset

            .. " "

            .. (chosen and colors.underscore or "")
            .. colors.green
            .. item.label
            .. colors.reset

            .. "\n"
        )
    end
end

function List:processedResult()
    local result = {}
    for i, selected in pairs(self.chosen) do
        if selected then
            table.insert(result, self.items[i].value)
        end
    end

    return result
end

function List:endCondition()
    local count = 0
    for _, v in pairs(self.chosen) do
        count = count + (v and 1 or 0)
    end

    self.finished = self.finished and (not self.required or count > 0)

    return self.finished
end

function List:before()
    -- Hide cursor
    self.output:write("\27[?25l")

    Prompt.before(self)
end

function List:after(result)
    -- Show selected label
    self:setCursor(self.promptPosition.x, self.promptPosition.y)

    -- Clear down
    self.output:write(Prompt.escapeCodes.cleardown)

    self.output:write(" " .. (#result == 1 and result[1] or table.concat(result, ", ")))

    -- Show cursor
    self.output:write("\27[?25h")

    Prompt.after(self)
end

return List
