{pkgs, ...}: {
  gtk.enable = true;

  home.pointerCursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
    x11 = {
      enable = true;
      defaultCursor = "phinger-cursors-dark";
    };
  };
}
