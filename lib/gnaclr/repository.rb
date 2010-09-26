module Gnaclr
  module Repository
    def self.get_repo(classification_id)
      classification = Classification.first(:id => classification_id)
      Grit::Repo.new(File.join(SiteConfig.files_path, classification.uuid))
    end

    def self.get_commits(repo, classification)
      count = 0
      repo.commits.map do |c| 
        count += 1 
        {
          :sequence_number => count, 
          :committed_date => c.committed_date, 
          :message => c.message, 
          :id => c.id, 
          :tree_id => c.tree.id,
          :file_name => c.tree.blobs.first.name, 
          :url_path => "#{SiteConfig.url_base}/classification_file/#{classification.id}/#{c.tree.id}" 
        }
      end
    end
  end
end
