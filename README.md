## Simple PHP_CodeSniffer plugin for nvim

To run sniffer
`:lua require'phpcs'.cs()`

To run beautifier
`:lua require'phpcs'.cbf()`

Available configurations
```
let g:nvim_phpcs_config_phpcs_path = 'phpcs'
let g:nvim_phpcs_config_phpcbf_path = 'phpcbf'
let g:nvim_phpcs_config_phpcs_standard = 'PSR2' " path to your ruleset phpcs.xml
```


### TODO:
 [ ] Bind phpcs to local quickfix list
 [ ] And or Add sign to current buffer

