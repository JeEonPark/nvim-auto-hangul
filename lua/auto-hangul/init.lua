local M = {}

-- 2-beolsik keyboard mapping
-- Consonants (초성/종성)
local CONS_MAP = {
  r = "ㄱ", R = "ㄲ", rt = "ㄳ",
  s = "ㄴ", sw = "ㄵ", sg = "ㄶ",
  e = "ㄷ", E = "ㄸ",
  f = "ㄹ", fr = "ㄺ", fa = "ㄻ", fq = "ㄼ", ft = "ㄽ", fx = "ㄾ", fv = "ㄿ", fg = "ㅀ",
  a = "ㅁ",
  q = "ㅂ", Q = "ㅃ", qt = "ㅄ",
  t = "ㅅ", T = "ㅆ",
  d = "ㅇ",
  w = "ㅈ", W = "ㅉ",
  c = "ㅊ",
  z = "ㅋ",
  x = "ㅌ",
  v = "ㅍ",
  g = "ㅎ"
}

-- Vowels (중성)
local VOWEL_MAP = {
  k = "ㅏ", o = "ㅐ", i = "ㅑ", O = "ㅒ",
  j = "ㅓ", p = "ㅔ", u = "ㅕ", P = "ㅖ",
  h = "ㅗ", hk = "ㅘ", ho = "ㅙ", hl = "ㅚ",
  y = "ㅛ",
  n = "ㅜ", nj = "ㅝ", np = "ㅞ", nl = "ㅟ",
  b = "ㅠ",
  m = "ㅡ", ml = "ㅢ",
  l = "ㅣ"
}

-- Unicode indices for Hangul composition
local CHO = {
  ["ㄱ"] = 0, ["ㄲ"] = 1, ["ㄴ"] = 2, ["ㄷ"] = 3, ["ㄸ"] = 4,
  ["ㄹ"] = 5, ["ㅁ"] = 6, ["ㅂ"] = 7, ["ㅃ"] = 8, ["ㅅ"] = 9,
  ["ㅆ"] = 10, ["ㅇ"] = 11, ["ㅈ"] = 12, ["ㅉ"] = 13, ["ㅊ"] = 14,
  ["ㅋ"] = 15, ["ㅌ"] = 16, ["ㅍ"] = 17, ["ㅎ"] = 18
}

local JUNG = {
  ["ㅏ"] = 0, ["ㅐ"] = 1, ["ㅑ"] = 2, ["ㅒ"] = 3, ["ㅓ"] = 4,
  ["ㅔ"] = 5, ["ㅕ"] = 6, ["ㅖ"] = 7, ["ㅗ"] = 8, ["ㅘ"] = 9,
  ["ㅙ"] = 10, ["ㅚ"] = 11, ["ㅛ"] = 12, ["ㅜ"] = 13, ["ㅝ"] = 14,
  ["ㅞ"] = 15, ["ㅟ"] = 16, ["ㅠ"] = 17, ["ㅡ"] = 18, ["ㅢ"] = 19,
  ["ㅣ"] = 20
}

local JONG = {
  [""] = -1,
  ["ㄱ"] = 0, ["ㄲ"] = 1, ["ㄳ"] = 2, ["ㄴ"] = 3, ["ㄵ"] = 4,
  ["ㄶ"] = 5, ["ㄷ"] = 6, ["ㄹ"] = 7, ["ㄺ"] = 8, ["ㄻ"] = 9,
  ["ㄼ"] = 10, ["ㄽ"] = 11, ["ㄾ"] = 12, ["ㄿ"] = 13, ["ㅀ"] = 14,
  ["ㅁ"] = 15, ["ㅂ"] = 16, ["ㅄ"] = 17, ["ㅅ"] = 18, ["ㅆ"] = 19,
  ["ㅇ"] = 20, ["ㅈ"] = 21, ["ㅊ"] = 22, ["ㅋ"] = 23, ["ㅌ"] = 24,
  ["ㅍ"] = 25, ["ㅎ"] = 26
}

-- Unicode Hangul composition
-- Base: 0xAC00 (가)
-- Formula: ((cho * 21) + jung) * 28 + jong + 1 + 0xAC00
local function compose_hangul(cho, jung, jong)
  jong = jong or -1
  return vim.fn.nr2char(((cho * 21 + jung) * 28 + jong + 1) + 0xAC00)
end

-- Check if key is a consonant key
local function is_consonant_key(c)
  return CONS_MAP[c] ~= nil
end

-- Check if key is a vowel key
local function is_vowel_key(c)
  return VOWEL_MAP[c] ~= nil
end

-- Check if word can be converted to Hangul (must have at least one Korean pattern)
local function can_be_hangul(word)
  -- Check if there's at least one consonant followed by a vowel
  for i = 1, #word - 1 do
    local c = word:sub(i, i)
    local next_c = word:sub(i + 1, i + 1)
    if is_consonant_key(c) and is_vowel_key(next_c) then
      return true
    end
  end
  return false
end

-- Korean romanization to Hangul conversion
local function roman_to_hangul(word)
  -- If word cannot be Hangul, return as-is
  if not can_be_hangul(word) then
    return word
  end

  local result = {}
  local i = 1
  local len = #word

  while i <= len do
    local c = word:sub(i, i)

    -- Must start with consonant
    if is_consonant_key(c) then
      local cho = CONS_MAP[c]
      local start_i = i
      i = i + 1

      -- Try to find vowel
      local jung = nil
      local vowel_len = 0

      -- Try 2-char vowel first
      if i + 1 <= len then
        local two_char = word:sub(i, i + 1)
        if VOWEL_MAP[two_char] then
          jung = VOWEL_MAP[two_char]
          vowel_len = 2
        end
      end

      -- Try 1-char vowel
      if not jung and i <= len then
        local one_char = word:sub(i, i)
        if VOWEL_MAP[one_char] then
          jung = VOWEL_MAP[one_char]
          vowel_len = 1
        end
      end

      if jung then
        i = i + vowel_len

        -- Try to find final consonant (jong)
        local jong = nil
        local jong_len = 0

        -- Try 2-char final consonant
        if i + 1 <= len then
          local two_char = word:sub(i, i + 1)
          if CONS_MAP[two_char] then
            -- Check if next char is a vowel (if so, this is next syllable's cho)
            local next_pos = i + 2
            if next_pos > len or not is_vowel_key(word:sub(next_pos, next_pos)) then
              jong = CONS_MAP[two_char]
              jong_len = 2
            end
          end
        end

        -- Try 1-char final consonant
        if not jong and i <= len then
          local one_char = word:sub(i, i)
          if CONS_MAP[one_char] then
            -- Check if next char is a vowel (if so, this is next syllable's cho)
            local next_pos = i + 1
            if next_pos > len or not is_vowel_key(word:sub(next_pos, next_pos)) then
              jong = CONS_MAP[one_char]
              jong_len = 1
            end
          end
        end

        if jong then
          i = i + jong_len
        end

        -- Compose syllable
        local cho_idx = CHO[cho]
        local jung_idx = JUNG[jung]
        local jong_idx = jong and JONG[jong] or -1

        if cho_idx and jung_idx then
          table.insert(result, compose_hangul(cho_idx, jung_idx, jong_idx))
        else
          -- Fallback: just add the original characters
          table.insert(result, c)
        end
      else
        -- No vowel found, add original character and continue
        table.insert(result, c)
      end
    else
      -- Not a consonant key, just add it
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
