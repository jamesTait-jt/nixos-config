{
  lib,
  colours,
  ...
}: {
  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "[╭](fg:current_line)"
        "$os"
        "$directory"
        "$git_branch"
        "$fill"
        "$nodejs"
        "$python"
        "$cmd_duration"
        "$username"
        "$line_break"
        "$character"
      ];

      palette = "selected";

      palettes.selected = {
        foreground = colours.fg;
        background = colours.bg0;
        current_line = colours.bg4;
        primary = "#2c2a2e";
        box = colours.bg3;
        blue = colours.blue;
        cyan = colours.aqua;
        green = colours.green;
        orange = colours.orange;
        purple = colours.purple;
        red = colours.red;
        yellow = colours.yellow;
      };

      os = {
        format = "(fg:current_line)[](fg:red)[$symbol ](fg:primary bg:red)[](fg:red)";
        disabled = false;
        symbols = {
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "";
          CentOS = "";
          Debian = "";
          EndeavourOS = "";
          Fedora = "";
          FreeBSD = "";
          Garuda = "";
          Gentoo = "";
          Linux = "";
          Macos = "";
          Manjaro = "";
          Mariner = "";
          Mint = "";
          NetBSD = "";
          NixOS = "";
          OpenBSD = "";
          OpenCloudOS = "";
          openEuler = "";
          openSUSE = "";
          OracleLinux = "⊂⊃";
          Pop = "";
          Raspbian = "";
          Redhat = "";
          RedHatEnterprise = "";
          Solus = "";
          SUSE = "";
          Ubuntu = "";
          Unknown = "";
          Windows = "";
        };
      };

      directory = {
        format = "[─](fg:current_line)[](fg:purple)[󰷏 ](fg:primary bg:purple)[](fg:purple bg:box)[ $read_only$truncation_symbol$path](fg:foreground bg:box)[](fg:box)";
        home_symbol = " ~/";
        truncation_symbol = " ";
        truncation_length = 2;
        read_only = "󱧵 ";
        read_only_style = "";
      };

      git_branch = {
        format = "[─](fg:current_line)[](fg:green)[$symbol](fg:primary bg:green)[](fg:green bg:box)[ $branch](fg:foreground bg:box)[](fg:box)";
        symbol = " ";
      };

      nodejs = {
        format = "[─](fg:current_line)[](fg:green)[$symbol](fg:primary bg:green)[](fg:green bg:box)[ $version](fg:foreground bg:box)[](fg:box)";
        symbol = "󰎙 Node.js";
      };

      python = {
        format = "[─](fg:current_line)[](fg:green)[$symbol](fg:primary bg:green)[](fg:green bg:box)[ $version](fg:foreground bg:box)[](fg:box)";
        symbol = " python";
      };

      fill = {
        symbol = "─";
        style = "fg:current_line";
      };

      cmd_duration = {
        min_time = 500;
        format = "[─](fg:current_line)[](fg:orange)[ ](fg:primary bg:orange)[](fg:orange bg:box)[ $duration ](fg:foreground bg:box)[](fg:box)";
      };

      username = {
        format = "[─](fg:current_line)[](fg:yellow)[ ](fg:primary bg:yellow)[](fg:yellow bg:box)[ $user](fg:foreground bg:box)[](fg:box)";
        show_always = true;
      };
    };
  };
}
