module Previews
  class BaseController < ApplicationController
    before_action :set_category_configuration, :set_template, :set_organisation, :set_motif_category, :set_department

    private

    def set_template
      @template = @category_configuration.template
    end

    def set_category_configuration
      @category_configuration = CategoryConfiguration.find(params[:category_configuration_id])
    end

    def set_organisation
      @organisation = @category_configuration.organisation
    end

    def set_department
      @department = @organisation.department
    end

    def set_motif_category
      @motif_category = @category_configuration.motif_category
    end

    def set_and_format_contents
      set_contents
      format_contents
    end

    def set_contents
      set_sms_contents
      set_mail_contents
      set_letter_contents
    end

    def format_contents
      [@mail_contents, @letter_contents].each do |html_contents|
        unescape_html_contents(html_contents)
        downsize_html_headings(html_contents)
        remove_images_from_html_contents(html_contents)
      end

      [@sms_contents, @mail_contents, @letter_contents].each do |contents|
        highlight_overridable_texts(contents, overridable_texts)
      end
    end

    def unescape_html_contents(html_contents_by_action)
      html_contents_by_action.each do |action, content|
        html_contents_by_action[action] = CGI.unescapeHTML(content)
      end
    end

    def downsize_html_headings(html_contents_by_action)
      html_contents_by_action.each do |action, content|
        html_contents_by_action[action] = content.gsub("h1", "h6").gsub("h4", "p")
      end
    end

    def remove_images_from_html_contents(html_contents_by_action)
      html_contents_by_action.each do |action, content|
        html_contents_by_action[action] = content.gsub(/<img.*\/>/, "")
      end
    end

    def highlight_overridable_texts(contents_by_action, overridable_texts)
      overridable_texts.each do |overridable_text|
        contents_by_action.each do |action, content|
          contents_by_action[action] = content.gsub(
            overridable_text,
            "<span class=\"text-purple\">#{overridable_text}</span>"
          )
        end
      end
    end
  end
end
