require File.expand_path(File.dirname(__FILE__) + '/../../../test_helper')

class AdminBaseHelperTest < ActionView::TestCase
  include Admin::BaseHelper

  attr_accessor :request

  def setup
    super
    @site = Site.first
    stub(self).current_user.returns User.new

    stub(self).admin_sites_path.returns 'admin_sites_path'
    stub(self).admin_site_user_path.returns 'admin_site_user_path'
    stub(self).admin_users_path.returns 'admin_users_path'
    stub(self).admin_user_path.returns 'admin_user_path'

    @controller = TestController.new
    @request = ActionController::TestRequest.new
  end

  # view_resource_link
  test "#view_resource_link" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = view_resource_link(resource, 'url')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'view', 'view_resource_1', 'View')
  end

  test "#view_resource_link uses options hash" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = view_resource_link(resource, 'url', :title => 'title')
    html.should have_tag('a[href=?][class=?][id=?][title=?]', 'url', 'view', 'view_resource_1', 'title', 'View')
  end

  test "#view_resource_link uses options hash and overrides default" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = view_resource_link(resource, 'url', :id => 'id')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'view', 'id', 'View')
  end

  test "#view_resource_link uses custom text" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = view_resource_link(resource, 'url', :text => 'text')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'view', 'view_resource_1', 'text')
  end

  # edit_resource_link
  test "#edit_resource_link" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = edit_resource_link(resource, 'url')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'edit', 'edit_resource_1', 'Edit')
  end

  test "#edit_resource_link uses options hash" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = edit_resource_link(resource, 'url', :title => 'title')
    html.should have_tag('a[href=?][class=?][id=?][title=?]', 'url', 'edit', 'edit_resource_1', 'title', 'Edit')
  end

  test "#edit_resource_link uses options hash and overrides default" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = edit_resource_link(resource, 'url', :id => 'id')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'edit', 'id', 'Edit')
  end

  test "#edit_resource_link uses custom text" do
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = edit_resource_link(resource, 'url', :text => 'text')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'edit', 'edit_resource_1', 'text')
  end

  # delete_resource_link
  test "#delete_resource_link" do
    stub(self).protect_against_forgery? { false } # let's make it easier
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = delete_resource_link(resource, 'url')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'delete', 'delete_resource_1', 'Delete')
  end

  test "#delete_resource_link uses options hash" do
    stub(self).protect_against_forgery? { false } # let's make it easier
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = delete_resource_link(resource, 'url', :title => 'title')
    html.should have_tag('a[href=?][class=?][id=?][title=?]', 'url', 'delete', 'delete_resource_1', 'title', 'Delete')
  end

  test "#delete_resource_link uses options hash and overrides default" do
    stub(self).protect_against_forgery? { false } # let's make it easier
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = delete_resource_link(resource, 'url', :id => 'id')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'delete', 'id', 'Delete')
  end

  test "#delete_resource_link uses custom text" do
    stub(self).protect_against_forgery? { false } # let's make it easier
    resource = Object.new
    stub(resource).id { 1 }
    stub(resource).class { 'Resource' }
    html = delete_resource_link(resource, 'url', :text => 'text')
    html.should have_tag('a[href=?][class=?][id=?]', 'url', 'delete', 'delete_resource_1', 'text')
  end

  # admin_site_select_tag
  test "#admin_site_select_tag with current user being a superuser
        it shows the site overview option in the site select menu" do
    stub(current_user).has_role?(:superuser).returns true
    admin_site_select_tag.should have_tag('select#site_select option[value=?]', 'admin_sites_path')
  end

  test "#admin_site_select_tag with current user being a superuser
        it shows the user manager option in the site select menu" do
    stub(current_user).has_role?(:superuser).returns true
    admin_site_select_tag.should have_tag('select#site_select option[value=?]', 'admin_users_path')
  end

  test "#admin_site_select_tag with current user not being a superuser
      it shows the site overview option in the site select menu" do
    admin_site_select_tag.should_not have_tag('select#site_select option[value=?]', 'admin_sites_path')
  end

  test "#admin_site_select_tag with current user not being a superuser
      it shows the user manager option in the site select menu" do
    admin_site_select_tag.should_not have_tag('select#site_select option[value=?]', 'admin_users_path')
  end

  # link_to_profile
  test "#link_to_profile returns admin/sites/1/users/1 as a profile link if site is set" do
    link_to_profile(@site).should == "<a href=\"admin_site_user_path\">Profile</a>"
  end

  test "#link_to_profile returns admin/users/1 as a profile link if no site is set" do
    link_to_profile.should == "<a href=\"admin_user_path\">Profile</a>"
  end

  test "#link_to_profile returns admin/users/1 as a profile link if site is a new record" do
    link_to_profile(Site.new).should == "<a href=\"admin_user_path\">Profile</a>"
  end

  test "#link_to_profile returns custom link name for profile if specified" do
    link_to_profile(Site.new, :name => 'Dummy').should == "<a href=\"admin_user_path\">Dummy</a>"
  end

  test "#link_to_profile returns admin/users/1 as a profile link if site is set but user is a superuser" do
    stub(current_user).has_role?(:superuser).returns true
    link_to_profile(@site).should == "<a href=\"admin_user_path\">Profile</a>"
  end
end
