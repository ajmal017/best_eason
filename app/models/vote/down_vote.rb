class DownVote < Vote
  belongs_to :entry, counter_cache: true
  
end