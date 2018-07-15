defmodule Harnais.Form.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :harnais_form,
      version: @version,
      elixir: "~> 1.6",
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/ianrumford/harnais_form",
      homepage_url: "https://github.com/ianrumford/harnais_form",
      docs: [
        extras: ["./README.md", "./CHANGELOG.md"],
        deps: [harnais: "https://hexdocs.pm/harnais/"]
      ],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:harnais_error, ">= 0.3.0"},
      {:harnais_list, ">= 0.1.0"},
      {:plymio_codi, ">= 0.3.1"},
      {:ex_doc, "~> 0.18.3", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Ian Rumford"],
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/ianrumford/harnais_form"}
    ]
  end

  defp description do
    """
    harnais_form: The Quoted Form Harness for the Harnais Family
    """
  end
end
