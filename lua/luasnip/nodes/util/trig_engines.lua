local jsregexp = require("luasnip.util.util").jsregexp

-- these functions get the line up to the cursor, the trigger, and then
-- determine whether the trigger matches the current line.
-- If the trigger does not match, the functions shall return nil, otherwise
-- the matching substring and the list of captures (empty table if there aren't
-- any).

local function match_plain(line_to_cursor, trigger)
	if
		line_to_cursor:sub(
			#line_to_cursor - #trigger + 1,
			#line_to_cursor
		) == trigger
	then
		-- no captures for plain trigger.
		return trigger, {}
	else
		return nil
	end
end

local function match_pattern(line_to_cursor, trigger)
	-- capture entire trigger, must be put into match.
	local find_res = { string.find(line_to_cursor, trigger .. "$") }
	if #find_res > 0 then
		local captures = {}
		local from = find_res[1]
		local match = line_to_cursor:sub(from, #line_to_cursor)
		for i = 3, #find_res do
			captures[i - 2] = find_res[i]
		end
		return match, captures
	else
		return nil
	end
end

local make_ecma_matcher
if jsregexp then
	make_ecma_matcher = function(trig)
		local trig_compiled = jsregexp.compile(trig .. "$", "")

		return function(line_to_cursor, _)
			-- get first (very likely only, since we appended the "$") match.
			local match = trig_compiled(line_to_cursor)[1]
			if match then
				-- return full match, and all groups.
				return line_to_cursor:sub(match.begin_ind-1), match.groups
			else
				return nil
			end
		end
	end
else
	make_ecma_matcher = function() return match_plain end
end

return {
	plain = function() return match_plain end,
	pattern = function() return match_pattern end,
	ecma = make_ecma_matcher,
}
