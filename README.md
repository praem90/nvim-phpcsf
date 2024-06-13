# nvim-phpcsf

## What is nvim-phpcsf?
`nvim-phpcsf` is a simple nvim plugin wrapper for both phpcs and phpcbf.
The PHP_CodeSniffer's output is populated using the telescope picker. Telescope helps to navigate through phpcs errors and warnings and preview.


## Instalation
Install [telescope](https://github.com/nvim-telescope/telescope.nvim) and [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer).
Using the [vim-plug](https://github.com/junegunn/vim-plug) plugin manager add the following in your VIM configuration (e.g. ~/.vimrc or ~/.config/nvim/init.vim when using Neovim):

```
Plug 'praem90/nvim-phpcsf'
```

To run sniffer
```
:lua require'phpcs'.cs()
```

To run beautifier
```
:lua require'phpcs'.cbf()
```

To run PHP_CodeBeautifier after save (It is recommended to run this after the buffer has been written BufWritePost)
```
augroup PHBSCF
    autocmd!
    autocmd BufWritePost,BufReadPost,InsertLeave *.php :lua require'phpcs'.cs()
    autocmd BufWritePost *.php :lua require'phpcs'.cbf()
augroup END
```

## Configurations
```vim
let g:nvim_phpcs_config_phpcs_path = 'phpcs'
let g:nvim_phpcs_config_phpcbf_path = 'phpcbf'
let g:nvim_phpcs_config_phpcs_standard = 'PSR12' " or path to your ruleset phpcs.xml
```

Using lua

```lua
require("phpcs").setup({
  phpcs = "phpcs",
  phpcbf = "phpcbf",
  standard = "PSR12"
})
```

## Thanks
[@thePrimeagen](https://github.com/theprimeagen)
[@tjDevries](https://github.com/tjDevries)

## TODO:
 - [x] Detect phpcs.xml automatically on the project root
 - [x] Add sign to current buffer

