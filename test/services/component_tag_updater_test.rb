require "test_helper"

module Journeybook
  class ComponentTagUpdaterTest < ActiveSupport::TestCase
    test "updates one component by index" do
      markdown = <<~MARKDOWN
        # Home

        {{ hero title="Old" subtitle="Keep" }}

        {{ cta_panel title="CTA" }}
      MARKDOWN

      updated = ComponentTagUpdater.new.update(markdown, 0, title: "New")

      assert_includes updated, '{{ hero title="New" subtitle="Keep" }}'
      assert_includes updated, '{{ cta_panel title="CTA" }}'
      assert_includes updated, "# Home"
    end

    test "updates repeated components independently" do
      markdown = '{{ hero title="First" }} {{ hero title="Second" }}'

      updated = ComponentTagUpdater.new.update(markdown, 1, title: "Updated")

      assert_equal '{{ hero title="First" }} {{ hero title="Updated" }}', updated
    end

    test "preserves unknown existing props" do
      markdown = '{{ hero title="Old" custom="Keep me" }}'

      updated = ComponentTagUpdater.new.update(markdown, 0, title: "New")

      assert_equal '{{ hero title="New" custom="Keep me" }}', updated
    end

    test "moves a component down" do
      markdown = "{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}"

      updated = ComponentTagUpdater.new.move(markdown, 0, :down)

      assert_equal "{{ cta_panel title=\"Second\" }}\n\n{{ hero title=\"First\" }}", updated
    end

    test "moves a component up" do
      markdown = "# Intro\n\n{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}"

      updated = ComponentTagUpdater.new.move(markdown, 1, :up)

      assert_equal "# Intro\n\n{{ cta_panel title=\"Second\" }}\n\n{{ hero title=\"First\" }}", updated
    end

    test "reorders components by their original indexes" do
      markdown = "{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}\n\n{{ logos title=\"Third\" }}"

      updated = ComponentTagUpdater.new.reorder(markdown, [ 2, 0, 1 ])

      assert_equal "{{ logos title=\"Third\" }}\n\n{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}", updated
    end

    test "rejects incomplete component reorder indexes" do
      assert_raises ArgumentError do
        ComponentTagUpdater.new.reorder('{{ hero title="Only" }}', [])
      end
    end

    test "deletes a component" do
      markdown = "# Intro\n\n{{ hero title=\"First\" }}\n\n{{ cta_panel title=\"Second\" }}"

      updated = ComponentTagUpdater.new.delete(markdown, 0)

      assert_equal "# Intro\n\n{{ cta_panel title=\"Second\" }}", updated
    end

    test "toggles a component visibility" do
      markdown = '{{ hero title="Visible" }}'

      hidden = ComponentTagUpdater.new.toggle_visibility(markdown, 0)

      assert_equal '{{ hero title="Visible" journeybook_hidden="true" }}', hidden
      assert_equal markdown, ComponentTagUpdater.new.toggle_visibility(hidden, 0)
    end

    test "serializes collection props as JSON in single quotes" do
      markdown = ComponentTagUpdater.new.append("", :feature_grid, items: [ { title: "One" } ])

      assert_equal %({{ feature_grid items='[{"title":"One"}]' }}), markdown
    end

    test "raises when moving beyond component list" do
      assert_raises IndexError do
        ComponentTagUpdater.new.move('{{ hero title="Only" }}', 0, :up)
      end
    end
  end
end
