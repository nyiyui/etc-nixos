{ ... }: {
  services.ollama = {
    enable = true;
    loadModels = [
      "nomic-embed-text"
    ];
  };
}
