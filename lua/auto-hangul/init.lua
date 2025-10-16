-- lua/auto-hangul/init.lua
local M = {}

---------------------------------------------------------------------
-- 🔡 두벌식 키보드 매핑
---------------------------------------------------------------------
local CONS_MAP = {
  r="ㄱ", R="ㄲ", rt="ㄳ",
  s="ㄴ", sw="ㄵ", sg="ㄶ",
  e="ㄷ", E="ㄸ",
  f="ㄹ", fr="ㄺ", fa="ㄻ", fq="ㄼ", ft="ㄽ", fx="ㄾ", fv="ㄿ", fg="ㅀ",
  a="ㅁ",
  q="ㅂ", Q="ㅃ", qt="ㅄ",
  t="ㅅ", T="ㅆ",
  d="ㅇ",
  w="ㅈ", W="ㅉ",
  c="ㅊ",
  z="ㅋ", x="ㅌ", v="ㅍ", g="ㅎ"
}

local VOWEL_MAP = {
  k="ㅏ", o="ㅐ", i="ㅑ", O="ㅒ",
  j="ㅓ", p="ㅔ", u="ㅕ", P="ㅖ",
  h="ㅗ", hk="ㅘ", ho="ㅙ", hl="ㅚ",
  y="ㅛ",
  n="ㅜ", nj="ㅝ", np="ㅞ", nl="ㅟ",
  b="ㅠ",
  m="ㅡ", ml="ㅢ",
  l="ㅣ"
}

---------------------------------------------------------------------
-- 🔢 유니코드 한글 조합용 테이블
---------------------------------------------------------------------
local CHO = {
  ["ㄱ"]=0, ["ㄲ"]=1, ["ㄴ"]=2, ["ㄷ"]=3, ["ㄸ"]=4,
  ["ㄹ"]=5, ["ㅁ"]=6, ["ㅂ"]=7, ["ㅃ"]=8, ["ㅅ"]=9,
  ["ㅆ"]=10, ["ㅇ"]=11, ["ㅈ"]=12, ["ㅉ"]=13, ["ㅊ"]=14,
  ["ㅋ"]=15, ["ㅌ"]=16, ["ㅍ"]=17, ["ㅎ"]=18
}

local JUNG = {
  ["ㅏ"]=0, ["ㅐ"]=1, ["ㅑ"]=2, ["ㅒ"]=3, ["ㅓ"]=4, ["ㅔ"]=5, ["ㅕ"]=6, ["ㅖ"]=7,
  ["ㅗ"]=8, ["ㅘ"]=9, ["ㅙ"]=10, ["ㅚ"]=11, ["ㅛ"]=12, ["ㅜ"]=13, ["ㅝ"]=14,
  ["ㅞ"]=15, ["ㅟ"]=16, ["ㅠ"]=17, ["ㅡ"]=18, ["ㅢ"]=19, ["ㅣ"]=20
}

local JONG = {
  [""]= -1, ["ㄱ"]=0, ["ㄲ"]=1, ["ㄳ"]=2, ["ㄴ"]=3, ["ㄵ"]=4, ["ㄶ"]=5,
  ["ㄷ"]=6, ["ㄹ"]=7, ["ㄺ"]=8, ["ㄻ"]=9, ["ㄼ"]=10, ["ㄽ"]=11, ["ㄾ"]=12,
  ["ㄿ"]=13, ["ㅀ"]=14, ["ㅁ"]=15, ["ㅂ"]=16, ["ㅄ"]=17, ["ㅅ"]=18, ["ㅆ"]=19,
  ["ㅇ"]=20, ["ㅈ"]=21, ["ㅊ"]=22, ["ㅋ"]=23, ["ㅌ"]=24, ["ㅍ"]=25, ["ㅎ"]=26
}

---------------------------------------------------------------------
-- 🧩 한글 유니코드 조합
---------------------------------------------------------------------
local function compose_hangul(cho, jung, jong)
  jong = jong or -1
  local code = ((cho * 21 + jung) * 28 + jong + 1) + 0xAC00
  if code >= 0xAC00 and code <= 0xD7A3 then
    return vim.fn.nr2char(code)
  end
  return ""
end

---------------------------------------------------------------------
-- 🔍 입력 문자 판별 함수
---------------------------------------------------------------------
local function get_consonant(c) return CONS_MAP[c:lower()] end
local function get_vowel(c) return VOWEL_MAP[c:lower()] end
local function is_consonant_key(c) return get_consonant(c) ~= nil end
local function is_vowel_key(c) return get_vowel(c) ~= nil end

