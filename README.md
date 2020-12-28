# vis-git-status

`vis-git-status` is a  [vis](https://github.com/martanne/vis) plugin that wil display git information about the current file in the status bar (branch, has branch changed, how many commits ahead/behind).

### Installation
Add the Lua file to you Vis path (`~/.config/vis`) and add this to your `visrc.lua`:
```
require("vis-git-status")
```
Clone the repo to your vis plugins directory (`~/.config/vis/plugins`) and add
this to your `visrc.lua`:
```
require("plugins/vis-git-status")
```
