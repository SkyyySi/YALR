#!/usr/bin/env lua
local io = io
local load = load
local print = print
local tostring = tostring
local setmetatable = setmetatable

local tts = require("tts")

local count = 0

---@param format string
local function printf(format, ...)
	io.stdout:write(format:format(...))
end

local function clear()
	os.execute("clear")
end

local prompt_fmt = "\x1b[32;1m[%s] >>>\x1b[0m "

local function clear_line(current_line)
	local line_length = #current_line
	io.stdout:write("\r"..tts.util.string_multiply(" ", line_length).."\r")
end

local line_history = {}
do
	local mt = {}
	mt.__index = mt
	setmetatable(line_history, mt)

	---@param s string
	---@return string, integer
	function mt.string_escape(s)
		return s:gsub("\\", [[\\]])
			:gsub("\a", [[\a]])
			:gsub("\b", [[\b]])
			:gsub("\f", [[\f]])
			:gsub("\n", [[\n]])
			:gsub("\r", [[\r]])
			:gsub("\t", [[\t]])
			:gsub("\v", [[\v]])
			:gsub("\"", [[\"]])
			:gsub("\'", [[\']])
	end

	mt.dump_path = os.getenv("HOME").."/.yalr_history.lua"

	function mt:load(path)
		path = path or mt.dump_path
		local success, result = pcall(dofile, path)

		if success then
			for k, v in pairs(result) do
				self[k] = v
			end
		end
	end

	function mt:dump(path)
		path = path or mt.dump_path
		local file, err = io.open(path, "w+")

		if not file or err then
			print(err)
			return
		end

		local str = "return {"
		for k, v in pairs(self) do
			str = ('%s"%s",'):format(str, mt.string_escape(v))
		end
		str = str.."}"

		file:write(str)
		file:close()
	end
end

local function read_line()
	local special = 0
	local hist_index = #line_history + 1
	line_history[hist_index] = line_history[hist_index] or ""

	while true do
		local c, c_byte
		os.execute("stty -icanon")
		c = io.read(1)
		c_byte = string.byte(c)

		if c:match("[\n]") then
			os.execute("stty icanon")
			table.insert(line_history, line_history[hist_index])
			line_history:dump()
			return line_history[hist_index]
		elseif c_byte == 17 then -- Ctrl+L / clear
			clear()
			io.stdout:write(prompt_fmt:format(count)..tostring(line_history[hist_index]))
		elseif c_byte == 27 then
			special = 1
		elseif c_byte == 127 then -- backspace
			printf("\b\b   \b\b\b")
			if #line_history[hist_index] > 0 then
				printf("\b \b")
				line_history[hist_index] = line_history[hist_index]:sub(1, #line_history[hist_index]-1)
			end
		else
			local current_line = prompt_fmt:format(count)..tostring(line_history[hist_index])
			if 0 < special and special < 2 then
				-- ^[[A = up
				-- ^[[B = down
				-- ^[[C = right
				-- ^[[D = left
				io.stdout:write("\b\b\b    \b\b\b")
				special = special + 1
			elseif 1 < special and special < 3 then
				io.stdout:write("\b\b  \b\b")
				--io.stdout:write(line_history[hist_index]:sub(#line_history[hist_index], #line_history[hist_index]):lower())
				--printf("{'%s' %s}", c, c_byte)
				if c_byte == 65 and 1 <= hist_index - 1 then -- up
					clear_line(current_line)
					hist_index = hist_index - 2
					io.stdout:write(prompt_fmt:format(count)..line_history[hist_index])
				elseif c_byte == 66 and #line_history > hist_index + 1 then -- down
					clear_line(current_line)
					hist_index = hist_index + 2
					io.stdout:write(prompt_fmt:format(count)..line_history[hist_index])
				end
				special = special + 1
			else
				line_history[hist_index] = line_history[hist_index]..tostring(c)
			end
			--printf("{'%s' %s}_-_-_", c, c_byte)
		end
	end
end

--local input = read_line()
--printf("\nYou typed: '%s'.\n", input)

--[ [
print("Welcome to YALR!")
line_history:load()
while true do
	---@type string
	local input
	---@type function?
	local expr
	---@type string
	local resoult
	---@type any
	local evaled_expr
	---@type string
	local type_of_evaled_expr
	---@type boolean
	local success

	local err

	io.write(prompt_fmt:format(count))

	success, input = pcall(read_line)

	if not success then
		print(input)
	elseif input ~= nil and input ~= "" then
		if input == "exit" or input == "quit" then
			print("Bye!")
			os.exit(0)
			break
		elseif input == "clear" then
			clear()
			count = count + 1
		else
			count = count + 1
			success, resoult = pcall(load(input))
			if success then
				if resoult ~= nil then
					print(tts.prettify(resoult))
				end
			else
				success, resoult = pcall(load("return "..input))
				if success then
					print(tts.prettify(resoult))
				elseif resoult ~= nil then
					print(resoult)
				end
			end
		end
	end
end
--]]
