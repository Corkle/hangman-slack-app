defmodule HangmanWeb.ErrorView do
  use HangmanWeb.Web, :view

  def render("404.html", _assigns),
    do: "Page not found"

  def render("500.html", _assigns),
    do: "Server internal error"

  def template_not_found(_template, assigns),
    do: render("500.html", assigns)
end
