# NVIM-RUN
Plugin for [Neovim](https://neovim.io) that adds the `:Run` command.

## How does it know what to run?
You decide what it is going to run. Everything is configurable with a `YAML` file in your `$HOME` directory [or in your project root directory (WiP)]. You can specify different behaviors per different file type or one sequence of command to execute.

## Install
TODO

## Use
1. Create `.nvim-run.yaml` in your HOME directory
2. Create the configuration per each file type you are interested (keep in mind that it CANNOT interact with the user):
```YAML
tex:
  - "lualatex --halt-on-error --interaction=nonstopmode main.tex"
  - "open main.pdf"
python:
  - "python3 #"
```
3. Open your file and type `:Run`

### Special characters
- `#`: absolute file path of the file open in the buffer in which you invoke `:Run`
