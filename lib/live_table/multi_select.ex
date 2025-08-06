defmodule LiveTable.MultiSelect do
  @moduledoc """
  A module for handling multi-select filters in LiveTable.
  
  This module provides functionality for creating and managing multi-select filters
  that work with string values, unlike the default Select filter which only works with IDs.
  
  Uses native HTML select element with optional multiple selection support.
  """
  
  use Phoenix.Component
  import Ecto.Query
  
  defstruct [:field, :key, :options]
  
  @default_options %{
    label: "",
    options: [],
    selected: [],
    multiple: true,  # Enable multiple selection
    size: 4,  # Number of visible options in select
    prompt: "Select options...",
    css_classes: "",
    label_classes: "block text-sm font-medium leading-6 text-gray-900 dark:text-gray-100 mb-2",
    select_classes: "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
  }
  
  @doc """
  Creates a new MultiSelect filter.
  
  ## Examples
      
      MultiSelect.new(:role, "role_filter", %{
        label: "Filter by Role",
        options: [
          %{label: "Administrator", value: "admin"},
          %{label: "Regular User", value: "user"}
        ]
      })
  """
  def new(field, key, options \\ %{}) do
    complete_options = Map.merge(@default_options, options)
    %__MODULE__{field: field, key: key, options: complete_options}
  end
  
  @doc """
  Applies the filter to an Ecto query.
  """
  def apply(acc, %__MODULE__{field: _field, options: %{selected: []}}), do: acc
  
  def apply(acc, %__MODULE__{field: field, options: %{selected: values}}) when is_list(values) and values != [] do
    dynamic([resource: r], ^acc and field(r, ^field) in ^values)
  end
  
  def apply(acc, _), do: acc
  
  @doc """
  Renders the multi-select filter component.
  """
  attr :filter, __MODULE__, required: true
  attr :key, :string, required: true
  attr :applied_filters, :map, default: %{}
  
  def render(assigns) do
    ~H"""
    <div id={"multiselect_filter_#{@key}"} class={@filter.options.css_classes}>
      <label :if={@filter.options.label} for={@key} class={@filter.options.label_classes}>
        {@filter.options.label}
      </label>
      
      <form phx-change="sort">
        <select
          multiple={@filter.options.multiple}
          id={@key}
          name={"filters[#{@key}][]"}
          class={@filter.options.select_classes}
          size={@filter.options.size}
        >
          <option value="" disabled class="text-gray-500">
            {@filter.options.prompt}
          </option>
          <%= for option <- @filter.options.options do %>
            <option value={option.value} selected={option.value in @filter.options.selected}>
              {option.label}
            </option>
          <% end %>
        </select>
        
        <div class="mt-2 flex gap-2">
          <button
            type="button"
            onclick={"document.getElementById('#{@key}').selectedIndex = -1; document.getElementById('#{@key}').form.requestSubmit()"}
            class="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100"
          >
            Clear selection
          </button>
          <span class="text-xs text-gray-500 dark:text-gray-400">
            <%= if @filter.options.multiple do %>
              Hold Ctrl/Cmd to select multiple
            <% end %>
          </span>
        </div>
      </form>
    </div>
    """
  end
end