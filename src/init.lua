-- {
--     prompt = "> ",
--     hint = "A hint about the query",
--     -- If nil   -> regular input
--     -- If true and choiceCount == 1 -> yes/no
--     -- If # > 0 -> arrow list
--     -- If hash  -> key list
--     choices = {
--         1, 2, 3, -- That part would be selectable with arrows

--         -- That part would be selectable by key
--         a = 1,
--         b = 2,
--         c = 3,
--     },
--     -- If > 0 -> check list
--     choiceCount = 1,
--     -- If input doesn't match pattern, not shown and not remembered
--     inputPattern = "^[0-9]*$",
--     -- Pattern to accept input or not
--     validatorPattern = nil,
--     -- * to show ****, hidden to hide completly
--     ofuscated = "*|hidden"
-- }

return {
    prompt = require "query.prompt"
}
