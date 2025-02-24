{
  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--no-first-run"
      "--force-dark-mode"
    ];
    extensions = [
      {id = "nngceckbapebfimnlniiiahkandclblb";}
      {id = "bmnlcjabgnpnenekpadlanbbkooimhnj";}
    ];
  };
}
