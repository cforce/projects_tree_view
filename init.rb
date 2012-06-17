require 'redmine'

# Patches to the Redmine core.
require 'projects_tree_view'

Redmine::Plugin.register :projects_tree_view do
  name 'Projects Tree View plugin'
  author 'Chris Peterson and Github community'
  description 'This is a Redmine plugin which will turn the projects page into a tree view'
  version '0.0.7'
end

class ProjectsTreeViewListener < Redmine::Hook::ViewListener

  # Adds javascript and stylesheet tags
  def view_layouts_base_html_head(context)
    javascript_include_tag('projects_tree_view', :plugin => :projects_tree_view) +
    stylesheet_link_tag('projects_tree_view', :plugin => :projects_tree_view)
  end
  
end
