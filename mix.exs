defmodule DocusignElixirSampleApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :docusign_elixir_sample_app,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:docusign],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:docusign, path: "../docusign_elixir"},
      {:timex, "~> 3.4"},
      {:oauth2, "~> 2.0", override: true},
      {:hackney, "~> 1.15 and >= 1.15.2"}
    ]
  end

  # Run mix escript.build to build an executable.
  defp escript() do
    [main_module: DocusignElixirSampleApp.CLI]
  end
end
