class UpVote < Vote
  belongs_to :entry, counter_cache: true
  
  after_create {|record| VoteActivity.write(record)}
end