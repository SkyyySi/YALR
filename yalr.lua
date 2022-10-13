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

local line_history = {}

local function read_line()
	local line = ""
	local special = 0
	local hist_index = #line_history + 1

	while true do
		local c, c_byte
		os.execute("stty -icanon")
		c = io.read(1)
		c_byte = string.byte(c)

		if c:match("[\n]") then
			os.execute("stty icanon")
			table.insert(line_history, line)
			return line
		elseif c_byte == 27 then
			special = 1
		elseif c_byte == 127 then -- backspace
			printf("\b\b   \b\b\b")
			if #line > 0 then
				printf("\b \b")
				line = line:sub(1, #line-1)
			end
		else
			if 0 < special and special < 2 then
				-- ^[[A = up
				-- ^[[B = down
				-- ^[[C = right
				-- ^[[D = left
				printf("\b\b\b    \b\b\b")
				special = special + 1
			elseif 0 < special and special < 3 then
				printf("\b\b\b    \b\b\b")
				special = special + 1
			else
				line = line..tostring(c)
			end
			--printf("{'%s' %s}_-_-_", c, c_byte)
		end
	end
end

--local input = read_line()
--printf("\nYou typed: '%s'.\n", input)

--[ [
print("Welcome to YALR!")
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

	count = count + 1

	io.write("\x1b[32;1m"..tostring(count).." >>>\x1b[0m ")

	success, input = pcall(read_line)

	if not success then
		print(input)
	elseif input ~= nil then
		if input == "exit" or input == "quit" then
			print("Bye!")
			os.exit(0)
			break
		end

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
--]]
