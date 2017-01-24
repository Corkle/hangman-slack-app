defmodule HangmanWeb.ErrorView do
  use HangmanWeb.Web, :view

  def render("404.json", _assigns),
    do: %{errors: %{detail: "Page not found"}}

  def render("500.json", _assigns),
    do: %{errors: %{detail: "Internal server error"}}

  def template_not_found(_template, assigns),
    do: render("500.json", assigns)
end