---------------------------------------------------------------------
-- 🧠 영문 → 한글 변환 (두벌식 조합)
---------------------------------------------------------------------
local function try_convert_hangul(word)
  local result = {}
  local i = 1
  local len = #word

  while i <= len do
    local c = word:sub(i,i)
    if not is_consonant_key(c) then
      return nil,0
    end

    local cho = get_consonant(c)
    i = i + 1

    -- 모음 탐색
    local jung=nil
    local vowel_len=0
    if i+1<=len then
      local two = word:sub(i,i+1):lower()
      if VOWEL_MAP[two] then jung=VOWEL_MAP[two]; vowel_len=2 end
    end
    if not jung and i<=len then
      local one = word:sub(i,i)
      if VOWEL_MAP[one:lower()] then jung=VOWEL_MAP[one:lower()]; vowel_len=1 end
    end
    if not jung then return nil,0 end
    i = i + vowel_len

    -- 종성 탐색
    local jong=nil; local jong_len=0
    if i<=len then
      local next_char = word:sub(i,i)
      if is_consonant_key(next_char) then
        local next_next = word:sub(i+1,i+1)
        if not is_vowel_key(next_next) then
          jong=get_consonant(next_char)
          jong_len=1
        end
      end
    end
    if jong then i=i+jong_len end

    local cho_idx=CHO[cho]; local jung_idx=JUNG[jung]; local jong_idx=jong and JONG[jong] or -1
    if cho_idx and jung_idx then
      table.insert(result, compose_hangul(cho_idx,jung_idx,jong_idx))
    end
  end

  return table.concat(result), i-1
end

local function roman_to_hangul(word)
  local converted, consumed = try_convert_hangul(word)
  if converted and consumed == #word then return converted end
  return word
end

---------------------------------------------------------------------
-- 🪶 마지막 단어 변환
---------------------------------------------------------------------
local function get_last_word()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, col - 1)
  local word = before:match("([%w]+)$") or ""
  return word, #before - #word
end

function M.convert_last_word()
  local word, start_pos = get_last_word()
  if word == "" then return end
  local converted = roman_to_hangul(word)
  if converted == word then return end

  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local before = line:sub(1, start_pos)
  local after = line:sub(col)
  local new_line = before .. converted .. after
  vim.api.nvim_set_current_line(new_line)
  vim.fn.cursor(0, start_pos + #converted + 1)
end

---------------------------------------------------------------------
-- 🇰🇷 한글/영문 모드 전환 (kk / ee)
---------------------------------------------------------------------
local hangul_mode=false
local last_k=0
local last_e=0
local THRESHOLD=300
local function now_ms() return math.floor(vim.loop.hrtime()/1e6) end

vim.keymap.set("i","k",function()
  vim.api.nvim_feedkeys("k","n",true)
  vim.schedule(function()
    local t=now_ms()
    if t-last_k<=THRESHOLD and t>last_k then
      local line=vim.api.nvim_get_current_line()
      local col=vim.fn.col(".")
      if col>2 and line:sub(col-2,col-1)=="kk" then
        local before=line:sub(1,col-3)
        local after=line:sub(col)
        vim.api.nvim_set_current_line(before..after)
        vim.fn.cursor(0,#before+1)
        hangul_mode=true
        vim.notify("Hangul Mode",vim.log.levels.INFO)
        last_k=0
        return
      end
    end
    last_k=t
  end)
end,{noremap=true,silent=true})

vim.keymap.set("i","e",function()
  vim.api.nvim_feedkeys("e","n",true)
  vim.schedule(function()
    local t=now_ms()
    if t-last_e<=THRESHOLD and t>last_e then
      local line=vim.api.nvim_get_current_line()
      local col=vim.fn.col(".")
      if col>2 and line:sub(col-2,col-1)=="ee" then
        local before=line:sub(1,col-3)
        local after=line:sub(col)
        vim.api.nvim_set_current_line(before..after)
        vim.fn.cursor(0,#before+1)
        hangul_mode=false
        vim.notify("English Mode",vim.log.levels.INFO)
        last_e=0
        return
      end
    end
    last_e=t
  end)
end,{noremap=true,silent=true})

---------------------------------------------------------------------
-- 🪄 Space 키로 자동 변환
---------------------------------------------------------------------
vim.keymap.set("i","<Space>",function()
  last_k, last_e = 0,0
  if hangul_mode then
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col(".")
    local before = line:sub(1,col-1)
    local word = before:match("([%w]+)$") or ""
    if word~="" then
      local converted = roman_to_hangul(word)
      local start_pos = #before - #word
      local after = line:sub(col)
      local new_line = before:sub(1,start_pos)..converted..after
      vim.api.nvim_set_current_line(new_line)
      vim.fn.cursor(0,start_pos+#converted+1)
    end
  end
  vim.api.nvim_feedkeys(" ","i",false)
end,{noremap=true,silent=true})

---------------------------------------------------------------------
-- 모드 초기화
---------------------------------------------------------------------
vim.api.nvim_create_autocmd("InsertLeave",{
  callback=function()
    hangul_mode=false
    last_k, last_e = 0,0
  end
})

return M
