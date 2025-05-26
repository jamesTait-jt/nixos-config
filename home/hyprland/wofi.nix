{colours, ...}: {
  programs.wofi = {
    enable = true;
    settings = {
      location = "bottom-right";
      allow_markup = true;
      width = 500;
    };
    style = ''
* {
  font-family: JetBrainsMono, monospace;
  font-size: 16px;
  color: ${colours.fg};
  background-color: ${colours.bg0};
}

window {
  background-color: ${colours.bg0};
  border: 2px solid ${colours.green};
  border-radius: 10px;
  padding: 10px;
}

#input {
  margin: 5px;
  padding: 5px;
  border: none;
  border-radius: 5px;
  background-color: ${colours.bg_green};
  color: ${colours.fg};
}

#inner-box,
#outer-box,
#scroll {
  margin: 5px;
}

#text {
  padding: 5px;
}

#entry:selected {
  background-color: ${colours.green};
  color: ${colours.bg0};
  border-radius: 5px;
};
'';
  };
}
