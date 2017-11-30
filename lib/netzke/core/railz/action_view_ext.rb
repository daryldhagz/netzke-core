module Netzke
  module Railz
    module ActionViewExt
      # A helper to load Netzke and Ext JS files. Usually used in the layout.
      #
      # Params:
      #
      # [theme]
      #   The theme to apply. E.g.:
      #
      #     <%= load_netzke theme: "classic" %>
      #
      #   Themes shipped with Ext JS:
      #   * "neptune" (default in Netzke)
      #   * "classic"
      #   * "gray"
      #   * "access"
      #
      # [minified]
      #   Whether to include minified JS and styleshetes. By default is +false+ for Rails development env,
      #   +true+ otherwise
      def load_netzke(params = {})
        params[:minified] = !Rails.env.development? if params[:minified].nil?
        params[:theme] ||= "triton"

        raw([netzke_html, netzke_css_include(params), netzke_css(params), netzke_js_include(params), netzke_js(params)].join("\n"))
      end

      # Use this helper in your views to embed Netzke components. E.g.:
      #     netzke :my_grid, :class_name => "Basepack::GridPanel", :columns => [:id, :name, :created_at]
      def netzke(name, config = {})
        @rendered_classes ||= []

        # If we are the first netzke call on the page, reset components hash in the session.
        # WON'T WORK, because it breaks the browser "back" button
        # if @rendered_classes.empty?
        #   Netzke::Core.reset_components_in_session
        # end

        class_name = config[:class_name] ||= name.to_s.camelcase

        config[:name] = name

        cmp = Netzke::Base.instance_by_config(config)

        # Register the component in session
        session[:netzke_components] ||= {}
        session[:netzke_components][cmp.js_id.to_sym] = config

        content_for :netzke_js_classes, raw(cmp.js_missing_code(@rendered_classes))

        content_for :netzke_css, raw(cmp.css_missing_code(@rendered_classes))

        content_for :netzke_on_ready, raw("#{cmp.js_component_instance}\n\n#{cmp.js_component_render}")

        # Now mark all this component's dependency classes (including self) as rendered (by storing their xtypes), so that we only generate a class once per view
        @rendered_classes = (@rendered_classes + cmp.dependency_classes.map{|k| k.client_class_config.xtype}).uniq

        # Return the html for this component
        raw(cmp.js_component_html)
      end

      private

      def netzke_html
        %{
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        }
      end

      # Link tags for all the required stylsheets
      def netzke_css_include(params)
        # ExtJS base
        res = ["#{Netzke::Core.ext_uri}/build/classic/theme-#{params[:theme]}/resources/theme-#{params[:theme]}-all.css"]

        # Netzke-related dynamic css
        res << "#{request.protocol}#{request.host}#{netzke_ext_path}.css"

        res += Netzke::Core.external_ext_css

        stylesheet_link_tag(*res)
      end

      # Inline CSS specific for the page
      def netzke_css(params)
        %{
  <style type="text/css" media="screen">
    #{content_for(:netzke_css)}
  </style>} if content_for(:netzke_css).present?
      end

      # Script tags for all the required JavaScript
      def netzke_js_include(params)
        res = []

        # ExtJS
        res << (params[:minified] ? "#{Netzke::Core.ext_uri}/build/ext-all.js" : "#{Netzke::Core.ext_uri}/build/ext-all-debug.js")

        # Ext I18n
        res << "#{Netzke::Core.ext_uri}/build/classic/locale/locale-#{I18n.locale}" if I18n.locale != :en

        # Netzke-related dynamic JavaScript
        res << "#{request.protocol}#{request.host}#{netzke_ext_path}.js"

        javascript_include_tag(*res)
      end

      # Inline JavaScript for all Netzke classes on the page, as well as Ext.onReady, which renders Netzke components in this view after the page is loaded
      def netzke_js(params = {})
        res = []
        res << content_for(:netzke_js_classes)

        res << "Ext.onReady(function(){"
        res << content_for(:netzke_on_ready)
        res << "});"

        javascript_tag(res.join("\n"))
      end

    end

  end
end
