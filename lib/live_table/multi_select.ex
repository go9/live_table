defmodule LiveTable.MultiSelect do
  @moduledoc """
  A module for handling multi-select filters in LiveTable.
  
  This module provides functionality for creating and managing multi-select filters
  that work with string values, unlike the default Select filter which only works with IDs.
  
  Supports two modes:
  - Native select - Uses native HTML select with multiple attribute (default when tags: false)
  - LiveSelect with tags - Uses LiveSelect component in tags mode for better UX (when tags: true)
  """
  
  use Phoenix.Component
  import Ecto.Query
  import LiveSelect
  
  defstruct [:field, :key, :options]
  
  @default_options %{
    label: "",
    options: [],
    selected: [],
    tags: false,  # Enable LiveSelect with tags mode
    prompt: "Select options...",
    placeholder: "Select options...",
    css_classes: "",
    label_classes: "block text-sm font-medium leading-6 text-gray-900 dark:text-gray-100 mb-2",
    select_classes: "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500",
    tag_class: "inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-medium bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400"
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
      
      <%= if @filter.options.tags do %>
        <.render_live_select filter={@filter} key={@key} />
      <% else %>
        <.render_native_select filter={@filter} key={@key} />
      <% end %>
    </div>
    """
  end
  
  defp render_live_select(assigns) do
    ~H"""
    <form phx-change="live_select_multiselect">
      <.live_select
        field={Phoenix.Component.to_form(%{})["filters[#{@key}]"]}
        id={@key}
        placeholder={@filter.options.placeholder || @filter.options.prompt}
        mode={:tags}
        value={Enum.map(@filter.options.selected, fn val ->
          option = Enum.find(@filter.options.options, fn opt -> opt.value == val end)
          if option, do: %{label: option.label, value: val}, else: %{label: val, value: val}
        end)}
        options={Enum.map(@filter.options.options, fn opt ->
          %{label: opt.label, value: opt.value}
        end)}
        text_input_class={@filter.options.select_classes}
        text_input_selected_class="bg-gray-50 dark:bg-gray-700"
        dropdown_class="absolute mt-1 w-full rounded-md bg-white dark:bg-gray-900 shadow-lg border border-gray-200 dark:border-gray-700"
        option_class="relative px-3 py-2 hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors duration-150"
        selected_option_class="bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400"
        active_option_class="bg-gray-100 dark:bg-gray-800"
        tag_class={@filter.options.tag_class}
      >
        <:option :let={option}>
          <span class="text-sm">{option.label}</span>
        </:option>
        <:tag :let={option}>
          <span class="mr-1">{option.label}</span>
          <span class="text-xs">×</span>
        </:tag>
      </.live_select>
    </form>
    """
  end
  
  defp render_native_select(assigns) do
    ~H"""
    <form phx-change="sort">
      <select
        multiple
        id={@key}
        name={"filters[#{@key}][]"}
        class={@filter.options.select_classes}
        size="4"
      >
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
      </div>
    </form>
    """
  end
end