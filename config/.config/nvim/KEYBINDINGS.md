# Neovim Keybindings (init.lua & Plugin Configurations)

All keymaps defined in **init.lua** (including those inside plugin configurations) that are globally available (or buffer‑local on LSP attach) are listed below, grouped by purpose.

---

## General
- **`<Esc>`** (`n`) – Clear search highlighting (`:nohlsearch`).
- **`<leader>q`** (`n`) – Open diagnostic quickfix list (`vim.diagnostic.setloclist`).
- **`<Esc><Esc>`** (`t`) – Exit terminal mode (`<C-\><C-n>`).

## Window / Pane Management
- **`<leader>sv`** (`n`) – Split window vertically (`<C-w>v`).
- **`<leader>sh`** (`n`) – Split window horizontally (`<C-w>s`).
- **`<C-h>`** (`n`) – Move focus to the left window.
- **`<C-l>`** (`n`) – Move focus to the right window.
- **`<C-j>`** (`n`) – Move focus to the lower window.
- **`<C-k>`** (`n`) – Move focus to the upper window.

## Telescope (Fuzzy Finder)
| Keys | Mode | Action |
|------|------|--------|
| `<leader>sht` | n | `builtin.help_tags` – Help tags search |
| `<leader>sk`  | n | `builtin.keymaps` – Show keymaps |
| `<leader>sf`  | n | `builtin.find_files` – Find files |
| `<leader>ss`  | n | `builtin.builtin` – Telescope picker selector |
| `<leader>sw`  | n & v | `builtin.grep_string` – Grep current word |
| `<leader>sg`  | n | `builtin.live_grep` – Live grep |
| `<leader>sd`  | n | `builtin.diagnostics` – Search diagnostics |
| `<leader>sr`  | n | `builtin.resume` – Resume last picker |
| `<leader>s.`  | n | `builtin.oldfiles` – Recent files |
| `<leader>sc`  | n | `builtin.commands` – Commands picker |
| `<leader><leader>` | n | `builtin.buffers` – List open buffers |
| `<leader>/`   | n | Fuzzy search in current buffer (custom wrapper) |
| `<leader>s/`  | n | Live grep limited to open files |
| `<leader>sn`  | n | Find files in your Neovim config directory |

## LSP‑Related (Buffer‑Local on `LspAttach`)
### Direct LSP buffer mappings (created inside the `LspAttach` autocommand)
| Keys | Mode | Action |
|------|------|--------|
| `grr` | n | `builtin.lsp_references` – Find references |
| `gri` | n | `builtin.lsp_implementations` – Go to implementation |
| `grd` | n | `builtin.lsp_definitions` – Go to definition |
| `gO`  | n | `builtin.lsp_document_symbols` – Document symbols |
| `gW`  | n | `builtin.lsp_dynamic_workspace_symbols` – Workspace symbols |
| `grt` | n | `builtin.lsp_type_definitions` – Type definitions |

### Convenience mappings added by the `map` helper (also buffer‑local)
- **`gd`** – Go to definition (`telescope.lsp_definitions`).
- **`gr`** – Find references (`telescope.lsp_references`).
- **`gI`** – Go to implementation (`telescope.lsp_implementations`).
- **`<leader>D`** – Show type definition (`telescope.lsp_type_definitions`).
- **`<leader>ds`** – Document symbols (`telescope.lsp_document_symbols`).
- **`<leader>ws`** – Workspace symbols (`telescope.lsp_dynamic_workspace_symbols`).
- **`<leader>rn`** – Rename symbol (`vim.lsp.buf.rename`).
- **`<leader>ca`** – Code action (`vim.lsp.buf.code_action`) – works in Normal and Visual modes.
- **`gD`** – Go to declaration (`vim.lsp.buf.declaration`).
- **`<leader>th`** – Toggle inlay hints (`vim.lsp.inlay_hint.enable`).

## Plugin‑Specific Keymaps
### `conform.nvim` (Auto‑format)
- **`<leader>f`** (`n`) – Format the current buffer (`require('conform').format`).

### `todo-comments.nvim`
- **`<leader>ct`** – Open TodoTrouble view.
- **`<leader>cT`** – Open TodoTelescope view.

### `mini.files`
- **`<leader>e`** (`n`) – Open the MiniFiles explorer.

### `mini.trailspace`
- **`<leader>cw`** (`n`) – Trim trailing whitespace.

---

**Note:** `<leader>` is set to the space bar (`vim.g.mapleader = " "`). All mappings above are defined in `init.lua` or its inline plugin configurations, and are therefore active when Neovim starts.
