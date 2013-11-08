require 'spec_helper'

describe DocRepo do

  include ShellOut
  include_context 'tmp_dirs'

  describe '#download_and_unzip' do
    let(:destination_dir) { tmp_subdir 'middleman_source_dir' }
    let(:zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-docs-repo', 'some-sha' }
    let(:repo_hash) { {'github_repo' => 'my-docs-org/my-docs-repo', 'sha' => 'some-sha'} }
    let(:repo) { DocRepo.new(repo_hash, nil, nil, local_repo_dir) }

    context 'when told to look for repos on github' do
      let(:local_repo_dir) { nil }

      it 'downloads and unzips the repo' do
        stub_request(:get, 'https://github.com/my-docs-org/my-docs-repo/archive/some-sha.tar.gz').to_return(
            :body => zipped_markdown_repo, :headers => { 'Content-Type' => 'application/x-gzip' }
        )
        repo.copy_to destination_dir
        index_html = File.read File.join(destination_dir, 'my-docs-repo', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end
    end

    context 'when told to look for repos locally' do
      let(:local_repo_dir) { MarkdownRepoFixture.copy_to_tmp_repo_dir }

      it 'finds them in the supplied directory' do
        repo.copy_to destination_dir
        index_html = File.read File.join(destination_dir, 'my-docs-repo', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end

      context 'when the repo is not present in the supplied directory' do
        let(:repo_hash) { {'github_repo' => 'my-docs-org/my-non-existent-docs-repo'} }
        it 'gracefully skips repos that are not present in the supplied directory' do
          repo.copy_to destination_dir
          new_entries = Dir.entries(destination_dir) - ['..', '.']
          expect(new_entries.size).to eq(0)
        end
      end
    end

    context 'when a custom directory is specified for the repo' do
      let(:local_repo_dir) { MarkdownRepoFixture.copy_to_tmp_repo_dir }
      let(:repo_hash) { {'github_repo' => 'my-docs-org/my-docs-repo',
                         'sha' => 'some-sha', 'directory' => 'pretty_url_path'} }

      it "puts the repo into that directory" do
        stub_request(:get, 'https://github.com/my-docs-org/my-docs-repo/archive/some-sha.tar.gz').to_return(
            :body => zipped_markdown_repo, :headers => { 'Content-Type' => 'application/x-gzip' }
        )
        repo.copy_to destination_dir
        index_html = File.read File.join(destination_dir, 'pretty_url_path', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end
    end
  end
end