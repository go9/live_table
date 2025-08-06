defmodule LiveTable.MultiSelect do
  @moduledoc """
  A module for handling select and multi-select filters in LiveTable using LiveSelect.
  
  This module provides functionality for creating and managing select filters
  that work with string values, using the LiveSelect component.
  
  Supports two modes:
  - Single select (default) - Standard dropdown selection
  - Multi-select with tags - Enable with `tags: true` option
  """
  
  use Phoenix.Component
  import Ecto.Query
  import LiveSelect
  
  defstruct [:field, :key, :options]
  
  @default_options %{
    label: "",
    options: [],
    selected: nil,
    tags: false,  # Enable multi-select with tags
    prompt: "Select option...",
    placeholder: "Select option...",
    css_classes: "",
    label_classes: "block text-sm font-medium leading-6 text-gray-900 dark:text-gray-100 mb-2",
    select_classes: "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500",
    tag_class: "inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-medium bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400"
  }
  
  @doc """
  Creates a new select filter using LiveSelect.
  
  ## Examples
      
      # Single select (default)
      MultiSelect.new(:status, "status_filter", %{
        label: "Filter by Status",
        options: [
          %{label: "Active", value: "active"},
          %{label: "Inactive", value: "inactive"}
        ]
      })
      
      # Multi-select with tags
      MultiSelect.new(:role, "role_filter", %{
        label: "Filter by Role",
        tags: true,
        selected: [],
        options: [
          %{label: "Administrator", value: "admin"},
          %{label: "Regular User", value: "user"}
        ]
      })
  """
  def new(field, key, options \\ %{}) do
    complete_options = Map.merge(@default_options, options)
    # Ensure selected is properly initialized based on tags mode
    complete_options = 
      if complete_options.tags and is_nil(complete_options.selected) do
        Map.put(complete_options, :selected, [])
      else
        complete_options
      end
    %__MODULE__{field: field, key: key, options: complete_options}
  end
  
  @doc """
  Applies the filter to an Ecto query.
  """
  def apply(acc, %__MODULE__{field: _field, options: %{selected: []}}), do: acc
  def apply(acc, %__MODULE__{field: _field, options: %{selected: nil}}), do: acc
  def apply(acc, %__MODULE__{field: _field, options: %{selected: ""}}), do: acc
  
  # Multi-select (tags mode)
  def apply(acc, %__MODULE__{field: field, options: %{selected: values, tags: true}}) when is_list(values) and values != [] do
    dynamic([resource: r], ^acc and field(r, ^field) in ^values)
  end
  
  # Single select
  def apply(acc, %__MODULE__{field: field, options: %{selected: value}}) when is_binary(value) and value != "" do
    dynamic([resource: r], ^acc and field(r, ^field) == ^value)
  end
  
  def apply(acc, _), do: acc
  
  @doc """
  Renders the select filter component using LiveSelect.
  """
  attr :filter, __MODULE__, required: true
  attr :key, :string, required: true
  attr :applied_filters, :map, default: %{}
  
  def render(assigns) do
    ~H"""
    <div id={"select_filter_#{@key}"} class={@filter.options.css_classes}>
      <label :if={@filter.options.label} for={@key} class={@filter.options.label_classes}>
        {@filter.options.label}
      </label>
      
      <div phx-change="sort">
        <.live_select
          field={Phoenix.Component.to_form(%{})[(if @filter.options.tags, do: "filters[#{@key}]", else: "filters[#{@key}]")]}
          id={@key}
          placeholder={@filter.options.placeholder || @filter.options.prompt}
          mode={if @filter.options.tags, do: :tags, else: :single}
          value={format_value(@filter.options)}
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
          <:tag :let={option} :if={@filter.options.tags}>
            <span class="mr-1">{option.label}</span>
            <span class="text-xs">×</span>
          </:tag>
        </.live_select>
      </div>
    </div>
    """
  end
  
  defp format_value(%{selected: selected, tags: true, options: options}) when is_list(selected) do
    Enum.map(selected, fn val ->
      option = Enum.find(options, fn opt -> opt.value == val end)
      if option, do: %{label: option.label, value: val}, else: %{label: val, value: val}
    end)
  end
  
  defp format_value(%{selected: selected, tags: false}) when is_binary(selected) and selected != "" do
    selected
  end
  
  defp format_value(_), do: nil
end