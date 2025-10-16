local M = {}

---------------------------------------------------------------------
-- 두벌식 키보드 매핑
---------------------------------------------------------------------
local CONSONANTS = {
  r="ㄱ", R="ㄲ", s="ㄴ", e="ㄷ", E="ㄸ", f="ㄹ", a="ㅁ",
  q="ㅂ", Q="ㅃ", t="ㅅ", T="ㅆ", d="ㅇ", w="ㅈ", W="ㅉ",
  c="ㅊ", z="ㅋ", x="ㅌ", v="ㅍ", g="ㅎ"
}

local VOWELS = {
  k="ㅏ", o="ㅐ", i="ㅑ", O="ㅒ", j="ㅓ", p="ㅔ", u="ㅕ", P="ㅖ",
  h="ㅗ", hk="ㅘ", ho="ㅙ", hl="ㅚ",
  y="ㅛ", n="ㅜ", nj="ㅝ", np="ㅞ", nl="ㅟ",
  b="ㅠ", m="ㅡ", ml="ㅢ", l="ㅣ"
}

---------------------------------------------------------------------
-- 유니코드 조합 테이블
---------------------------------------------------------------------
local CHO = { ["ㄱ"]=0,["ㄲ"]=1,["ㄴ"]=2,["ㄷ"]=3,["ㄸ"]=4,["ㄹ"]=5,["ㅁ"]=6,["ㅂ"]=7,["ㅃ"]=8,
              ["ㅅ"]=9,["ㅆ"]=10,["ㅇ"]=11,["ㅈ"]=12,["ㅉ"]=13,["ㅊ"]=14,["ㅋ"]=15,["ㅌ"]=16,
              ["ㅍ"]=17,["ㅎ"]=18 }

local JUNG = { ["ㅏ"]=0,["ㅐ"]=1,["ㅑ"]=2,["ㅒ"]=3,["ㅓ"]=4,["ㅔ"]=5,["ㅕ"]=6,["ㅖ"]=7,
               ["ㅗ"]=8,["ㅘ"]=9,["ㅙ"]=10,["ㅚ"]=11,["ㅛ"]=12,["ㅜ"]=13,["ㅝ"]=14,["ㅞ"]=15,
               ["ㅟ"]=16,["ㅠ"]=17,["ㅡ"]=18,["ㅢ"]=19,["ㅣ"]=20 }

local JONG = { [""]= -1,["ㄱ"]=0,["ㄲ"]=1,["ㄳ"]=2,["ㄴ"]=3,["ㄵ"]=4,["ㄶ"]=5,["ㄷ"]=6,["ㄹ"]=7,
               ["ㄺ"]=8,["ㄻ"]=9,["ㄼ"]=10,["ㄽ"]=11,["ㄾ"]=12,["ㄿ"]=13,["ㅀ"]=14,["ㅁ"]=15,
               ["ㅂ"]=16,["ㅄ"]=17,["ㅅ"]=18,["ㅆ"]=19,["ㅇ"]=20,["ㅈ"]=21,["ㅊ"]=22,["ㅋ"]=23,
               ["ㅌ"]=24,["ㅍ"]=25,["ㅎ"]=26 }

local function compose(cho,jung,jong)
  jong = jong or -1
  return vim.fn.nr2char(((cho*21+jung)*28+jong+1)+0xAC00)
end

---------------------------------------------------------------------
-- 두벌식 로마자 → 한글 변환
---------------------------------------------------------------------
local function roman_to_hangul(input)
  local result = {}
  local i = 1
  while i <= #input do
    local c = input:sub(i,i)
    local cho = CONSONANTS[c]
    if not cho then
      table.insert(result, c)
      i = i + 1
    else
      i = i + 1
      local jung, jong
      local two = input:sub(i,i+1)
      local one = input:sub(i,i)
      if VOWELS[two] then jung = VOWELS[two]; i = i + 2
      elseif VOWELS[one] then jung = VOWELS[one]; i = i + 1 end
      if not jung then
        table.insert(result, cho)
      else
        local next_c = input:sub(i,i)
        if CONSONANTS[next_c] then
          local nn = input:sub(i+1,i+1)
          if nn == "" or not VOWELS[nn] then
            jong = CONSONANTS[next_c]
            i = i + 1
          end
        end
        table.insert(result, compose(CHO[cho], JUNG[jung], jong and JONG[jong] or -1))
      end
    end
  end
  return table.concat(result)
