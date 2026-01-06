defmodule SahajyogWeb.QuillEditor do
  @moduledoc """
  Component for rendering a Quill rich text editor with Phoenix LiveView integration.
  Uses a JavaScript hook for editor initialization and content synchronization.
  """
  use Phoenix.Component

  attr :field, Phoenix.HTML.FormField, required: true
  attr :placeholder, :string, default: "Write your content here..."
  attr :class, :string, default: ""

  def quill_editor(assigns) do
    ~H"""
    <div phx-hook="QuillEditor" id={"quill-#{@field.id}"} class={@class} phx-update="ignore">
      <input
        type="hidden"
        id={@field.id}
        name={@field.name}
        value={@field.value}
        placeholder={@placeholder}
      />
      <div class="quill-editor"></div>
    </div>
    """
  end
end
