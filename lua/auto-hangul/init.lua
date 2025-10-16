
return Mlocal M = {}

---------------------------------------------------------------------
-- 두벌식 자판 매핑
---------------------------------------------------------------------
local CONSONANTS = {
  r="ㄱ", R="ㄲ", s="ㄴ", e="ㄷ", E="ㄸ", f="ㄹ", a="ㅁ", q="ㅂ", Q="ㅃ",
  t="ㅅ", T="ㅆ", d="ㅇ", w="ㅈ", W="ㅉ", c="ㅊ", z="ㅋ", x="ㅌ", v="ㅍ", g="ㅎ"
}

local VOWELS = {
  k="ㅏ", o="ㅐ", i="ㅑ", O="ㅒ", j="ㅓ", p="ㅔ", u="ㅕ", P="ㅖ",
  h="ㅗ", hk="ㅘ", ho="ㅙ", hl="ㅚ", y="ㅛ",
  n="ㅜ", nj="ㅝ", np="ㅞ", nl="ㅟ",
  b="ㅠ", m="ㅡ", ml="ㅢ", l="ㅣ"
}

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

local function compose(cho, jung, jong)
  jong = jong or -1
  return vim.fn.nr2char(((cho * 21 + jung) * 28 + jong + 1) + 0xAC00)
end

---------------------------------------------------------------------
-- 한글 오토마타
---------------------------------------------------------------------
local function roman_to_hangul(input)
  local result = {}
  local cho, jung, jong = nil, nil, nil
  local i = 1

  while i <= #input do
    local c = input:sub(i,i)
    local two = input:sub(i,i+1)
    local v = VOWELS[two] or VOWELS[c]
    local cons = CONSONANTS[c]

    if cons and not jung then
      if cho and jung then
        table.insert(result, compose(CHO[cho], JUNG[jung], JONG[jong or ""] or -1))
        cho, jung, jong = cons, nil, nil
      else
        cho = cons
      end
      i = i + 1
    elseif v then
      jung = v
      i = i + (#two == 2 and VOWELS[two] and 2 or 1)
    elseif cons and jung then
      -- 종성 후보
      local next_two = input:sub(i,i+1)
      if VOWELS[next_two] or VOWELS[input:sub(i+1,i+1)] then
        -- 다음에 모음 -> 새 음절
        table.insert(result, compose(CHO[cho], JUNG[jung], JONG[jong or ""] or -1))
        cho, jung, jong = cons, nil, nil
      else
        jong = cons
      end
      i = i + 1
    else
      -- 처리 불가한 문자
      if cho and jung then
        table.insert(result, compose(CHO[cho], JUNG[jung], JONG[jong or ""] or -1))
      elseif cho then
        table.insert(result, cho)
      end
      cho, jung, jong = nil, nil, nil
      table.insert(result, c)
      i = i + 1
    end
  end

  if cho and jung then
    table.insert(result, compose(CHO[cho], JUNG[jung], JONG[jong or ""] or -1))
  elseif cho then
    table.insert(result, cho)
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
  vim.fn.cursor(0, start + #converted + 1)
end

---------------------------------------------------------------------
-- Insert 모드에서 스페이스 눌렀을 때 자동 변환
---------------------------------------------------------------------
vim.keymap.set("i","<Space>",function()
  M.convert_last_word()
  vim.api.nvim_feedkeys(" ","i",false)
end,{noremap=true,silent=true})

return M
