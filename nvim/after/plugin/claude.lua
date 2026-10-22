local sessions_dir = vim.fn.expand("~") .. "/.claude/sessions/"

local function read_session(pid)
  local path = sessions_dir .. pid .. ".json"
  if vim.fn.filereadable(path) == 0 then return nil end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if ok and type(data) == "table" then return data end
end

local function parent_pid(pid)
  local out = vim.fn.system({ "ps", "-o", "ppid=", "-p", tostring(pid) })
  return tonumber(vim.trim(out))
end

local function ancestor_session_id()
  local pid = vim.uv.os_getppid()
  while pid and pid > 1 do
    local data = read_session(pid)
    if data and data.sessionId then return data.sessionId end
    pid = parent_pid(pid)
  end
end

local function tmux_window_session_id()
  local pane = vim.env.TMUX_PANE
  if not pane or pane == "" then return nil end
  local window = vim.trim(vim.fn.system({ "tmux", "display", "-p", "-t", pane, "#{window_id}" }))
  local best, best_start = nil, 0
  for _, path in ipairs(vim.fn.glob(sessions_dir .. "*.json", false, true)) do
    local data = read_session(vim.fn.fnamemodify(path, ":t:r"))
    local tmux = data and data.tmux
    if tmux and tmux:match(":(@%d+)") == window and (data.startedAt or 0) > best_start then
      best, best_start = data.sessionId, data.startedAt or 0
    end
  end
  return best
end

local function transcript_path()
  local projects = vim.fn.expand("~") .. "/.claude/projects/"
  for _, id in ipairs({ ancestor_session_id(), vim.env.CLAUDE_CODE_SESSION_ID, tmux_window_session_id() }) do
    if id and id ~= "" then
      local matches = vim.fn.glob(projects .. "*/" .. id .. ".jsonl", false, true)
      if matches[1] then return matches[1] end
    end
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
  local turns, texts, after_tool = {}, {}, false
  local function close_turn()
    if #texts > 0 then table.insert(turns, table.concat(texts, "\n\n")) end
    texts, after_tool = {}, false
  end
  for line in io.lines(path) do
    local ok, entry = pcall(vim.json.decode, line)
    if ok and type(entry) == "table" and not entry.isSidechain then
      if is_prompt(entry) then
        close_turn()
      elseif entry.type == "assistant" then
        for _, block in ipairs(entry.message.content or {}) do
          if block.type == "tool_use" then
            after_tool = true
          elseif block.type == "text" and block.text ~= "" then
            if after_tool then texts, after_tool = {}, false end
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
