class Spinach::Features::ProjectBorkedMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths
  include Select2Helper

  step 'I am a member of project "Shop"' do
    @project = Project.find_by(name: "Shop")
    @project ||= create(:project, name: "Shop")
    @project.team << [@user, :reporter]
  end

  step 'I have a project borked off of "Shop" called "Borked Shop"' do
    @borked_project = Projects::BorkService.new(@project, @user).execute
  end

  step 'I click link "New Merge Request"' do
    click_link "New Merge Request"
  end

  step 'I should see merge request "Merge Request On Borked Project"' do
    expect(@project.merge_requests.size).to be >= 1
    @merge_request = @project.merge_requests.last
    expect(current_path).to eq namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
    expect(@merge_request.title).to eq "Merge Request On Borked Project"
    expect(@merge_request.source_project).to eq @borked_project
    expect(@merge_request.source_branch).to eq "fix"
    expect(@merge_request.target_branch).to eq "master"
    expect(page).to have_content @borked_project.path_with_namespace
    expect(page).to have_content @project.path_with_namespace
    expect(page).to have_content @merge_request.source_branch
    expect(page).to have_content @merge_request.target_branch
  end

  step 'I fill out a "Merge Request On Borked Project" merge request' do
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    first('.js-source-project').click
    first('.dropdown-source-project a', text: @borked_project.path_with_namespace)

    first('.js-target-project').click
    first('.dropdown-target-project a', text: @project.path_with_namespace)

    first('.js-source-branch').click
    first('.dropdown-source-branch .dropdown-content a', text: 'fix').click

    click_button "Compare branches and continue"

    expect(page).to have_css("h3.page-title", text: "New Merge Request")

    page.within 'form#new_merge_request' do
      fill_in "merge_request_title", with: "Merge Request On Borked Project"
    end
  end

  step 'I submit the merge request' do
    click_button "Submit merge request"
  end

  step 'I follow the target commit link' do
    commit = @project.repository.commit
    click_link commit.short_id(8)
  end

  step 'I should see the commit under the borked from project' do
    commit = @project.repository.commit
    expect(page).to have_content(commit.message)
  end

  step 'I click "Create Merge Request on bork" link' do
    click_link "Create Merge Request on bork"
  end

  step 'I see prefilled new Merge Request page for the borked project' do
    expect(current_path).to eq new_namespace_project_merge_request_path(@borked_project.namespace, @borked_project)
    expect(find("#merge_request_source_project_id").value).to eq @borked_project.id.to_s
    expect(find("#merge_request_target_project_id").value).to eq @project.id.to_s
    expect(find("#merge_request_source_branch").value).to have_content "new_design"
    expect(find("#merge_request_target_branch").value).to have_content "master"
    expect(find("#merge_request_title").value).to eq "New Design"
    verify_commit_link(".mr_target_commit", @project)
    verify_commit_link(".mr_source_commit", @borked_project)
  end

  step 'I update the merge request title' do
    fill_in "merge_request_title", with: "An Edited Borked Merge Request"
  end

  step 'I save the merge request' do
    click_button "Save changes"
  end

  step 'I should see the edited merge request' do
    expect(page).to have_content "An Edited Borked Merge Request"
    expect(@project.merge_requests.size).to be >= 1
    @merge_request = @project.merge_requests.last
    expect(current_path).to eq namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
    expect(@merge_request.source_project).to eq @borked_project
    expect(@merge_request.source_branch).to eq "fix"
    expect(@merge_request.target_branch).to eq "master"
    expect(page).to have_content @borked_project.path_with_namespace
    expect(page).to have_content @project.path_with_namespace
    expect(page).to have_content @merge_request.source_branch
    expect(page).to have_content @merge_request.target_branch
  end

  step 'I should see last push widget' do
    expect(page).to have_content "You pushed to new_design"
    expect(page).to have_link "Create Merge Request"
  end

  step 'I click link edit "Merge Request On Borked Project"' do
    find("#edit_merge_request").click
  end

  step 'I see the edit page prefilled for "Merge Request On Borked Project"' do
    expect(current_path).to eq edit_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
    expect(page).to have_content "Edit merge request #{@merge_request.to_reference}"
    expect(find("#merge_request_title").value).to eq "Merge Request On Borked Project"
  end

  step 'I fill out an invalid "Merge Request On Borked Project" merge request' do
    expect(find_by_id("merge_request_source_project_id", visible: false).value).to eq @borked_project.id.to_s
    expect(find_by_id("merge_request_target_project_id", visible: false).value).to eq @project.id.to_s
    expect(find_by_id("merge_request_source_branch", visible: false).value).to eq nil
    expect(find_by_id("merge_request_target_branch", visible: false).value).to eq "master"
    click_button "Compare branches"
  end

  step 'I should see validation errors' do
    expect(page).to have_content "You must select source and target branch"
  end

  step 'the target repository should be the original repository' do
    expect(find_by_id("merge_request_target_project_id").value).to eq "#{@project.id}"
  end

  step 'I click "Assign to" dropdown"' do
    click_button 'Assignee'
  end

  step 'I should see the target project ID in the input selector' do
    expect(find('.js-assignee-search')["data-project-id"]).to eq "#{@project.id}"
  end

  step 'I should see the users from the target project ID' do
    page.within '.dropdown-menu-user' do
      expect(page).to have_content 'Unassigned'
      expect(page).to have_content current_user.name
      expect(page).to have_content @project.users.first.name
    end
  end

  # Verify a link is generated against the correct project
  def verify_commit_link(container_div, container_project)
    # This should force a wait for the javascript to execute
    expect(find(:div, container_div).find(".commit_short_id")['href']).to have_content "#{container_project.path_with_namespace}/commit"
  end
end
