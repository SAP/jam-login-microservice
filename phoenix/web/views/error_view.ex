defmodule LoginProxy.ErrorView do
  use LoginProxy.Web, :view
  require Logger

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", assigns) do
    try do
      Logger.error "Internal server error: #{inspect(Map.delete(assigns, :conn))}"
      "Internal server error"
    rescue
      _ -> "Internal server error"
    end
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end
end
