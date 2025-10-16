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

-- Get consonant with case fallback
local function get_consonant(c)
  if CONS_MAP[c] then
    return CONS_MAP[c]
  elseif CONS_MAP[c:lower()] then
    return CONS_MAP[c:lower()]
  end
  return nil
end

-- Get vowel with case fallback
local function get_vowel(c)
  if VOWEL_MAP[c] then
    return VOWEL_MAP[c]
  elseif VOWEL_MAP[c:lower()] then
    return VOWEL_MAP[c:lower()]
  end
  return nil
end

-- Check if key is a consonant key
local function is_consonant_key(c)
  return get_consonant(c) ~= nil
end

-- Check if key is a vowel key
local function is_vowel_key(c)
  return get_vowel(c) ~= nil
end

-- Try to convert word to Hangul, returns converted string and number of chars consumed
local function try_convert_hangul(word)
  local result = {}
  local i = 1
  local len = #word

  while i <= len do
    local c = word:sub(i, i)

    -- Must start with consonant
    if is_consonant_key(c) then
      local cho = get_consonant(c)
      local start_i = i
      i = i + 1

      -- Try to find vowel
      local jung = nil
      local vowel_len = 0

      -- Try 2-char vowel first (with case-insensitive)
      if i + 1 <= len then
        local two_char = word:sub(i, i + 1)
        local two_char_lower = two_char:lower()
        if VOWEL_MAP[two_char_lower] then
          jung = VOWEL_MAP[two_char_lower]
          vowel_len = 2
        end
      end

      -- Try 1-char vowel (with case fallback)
      if not jung and i <= len then
        local one_char = word:sub(i, i)
        jung = get_vowel(one_char)
        if jung then
          vowel_len = 1
        end
      end

      if jung then
        i = i + vowel_len

        -- Try to find final consonant (jong)
        local jong = nil
        local jong_len = 0

        -- Try 2-char final consonant (with case-insensitive)
        if i + 1 <= len then
          local two_char = word:sub(i, i + 1)
          local two_char_lower = two_char:lower()
          if CONS_MAP[two_char_lower] then
            -- Check if next char is a vowel (if so, this is next syllable's cho)
            local next_pos = i + 2
            if next_pos > len or not is_vowel_key(word:sub(next_pos, next_pos)) then
              jong = CONS_MAP[two_char_lower]
              jong_len = 2
            end
          end
        end

        -- Try 1-char final consonant (with case fallback)
        if not jong and i <= len then
          local one_char = word:sub(i, i)
          local jong_candidate = get_consonant(one_char)
          if jong_candidate then
            -- Check if next char is a vowel (if so, this is next syllable's cho)
            local next_pos = i + 1
            if next_pos > len or not is_vowel_key(word:sub(next_pos, next_pos)) then
              jong = jong_candidate
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
          -- Failed to compose, return nil to indicate failure
          return nil, 0
        end
      else
        -- No vowel found after consonant, cannot be Hangul
        return nil, 0
      end
    else
      -- Starts with non-consonant (vowel or other), cannot be Hangul
      return nil, 0
    end
  end

  -- Successfully converted entire word
  return table.concat(result), i - 1
end

-- Korean romanization to Hangul conversion
local function roman_to_hangul(word)
  -- Try to convert the entire word
  local converted, chars_consumed = try_convert_hangul(word)

  -- Only return converted if entire word was consumed
  if converted and chars_consumed == #word then
    return converted
  end

  -- Otherwise, return original word (it's probably English)
  return word
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

-- Keymap: trigger conversion with 'kk'
vim.keymap.set("i", "k", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, col - 1)

  -- Check if last character is 'k'
  if before:sub(-1) == "k" then
    -- This is the second 'k', trigger conversion
    -- Get word before the first 'k'
    local before_first_k = before:sub(1, -2)
    local word = before_first_k:match("([%w]+)$") or ""

    if word ~= "" then
      local converted = roman_to_hangul(word)

      -- Only convert if it's different (valid Hangul conversion)
      if converted ~= word then
        -- Remove the word and both 'k's, then insert converted
        local start_pos = #before_first_k - #word
        local after = line:sub(col)
        local new_line = before_first_k:sub(1, start_pos) .. converted .. after

        vim.api.nvim_set_current_line(new_line)

        -- Set cursor after converted text
        local new_col = start_pos + #converted + 1
        vim.fn.cursor(0, new_col)
        return
      end
    end
  end

  -- Default: just insert 'k'
  vim.api.nvim_feedkeys("k", "n", true)
end, { noremap = true, silent = true })

return M
