
local helpers = require("test.functional.helpers")(after_each)
local exec_lua, feed = helpers.exec_lua, helpers.feed
local ls_helpers = require("helpers")
local Screen = require("test.functional.ui.screen")

describe("Jumping", function()
	local screen

	before_each(function()
		helpers.clear()
		ls_helpers.session_setup_luasnip()

		screen = Screen.new(50, 5)
		screen:attach()
		screen:set_default_attr_ids({
			[0] = { bold = true, foreground = Screen.colors.Blue },
			[1] = { bold = true, foreground = Screen.colors.Brown },
			[2] = { bold = true },
			[3] = { background = Screen.colors.LightGray },
			[4] = {background = Screen.colors.LightGrey, foreground = Screen.colors.DarkBlue};
		})
	end)

	after_each(function()
		screen:detach()
	end)

	it("Folds are opened when jumped into", function()
		local snip = [[
			s("aug", {
				t("augroup "),
				i(1, "GroupName"),
				t({ "AuGroup", "\t" }),
				t({ "au!", "\tau " }),
				i(2, "CursorHold * redrawstatus"),
				i(0),
				t({ "", "augroup end" }),
			})
		]]

		helpers.exec("set foldenable foldmethod=manual")

		exec_lua("ls.snip_expand("..snip..")")
        screen:expect{grid=[[
            augroup ^G{3:roupName}AuGroup                          |
                    au!                                       |
                    au CursorHold * redrawstatus              |
            augroup end                                       |
            {2:-- SELECT --}                                      |
        ]]}

		-- fold middle-lines.
		feed("<Esc>jzfj")
        screen:expect{grid=[[
            augroup GroupNameAuGroup                          |
            {4:^+--  2 lines: au!·································}|
            augroup end                                       |
            {0:~                                                 }|
                                                              |
        ]]}

		-- folded lines are opened correctly when jumped into them.
		exec_lua("ls.jump(1)")
        screen:expect{grid=[[
          augroup GroupNameAuGroup                          |
                  au!                                       |
                  au ^C{3:ursorHold * redrawstatus}              |
          augroup end                                       |
          {2:-- SELECT --}                                      |
        ]]}
	end)

	it("jumps correctly when multibyte-characters are present.", function()
		local snip = [[
			s("trig", {
				t{"asdf", "핓s㕥f"}, i(1, "asdf"),
				t{"", "asdf"}, i(2, "핓sdf"),
			})
		]]

		exec_lua("ls.snip_expand("..snip..")")
		screen:expect{grid=[[
            asdf                                              |
            핓s㕥f^a{3:sdf}                                        |
            asdf핓sdf                                         |
            {0:~                                                 }|
            {2:-- SELECT --}                                      |
        ]]}

        exec_lua("ls.jump(1)")
		screen:expect{grid=[[
            asdf                                              |
            핓s㕥fasdf                                        |
            asdf^핓{3:sdf}                                         |
            {0:~                                                 }|
            {2:-- SELECT --}                                      |
        ]]}
	end)
end)
