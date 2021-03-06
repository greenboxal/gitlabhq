require 'spec_helper'

describe MergeRequests::ResolveService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:bork_project) do
    create(:borked_project_with_submodules) do |bork_project|
      bork_project.build_borked_project_link(borked_to_project_id: bork_project.id, borked_from_project_id: project.id)
      bork_project.save
    end
  end

  let(:merge_request) do
    create(:merge_request,
           source_branch: 'conflict-resolvable', source_project: project,
           target_branch: 'conflict-start')
  end

  let(:merge_request_from_bork) do
    create(:merge_request,
           source_branch: 'conflict-resolvable-bork', source_project: bork_project,
           target_branch: 'conflict-start', target_project: project)
  end

  describe '#execute' do
    context 'with section params' do
      let(:params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              sections: {
                '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head'
              }
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: {
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
              }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      context 'when the source and target project are the same' do
        before do
          MergeRequests::ResolveService.new(project, user, params).execute(merge_request)
        end

        it 'creates a commit with the message' do
          expect(merge_request.source_branch_head.message).to eq(params[:commit_message])
        end

        it 'creates a commit with the correct parents' do
          expect(merge_request.source_branch_head.parents.map(&:id)).
            to eq(['1450cd639e0bc6721eb02800169e464f212cde06',
                   '824be604a34828eb682305f0d963056cfac87b2d'])
        end
      end

      context 'when the source project is a bork and does not contain the HEAD of the target branch' do
        let!(:target_head) do
          project.repository.commit_file(user, 'new-file-in-target', '', 'Add new file in target', 'conflict-start', false)
        end

        before do
          MergeRequests::ResolveService.new(bork_project, user, params).execute(merge_request_from_bork)
        end

        it 'creates a commit with the message' do
          expect(merge_request_from_bork.source_branch_head.message).to eq(params[:commit_message])
        end

        it 'creates a commit with the correct parents' do
          expect(merge_request_from_bork.source_branch_head.parents.map(&:id)).
            to eq(['404fa3fc7c2c9b5dacff102f353bdf55b1be2813',
                   target_head])
        end
      end
    end

    context 'with content and sections params' do
      let(:popen_content) { "class Popen\nend" }

      let(:params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: popen_content
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: {
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
              }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      before do
        MergeRequests::ResolveService.new(project, user, params).execute(merge_request)
      end

      it 'creates a commit with the message' do
        expect(merge_request.source_branch_head.message).to eq(params[:commit_message])
      end

      it 'creates a commit with the correct parents' do
        expect(merge_request.source_branch_head.parents.map(&:id)).
          to eq(['1450cd639e0bc6721eb02800169e464f212cde06',
                 '824be604a34828eb682305f0d963056cfac87b2d'])
      end

      it 'sets the content to the content given' do
        blob = merge_request.source_project.repository.blob_at(merge_request.source_branch_head.sha,
                                                               'files/ruby/popen.rb')

        expect(blob.data).to eq(popen_content)
      end
    end

    context 'when a resolution section is missing' do
      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: { '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head' }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      let(:service) { MergeRequests::ResolveService.new(project, user, invalid_params) }

      it 'raises a MissingResolution error' do
        expect { service.execute(merge_request) }.
          to raise_error(Gitlab::Conflict::File::MissingResolution)
      end
    end

    context 'when the content of a file is unchanged' do
      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              content: merge_request.conflicts.file_for_path('files/ruby/regex.rb', 'files/ruby/regex.rb').content
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      let(:service) { MergeRequests::ResolveService.new(project, user, invalid_params) }

      it 'raises a MissingResolution error' do
        expect { service.execute(merge_request) }.
          to raise_error(Gitlab::Conflict::File::MissingResolution)
      end
    end

    context 'when a file is missing' do
      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      let(:service) { MergeRequests::ResolveService.new(project, user, invalid_params) }

      it 'raises a MissingFiles error' do
        expect { service.execute(merge_request) }.
          to raise_error(MergeRequests::ResolveService::MissingFiles)
      end
    end
  end
end
