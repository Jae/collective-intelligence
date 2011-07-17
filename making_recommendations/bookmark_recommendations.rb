require 'bundler/setup'
require File.dirname(__FILE__) + '/delicious/deliruby'
require File.dirname(__FILE__) + '/recommendations'
require File.dirname(__FILE__) + '/pearson_correlation'

popular_bookmark = Deliruby::Bookmarks.recent[0]
users = Deliruby::Bookmarks.for_url(popular_bookmark.url).map {|bookmark| bookmark.creator}
users << popular_bookmark.creator unless users.include? popular_bookmark.creator

bookmarks = users.reduce({}) do |bookmarks, user|
  # filter the data set to the tags of popular_bookmark to increase relevancy
  bookmarks_with_common_tags = popular_bookmark.tags.map do |tag|
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

recommended = Recommendations.top_matches(popular_bookmark.url, Recommendations.transpose(ratings))  do |ratings1, ratings2| 
  PearsonCorrelation.similarity_score(ratings1, ratings2)
end

puts "if you enjoyed #{popular_bookmark.url}, then check out the following #{recommended.map {|r| r[0]}}"