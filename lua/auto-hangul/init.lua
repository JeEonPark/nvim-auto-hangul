local M = {}

-- Korean keyboard layout mapping (2-beolsik)
local CHO = {
  r = 0, R = 1, s = 2, e = 3, E = 4, f = 5, a = 6, q = 7, Q = 8,
  t = 9, T = 10, d = 11, w = 12, W = 13, c = 14, z = 15, x = 16,
  v = 17, g = 18
}

local JUNG = {
  k = 0, o = 1, i = 2, O = 3, j = 4, p = 5, u = 6, P = 7, h = 8,
  hk = 9, ho = 10, y = 11, n = 12, nj = 13, np = 14, nl = 15,
  b = 16, m = 17, ml = 18, l = 19
}

local JONG = {
  [""] = -1,
  r = 0, R = 1, rt = 2, s = 3, sw = 4, sg = 5, e = 6, f = 7, fr = 8,
  fa = 9, fq = 10, ft = 11, fx = 12, fv = 13, fg = 14, a = 15, q = 16,
  qt = 17, t = 18, T = 19, d = 20, w = 21, c = 22, z = 23, x = 24,
  v = 25, g = 26
}

-- Unicode Hangul composition
-- Base: 0xAC00 (가)
-- Formula: ((cho * 21) + jung) * 28 + jong + 1 + 0xAC00
local function compose_hangul(cho, jung, jong)
  jong = jong or -1
  return utf8.char(((cho * 21 + jung) * 28 + jong + 1) + 0xAC00)
end

-- Check if character is Korean consonant
local function is_cho(c)
  return CHO[c] ~= nil
end

-- Check if character is Korean vowel
local function is_jung(c)
  return JUNG[c] ~= nil
end

-- Korean romanization to Hangul conversion
local function roman_to_hangul(word)
  local result = {}
  local i = 1
  local len = #word

  while i <= len do
    local c = word:sub(i, i)

    if is_cho(c) then
      local cho_idx = CHO[c]
      local jung_start = i + 1

      -- Find vowel
      if jung_start <= len then
        local jung_candidate = word:sub(jung_start, jung_start)
        local jung_idx = nil

        -- Check for compound vowel (2 chars)
        if jung_start + 1 <= len then
          local two_char = word:sub(jung_start, jung_start + 1)
          if JUNG[two_char] then
            jung_idx = JUNG[two_char]
            jung_start = jung_start + 1
          end
        end

        -- Single vowel
        if not jung_idx and JUNG[jung_candidate] then
          jung_idx = JUNG[jung_candidate]
        end

        if jung_idx then
          local jong_start = jung_start + 1
          local jong_idx = nil

          -- Find final consonant
          if jong_start <= len then
            local jong_candidate = word:sub(jong_start, jong_start)

            -- Check for compound final consonant (2 chars)
            if jong_start + 1 <= len then
              local two_char = word:sub(jong_start, jong_start + 1)
              if JONG[two_char] then
                jong_idx = JONG[two_char]
                jong_start = jong_start + 1
              end
            end

            -- Single final consonant
            if not jong_idx and JONG[jong_candidate] then
              -- Make sure next char is not a vowel (if it is, this consonant is next syllable's cho)
              if jong_start + 1 > len or not is_jung(word:sub(jong_start + 1, jong_start + 1)) then
                jong_idx = JONG[jong_candidate]
              end
            end
          end

          table.insert(result, compose_hangul(cho_idx, jung_idx, jong_idx))
          i = jong_idx and jong_start + 1 or jung_start + 1
        else
          -- No vowel found, just add the consonant
          table.insert(result, c)
          i = i + 1
        end
      else
        table.insert(result, c)
        i = i + 1
      end
    else
      -- Not a consonant, just add it
      table.insert(result, c)
      i = i + 1
    end
  end

  return table.concat(result)
end

-- Get last word before cursor
local function get_last_word()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, col - 1)
  local word = before:match("([%w]+)$") or ""
  return word, #before - #word
end

-- Convert last word to Hangul
function M.convert_last_word()
  local word, start_pos = get_last_word()
  if word == "" or #word == 0 then return end

  local converted = roman_to_hangul(word)
  if converted == word then return end -- No conversion needed

  -- Replace word before cursor
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, start_pos)
  local after = line:sub(col)
  local new_line = before .. converted .. after

  vim.api.nvim_set_current_line(new_line)

  -- Adjust cursor position
  local new_col = start_pos + #converted + 1
  vim.fn.cursor(0, new_col)
end

-- 매핑
vim.keymap.set("i", "<Space>", function()
  M.convert_last_word()
  vim.api.nvim_feedkeys(" ", "n", true)
end, { noremap = true, silent = true })

return M