end

---------------------------------------------------------------------
-- 커서 앞 단어 변환
---------------------------------------------------------------------
local function get_last_word()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, col - 1)
  local word = before:match("([%w]+)$") or ""
  return word, #before - #word
end

function M.convert_last_word()
  local word, start = get_last_word()
  if word == "" then return end
  local converted = roman_to_hangul(word)
  if converted == word then return end
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, start)
  local after = line:sub(col)
  vim.api.nvim_set_current_line(before .. converted .. after)
  vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), start + #converted + 1 })
end

---------------------------------------------------------------------
-- 모드 전환
---------------------------------------------------------------------
local hangul_mode = false
local pending_k = false
local pending_e = false
local THRESHOLD = 200 -- ms
local function now_ms() return math.floor(vim.loop.hrtime() / 1e6) end

-- 🧠 k 입력 처리
vim.keymap.set("i", "k", function()
  local current_time = now_ms()

  if pending_k then
    -- 두 번째 k → Hangul Mode 전환
    pending_k = false
    -- 이전 k는 출력하지 않음, 둘 다 제거
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col(".")
    local before = line:sub(1, col - 3)
    local after = line:sub(col)
    vim.api.nvim_set_current_line(before .. after)
    vim.fn.cursor(0, #before + 1)
    hangul_mode = true
    vim.notify("Hangul Mode", vim.log.levels.INFO)
    return
  end

  -- 첫 번째 k → 잠시 보류
  pending_k = true
  local this_k_time = current_time

  -- 200ms 뒤에 아직 두 번째 k가 없으면 k 삽입
  vim.defer_fn(function()
    if pending_k and now_ms() - this_k_time >= THRESHOLD then
      pending_k = false
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_get_current_line()
      local before = line:sub(1, col)
      local after = line:sub(col + 1)
      vim.api.nvim_set_current_line(before .. "k" .. after)
      vim.api.nvim_win_set_cursor(0, { row, col + 1 })
    end
  end, THRESHOLD)
end, { noremap = true, silent = true })

-- 🧠 e 입력 처리
vim.keymap.set("i", "e", function()
  local current_time = now_ms()

  if pending_e then
    -- 두 번째 e → English Mode 전환
    pending_e = false
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col(".")
    local before = line:sub(1, col - 3)
    local after = line:sub(col)
    vim.api.nvim_set_current_line(before .. after)
    vim.fn.cursor(0, #before + 1)
    hangul_mode = false
    vim.notify("English Mode", vim.log.levels.INFO)
    return
  end

  pending_e = true
  local this_e_time = current_time

  vim.defer_fn(function()
    if pending_e and now_ms() - this_e_time >= THRESHOLD then
      pending_e = false
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_get_current_line()
      local before = line:sub(1, col)
      local after = line:sub(col + 1)
      vim.api.nvim_set_current_line(before .. "e" .. after)
      vim.api.nvim_win_set_cursor(0, { row, col + 1 })
    end
  end, THRESHOLD)
end, { noremap = true, silent = true })

---------------------------------------------------------------------
-- 스페이스 누를 때 변환 (무한 루프 X)
---------------------------------------------------------------------
vim.keymap.set("i", "<Space>", function()
  if hangul_mode then
    M.convert_last_word()
  end

  -- 스페이스 직접 삽입 (feedkeys 사용 X)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  vim.api.nvim_set_current_line(before .. " " .. after)
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })
end, { noremap = true, silent = true })

---------------------------------------------------------------------
-- InsertLeave 시 초기화
---------------------------------------------------------------------
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    hangul_mode = false
    last_k, last_e = 0, 0
  end,
})

return M
