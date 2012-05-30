require_dependency 'projects_helper'

module ProjectstreeviewProjectsHelperPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    
    ###
    # Compatibility helpers
    ###
    
    # Redmine Core trunk@r2734 (0.9-devel)
    # Returns true if the method is defined, else it returns false
    def users_by_role_implemented
      return ProjectsController.method_defined?("users_by_role")
    end

    # Redmine Core trunk@r2750 (0.9-devel)
    # Returns true if the method is defined, else it returns false
    def authorize_global_implemented
      return ApplicationController.method_defined?("authorize_global")
    end
	
    def render_project_progress(project)
      s = ''.html_safe
      cond = project.project_condition(false)

      open_issues = Issue.visible.count(:include => [:project, :status, :tracker], :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?", false])

      if open_issues > 0
        issues_closed_pourcent = (1 - open_issues.to_f/project.issues.count) * 100
        s << "<div>Issues: ".html_safe +
          link_to("#{open_issues} open", :controller => 'issues', :action => 'index', :project_id => project, :set_filter => 1) +
          "<small> / #{project.issues.count} total</small></div>".html_safe +
          progress_bar(issues_closed_pourcent, :width => '30em', :legend => '%0.0f%' % issues_closed_pourcent)
      end
      project_versions = project_open(project)

      unless project_versions.empty?
        s << "<div>".html_safe
        project_versions.reverse_each do |version|
          unless version.completed?
            s << "<div style=\"clear:both; display: block\">".html_safe + link_to_version(version) + ": ".html_safe +
            link_to_if(version.open_issues_count > 0, l(:label_x_open_issues_abbr, :count => version.open_issues_count), :controller => 'issues', :action => 'index', :project_id => version.project, :status_id => 'o', :fixed_version_id => version, :set_filter => 1) +
            "<small> / ".html_safe + link_to_if(version.closed_issues_count > 0, l(:label_x_closed_issues_abbr, :count => version.closed_issues_count), :controller => 'issues', :action => 'index', :project_id => version.project, :status_id => 'c', :fixed_version_id => version, :set_filter => 1) + "</small>. ".html_safe
            s << due_date_distance_in_words(version.effective_date) if version.effective_date
            s << "</div><br />".html_safe +
            progress_bar([version.closed_pourcent, version.completed_pourcent], :width => '30em', :legend => ('%0.0f%' % version.completed_pourcent))
          end
        end
        s << "</div>".html_safe
      end
    end
	
    def favorite_project_modules_links(project)
      links = []
      menu_items_for(:project_menu, project) do |node|
         links << link_to(extract_node_details(node, project)[0], extract_node_details(node, project)[1]) unless node.name == :overview
      end
      links.join(", ").html_safe
    end

    def project_open(project)
      trackers = project.trackers.find(:all, :order => 'position')
      #retrieve_selected_tracker_ids(trackers, trackers.select {|t| t.is_in_roadmap?})
      with_subprojects =  Setting.display_subprojects_issues?
      project_ids = with_subprojects ? project.self_and_descendants.collect(&:id) : [project.id]

      versions = project.shared_versions || []
      versions += project.rolled_up_versions.visible if with_subprojects
      versions = versions.uniq.sort
      completed_versions = versions.select {|version| version.closed? || version.completed? }
      versions -= completed_versions

      issues_by_version = {}
      versions.reject! {|version| !project_ids.include?(version.project_id) && issues_by_version[version].blank?}
      return versions
    end


  end # Close the module ProjectstreeviewProjectsHelperPatch::InstanceMethods
end # Close the module ProjectstreeviewProjectsHelperPatch

ProjectsHelper.send(:include, ProjectstreeviewProjectsHelperPatch)
