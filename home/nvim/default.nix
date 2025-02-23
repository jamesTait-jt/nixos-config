{pkgs, ...}: {
  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        lineNumberMode = "relNumber";

        globals = {
          mapleader = " ";
        };

        options = {
          tabstop = 4;
          softtabstop = 4;
          shiftwidth = 4;
          expandtab = true;
          smartindent = true;
          textwidth = 90;
          wrap = false;
          swapfile = false;
          backup = false;
          scrolloff = 8;
          updatetime = 50;
        };

        # Set tab width to 2 for nix files - alejandro is not configurable so this makes
        # vim match the formatter.
        pluginRC.nix = ''
          vim.api.nvim_create_autocmd("FileType", {
              pattern = "nix",
              callback = function(opts)
                  local bo = vim.bo[opts.buf]
                  bo.tabstop = 2
                  bo.shiftwidth = 2
                  bo.softtabstop = 2
            end
          })
        '';

        keymaps = [
          # Block indenting
          {
            key = "<Tab>";
            mode = "n";
            action = ">>";
          }
          {
            key = "<S-Tab>";
            mode = "n";
            action = "<<";
          }
          {
            key = "<S-Tab>";
            mode = "i";
            action = "<C-O><<";
          }
          {
            key = "<Tab>";
            mode = "v";
            action = ">gv";
          }
          {
            key = "<S-Tab>";
            mode = "v";
            action = "<gv";
          }

          # Move highlighted block
          {
            key = "J";
            mode = "v";
            action = ":m '>+1<CR>gv=gv";
          }
          {
            key = "K";
            mode = "v";
            action = ":m '<-2<CR>gv=gv";
          }

          # Don't write over clipboard when pasting
          {
            key = "<leader>p";
            mode = "x";
            action = ''"_dP'';
          }
          {
            key = "<leader>d";
            mode = ["n" "v"];
            action = ''"_d'';
          }

          # Share clipboard
          {
            key = "<leader>y";
            mode = ["n" "v"];
            action = ''"+y'';
          }
          {
            key = "<leader>Y";
            mode = "n";
            action = "\"+Y";
          }

          # Unbind Q to avoid mistakes
          {
            key = "Q";
            mode = "n";
            action = "<nop>";
          }

          # QuickFix list navigation
          {
            key = "<C-k>";
            mode = "n";
            action = "<cmd>cnext<CR>zz";
          }
          {
            key = "<C-j>";
            mode = "n";
            action = "<cmd>cprev<CR>zz";
          }
          {
            key = "<leader>k";
            mode = "n";
            action = "<cmd>lnext<CR>zz";
          }
          {
            key = "<leader>j";
            mode = "n";
            action = "<cmd>lprev<CR>zz";
          }

          ####### PLUGINS ######
          {
            key = "<leader>pv";
            mode = "n";
            action = "<cmd>Neotree toggle<CR>";
          }
        ];

        extraPlugins = with pkgs.vimPlugins; {
          everforest = {
            package = everforest;
            setup = ''
              vim.g.enable_italic = true
              vim.g.everforest_transparent_background = 1
              vim.cmd.colorscheme("everforest")
            '';
          };

          telescope-nvim = {
            package = telescope-nvim;
            setup = ''
              local telescope = require("telescope")
              local actions = require("telescope.actions")

              telescope.setup({
                defaults = {
                  mappings = {
                    i = {
                      ["<C-k>"] = actions.move_selection_previous,
                      ["<C-j>"] = actions.move_selection_next,
                      ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                    }
                  }
                }
              })
            '';
          };
        };

        lsp = {
          formatOnSave = true;
        };

        languages = {
          enableLSP = true;
          enableTreesitter = true;

          nix = {
            enable = true;
            format.enable = true;
            format.type = "alejandra";

            lsp.server = "nixd";
          };

          lua.enable = true;
        };

        autocomplete.nvim-cmp = {
          enable = true;
        };

        autopairs.nvim-autopairs = {
          enable = true;
        };

        statusline.lualine = {
          enable = true;
          theme = "everforest";
          setupOpts.disabledFiletypes = ["neo-tree"];
        };

        filetree.neo-tree = {
          enable = true;
        };

        telescope = {
          enable = true;
          mappings = {
            findFiles = "<leader>pf";
            liveGrep = "<leader>pg";
          };
        };
      };
    };
  };
}
