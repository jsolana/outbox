defmodule Outbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :outbox,
      version: "0.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      name: "Outbox",
      package: package(),
      source_url: "https://github.com/jsolana/outbox",
      docs: docs()
    ]
  end

  defp description() do
    "Outbox pattern support for Elixir"
  end

  defp package() do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Javier Solana"],
      links: %{"GitHub" => "https://github.com/jsolana/outbox"}
    }
  end

  defp docs() do
    [
      # The main page in the docs
      main: "readme",
      logo: "guides/logo.png",
      extras: ["README.md"],
      before_closing_body_tag: fn
        :html ->
          """
          <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
          <script>mermaid.initialize({startOnLoad: true})</script>
          """

        _ ->
          ""
      end
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Observability
      {:telemetry, "~> 1.2"},
      # Encoding / Decoding
      {:jason, "~> 1.4"},
      # Persistence
      {:ecto, "~> 3.10.3"},
      {:ecto_sql, "~> 3.10.2"},
      # Event processing
      {:gen_stage, "~> 1.2"},
      # Doc
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      #  Testing
      {:mox, "~> 1.0", only: :test},
      # Code analysis
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
