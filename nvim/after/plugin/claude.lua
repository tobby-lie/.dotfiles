local function transcript_path()
  local projects = vim.fn.expand("~") .. "/.claude/projects/"
  local id = vim.env.CLAUDE_CODE_SESSION_ID
  if id and id ~= "" then
    local matches = vim.fn.glob(projects .. "*/" .. id .. ".jsonl", false, true)
    if matches[1] then return matches[1] end
  end
  local dir = projects .. vim.fn.getcwd():gsub("[^%w]", "-") .. "/"
  local newest, newest_time = nil, 0
  for _, file in ipairs(vim.fn.glob(dir .. "*.jsonl", false, true)) do
    local time = vim.fn.getftime(file)
    if time > newest_time then newest, newest_time = file, time end
  end
  return newest
end

local function is_prompt(entry)
  if entry.type ~= "user" or entry.isMeta then return false end
  local content = entry.message and entry.message.content
  if type(content) == "string" then return true end
  if type(content) ~= "table" then return false end
  for _, block in ipairs(content) do
    if block.type == "tool_result" then return false end
  end
  return true
end

local function replies()
  local path = transcript_path()
  if not path then return {} end
  local turns, texts = {}, {}
  local function close_turn()
    if #texts > 0 then table.insert(turns, table.concat(texts, "\n\n")) end
    texts = {}
  end
  for line in io.lines(path) do
    local ok, entry = pcall(vim.json.decode, line)
    if ok and type(entry) == "table" and not entry.isSidechain then
      if is_prompt(entry) then
        close_turn()
      elseif entry.type == "assistant" then
        for _, block in ipairs(entry.message.content or {}) do
          if block.type == "text" and block.text ~= "" then
            table.insert(texts, block.text)
          end
        end
      end
    end
  end
  close_turn()
  return turns
end

local function paste_quoted(reply)
  local quoted = {}
  for _, line in ipairs(vim.split(reply, "\n")) do
    table.insert(quoted, line == "" and ">" or "> " .. line)
  end
  table.insert(quoted, "")
  if vim.api.nvim_get_current_line() == "" then
    local row = math.max(vim.api.nvim_win_get_cursor(0)[1], 1)
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, quoted)
  else
    vim.api.nvim_put(quoted, "l", true, true)
  end
end

local function warn_no_reply()
  vim.notify("No Claude reply to paste (not opened from a Claude Code session?)", vim.log.levels.WARN)
end

vim.keymap.set("n", "<leader>a", function()
  local turns = replies()
  if #turns == 0 then return warn_no_reply() end
  paste_quoted(turns[#turns])
end, { desc = "Paste Claude's last reply, quoted" })

vim.keymap.set("n", "<leader>A", function()
  local turns = replies()
  if #turns == 0 then return warn_no_reply() end
  local recent = {}
  for i = #turns, math.max(#turns - 9, 1), -1 do
    table.insert(recent, turns[i])
  end
  local target = vim.api.nvim_get_current_buf()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  require("telescope.pickers").new({}, {
    prompt_title = "Claude replies",
    finder = require("telescope.finders").new_table({
      results = recent,
      entry_maker = function(reply)
        local first = vim.split(reply, "\n")[1]
        return { value = reply, display = first, ordinal = reply }
      end,
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = require("telescope.previewers").new_buffer_previewer({
      define_preview = function(self, entry)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value, "\n"))
        vim.bo[self.state.bufnr].filetype = "markdown"
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          vim.api.nvim_set_current_buf(target)
          paste_quoted(entry.value)
        end
      end)
      return true
    end,
  }):find()
end, { desc = "Pick a recent Claude reply and paste it, quoted" })
