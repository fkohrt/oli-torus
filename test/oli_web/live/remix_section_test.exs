defmodule OliWeb.RemixSectionLiveTest do
  use OliWeb.ConnCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Oli.Seeder
  alias Lti_1p3.Tool.ContextRoles
  alias Oli.Delivery.Sections
  alias Oli.Accounts

  describe "remix section live test" do
    setup [:setup_session]

    test "remix section mount as open and free", %{
      conn: conn,
      admin: admin,
      map: %{
        oaf_section_1: oaf_section_1,
        unit1_container: unit1_container,
        revision1: revision1,
        revision2: revision2
      }
    } do
      conn =
        Plug.Test.init_test_session(conn, %{})
        |> Pow.Plug.assign_current_user(admin, OliWeb.Pow.PowHelpers.get_pow_config(:author))

      conn =
        get(
          conn,
          Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, oaf_section_1.slug)
        )

      {:ok, view, _html} = live(conn)

      assert view |> element("#entry-#{unit1_container.revision.resource_id}") |> has_element?()
      assert view |> element("#entry-#{revision1.resource_id}") |> has_element?()
      assert view |> element("#entry-#{revision2.resource_id}") |> has_element?()
    end

    test "remix section mount as instructor", %{
      conn: conn,
      map: %{
        section_1: section_1,
        unit1_container: unit1_container,
        revision1: revision1,
        revision2: revision2
      }
    } do
      conn =
        get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, section_1.slug))

      {:ok, view, _html} = live(conn)

      assert view |> element("#entry-#{unit1_container.revision.resource_id}") |> has_element?()
      assert view |> element("#entry-#{revision1.resource_id}") |> has_element?()
      assert view |> element("#entry-#{revision2.resource_id}") |> has_element?()
    end

    test "remix section mount as product manager", %{
      conn: conn
    } do
      # create a product
      %{
        prod1: prod1,
        author: product_author,
        publication: publication,
        revision1: revision1,
        revision2: revision2
      } =
        Seeder.base_project_with_resource2()
        |> Seeder.create_product(%{title: "My 1st product", amount: Money.new(:USD, 100)}, :prod1)

      {:ok, _prod} = Sections.create_section_resources(prod1, publication)

      conn =
        Plug.Test.init_test_session(conn, %{})
        |> Pow.Plug.assign_current_user(
          product_author,
          OliWeb.Pow.PowHelpers.get_pow_config(:author)
        )

      conn =
        get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, prod1.slug))

      {:ok, view, _html} = live(conn)

      assert view |> element("#entry-#{revision1.resource_id}") |> has_element?()
      assert view |> element("#entry-#{revision2.resource_id}") |> has_element?()
    end

    test "remix section navigation", %{
      conn: conn,
      map: %{
        section_1: section1,
        unit1_container: unit1_container,
        nested_revision1: nested_revision1,
        nested_revision2: nested_revision2
      }
    } do
      conn =
        get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, section1.slug))

      {:ok, view, _html} = live(conn)

      # navigate to a lower unit
      view
      |> element("#entry-#{unit1_container.revision.resource_id} button.entry-title")
      |> render_click()

      assert view |> element("#entry-#{unit1_container.revision.resource_id}") |> has_element?() ==
               false

      assert view |> element("#entry-#{nested_revision1.resource_id}") |> has_element?()
      assert view |> element("#entry-#{nested_revision2.resource_id}") |> has_element?()

      # navigate back to root container
      view
      |> element("#curriculum-back")
      |> render_click()

      assert view |> element("#entry-#{unit1_container.revision.resource_id}") |> has_element?()
    end

    test "remix section reorder and save", %{
      conn: conn,
      map: %{
        section_1: section
      }
    } do
      conn =
        get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, section.slug))

      {:ok, view, _html} = live(conn)

      render_hook(view, "reorder", %{"sourceIndex" => "0", "dropIndex" => "2"})

      view
      |> element("#save")
      |> render_click()

      assert_redirect(view, Routes.page_delivery_path(conn, :index, section.slug))
    end

    test "remix section items and add materials items are ordered correctly", %{
      conn: conn,
      admin: admin,
      map: %{
        oaf_section_1: oaf_section_1,
        unit1_container: unit1_container,
        latest1: latest1,
        latest2: latest2
      }
    } do
      conn =
        Plug.Test.init_test_session(conn, %{})
        |> Pow.Plug.assign_current_user(admin, OliWeb.Pow.PowHelpers.get_pow_config(:author))

      {:ok, view, _html} = live(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, oaf_section_1.slug))

      assert view
        |> element(".curriculum-entries > div:nth-child(2)")
        |> render() =~ "#{latest1.title}"

      assert view
        |> element(".curriculum-entries > div:nth-child(4)")
        |> render() =~ "#{latest2.title}"

      assert view
        |> element(".curriculum-entries > div:nth-child(6)")
        |> render() =~ "#{unit1_container.revision.title}"

      # click add materials and assert is listing units first
      view
      |> element("button[phx-click=\"show_add_materials_modal\"]")
      |> render_click()

      view
      |> element(".hierarchy > div:first-child > button[phx-click=\"HierarchyPicker.select_publication\"]")
      |> render_click()

      assert view
        |> element(".hierarchy > div[id^=\"hierarchy_item_\"]:nth-child(1)")
        |> render() =~ "#{unit1_container.revision.title}"

      assert view
        |> element(".hierarchy > div[id^=\"hierarchy_item_\"]:nth-child(2)")
        |> render() =~ "#{latest1.title}"

      assert view
        |> element(".hierarchy > div[id^=\"hierarchy_item_\"]:nth-child(3)")
        |> render() =~ "#{latest2.title}"
    end
  end

  describe "breadcrumbs" do
    setup [:setup_session]

    test "as instructor", %{
      conn: conn,
      map: %{
        section_1: section_1
      }
    } do
      conn =
        get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, section_1.slug))

      {:ok, _view, html} = live(conn)

      refute html =~ "Admin"
      assert html =~ "Customize Content"
    end

    test "as admin", %{
      conn: conn,
      admin: admin,
      map: %{
        section_1: section_1
      }
    } do
      conn =
        Plug.Test.init_test_session(conn, %{})
        |> Pow.Plug.assign_current_user(admin, OliWeb.Pow.PowHelpers.get_pow_config(:author))
        |> get(Routes.live_path(OliWeb.Endpoint, OliWeb.Delivery.RemixSection, section_1.slug))

      {:ok, _view, html} = live(conn)

      assert html =~ "Admin"
      assert html =~ "Customize Content"
    end
  end

  defp setup_session(%{conn: conn}) do
    map = Seeder.base_project_with_resource4()

    {:ok, instructor} =
      Accounts.update_user_platform_roles(
        user_fixture(%{can_create_sections: true, independent_learner: true}),
        [
          Lti_1p3.Tool.PlatformRoles.get_role(:institution_instructor)
        ]
      )

    admin = author_fixture(%{system_role_id: Oli.Accounts.SystemRole.role_id().admin})

    {:ok, _enrollment} =
      Sections.enroll(instructor.id, map.section_1.id, [
        ContextRoles.get_role(:context_instructor)
      ])

    conn =
      Plug.Test.init_test_session(conn, lti_session: nil, section_slug: map.section_1.slug)
      |> Pow.Plug.assign_current_user(instructor, OliWeb.Pow.PowHelpers.get_pow_config(:user))

    {:ok,
     conn: conn,
     map: map,
     admin: admin,
     author: map.author,
     institution: map.institution,
     project: map.project,
     publication: map.publication}
  end
end
