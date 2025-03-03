{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Productivity app
    notion-app-enhanced
  ];
}
