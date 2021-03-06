require 'spec_helper'

describe MergeRequests::RefreshService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { MergeRequests::RefreshService }

  describe '#execute' do
    before do
      @user = create(:user)
      group = create(:group)
      group.add_owner(@user)

      @project = create(:project, namespace: group)
      @bork_project = Projects::BorkService.new(@project, @user).execute
      @merge_request = create(:merge_request,
                              source_project: @project,
                              source_branch: 'master',
                              target_branch: 'feature',
                              target_project: @project,
                              merge_when_build_succeeds: true,
                              merge_user: @user)

      @bork_merge_request = create(:merge_request,
                                   source_project: @bork_project,
                                   source_branch: 'master',
                                   target_branch: 'feature',
                                   target_project: @project)

      @build_failed_todo = create(:todo,
                                  :build_failed,
                                  user: @user,
                                  project: @project,
                                  target: @merge_request,
                                  author: @user)

      @bork_build_failed_todo = create(:todo,
                                       :build_failed,
                                       user: @user,
                                       project: @project,
                                       target: @merge_request,
                                       author: @user)

      @commits = @merge_request.commits

      @oldrev = @commits.last.id
      @newrev = @commits.first.id
    end

    context 'push to origin repo source branch' do
      let(:refresh_service) { service.new(@project, @user) }
      before do
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it 'executes hooks with update action' do
        expect(refresh_service).to have_received(:execute_hooks).
          with(@merge_request, 'update', @oldrev)
      end

      it { expect(@merge_request.notes).not_to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@merge_request.merge_when_build_succeeds).to be_falsey }
      it { expect(@merge_request.diff_head_sha).to eq(@newrev) }
      it { expect(@bork_merge_request).to be_open }
      it { expect(@bork_merge_request.notes).to be_empty }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@bork_build_failed_todo).to be_done }
    end

    context 'push to origin repo target branch' do
      before do
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@bork_merge_request).to be_merged }
      it { expect(@bork_merge_request.notes.last.note).to include('merged') }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@bork_build_failed_todo).to be_done }
    end

    context 'manual merge of source branch' do
      before do
        # Merge master -> feature branch
        author = { email: 'test@doggohub.com', time: Time.now, name: "Me" }
        commit_options = { message: 'Test message', committer: author, author: author }
        @project.repository.merge(@user, @merge_request, commit_options)
        commit = @project.repository.commit('feature')
        service.new(@project, @user).execute(@oldrev, commit.id, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@merge_request.diffs.size).to be > 0 }
      it { expect(@bork_merge_request).to be_merged }
      it { expect(@bork_merge_request.notes.last.note).to include('merged') }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@bork_build_failed_todo).to be_done }
    end

    context 'push to bork repo source branch' do
      let(:refresh_service) { service.new(@bork_project, @user) }
      before do
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it 'executes hooks with update action' do
        expect(refresh_service).to have_received(:execute_hooks).
          with(@bork_merge_request, 'update', @oldrev)
      end

      it { expect(@merge_request.notes).to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@bork_merge_request.notes.last.note).to include('added 28 commits') }
      it { expect(@bork_merge_request).to be_open }
      it { expect(@build_failed_todo).to be_pending }
      it { expect(@bork_build_failed_todo).to be_pending }
    end

    context 'push to bork repo target branch' do
      describe 'changes to merge requests' do
        before do
          service.new(@bork_project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          reload_mrs
        end

        it { expect(@merge_request.notes).to be_empty }
        it { expect(@merge_request).to be_open }
        it { expect(@bork_merge_request.notes).to be_empty }
        it { expect(@bork_merge_request).to be_open }
        it { expect(@build_failed_todo).to be_pending }
        it { expect(@bork_build_failed_todo).to be_pending }
      end

      describe 'merge request diff' do
        it 'does not reload the diff of the merge request made from bork' do
          expect do
            service.new(@bork_project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          end.not_to change { @bork_merge_request.reload.merge_request_diff }
        end
      end
    end

    context 'push to origin repo target branch after bork project was removed' do
      before do
        @bork_project.destroy
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@bork_merge_request).to be_open }
      it { expect(@bork_merge_request.notes).to be_empty }
      it { expect(@build_failed_todo).to be_done }
      it { expect(@bork_build_failed_todo).to be_done }
    end

    context 'push new branch that exists in a merge request' do
      let(:refresh_service) { service.new(@bork_project, @user) }

      it 'refreshes the merge request' do
        expect(refresh_service).to receive(:execute_hooks).
                                       with(@bork_merge_request, 'update', Gitlab::Git::BLANK_SHA)
        allow_any_instance_of(Repository).to receive(:merge_base).and_return(@oldrev)

        refresh_service.execute(Gitlab::Git::BLANK_SHA, @newrev, 'refs/heads/master')
        reload_mrs

        expect(@merge_request.notes).to be_empty
        expect(@merge_request).to be_open

        notes = @bork_merge_request.notes.reorder(:created_at).map(&:note)
        expect(notes[0]).to include('restored source branch `master`')
        expect(notes[1]).to include('added 28 commits')
        expect(@bork_merge_request).to be_open
      end
    end

    context 'merge request metrics' do
      let(:issue) { create :issue, project: @project }
      let(:commit_author) { create :user }
      let(:commit) { project.commit }

      before do
        project.team << [commit_author, :developer]
        project.team << [user, :developer]

        allow(commit).to receive_messages(
          safe_message: "Closes #{issue.to_reference}",
          references: [issue],
          author_name: commit_author.name,
          author_email: commit_author.email,
          committed_date: Time.now
        )

        allow_any_instance_of(MergeRequest).to receive(:commits).and_return([commit])
      end

      context 'when the merge request is sourced from the same project' do
        it 'creates a `MergeRequestsClosingIssues` record for each issue closed by a commit' do
          merge_request = create(:merge_request, target_branch: 'master', source_branch: 'feature', source_project: @project)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/feature')

          issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
          expect(issue_ids).to eq([issue.id])
        end
      end

      context 'when the merge request is sourced from a different project' do
        it 'creates a `MergeRequestsClosingIssues` record for each issue closed by a commit' do
          borked_project = create(:project)
          create(:borked_project_link, borked_to_project: borked_project, borked_from_project: @project)

          merge_request = create(:merge_request,
                                 target_branch: 'master',
                                 source_branch: 'feature',
                                 target_project: @project,
                                 source_project: borked_project)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/feature')

          issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
          expect(issue_ids).to eq([issue.id])
        end
      end
    end

    def reload_mrs
      @merge_request.reload
      @bork_merge_request.reload
      @build_failed_todo.reload
      @bork_build_failed_todo.reload
    end
  end
end
