local M = {}

-- 자음/모음 테이블
local map = { r="ㄱ", s="ㄴ", e="ㄷ", f="ㄹ", a="ㅁ", q="ㅂ", t="ㅅ",
              d="ㅇ", w="ㅈ", c="ㅊ", z="ㅋ", x="ㅌ", v="ㅍ", g="ㅎ",
              k="ㅏ", o="ㅐ", i="ㅑ", j="ㅓ", p="ㅔ", u="ㅕ", h="ㅗ",
              y="ㅛ", n="ㅜ", b="ㅠ", m="ㅡ", l="ㅣ" }

-- 영문 → 한글 조합 (단순 매핑 예시)
local function roman_to_hangul(word)
  local res = {}
  for c in word:gmatch(".") do
    table.insert(res, map[c] or c)
  end
  return table.concat(res)
end

-- 마지막 단어 가져오기
local function get_last_word()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, col - 1)
  return before:match("(%S+)$") or ""
end

-- 변환 함수
function M.convert_last_word()
  local word = get_last_word()
  if word == "" then return end
  local converted = roman_to_hangul(word)

  -- replace word before cursor
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local new_line = line:gsub(word .. "$", converted)
  vim.api.nvim_set_current_line(new_line)
end

-- 매핑
vim.keymap.set("i", "<Space>", function()
  M.convert_last_word()
  vim.api.nvim_feedkeys(" ", "n", true)
end, { noremap = true, silent = true })

return M
