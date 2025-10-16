# auto-hangul.nvim

Neovim plugin for automatic Korean (Hangul) input conversion using English keyboard layout (2-beolsik).

## Features

- Automatic conversion of romanized Korean input to proper Hangul characters
- Proper syllable composition (초성, 중성, 종성)
- Space bar trigger for conversion
- Supports compound vowels and final consonants

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'JeEonPark/auto-hangul',
  config = function()
    require('auto-hangul')
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'JeEonPark/auto-hangul',
  config = function()
    require('auto-hangul')
  end
}
```

## Usage

Type Korean words using the English keyboard layout and press **Space** to convert:

### Examples

- `rkr` + Space → `각`
- `gksmf` + Space → `한글`
- `qkdrnr` + Space → `바보`
- `dkssud` + Space → `안녕`

### Keyboard Layout (2-beolsik)

#### Consonants (초성)
```
r=ㄱ s=ㄴ e=ㄷ f=ㄹ a=ㅁ q=ㅂ t=ㅅ d=ㅇ
w=ㅈ c=ㅊ z=ㅋ x=ㅌ v=ㅍ g=ㅎ
R=ㄲ E=ㄸ Q=ㅃ T=ㅆ W=ㅉ
```

#### Vowels (중성)
```
k=ㅏ o=ㅐ i=ㅑ O=ㅒ j=ㅓ p=ㅔ u=ㅕ P=ㅖ
h=ㅗ y=ㅛ n=ㅜ b=ㅠ m=ㅡ l=ㅣ
hk=ㅘ ho=ㅙ hl=ㅚ nj=ㅝ np=ㅞ nl=ㅟ ml=ㅢ
```

## How It Works

The plugin uses Unicode Hangul composition to combine Korean characters:
- Base character: `0xAC00` (가)
- Formula: `((cho * 21) + jung) * 28 + jong + 1 + 0xAC00`

Where:
- `cho` = initial consonant index (0-18)
- `jung` = vowel index (0-20)
- `jong` = final consonant index (-1 for none, 0-26)

## Configuration

Currently, the plugin is triggered automatically on Space in insert mode. You can modify the keymap in your config:

```lua
local auto_hangul = require('auto-hangul')

-- Custom keymap (example: use <C-Space> instead)
vim.keymap.del("i", "<Space>")  -- Remove default mapping
vim.keymap.set("i", "<C-Space>", function()
  auto_hangul.convert_last_word()
  vim.api.nvim_feedkeys(" ", "n", true)
end, { noremap = true, silent = true })
```

## License

MIT
