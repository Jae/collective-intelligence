require 'bundler/setup'
require File.join(File.dirname(__FILE__), %w[delicious deliruby])
require File.join(File.dirname(__FILE__), %w[recommendations])
require File.join(File.dirname(__FILE__), %w[pearson_correlation])

recent_bookmark = Deliruby::Bookmarks.recent[0]
users = Deliruby::Bookmarks.for_url(recent_bookmark.url).map {|bookmark| bookmark.creator}
users << recent_bookmark.creator unless users.include? recent_bookmark.creator

bookmarks = users.reduce({}) do |bookmarks, user|
  # filter the data set to the tags of recent_bookmark to increase relevancy
  bookmarks_with_common_tags = recent_bookmark.tags.map do |tag|
    Deliruby::Bookmarks.for_user(user, [tag]).map {|bookmark| bookmark.url} rescue nil
  end.flatten.uniq
  
  bookmarks[user] = bookmarks_with_common_tags unless bookmarks_with_common_tags.empty?
  bookmarks
end

all_bookmarks = bookmarks.values.flatten.uniq
ratings = bookmarks.keys.reduce({}) do |ratings, user|
  bookmarks[user].each {|bookmark| (ratings[user]||={})[bookmark] = 1.0}
  (all_bookmarks - bookmarks[user]).each {|bookmark| (ratings[user]||={})[bookmark] = 0.0}
  ratings
end

recommended = Recommendations.top_matches(recent_bookmark.url, Recommendations.transpose(ratings))  do |ratings1, ratings2| 
  PearsonCorrelation.similarity_score(ratings1, ratings2)
end

puts "if you enjoyed #{recent_bookmark.url} tagged with #{recent_bookmark.tags}, then check out the following #{recommended.keys}"