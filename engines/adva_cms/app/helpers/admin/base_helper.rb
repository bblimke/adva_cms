# TODO move this to the base_helper?

module Admin::BaseHelper
  def view_resource_link(resource, path, options={})
    text = options.delete(:text) || t(:'adva.resources.view')
    resource_link text, path, options.reverse_merge(:class => 'view', :id => "view_#{resource.class.to_s.downcase}_#{resource.id}")
  end

  def edit_resource_link(resource, path, options={})
    text = options.delete(:text) || t(:'adva.resources.edit')
    resource_link text, path, options.reverse_merge(:class => 'edit', :id => "edit_#{resource.class.to_s.downcase}_#{resource.id}")
  end

  def delete_resource_link(resource, path, options={})
    text = options.delete(:text) || t(:'adva.resources.delete')
    klass = resource.class.to_s
    options.reverse_merge!(:class => 'delete', :id => "delete_#{klass.downcase}_#{resource.id}", :confirm => t(:"adva.#{klass.tableize}.confirm_delete"), :method => :delete)
    resource_link text, path, options
  end

  def admin_site_select_tag
    return '' unless current_user.has_role?(:superuser) || Site.multi_sites_enabled
    options = []

    if current_user.has_role?(:superuser)
      options << [t(:'adva.links.sites_overview'), admin_sites_path]
      options << [t(:'adva.links.superusers_admins'), admin_users_path]
      options << ['------------------', '#']
    end

    # TODO only show sites where the user actually has access to!
    options += Site.all.collect { |site| [site.name, admin_site_path(site)] }

    selection = options.reverse.detect { |name, url| request.path.starts_with?(url) }

    select_tag 'site_select', options_for_select(options, selection)
  end

  def link_to_profile(site = nil, options = {})
    name = options[:name].nil? ? t(:'adva.links.profile') : options[:name]

    if site.nil? || site.new_record? || current_user.has_role?(:superuser)
      link_to(name, admin_user_path(current_user))
    else
      link_to(name, admin_site_user_path(site, current_user))
    end
  end

  def translated_locales(article, view)
    article.translated_locales.map {|tl|
      link_to tl, edit_admin_article_url( :cl => tl )
    }.join(', ')
  end

  private
  def resource_link(text, path, options={})
    link_to text, path, options
  end
end
